-- AmmoBoxManager.server.lua
-- Recharge complète des munitions contre 150$ via le modèle AmmoBox dans map1

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local WeaponConfig = require(Shared:WaitForChild("WeaponConfig"))
local Events = ReplicatedStorage:WaitForChild("Events")
local UpdateMoney = Events:WaitForChild("UpdateMoney")

local AMMO_PRICE = 150
local COOLDOWN = 5 -- secondes entre chaque utilisation par joueur
local playerCooldowns = {}

local function getMoney(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats and leaderstats:FindFirstChild("Money") then
		return leaderstats.Money.Value
	end
	return 0
end

local function removeMoney(player, amount)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats or not leaderstats:FindFirstChild("Money") then return false end
	if leaderstats.Money.Value < amount then return false end
	leaderstats.Money.Value -= amount
	UpdateMoney:FireClient(player, leaderstats.Money.Value)
	return true
end

local function refillAmmo(player)
	local sessionData = player:FindFirstChild("SessionData")
	if not sessionData then return end

	local weaponName = sessionData:FindFirstChild("WeaponName")
	local currentAmmo = sessionData:FindFirstChild("CurrentAmmo")
	local reserveAmmo = sessionData:FindFirstChild("ReserveAmmo")
	local primaryAmmo = sessionData:FindFirstChild("PrimaryAmmo")
	local primaryReserve = sessionData:FindFirstChild("PrimaryReserve")

	if not weaponName then return end

	local wData = WeaponConfig.Weapons[weaponName.Value]
	if wData and wData.magSize and wData.magSize > 0 then
		if currentAmmo then currentAmmo.Value = wData.magSize end
		if reserveAmmo then reserveAmmo.Value = wData.reserveAmmo end
		if primaryAmmo then primaryAmmo.Value = wData.magSize end
		if primaryReserve then primaryReserve.Value = wData.reserveAmmo end

		local UpdateAmmo = Events:FindFirstChild("UpdateAmmo")
		if UpdateAmmo then
			UpdateAmmo:FireClient(player, wData.magSize, wData.reserveAmmo, wData.displayName)
		end
	end
end

local function setupAmmoBox(ammoBox)
	-- Trouver ou créer la part principale
	local part = ammoBox:FindFirstChildWhichIsA("BasePart", true)
	if not part then
		warn("[AmmoBoxManager] Aucune BasePart dans AmmoBox")
		return
	end

	-- Supprimer ancien prompt si existe
	local oldPrompt = part:FindFirstChildOfClass("ProximityPrompt")
	if oldPrompt then oldPrompt:Destroy() end

	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "Ammo Box"
	prompt.ActionText = "Recharger ($" .. AMMO_PRICE .. ")"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 8
	prompt.Parent = part

	prompt.Triggered:Connect(function(player)
		-- Cooldown
		local now = tick()
		if playerCooldowns[player.UserId] and now - playerCooldowns[player.UserId] < COOLDOWN then
			return
		end

		if getMoney(player) < AMMO_PRICE then
			-- Notification pas assez d'argent
			local ShowNotification = Events:FindFirstChild("ShowNotification")
			if ShowNotification then
				ShowNotification:FireClient(player, "Pas assez d'argent ! ($" .. AMMO_PRICE .. ")")
			end
			return
		end

		if removeMoney(player, AMMO_PRICE) then
			refillAmmo(player)
			playerCooldowns[player.UserId] = now
			print("[AmmoBoxManager] " .. player.Name .. " a rechargé ses munitions (-$" .. AMMO_PRICE .. ")")
		end
	end)

	print("[AmmoBoxManager] AmmoBox configurée : " .. ammoBox:GetFullName())
end

-- Chercher AmmoBox dans map1 (et toutes les maps)
local function findAndSetupAmmoBoxes()
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj.Name == "Ammo Box" or obj.Name == "AmmoBox" or obj.Name == "ammo box" then
			if obj:IsA("Model") or obj:IsA("BasePart") then
				setupAmmoBox(obj:IsA("Model") and obj or obj.Parent)
			end
		end
	end
end

-- Attendre que le workspace soit chargé
task.wait(2)
findAndSetupAmmoBoxes()
print("[AmmoBoxManager] Initialisé !")
