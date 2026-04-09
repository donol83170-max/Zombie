-- EconomyManager.server.lua
-- Gestion de l'argent, achats, leaderstats
-- Système #2 (Critique)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = ReplicatedStorage:WaitForChild("Events")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local ClassConfig = require(Shared:WaitForChild("ClassConfig"))

local UpdateMoney = Events:WaitForChild("UpdateMoney")
local ShowNotification = Events:WaitForChild("ShowNotification")
local ZombieDied = Events:WaitForChild("ZombieDied")
local DamageZombie = Events:WaitForChild("DamageZombie")

-- Double money flag par joueur
local doubleMoneyPlayers = {} -- { [userId] = true/false }

-- === FONCTIONS PUBLIQUES ===

local EconomyManager = {}

function EconomyManager.getMoney(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats and leaderstats:FindFirstChild("Money") then
		return leaderstats.Money.Value
	end
	return 0
end

function EconomyManager.addMoney(player, amount)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats or not leaderstats:FindFirstChild("Money") then return end

	-- Appliquer le multiplicateur de classe
	local sessionData = player:FindFirstChild("SessionData")
	local className = sessionData and sessionData:FindFirstChild("Class") and sessionData.Class.Value or "Soldier"
	local classData = ClassConfig.Classes[className]
	local moneyMult = classData and classData.moneyMult or 1

	-- Appliquer le double money bonus
	if doubleMoneyPlayers[player.UserId] then
		moneyMult *= 2
	end

	local finalAmount = math.floor(amount * moneyMult)
	leaderstats.Money.Value += finalAmount
	
	print(string.format("[EconomyManager] $$$ ARGENT AJOUTÉ à %s : +$%d (Total: %d) $$$", player.Name, finalAmount, leaderstats.Money.Value))

	-- Notifier le client
	UpdateMoney:FireClient(player, leaderstats.Money.Value)
end

function EconomyManager.removeMoney(player, amount)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats or not leaderstats:FindFirstChild("Money") then return false end

	if leaderstats.Money.Value >= amount then
		leaderstats.Money.Value -= amount
		-- Empêcher les valeurs négatives
		if leaderstats.Money.Value < 0 then
			leaderstats.Money.Value = 0
		end
		UpdateMoney:FireClient(player, leaderstats.Money.Value)
		return true
	end
	return false
end

function EconomyManager.canAfford(player, amount)
	return EconomyManager.getMoney(player) >= amount
end

function EconomyManager.setDoubleMoney(player, enabled)
	doubleMoneyPlayers[player.UserId] = enabled
end

-- === RÉCOMPENSES ZOMBIE ===

-- Quand un zombie meurt, récompenser le tueur
-- On récompense TOUS les joueurs proches (celui qui a tiré en premier)
-- Simplification : on récompense tous les joueurs vivants
workspace.ChildAdded:Connect(function(child)
	if child:IsA("Model") and child.Name:sub(1, 6) == "Enemy_" then
		local humanoid = child:WaitForChild("Humanoid", 5)
		if humanoid then
			humanoid.Died:Connect(function()
				local reward = child:GetAttribute("Reward") or GameConfig.MONEY_PER_HIT
				-- Trouver le joueur le plus proche (celui qui a probablement tué)
				local rootPart = child:FindFirstChild("HumanoidRootPart")
				if not rootPart then return end

				local closestPlayer = nil
				local closestDist = math.huge
				for _, player in ipairs(Players:GetPlayers()) do
					local char = player.Character
					if char and char:FindFirstChild("HumanoidRootPart") then
						local dist = (char.HumanoidRootPart.Position - rootPart.Position).Magnitude
						if dist < closestDist then
							closestDist = dist
							closestPlayer = player
						end
					end
				end

				if closestPlayer then
					EconomyManager.addMoney(closestPlayer, reward)
					-- Incrémenter kills
					local sessionData = closestPlayer:FindFirstChild("SessionData")
					if sessionData and sessionData:FindFirstChild("Kills") then
						sessionData.Kills.Value += 1
					end
				end
			end)
		end
	end
end)

-- Serveur fait autorité sur les dégâts et récompense à chaque impact
-- Fonction commune de dégâts
local function applyZombieDamage(player, zombieModel, isHeadshot, weaponName)
	if not zombieModel or not zombieModel.Parent then return end
	
	-- Remonter la hiérarchie pour trouver le vrai modèle "Enemy_*"
	local actualZombie = zombieModel
	if actualZombie:IsA("Model") and actualZombie.Name:sub(1, 6) ~= "Enemy_" then
		local current = actualZombie.Parent
		for _ = 1, 5 do
			if current == nil or current == workspace then break end
			if current:IsA("Model") and current.Name:sub(1, 6) == "Enemy_" then
				actualZombie = current
				break
			end
			current = current.Parent
		end
	end
	
	-- Recherche ultra-robuste de l'Humanoid
	local humanoid = actualZombie:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		humanoid = actualZombie:FindFirstChild("Humanoid", true)
	end
	
	if not humanoid or humanoid.Health <= 0 then return end
	
	-- Calculer les dégâts depuis la config de l'arme
	local WeaponConfig = require(Shared:WaitForChild("WeaponConfig"))
	local weaponData = weaponName and WeaponConfig.Weapons[weaponName]
	local baseDamage = (weaponData and weaponData.damage) or 25
	local headshotMult = (weaponData and weaponData.headshotMult) or 2.0
	local damage = isHeadshot and (baseDamage * headshotMult) or baseDamage
	
	-- Appliquer les dégâts DIRECTEMENT (pas TakeDamage qui respecte les ForceFields)
	humanoid.Health = math.max(0, humanoid.Health - damage)

	-- Récompense d'impact : $50 headshot, $10 body
	local reward = isHeadshot and 50 or 10
	if player then
		EconomyManager.addMoney(player, reward)
	end
end

-- Serveur fait autorité sur les dégâts et récompense à chaque impact
DamageZombie.OnServerEvent:Connect(applyZombieDamage)

-- === HOOK FE WEAPON KIT ===
-- Intercepte les vrais tirs parfaits du FE Weapon Kit !
local function setupFEWeaponKitHooks()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then return end

	local function onKitHit(player, ...)
		local args = {...}
		local hitPart = nil
		local targetModel = nil
		
		-- Fouiller les arguments pour trouver la part ou le zombie touché
		for _, arg in ipairs(args) do
			if typeof(arg) == "Instance" then
				if arg:IsA("BasePart") then
					hitPart = arg
					targetModel = arg.Parent
				elseif arg:IsA("Humanoid") then
					targetModel = arg.Parent
				elseif arg:IsA("Model") then
					targetModel = arg
				end
				
				if targetModel and targetModel.Name:sub(1, 6) == "Enemy_" then
					break
				end
			end
		end
		
		if targetModel and targetModel.Name:sub(1, 6) == "Enemy_" then
			-- Si "player" n'est pas fourni (BindableEvent), essayer de deviner le tireur
			if not player then
				for _, p in ipairs(Players:GetPlayers()) do
					if p.Character and hitPart and (p.Character.HumanoidRootPart.Position - hitPart.Position).Magnitude < 150 then
						player = p
						break
					end
				end
			end
			
			local weaponName = "?"
			if player and player.Character then
				local tool = player.Character:FindFirstChildOfClass("Tool")
				if tool then weaponName = tool.Name end
			end
			
			local isHeadshot = hitPart and hitPart.Name == "Head" or false
			applyZombieDamage(player, targetModel, isHeadshot, weaponName)
		end
	end

	-- Connecte l'événement serveur normal
	local inflictRemote = remotes:FindFirstChild("InflictTarget")
	if inflictRemote and inflictRemote:IsA("RemoteEvent") then
		inflictRemote.OnServerEvent:Connect(onKitHit)
	end
	
	-- Connecte l'événement local aux NPCs
	local inflictNPC = remotes:FindFirstChild("inflictTargetNPC")
	if inflictNPC and inflictNPC:IsA("BindableEvent") then
		inflictNPC.Event:Connect(function(...)
			onKitHit(nil, ...) 
		end)
	end
end
task.spawn(setupFEWeaponKitHooks)

-- Nettoyage
Players.PlayerRemoving:Connect(function(player)
	doubleMoneyPlayers[player.UserId] = nil
end)

-- Rendre le module accessible globalement via _G (pour les autres managers)
_G.EconomyManager = EconomyManager

print("[EconomyManager] Initialisé !")
