-- DoorManager.server.lua
-- Système de portes payantes entre les zones
-- Système #9 (Moyenne)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = ReplicatedStorage:WaitForChild("Events")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local ShowNotification = Events:WaitForChild("ShowNotification")
local DoorOpened = Events:WaitForChild("DoorOpened")

task.wait(1) -- Attendre EconomyManager

-- === CRÉATION DES PORTES ===

local function createDoor(doorId, position, price, parent)
	-- Créer la porte
	local door = Instance.new("Part")
	door.Name = doorId
	door.Size = Vector3.new(10, 12, 2)
	door.Anchored = true
	door.CanCollide = true
	door.Position = position
	door.Color = Color3.fromRGB(120, 80, 40)
	door.Material = Enum.Material.Wood
	door.Parent = parent or workspace:FindFirstChild("Doors") or workspace

	-- BillboardGui avec le prix
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(6, 0, 3, 0)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = false
	billboard.Parent = door

	local priceLabel = Instance.new("TextLabel")
	priceLabel.Name = "PriceLabel"
	priceLabel.Size = UDim2.new(1, 0, 0.5, 0)
	priceLabel.Position = UDim2.new(0, 0, 0, 0)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = "🚪 OUVRIR — $" .. price
	priceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	priceLabel.TextScaled = true
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.Parent = billboard

	-- ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Ouvrir"
	prompt.ObjectText = "Porte — $" .. price
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 10
	prompt.Parent = door

	-- Gestion de l'ouverture
	prompt.Triggered:Connect(function(player)
		local economy = _G.EconomyManager
		if not economy then return end

		if economy.canAfford(player, price) then
			economy.removeMoney(player, price)

			-- Animation d'ouverture (descendre la porte dans le sol)
			prompt:Destroy() -- Supprimer le prompt
			billboard:Destroy()

			local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
			local tween = TweenService:Create(door, tweenInfo, {
				Position = door.Position - Vector3.new(0, 15, 0),
				Transparency = 1,
			})
			tween:Play()

			tween.Completed:Connect(function()
				door.CanCollide = false
			end)

			-- Notifier tous les joueurs
			ShowNotification:FireAllClients("🚪 " .. player.Name .. " a ouvert une porte !", "#00FF00", 3)
			DoorOpened:FireAllClients(doorId)

			print("[DoorManager] " .. player.Name .. " a ouvert " .. doorId .. " pour $" .. price)
		else
			ShowNotification:FireClient(player, "💸 Fonds insuffisants ! ($" .. price .. " requis)", "#FF0000", 2)
		end
	end)

	return door
end

-- === INITIALISATION ===

-- Portes automatiques désactivées (map utilise le système FortressDoorManager)
-- local doorsFolder = workspace:FindFirstChild("Doors")
-- if doorsFolder and #doorsFolder:GetChildren() == 0 then
-- 	createDoor("Door_Zone2", Vector3.new(0, 6, -25), 750, doorsFolder)
-- 	createDoor("Door_Zone3", Vector3.new(0, 6, -75), 2000, doorsFolder)
-- end

print("[DoorManager] Initialisé !")
