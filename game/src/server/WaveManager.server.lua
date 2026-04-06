-- WaveManager.server.lua
-- Gestion des manches, spawn de zombies, progression
-- Système #1 (Critique)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = ReplicatedStorage:WaitForChild("Events")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local ZombieConfig = require(Shared:WaitForChild("ZombieConfig"))
local Constants = require(Shared:WaitForChild("Constants"))

-- State
local currentWave = 0
local zombiesAlive = 0
local zombiesToSpawn = 0
local gameActive = false
local isHardcore = false
local activeZombies = {} -- table de tous les zombies NPC en vie

-- Events
local UpdateWave = Events:WaitForChild("UpdateWave")
local WaveCompleted = Events:WaitForChild("WaveCompleted")
local ShowNotification = Events:WaitForChild("ShowNotification")
local GameOver = Events:WaitForChild("GameOver")
local GameStarted = Events:WaitForChild("GameStarted")
local ZombieDied = Events:WaitForChild("ZombieDied")

-- === FONCTIONS UTILITAIRES ===

local function getAlivePlayers()
	local alive = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local sessionData = player:FindFirstChild("SessionData")
		if sessionData and sessionData:FindFirstChild("IsAlive") then
			if sessionData.IsAlive.Value then
				local char = player.Character
				if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
					table.insert(alive, player)
				end
			end
		end
	end
	return alive
end

local function getClosestPlayer(position)
	local closest = nil
	local closestDist = math.huge
	for _, player in ipairs(getAlivePlayers()) do
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local dist = (char.HumanoidRootPart.Position - position).Magnitude
			if dist < closestDist then
				closestDist = dist
				closest = player
			end
		end
	end
	return closest
end

local function getZombieSpawnPoints()
	local spawns = workspace:FindFirstChild("ZombieSpawns")
	if not spawns then
		warn("[WaveManager] Dossier ZombieSpawns introuvable dans Workspace ! Création...")
		spawns = Instance.new("Folder")
		spawns.Name = "ZombieSpawns"
		spawns.Parent = workspace
	end

	local children = spawns:GetChildren()
	
	if #children == 0 then
		warn("[WaveManager] Le dossier ZombieSpawns est vide ! Création de 4 points de spawn par défaut...")
		for i = 1, 4 do
			local part = Instance.new("Part")
			part.Name = "Spawn_" .. i
			part.Anchored = true
			part.CanCollide = false
			part.Transparency = 1
			part.Size = Vector3.new(4, 1, 4)
			part.Position = Vector3.new(math.random(-50, 50), 5, math.random(-50, 50))
			part.Parent = spawns
		end
		children = spawns:GetChildren()
	end
	
	-- Forcer tous les points de spawn à être invisibles en jeu au cas où
	for _, spawnPoint in ipairs(children) do
		if spawnPoint:IsA("BasePart") then
			spawnPoint.Transparency = 1
			spawnPoint.CanCollide = false
			-- S'il y a un Decal (logo de SpawnLocation), on le cache aussi
			for _, child in ipairs(spawnPoint:GetChildren()) do
				if child:IsA("Decal") or child:IsA("Texture") then
					child.Transparency = 1
				end
			end
		end
	end
	
	return children
end

-- === SONS ZOMBIE ===
-- On réutilise les sons déjà dans les templates Toolbox.
-- Si aucun son n'existe dans le template, on en crée avec les sons
-- par défaut de Roblox (Humanoid/Splash etc.) qui ne nécessitent pas d'autorisation.

