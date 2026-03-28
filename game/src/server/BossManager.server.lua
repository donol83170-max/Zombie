-- BossManager.server.lua
-- Gestion des boss multi-phases (spawn toutes les 5 manches)
-- Système #6 (Haute)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = ReplicatedStorage:WaitForChild("Events")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local ZombieConfig = require(Shared:WaitForChild("ZombieConfig"))
local Constants = require(Shared:WaitForChild("Constants"))

local WaveCompleted = Events:WaitForChild("WaveCompleted")
local UpdateWave = Events:WaitForChild("UpdateWave")
local ShowNotification = Events:WaitForChild("ShowNotification")
local BossSpawned = Events:WaitForChild("BossSpawned")
local BossHealthUpdate = Events:WaitForChild("BossHealthUpdate")

local currentBoss = nil

-- === FONCTIONS ===

local function getClosestPlayer(position)
	local closest = nil
	local closestDist = math.huge
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				local dist = (char.HumanoidRootPart.Position - position).Magnitude
				if dist < closestDist then
					closestDist = dist
					closest = player
				end
			end
		end
	end
	return closest
end

local function createBossMinion(position)
	local bossConfig = ZombieConfig.Types.Basic
	local minion = Instance.new("Model")
	minion.Name = "Enemy_Basic"

	local torso = Instance.new("Part")
	torso.Name = "HumanoidRootPart"
	torso.Size = Vector3.new(2, 2, 1)
	torso.Color = bossConfig.color
	torso.Anchored = false
	torso.CanCollide = true
	torso.Parent = minion

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.2, 1.2, 1.2)
	head.Color = bossConfig.color
	head.Anchored = false
	head.CanCollide = false
	head.Parent = minion

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = torso
	weld.Part1 = head
	weld.Parent = head
	head.CFrame = CFrame.new(position) * CFrame.new(0, 1.5, 0)

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = 50
	humanoid.Health = 50
	humanoid.WalkSpeed = 12
	humanoid.Parent = minion

	minion.PrimaryPart = torso
	minion:SetPrimaryPartCFrame(CFrame.new(position))
	minion:SetAttribute("ZombieType", "Basic")
	minion:SetAttribute("Damage", 10)
	minion:SetAttribute("Reward", 10)

	return minion
end

