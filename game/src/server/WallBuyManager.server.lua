-- WallBuyManager.server.lua
-- Système d'achat d'armes aux murs via ProximityPrompt
-- Système #3 (Critique)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = ReplicatedStorage:WaitForChild("Events")
local WeaponConfig = require(Shared:WaitForChild("WeaponConfig"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local ShowNotification = Events:WaitForChild("ShowNotification")
local UpdateAmmo = Events:WaitForChild("UpdateAmmo")
local UpdateMoney = Events:WaitForChild("UpdateMoney")

-- Attendre que EconomyManager soit disponible
task.wait(1)

-- === CRÉATION DES WALL BUYS ===

local function createWallBuy(weaponId, position, parent)
	local weaponData = WeaponConfig.Weapons[weaponId]
	if not weaponData then
		warn("[WallBuy] Arme introuvable: " .. weaponId)
		return
	end

	-- Créer le panneau mural
	local part = Instance.new("Part")
	part.Name = "WallBuy_" .. weaponId
	part.Size = Vector3.new(4, 3, 0.5)
	part.Anchored = true
	part.CanCollide = true
	part.Position = position
	part.Color = Color3.fromRGB(60, 60, 60)
	part.Material = Enum.Material.Metal
	part.Parent = parent or workspace:FindFirstChild("WallBuys") or workspace

	-- BillboardGui avec nom et prix
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(6, 0, 3, 0)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.AlwaysOnTop = false
	billboard.Parent = part

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = weaponData.displayName
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = billboard

	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(1, 0, 0.4, 0)
	priceLabel.Position = UDim2.new(0, 0, 0.5, 0)
	priceLabel.BackgroundTransparency = 1
	priceLabel.TextScaled = true
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.Parent = billboard

	if weaponData.price == 0 then
		priceLabel.Text = "GRATUIT"
		priceLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
	else
		priceLabel.Text = "$" .. weaponData.price
		priceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	end

	-- ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Acheter"
	prompt.ObjectText = weaponData.displayName .. " — $" .. weaponData.price
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 8
	prompt.Parent = part

	-- Gestion de l'achat
	prompt.Triggered:Connect(function(player)
		-- Vérifier les fonds
		local economy = _G.EconomyManager
		if not economy then
			warn("[WallBuy] EconomyManager non disponible")
			return
		end

		if weaponData.price == 0 or economy.canAfford(player, weaponData.price) then
			-- Déduire l'argent
			if weaponData.price > 0 then
				local success = economy.removeMoney(player, weaponData.price)
				if not success then
					ShowNotification:FireClient(player, "💸 Fonds insuffisants !", "#FF0000", 2)
					return
				end
			end

			-- Donner l'arme (et la sauvegarder comme arme primaire)
			local sessionData = player:FindFirstChild("SessionData")
			if sessionData then
				sessionData.WeaponName.Value = weaponId
				sessionData.CurrentAmmo.Value = weaponData.magSize
				sessionData.ReserveAmmo.Value = weaponData.reserveAmmo
				-- Sauvegarder comme arme primaire
				if sessionData:FindFirstChild("PrimaryWeaponName") then
					sessionData.PrimaryWeaponName.Value = weaponId
				end
				if sessionData:FindFirstChild("PrimaryAmmo") then
					sessionData.PrimaryAmmo.Value = weaponData.magSize
				end
				if sessionData:FindFirstChild("PrimaryReserve") then
					sessionData.PrimaryReserve.Value = weaponData.reserveAmmo
				end
				if sessionData:FindFirstChild("ActiveSlot") then
					sessionData.ActiveSlot.Value = 1
				end
			end

			-- Notifier le client
			UpdateAmmo:FireClient(player, weaponData.magSize, weaponData.reserveAmmo, weaponData.displayName)
			ShowNotification:FireClient(player, "🔫 " .. weaponData.displayName .. " acheté !", "#00FF00", 2)

			print("[WallBuy] " .. player.Name .. " a acheté " .. weaponData.displayName)
		else
			ShowNotification:FireClient(player, "💸 Fonds insuffisants !", "#FF0000", 2)
		end
	end)

	return part
end

-- === INITIALISATION ===

-- Créer les wall buys par défaut si le dossier est vide
local wallBuysFolder = workspace:FindFirstChild("WallBuys")
if wallBuysFolder and #wallBuysFolder:GetChildren() == 0 then
	-- Zone 1
	createWallBuy("Pistol", Vector3.new(10, 3, 0), wallBuysFolder)
	createWallBuy("Shotgun", Vector3.new(20, 3, 0), wallBuysFolder)

	-- Zone 2
	createWallBuy("SMG", Vector3.new(10, 3, -50), wallBuysFolder)
	createWallBuy("AK47", Vector3.new(20, 3, -50), wallBuysFolder)

	-- Zone 3
	createWallBuy("Sniper", Vector3.new(10, 3, -100), wallBuysFolder)
	createWallBuy("Flamethrower", Vector3.new(20, 3, -100), wallBuysFolder)

	print("[WallBuyManager] Wall buys par défaut créés")
end

print("[WallBuyManager] Initialisé !")
