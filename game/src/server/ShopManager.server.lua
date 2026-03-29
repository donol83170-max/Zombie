-- ShopManager.server.lua
-- Boutique principale avec 3 onglets (Armes, Skins, Consommables)
-- Système #12 (Haute)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = ReplicatedStorage:WaitForChild("Events")
local WeaponConfig = require(Shared:WaitForChild("WeaponConfig"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local RequestBuyShopItem = Events:WaitForChild("RequestBuyShopItem")
local ShowNotification = Events:WaitForChild("ShowNotification")
local UpdateAmmo = Events:WaitForChild("UpdateAmmo")
local UpdateHealth = Events:WaitForChild("UpdateHealth")

task.wait(1) -- Attendre EconomyManager

-- === CATALOGUE ===

local ShopItems = {
	-- Armes
	{ id = "Pistol",       category = "Armes",       price = 0,    type = "weapon" },
	{ id = "SMG",          category = "Armes",       price = 800,  type = "weapon" },
	{ id = "Shotgun",      category = "Armes",       price = 1500, type = "weapon" },
	{ id = "AK47",         category = "Armes",       price = 2500, type = "weapon" },
	{ id = "Sniper",       category = "Armes",       price = 4000, type = "weapon" },
	{ id = "Flamethrower", category = "Armes",       price = 6000, type = "weapon" },

	-- Consommables
	{ id = "Shield",       category = "Consommables", price = 300,  type = "consumable", duration = 30, effect = "absorb50" },
	{ id = "Speed",        category = "Consommables", price = 200,  type = "consumable", duration = 30, effect = "speed2x" },
	{ id = "Grenade",      category = "Consommables", price = 150,  type = "consumable", effect = "explosion" },
}

-- === ACHAT ===

local function buyWeapon(player, weaponId)
	local weaponData = WeaponConfig.Weapons[weaponId]
	if not weaponData then return false, "Arme introuvable" end

	local economy = _G.EconomyManager
	if not economy then return false, "Système économique indisponible" end

	if weaponData.price > 0 and not economy.canAfford(player, weaponData.price) then
		return false, "Fonds insuffisants"
	end

	if weaponData.price > 0 then
		economy.removeMoney(player, weaponData.price)
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

	UpdateAmmo:FireClient(player, weaponData.magSize, weaponData.reserveAmmo, weaponData.displayName)
	return true, weaponData.displayName
end

local function buyConsumable(player, itemId)
	local economy = _G.EconomyManager
	if not economy then return false, "Système économique indisponible" end

	local config = GameConfig.CONSUMABLES[itemId]
	if not config then return false, "Consommable introuvable" end

	if not economy.canAfford(player, config.price) then
		return false, "Fonds insuffisants"
	end

	economy.removeMoney(player, config.price)

	local char = player.Character
	if not char then return false, "Personnage introuvable" end
	local humanoid = char:FindFirstChildOfClass("Humanoid")

	if itemId == "Shield" then
		-- Bouclier : réduire les dégâts pendant 30s (ForceField)
		local ff = Instance.new("ForceField")
		ff.Parent = char
		task.delay(config.duration, function()
			if ff and ff.Parent then ff:Destroy() end
		end)
		return true, "🛡️ Bouclier activé !"

	elseif itemId == "Speed" then
		-- Vitesse x2 pendant 30s
		if humanoid then
			local original = humanoid.WalkSpeed
			humanoid.WalkSpeed = original * config.multiplier
			task.delay(config.duration, function()
				if humanoid and humanoid.Parent then
					humanoid.WalkSpeed = original
				end
			end)
		end
		return true, "⚡ Vitesse x2 !"

	elseif itemId == "Grenade" then
		-- Explosion autour du joueur
		local rootPart = char:FindFirstChild("HumanoidRootPart")
		if rootPart then
			local pos = rootPart.Position + (rootPart.CFrame.LookVector * 20)
			local explosion = Instance.new("Explosion")
			explosion.Position = pos
			explosion.BlastRadius = config.radius
			explosion.BlastPressure = 0
			explosion.DestroyJointRadiusPercent = 0
			explosion.Parent = workspace

			-- Dégâts aux zombies dans le rayon
			for _, child in ipairs(workspace:GetChildren()) do
				if child:IsA("Model") and child.Name:sub(1, 6) == "Enemy_" then
					local zRoot = child:FindFirstChild("HumanoidRootPart")
					if zRoot then
						local dist = (zRoot.Position - pos).Magnitude
						if dist <= config.radius then
							local zHum = child:FindFirstChildOfClass("Humanoid")
							if zHum then
								zHum:TakeDamage(config.damage)
							end
						end
					end
				end
			end
		end
		return true, "💥 Grenade lancée !"
	end

	return false, "Effet inconnu"
end

-- === EVENT HANDLER ===

RequestBuyShopItem.OnServerEvent:Connect(function(player, itemId, itemType)
	local success, message

	if itemType == "weapon" then
		success, message = buyWeapon(player, itemId)
	elseif itemType == "consumable" then
		success, message = buyConsumable(player, itemId)
	else
		success, message = false, "Type d'item inconnu"
	end

	if success then
		ShowNotification:FireClient(player, "✅ " .. message, "#00FF00", 2)
	else
		ShowNotification:FireClient(player, "❌ " .. message, "#FF0000", 2)
	end
end)

-- Rendre le catalogue accessible
_G.ShopItems = ShopItems

print("[ShopManager] Initialisé !")