local function spawnBoss(wave)
	local bossConfig = ZombieConfig.Boss
	local hp = bossConfig.baseHp + (wave * bossConfig.hpPerWave)

	-- Notification
	ShowNotification:FireAllClients("⚠️ BOSS INCOMING !", "#FF0000", 3)
	task.wait(3)

	-- Créer le boss
	local boss = Instance.new("Model")
	boss.Name = "Enemy_Boss"

	local torso = Instance.new("Part")
	torso.Name = "HumanoidRootPart"
	torso.Size = Vector3.new(2 * bossConfig.scale, 2 * bossConfig.scale, 1 * bossConfig.scale)
	torso.Color = bossConfig.color
	torso.Anchored = false
	torso.CanCollide = true
	torso.Parent = boss

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.5 * bossConfig.scale, 1.5 * bossConfig.scale, 1.5 * bossConfig.scale)
	head.Color = bossConfig.color
	head.Anchored = false
	head.CanCollide = false
	head.Parent = boss

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = torso
	weld.Part1 = head
	weld.Parent = head
	head.CFrame = torso.CFrame * CFrame.new(0, 2 * bossConfig.scale, 0)

	-- Aura rouge
	local aura = Instance.new("ParticleEmitter")
	aura.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0))
	aura.Size = NumberSequence.new(2)
	aura.Rate = 30
	aura.Lifetime = NumberRange.new(0.5, 1)
	aura.Speed = NumberRange.new(2, 5)
	aura.Parent = torso

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = hp
	humanoid.Health = hp
	humanoid.WalkSpeed = bossConfig.speed
	humanoid.Parent = boss

	boss.PrimaryPart = torso
	boss:SetAttribute("ZombieType", "Boss")
	boss:SetAttribute("Damage", bossConfig.damage)
	boss:SetAttribute("Reward", bossConfig.reward)
	boss:SetAttribute("Wave", wave)

	-- Position de spawn
	local spawnPos = Vector3.new(0, 5, -50)
	boss:SetPrimaryPartCFrame(CFrame.new(spawnPos))
	boss.Parent = workspace
	currentBoss = boss

	-- Notifier les clients
	BossSpawned:FireAllClients(hp)

	print("[BossManager] Boss spawné ! PV: " .. hp)

	-- === IA DU BOSS AVEC PHASES ===
	local currentPhase = 1
	local isDead = false
	local lastSummonTime = 0

	task.spawn(function()
		while not isDead and humanoid.Health > 0 do
			local hpPercent = humanoid.Health / humanoid.MaxHealth

			-- Déterminer la phase
			local newPhase = 1
			if hpPercent <= GameConfig.BOSS_PHASE3_THRESHOLD then
				newPhase = 3
			elseif hpPercent <= GameConfig.BOSS_PHASE2_THRESHOLD then
				newPhase = 2
			end

			if newPhase ~= currentPhase then
				currentPhase = newPhase
				if currentPhase == 2 then
					humanoid.WalkSpeed = bossConfig.speed * GameConfig.BOSS_PHASE2_SPEED_MULT
					ShowNotification:FireAllClients("⚠️ LE BOSS S'ÉNERVE !", "#FF4444", 2)
				elseif currentPhase == 3 then
					ShowNotification:FireAllClients("☠️ LE BOSS INVOQUE DES ZOMBIES !", "#FF0000", 2)
				end
			end

			-- Phase 3 : invoquer des zombies
			if currentPhase == 3 then
				local now = tick()
				if now - lastSummonTime >= GameConfig.BOSS_PHASE3_SUMMON_INTERVAL then
					lastSummonTime = now
					for i = 1, GameConfig.BOSS_PHASE3_SUMMON_COUNT do
						local offset = Vector3.new(math.random(-10, 10), 3, math.random(-10, 10))
						local minion = createBossMinion(torso.Position + offset)
						minion.Parent = workspace

						-- IA basique pour le minion
						task.spawn(function()
							local mHumanoid = minion:FindFirstChildOfClass("Humanoid")
							local mRoot = minion:FindFirstChild("HumanoidRootPart")
							while mHumanoid and mHumanoid.Health > 0 do
								local target = getClosestPlayer(mRoot.Position)
								if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
									mHumanoid:MoveTo(target.Character.HumanoidRootPart.Position)
									local dist = (mRoot.Position - target.Character.HumanoidRootPart.Position).Magnitude
									if dist <= 5 then
										local tHum = target.Character:FindFirstChildOfClass("Humanoid")
										if tHum then tHum:TakeDamage(10) end
									end
								end
								task.wait(1)
							end
							task.delay(3, function()
								if minion and minion.Parent then minion:Destroy() end
							end)
						end)
					end
					print("[BossManager] Boss a invoqué " .. GameConfig.BOSS_PHASE3_SUMMON_COUNT .. " zombies !")
				end
			end

			-- Mouvement vers le joueur le plus proche
			local target = getClosestPlayer(torso.Position)
			if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
				humanoid:MoveTo(target.Character.HumanoidRootPart.Position)

				-- Dégâts au contact
				local dist = (torso.Position - target.Character.HumanoidRootPart.Position).Magnitude
				if dist <= 6 then
					local tHum = target.Character:FindFirstChildOfClass("Humanoid")
					if tHum then tHum:TakeDamage(bossConfig.damage) end
				end
			end

			-- Mettre à jour la barre de vie du boss côté client
			BossHealthUpdate:FireAllClients(humanoid.Health, humanoid.MaxHealth)

			task.wait(0.5)
		end
	end)

	-- Mort du boss
	humanoid.Died:Connect(function()
		isDead = true
		currentBoss = nil

		-- Récompenser TOUS les joueurs
		local economy = _G.EconomyManager
		if economy then
			for _, player in ipairs(Players:GetPlayers()) do
				economy.addMoney(player, bossConfig.reward)
			end
		end

		ShowNotification:FireAllClients("🏆 BOSS ÉLIMINÉ ! +$" .. bossConfig.reward .. " pour tous !", "#FFD700", 4)
		BossHealthUpdate:FireAllClients(0, 0)

		print("[BossManager] Boss tué ! Récompense distribuée.")

		task.delay(5, function()
			if boss and boss.Parent then
				boss:Destroy()
			end
		end)
	end)
end

-- === ÉCOUTER LES MANCHES ===
-- Le WaveManager fire WaveCompleted après chaque manche
-- On écoute UpdateWave pour savoir quand spawn le boss

UpdateWave.Event = nil -- C'est un RemoteEvent, on ne peut pas écouter serveur→serveur directement

-- Alternative : surveiller les leaderstats pour détecter la manche
-- Ou utiliser _G pour communiquer
_G.SpawnBoss = function(wave)
	if wave % GameConfig.BOSS_EVERY_N_WAVES == 0 then
		spawnBoss(wave)
	end
end

-- Écouter les manches via WaveCompleted (qui est aussi fired côté serveur)
-- On vérifie périodiquement
task.spawn(function()
	local lastCheckedWave = 0
	while true do
		task.wait(1)
		for _, player in ipairs(Players:GetPlayers()) do
			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats and leaderstats:FindFirstChild("Wave") then
				local wave = leaderstats.Wave.Value
				if wave > lastCheckedWave and wave % GameConfig.BOSS_EVERY_N_WAVES == 0 then
					lastCheckedWave = wave
					spawnBoss(wave)
					break
				end
			end
		end
	end
end)

print("[BossManager] Initialisé !")
