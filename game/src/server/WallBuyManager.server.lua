-- WallBuyManager.server.lua
-- Système d'achat d'armes aux murs via ProximityPrompt
-- Place un objet dans le dossier "WallBuys" de Workspace et nomme-le "WallBuy_NomArme"
-- Exemple : WallBuy_Pistol, WallBuy_SMG, WallBuy_AK47, WallBuy_Shotgun, WallBuy_Sniper, WallBuy_Flamethrower

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

-- === SETUP D'UN WALL BUY ===

local function setupWallBuy(object, weaponId)
	local weaponData = WeaponConfig.Weapons[weaponId]
	if not weaponData then
		warn("[WallBuy] Arme introuvable: " .. weaponId .. " (objet: " .. object.Name .. ")")
		return
	end

	-- Trouver la Part principale (si c'est un Model, prendre la PrimaryPart ou la première Part)
	local targetPart = object
	if object:IsA("Model") then
		targetPart = object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart", true)
		if not targetPart then
			warn("[WallBuy] Aucune Part trouvée dans le modèle: " .. object.Name)
			return
		end
	end

	-- BillboardGui avec nom et prix
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(6, 0, 3, 0)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = false
	billboard.Parent = targetPart

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
	prompt.Parent = targetPart

	-- Gestion de l'achat
	prompt.Triggered:Connect(function(player)
		local economy = _G.EconomyManager
		if not economy then
			warn("[WallBuy] EconomyManager non disponible")
			return
		end

		if weaponData.price == 0 or economy.canAfford(player, weaponData.price) then
			if weaponData.price > 0 then
				local success = economy.removeMoney(player, weaponData.price)
				if not success then
					ShowNotification:FireClient(player, "💸 Fonds insuffisants !", "#FF0000", 2)
					return
				end
			end

			local sessionData = player:FindFirstChild("SessionData")
			if sessionData then
				sessionData.WeaponName.Value = weaponId
				sessionData.CurrentAmmo.Value = weaponData.magSize
				sessionData.ReserveAmmo.Value = weaponData.reserveAmmo
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

			UpdateAmmo:FireClient(player, weaponData.magSize, weaponData.reserveAmmo, weaponData.displayName)
			ShowNotification:FireClient(player, "🔫 " .. weaponData.displayName .. " acheté !", "#00FF00", 2)

			print("[WallBuy] " .. player.Name .. " a acheté " .. weaponData.displayName)
		else
			ShowNotification:FireClient(player, "💸 Fonds insuffisants !", "#FF0000", 2)
		end
	end)

	print("[WallBuy] Setup OK : " .. weaponData.displayName .. " sur " .. object.Name)
end

-- === INITIALISATION ===

local wallBuysFolder = workspace:FindFirstChild("WallBuys")
if not wallBuysFolder then
	wallBuysFolder = Instance.new("Folder")
	wallBuysFolder.Name = "WallBuys"
	wallBuysFolder.Parent = workspace
	print("[WallBuyManager] Dossier WallBuys créé")
end

-- Scanner tous les objets existants dans le dossier
for _, child in ipairs(wallBuysFolder:GetChildren()) do
	local weaponId = child.Name:match("^WallBuy_(.+)$")
	if weaponId then
		weaponId = weaponId:gsub("%s+", "") -- Nettoyer les espaces
		setupWallBuy(child, weaponId)
	else
		warn("[WallBuy] Nom invalide: " .. child.Name .. " (doit être WallBuy_NomArme)")
	end
end

-- Détecter les wall buys ajoutés après le démarrage
wallBuysFolder.ChildAdded:Connect(function(child)
	task.wait(0.1) -- Laisser le temps au modèle de se charger
	local weaponId = child.Name:match("^WallBuy_(.+)$")
	if weaponId then
		weaponId = weaponId:gsub("%s+", "") -- Nettoyer les espaces
		setupWallBuy(child, weaponId)
	end
end)

print("[WallBuyManager] Initialisé ! (" .. #wallBuysFolder:GetChildren() .. " wall buys détectés)")
