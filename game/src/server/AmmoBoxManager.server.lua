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

local function getToolAmmoValues(tool)
	local wData = WeaponConfig.Weapons[tool.Name]
	local magSize = wData and wData.magSize or 0
	local reserve = 0

	-- Lire Setting.1 (le vrai module de config du gun kit)
	local setting = tool:FindFirstChild("Setting")
	local setting1 = setting and setting:FindFirstChild("1")
	local moduleToRead = setting1 or setting

	if moduleToRead then
		local ok, data = pcall(require, moduleToRead)
		if ok and type(data) == "table" then
			magSize = data.MagSize or data.magSize or magSize
			reserve = data.Ammo or data.MaxAmmo or data.ReserveAmmo or 0
			print("[AmmoBoxManager] Setting lu -> Mag=" .. magSize .. " Reserve=" .. reserve)
		else
			warn("[AmmoBoxManager] require(Setting) a échoué :", data)
		end
	end

	-- Fallback : lire directement les NumberValues actuelles du tool (valeur max)
	if reserve == 0 then
		local vf = tool:FindFirstChild("ValueFolder")
		local vf1 = vf and vf:FindFirstChild("1")
		local ammoVal = vf1 and vf1:FindFirstChild("Ammo")
		if ammoVal then
			reserve = ammoVal.Value
			print("[AmmoBoxManager] Fallback NumberValue -> Reserve=" .. reserve)
		else
			reserve = wData and wData.reserveAmmo or 0
			warn("[AmmoBoxManager] Fallback WeaponConfig -> Reserve=" .. reserve)
		end
	end

	return magSize, reserve
end

local function refillAmmo(player)
	local char = player.Character
	local backpack = player:FindFirstChild("Backpack")
	if not char then return end

	local equippedTool = char:FindFirstChildOfClass("Tool")
	local containers = { char }
	if backpack then table.insert(containers, backpack) end

	-- Mettre à jour tous les tools du joueur
	for _, container in ipairs(containers) do
		for _, tool in ipairs(container:GetChildren()) do
			if not tool:IsA("Tool") then continue end
			local magSize, reserve = getToolAmmoValues(tool)
			if magSize == 0 then continue end

			-- Mettre à jour les IntValues (Mag + Ammo)
			for _, v in ipairs(tool:GetDescendants()) do
				if v:IsA("IntValue") or v:IsA("NumberValue") then
					if v.Name == "Mag" then v.Value = magSize
					elseif v.Name == "Ammo" then v.Value = reserve
					end
				end
			end

			-- Notifier le gun system si c'est le tool équipé
			if tool == equippedTool then
				local gs = tool:FindFirstChild("GunServer")
				local changeMagAndAmmo = gs and gs:FindFirstChild("ChangeMagAndAmmo")
				print("[AmmoBoxManager] Tool équipé:", tool.Name, "| GunServer:", gs and "OK" or "KO", "| ChangeMagAndAmmo:", changeMagAndAmmo and "OK" or "KO")
				if changeMagAndAmmo then
					local values = {{ Id = 1, Mag = magSize, Ammo = reserve, Heat = 0 }}
					changeMagAndAmmo:FireClient(player, values, 0)
					print("[AmmoBoxManager] Refill HUD -> Mag=" .. magSize .. " Ammo=" .. reserve)
				end
			end
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
	prompt.MaxActivationDistance = 15
	prompt.RequiresLineOfSight = false
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
local configuredModels = {} -- éviter double setup

local function findAndSetupAmmoBoxes()
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj.Name == "Ammo Box" or obj.Name == "AmmoBox" or obj.Name == "ammo box" then
			if obj:IsA("Model") or obj:IsA("BasePart") then
				local target = obj:IsA("Model") and obj or obj.Parent
				-- Ne configurer que si ce n'est pas un enfant d'un modèle déjà configuré
				local alreadyHandled = false
				for _, configured in ipairs(configuredModels) do
					if target == configured or target:IsDescendantOf(configured) then
						alreadyHandled = true
						break
					end
				end
				if not alreadyHandled then
					table.insert(configuredModels, target)
					setupAmmoBox(target)
				end
			end
		end
	end
end

-- Attendre que le workspace soit chargé, puis surveiller les nouveaux objets
task.wait(3)
findAndSetupAmmoBoxes()

-- Surveiller les ajouts futurs (si la map charge après le script)
workspace.DescendantAdded:Connect(function(obj)
	if (obj.Name == "Ammo Box" or obj.Name == "AmmoBox" or obj.Name == "ammo box"
		or obj.Name == "AMMO BOX" or obj.Name == "Ammo_Box") then
		task.wait(0.1) -- laisser le modèle se construire
		if obj:IsA("Model") then
			setupAmmoBox(obj)
		elseif obj:IsA("BasePart") and obj.Parent:IsA("Model") then
			setupAmmoBox(obj.Parent)
		end
	end
end)

print("[AmmoBoxManager] Initialisé !")