local function setupZombieSounds(zombie)
	local rootPart = zombie:FindFirstChild("HumanoidRootPart") or zombie.PrimaryPart
	local head = zombie:FindFirstChild("Head")
	local soundParent = head or rootPart
	if not soundParent then return end

	-- Collecter TOUS les sons existants dans le template (modèles Toolbox)
	local existingSounds = {}
	for _, desc in ipairs(zombie:GetDescendants()) do
		if desc:IsA("Sound") then
			table.insert(existingSounds, desc)
		end
	end

	if #existingSounds > 0 then
		-- Le template a des sons ! Les configurer (pas en boucle permanente)
		print("[WaveManager] Sons template trouvés (" .. #existingSounds .. ") pour " .. zombie.Name)
		local groanSounds = {}
		for _, snd in ipairs(existingSounds) do
			snd.RollOffMaxDistance = 60
			snd.RollOffMinDistance = 8
			snd.Looped = false
			snd.Volume = math.min(snd.Volume, 0.4)
			-- Inclure tous les sons (pas seulement ceux avec un nom spécifique)
			table.insert(groanSounds, snd)
		end
		-- Jouer un son aléatoire toutes les 4-10 secondes
		if #groanSounds > 0 then
			task.spawn(function()
				local humanoid = zombie:FindFirstChildOfClass("Humanoid")
				while zombie.Parent and humanoid and humanoid.Health > 0 do
					task.wait(math.random(4, 10))
					if zombie.Parent and humanoid.Health > 0 then
						local snd = groanSounds[math.random(1, #groanSounds)]
						snd.PlaybackSpeed = 0.8 + math.random() * 0.4
						snd:Play()
					end
				end
			end)
		end
	else
		-- Pas de sons dans le template → créer un grognement zombie maison
		-- On utilise le système Humanoid de Roblox : quand un Humanoid bouge,
		-- il joue déjà des sons de pas. On ajoute juste un grognement ambiant.
		print("[WaveManager] Pas de sons template pour " .. zombie.Name .. " — grognement Humanoid activé")

		-- Activer les sons Humanoid par défaut (Running, etc.)
		local humanoid = zombie:FindFirstChildOfClass("Humanoid")
		if humanoid then
			-- Le HumanoidRootPart a normalement des sons par défaut de Roblox
			-- On cherche les sons qui existent déjà dans le HumanoidRootPart
			local hrpSounds = rootPart and rootPart:GetChildren() or {}
			for _, child in ipairs(hrpSounds) do
				if child:IsA("Sound") then
					child.Volume = 0.3
					child.RollOffMaxDistance = 60
				end
			end
		end
	end
end

-- === ZOMBIE CREATION ===

local function chooseZombieType(wave)
	if wave >= GameConfig.SPECIAL_ZOMBIE_START_WAVE then
		if math.random() < GameConfig.SPECIAL_ZOMBIE_CHANCE then
			-- Choisir un type spécial basé sur les poids
			local totalWeight = 0
			for _, entry in ipairs(ZombieConfig.SpecialDistribution) do
				totalWeight += entry.weight
			end
			local roll = math.random(1, totalWeight)
			local cumulative = 0
			for _, entry in ipairs(ZombieConfig.SpecialDistribution) do
				cumulative += entry.weight
				if roll <= cumulative then
					return entry.type
				end
			end
		end
	end
	return "Basic"
end

local function createZombieModel(zombieType, wave)
	local config = ZombieConfig.Types[zombieType]
	if not config then
		config = ZombieConfig.Types.Basic
	end

	local zombie
	local templates = ServerStorage:FindFirstChild("ZombieTemplates")
	local template = nil
	if templates then
		-- Chercher le template par nom (Enemy_Basic, Basic, ou displayName comme "Zombie")
		local found = templates:FindFirstChild("Enemy_" .. zombieType) or templates:FindFirstChild(zombieType) or templates:FindFirstChild(config.displayName)
		if found then
			if found:IsA("Model") then
				-- Template unique
				template = found
			elseif found:IsA("Folder") then
				-- Dossier de variantes → choisir au hasard
				local variants = found:GetChildren()
				if #variants > 0 then
					template = variants[math.random(1, #variants)]
				end
			end
		end
	end

	if template then
		zombie = template:Clone()
		zombie.Name = "Enemy_" .. zombieType
		-- Assurer l'existence du PrimaryPart (généralement HumanoidRootPart)
		if not zombie.PrimaryPart then
			zombie.PrimaryPart = zombie:FindFirstChild("HumanoidRootPart") or zombie:FindFirstChild("Torso")
		end

		-- Supprimer les scripts Toolbox cassés qui spamment des erreurs :
		-- - SoundScript cherche Head.Moan qui n'existe pas → crash
		-- - Health cherche Humanoid via WaitForChild → infinite yield
		-- Les objets Sound (grognements, etc.) sont PRÉSERVÉS et joués par setupZombieSounds()
		for _, s in ipairs(zombie:GetDescendants()) do
			if s:IsA("Script") and (s.Name == "Health" or s.Name == "SoundScript") then
				s:Destroy()
			end
		end

		-- S'assurer que le zombie téléchargé peut bouger (désancrer toutes les parts)
		for _, desc in ipairs(zombie:GetDescendants()) do
			if desc:IsA("BasePart") then
				desc.Anchored = false
			end
		end
	else
		-- Créer un modèle zombie simple (NPC humanoïde)
		zombie = Instance.new("Model")
		zombie.Name = "Enemy_" .. zombieType

		-- Créer les parties du corps
		local torso = Instance.new("Part")
		torso.Name = "HumanoidRootPart"
		torso.Size = Vector3.new(2 * config.scale, 2 * config.scale, 1 * config.scale)
		torso.Color = config.color
		torso.Anchored = false
		torso.CanCollide = true
		torso.Parent = zombie

		local head = Instance.new("Part")
		head.Name = "Head"
		head.Shape = Enum.PartType.Ball
		head.Size = Vector3.new(1.2 * config.scale, 1.2 * config.scale, 1.2 * config.scale)
		head.Color = config.color
		head.Anchored = false
		head.CanCollide = false
		head.Parent = zombie

		-- Weld head to torso
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = torso
		weld.Part1 = head
		weld.Parent = head
		head.CFrame = torso.CFrame * CFrame.new(0, 1.5 * config.scale, 0)
		
		zombie.PrimaryPart = torso
	end

	-- Humanoid
	local humanoid = zombie:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		humanoid = Instance.new("Humanoid")
		print("[WaveManager] Ajout d'un Humanoid manquant sur le template " .. zombieType)
		humanoid.Parent = zombie
	end
	
	local hp
	if zombieType == "Basic" then
		-- Les 4 premières manches : 3 balles de Pistolet (45 HP)
		if wave <= 4 then
			hp = 45
		else
			-- À partir de la manche 5, on ajoute 15 HP par manche
			-- jusqu'à une limite stricte de 180 HP (12 balles de pistolet max)
			local extraWaves = wave - 4
			hp = math.min(45 + (extraWaves * 15), 180)
		end
	else
		hp = config.baseHp + (config.hpPerWave * wave)
	end
	
	humanoid.MaxHealth = hp
	humanoid.Health = hp
	
	-- Les zombies sont plus lents pendant les 5 premières manches (Manche 1 = 60%, Manche 5 = 100%)
	local speedMult = 1
	if wave < 5 then
		speedMult = 0.5 + (wave * 0.1)
	end
	humanoid.WalkSpeed = config.speed * speedMult

	-- Attributs custom
	zombie:SetAttribute("ZombieType", zombieType)
	zombie:SetAttribute("Damage", config.damage)
	zombie:SetAttribute("Reward", config.reward)
	zombie:SetAttribute("Wave", wave)

	if zombieType == "Explosive" then
		zombie:SetAttribute("ExplosionRadius", config.explosionRadius)
		zombie:SetAttribute("TriggerDistance", config.triggerDistance)

		-- Ajouter particule seulement si pas déjà géré par le modèle custom
		local torso = zombie:FindFirstChild("HumanoidRootPart") or zombie.PrimaryPart
		if torso and not torso:FindFirstChildOfClass("ParticleEmitter") then
			local particles = Instance.new("ParticleEmitter")
			particles.Color = ColorSequence.new(Color3.fromRGB(255, 100, 0))
			particles.Size = NumberSequence.new(0.5)
			particles.Rate = 20
			particles.Lifetime = NumberRange.new(0.5, 1)
			particles.Speed = NumberRange.new(1, 3)
			particles.Parent = torso
		end
	end

	for _, part in ipairs(zombie:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = "Zombies"
			part.Anchored = false
		elseif (part:IsA("Script") or part:IsA("LocalScript"))
			and (part.Name == "Respawn" or part.Name == "Script") then
			part:Destroy()
		end
		-- NOTE : On préserve les objets Sound pour les voix/grognements
	end

	-- Ajouter/activer les sons zombies (grognements, attaque, mort)
	setupZombieSounds(zombie)

	return zombie
end

local function setupZombieAI(zombie)
	local PathfindingService = game:GetService("PathfindingService")
	local humanoid = zombie:FindFirstChildOfClass("Humanoid")
	local rootPart = zombie:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then return end

	local zombieType = zombie:GetAttribute("ZombieType") or "Basic"
	local damage = zombie:GetAttribute("Damage") or 10
	local isDead = false

	-- Boucle IA
	task.spawn(function()
		while not isDead and humanoid.Health > 0 do
			local target = getClosestPlayer(rootPart.Position)
			if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
				local targetPos = target.Character.HumanoidRootPart.Position

				-- Zombie Explosif : vérifier la distance de déclenchement
				if zombieType == "Explosive" then
					local dist = (rootPart.Position - targetPos).Magnitude
					local triggerDist = zombie:GetAttribute("TriggerDistance") or 5
					if dist <= triggerDist then
						-- EXPLOSION
						local explosionRadius = zombie:GetAttribute("ExplosionRadius") or 10
						for _, player in ipairs(getAlivePlayers()) do
							local pChar = player.Character
							if pChar and pChar:FindFirstChild("HumanoidRootPart") then
								local d = (pChar.HumanoidRootPart.Position - rootPart.Position).Magnitude
								if d <= explosionRadius then
									local pHumanoid = pChar:FindFirstChildOfClass("Humanoid")
									if pHumanoid then
										pHumanoid:TakeDamage(damage)
									end
								end
							end
						end
						-- Effet d'explosion
						local explosion = Instance.new("Explosion")
						explosion.Position = rootPart.Position
						explosion.BlastRadius = explosionRadius
						explosion.BlastPressure = 0 -- pas de physics push
						explosion.DestroyJointRadiusPercent = 0
						explosion.Parent = workspace

						humanoid.Health = 0
						break
					end
				end

				-- Pathfinding simplifié : MoveTo direct
				humanoid:MoveTo(targetPos)

				-- Dégâts au contact
				local dist = (rootPart.Position - targetPos).Magnitude
				if dist <= (GameConfig.ZOMBIE_ATTACK_RANGE or 5) then
					local targetHumanoid = target.Character:FindFirstChildOfClass("Humanoid")
					if targetHumanoid and targetHumanoid.Health > 0 then
						-- Cooldown global de 1 seconde pour le joueur (I-Frames)
						-- Évite de se faire One-Shot si 8 zombies tapent en même temps
						local lastHit = target.Character:GetAttribute("LastHitTime") or 0
						if tick() - lastHit >= 1 then
							target.Character:SetAttribute("LastHitTime", tick())
							-- On force 25 dégâts pour tuer en exactement 4 coups (sur 100 HP)
							targetHumanoid:TakeDamage(25)

							-- Jouer un son d'attaque si le zombie en a un
							for _, snd in ipairs(zombie:GetDescendants()) do
								if snd:IsA("Sound") then
									local ln = string.lower(snd.Name)
									if (ln == "attack" or ln == "bite" or ln == "hit") and not snd.Playing then
										snd:Play()
										break
									end
								end
							end
						end
					end
				end
			end

			task.wait(1) -- Update IA toutes les secondes
		end
	end)

	-- Gestion de la mort du zombie
	humanoid.Died:Connect(function()
		isDead = true
		zombiesAlive -= 1

		-- Arrêter tous les sons en boucle du zombie
		for _, snd in ipairs(zombie:GetDescendants()) do
			if snd:IsA("Sound") and snd.Looped then
				snd:Stop()
			end
		end

		-- Retirer de la liste active
		for i, z in ipairs(activeZombies) do
			if z == zombie then
				table.remove(activeZombies, i)
				break
			end
		end

		-- Notifier pour la récompense (EconomyManager écoute)
		local reward = zombie:GetAttribute("Reward") or 10
		ZombieDied:FireAllClients(zombieType, reward, rootPart.Position)

		-- Log
		print("[WaveManager] Zombie mort (" .. zombieType .. ") — Restants: " .. zombiesAlive)

		-- Nettoyage après délai
		task.delay(GameConfig.ZOMBIE_DESPAWN_TIME, function()
			if zombie and zombie.Parent then
				zombie:Destroy()
			end
		end)
	end)
end

-- === GESTION DES MANCHES ===

local function spawnWave(wave)
	local totalZombies = GameConfig.ZOMBIES_BASE + (wave * GameConfig.ZOMBIES_PER_WAVE)
	zombiesToSpawn = totalZombies
	zombiesAlive = totalZombies

	print("[WaveManager] Manche " .. wave .. " — " .. totalZombies .. " zombies")

	-- Notifier tous les clients
	UpdateWave:FireAllClients(wave)

	local spawnPoints = getZombieSpawnPoints()
	if #spawnPoints == 0 then
		warn("[WaveManager] Aucun point de spawn zombie !")
		return
	end

	-- Mélanger les points de spawn aléatoirement au début de la manche
	local rng = Random.new()
	local shuffledSpawns = {}
	for i, spawn in ipairs(spawnPoints) do
		shuffledSpawns[i] = spawn
	end
	for i = #shuffledSpawns, 2, -1 do
		local j = rng:NextInteger(1, i)
		shuffledSpawns[i], shuffledSpawns[j] = shuffledSpawns[j], shuffledSpawns[i]
	end

	-- Spawn progressif (manche 1 = tous en même temps avec délai aléatoire 0-5s)
	for i = 1, totalZombies do
		task.spawn(function()
			if not gameActive then return end

			-- Manche 1 : délai aléatoire entre 0 et 5s pour spawn simultané éparpillé
			if wave == 1 then
				task.wait(rng:NextNumber(0, 5))
			else
				local interval = rng:NextNumber() *
					(GameConfig.SPAWN_INTERVAL_MAX - GameConfig.SPAWN_INTERVAL_MIN) +
					GameConfig.SPAWN_INTERVAL_MIN
				task.wait(interval * (i - 1))
			end

			if not gameActive then return end

			local zombieType = chooseZombieType(wave)
			local zombie = createZombieModel(zombieType, wave)

			local spawnPoint = shuffledSpawns[rng:NextInteger(1, #shuffledSpawns)]
			local spawnPos = spawnPoint.Position + Vector3.new(
				rng:NextNumber(-3, 3), 3, rng:NextNumber(-3, 3)
			)
			zombie:SetPrimaryPartCFrame(CFrame.new(spawnPos))
			zombie.Parent = workspace

			table.insert(activeZombies, zombie)
			setupZombieAI(zombie)
		end)
	end
end

local function waitForWaveEnd()
	while zombiesAlive > 0 and gameActive do
		task.wait(0.5)
	end
end

local function gameLoop()
	gameActive = true
	currentWave = 0

	print("[WaveManager] Partie démarrée !")
	GameStarted:FireAllClients()

	while gameActive do
		currentWave += 1

		-- Afficher le numéro de manche
		ShowNotification:FireAllClients("MANCHE " .. currentWave, "#FFFFFF", 3)

		-- Délai avant le début de la manche
		local delay = GameConfig.WAVE_DELAY or 5
		if delay > 3 then
			task.wait(delay - 3)
		end
		
		-- Décompte visible
		for i = 3, 1, -1 do
			ShowNotification:FireAllClients("Spawns dans " .. i .. "...", "#FF5555", 1)
			task.wait(1)
		end

		-- Mettre à jour les leaderstats
		for _, player in ipairs(Players:GetPlayers()) do
			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats and leaderstats:FindFirstChild("Wave") then
				leaderstats.Wave.Value = currentWave
			end
		end

		-- Spawn la manche (le boss est géré par BossManager qui écoute le numéro de manche)
		spawnWave(currentWave)

		-- Attendre que tous les zombies soient morts
		waitForWaveEnd()

		if not gameActive then break end

		-- Manche terminée !
		print("[WaveManager] Manche " .. currentWave .. " terminée !")
		WaveCompleted:FireAllClients(currentWave)

		-- Vérifier s'il reste des joueurs vivants
		local alivePlayers = getAlivePlayers()
		if #alivePlayers == 0 then
			gameActive = false
			-- Game Over
			for _, player in ipairs(Players:GetPlayers()) do
				local sessionData = player:FindFirstChild("SessionData")
				local kills = sessionData and sessionData:FindFirstChild("Kills") and sessionData.Kills.Value or 0
				local money = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Money") and player.leaderstats.Money.Value or 0
				GameOver:FireClient(player, currentWave, kills, money)
			end
			print("[WaveManager] GAME OVER — Manche atteinte: " .. currentWave)
			break
		end

		-- Petit délai avant la prochaine manche
		task.wait(2)
	end
end

-- === DÉMARRAGE ===

-- Attendre qu'au moins 1 joueur soit connecté
if #Players:GetPlayers() == 0 then
	Players.PlayerAdded:Wait()
end

-- Intermission de 15 secondes au tout début pour le choix de classe
for i = 15, 1, -1 do
	ShowNotification:FireAllClients("Début de partie dans " .. i .. "...", "#FFFF00", 1)
	task.wait(1)
end

-- Détecter la mort des joueurs
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			local sessionData = player:FindFirstChild("SessionData")
			if sessionData then
				sessionData.IsAlive.Value = false
			end

			-- Vérifier game over
			local alive = getAlivePlayers()
			if #alive == 0 and gameActive then
				gameActive = false
				for _, p in ipairs(Players:GetPlayers()) do
					local sd = p:FindFirstChild("SessionData")
					local kills = sd and sd:FindFirstChild("Kills") and sd.Kills.Value or 0
					local money = p:FindFirstChild("leaderstats") and p.leaderstats:FindFirstChild("Money") and p.leaderstats.Money.Value or 0
					GameOver:FireClient(p, currentWave, kills, money)
				end
			-- Respawn en mode normal (pas hardcore)
			elseif not isHardcore then
				task.delay(GameConfig.RESPAWN_TIME, function()
					if player and player.Parent then
						player:LoadCharacter()
						if sessionData then
							sessionData.IsAlive.Value = true
						end
					end
				end)
			end
		end)
	end)
end)

-- Lancer la boucle de jeu
gameLoop()
