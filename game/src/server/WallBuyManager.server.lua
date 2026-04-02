-- WallBuyManager.server.lua
-- Système d'achat d'armes aux murs via ProximityPrompt
-- Place un objet dans le dossier "WallBuys" de Workspace et nomme-le "WallBuy_NomArme"
-- Exemple : WallBuy_Pistol, WallBuy_SMG, WallBuy_AK47, WallBuy_Shotgun, WallBuy_Sniper, WallBuy_Flamethrower

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = ReplicatedStorage:WaitForChild("Events")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local ShowNotification = Events:WaitForChild("ShowNotification")
local UpdateMoney = Events:WaitForChild("UpdateMoney")

-- Prix et noms des armes (remplace l'ancien WeaponConfig)
local WallBuyPrices = {
	Pistol       = { price = 250,  displayName = "Pistolet" },
	SMG          = { price = 800,  displayName = "SMG" },
	Shotgun      = { price = 1500, displayName = "Shotgun" },
	AK47         = { price = 2500, displayName = "AK-47" },
	Sniper       = { price = 4000, displayName = "Sniper" },
	Flamethrower = { price = 6000, displayName = "Lance-flammes" },
	SIGSAUERP250 = { price = 500,  displayName = "SIG Sauer P250" },
}

-- Attendre que EconomyManager soit disponible
task.wait(1)

-- === SETUP D'UN WALL BUY ===

local function setupWallBuy(object, weaponId)
	local weaponData = WallBuyPrices[weaponId]
	if not weaponData then
		warn("[WallBuy] Arme introuvable dans WallBuyPrices: " .. weaponId .. " (objet: " .. object.Name .. ")")
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

	-- ProximityPrompt (affiche le nom + prix directement)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Acheter — $" .. weaponData.price
	prompt.ObjectText = weaponData.displayName
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
					ShowNotification:FireClient(player, "Fonds insuffisants !", "#FF0000", 2)
					return
				end
			end

			-- Donner l'arme via le Backpack (compatible Fe Weapon Kit)
			local weaponTemplate = game.ServerStorage:FindFirstChild("WeaponTemplates")
			if weaponTemplate then
				local tool = weaponTemplate:FindFirstChild(weaponId)
				if tool then
					local clone = tool:Clone()
					clone.Parent = player.Backpack
				end
			end

			ShowNotification:FireClient(player, weaponData.displayName .. " acheté !", "#00FF00", 2)
			print("[WallBuy] " .. player.Name .. " a acheté " .. weaponData.displayName)
		else
			ShowNotification:FireClient(player, "Fonds insuffisants !", "#FF0000", 2)
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
