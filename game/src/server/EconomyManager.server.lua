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
DamageZombie.OnServerEvent:Connect(function(player, zombieModel, isHeadshot, weaponName)
	if not zombieModel or not zombieModel:IsA("Model") then return end
	local humanoid = zombieModel:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	
	local WeaponConfig = require(Shared:WaitForChild("WeaponConfig"))
	local wData = WeaponConfig.Weapons[weaponName]
	if not wData then return end
	
	-- Calcul des dégâts
	local damage = wData.damage
	if isHeadshot then
		damage *= (wData.headshotMult or 2)
	end
	
	-- Appliquer rigoureusement côté serveur
	humanoid:TakeDamage(damage)
	
	-- Donner la récompense d'impact (seulement s'il n'était pas déjà mort juste avant cet impact)
	-- $50 pour un tir dans la tête, $10 pour un tir dans le corps
	local reward = isHeadshot and 50 or 10
	EconomyManager.addMoney(player, reward)
end)

-- Nettoyage
Players.PlayerRemoving:Connect(function(player)
	doubleMoneyPlayers[player.UserId] = nil
end)

-- Rendre le module accessible globalement via _G (pour les autres managers)
_G.EconomyManager = EconomyManager

print("[EconomyManager] Initialisé !")
