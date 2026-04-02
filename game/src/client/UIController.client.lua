-- UIController.client.lua
-- Gestion des menus : sélection de classe, shop, notifications bonus
-- Systèmes #8, #12

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Events = ReplicatedStorage:WaitForChild("Events")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ClassConfig = require(Shared:WaitForChild("ClassConfig"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Constants = require(Shared:WaitForChild("Constants"))

-- === SÉLECTION DE CLASSE (affichée au début) ===

local function createClassSelectionUI()
	local UserInputService = game:GetService("UserInputService")
	UserInputService.MouseIconEnabled = true
	player.CameraMode = Enum.CameraMode.LockFirstPerson

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ClassSelection"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	-- Fond semi-transparent (TextButton pour supporter la propriété Modal)
	local bg = Instance.new("TextButton")
	bg.Name = "Background"
	bg.Text = ""
	bg.AutoButtonColor = false
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	bg.BackgroundTransparency = 0.4
	bg.Active = true
	bg.Modal = true -- Fait apparaître la souris même en FPS !
	bg.Parent = screenGui

	-- Titre
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0.1, 0)
	title.Position = UDim2.new(0, 0, 0.05, 0)
	title.BackgroundTransparency = 1
	title.Text = "🎖️ CHOISISSEZ VOTRE CLASSE"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 36
	title.Parent = bg

	-- Container des cartes
	local container = Instance.new("Frame")
	container.Size = UDim2.new(0.8, 0, 0.6, 0)
	container.Position = UDim2.new(0.1, 0, 0.2, 0)
	container.BackgroundTransparency = 1
	container.Parent = bg

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 20)
	layout.Parent = container

	-- Créer une carte par classe
	for className, classData in pairs(ClassConfig.Classes) do
		local card = Instance.new("TextButton")
		card.Name = className
		card.Size = UDim2.new(0, 180, 1, 0)
		card.BackgroundColor3 = Color3.fromHex("#1a1a2e")
		card.BorderSizePixel = 0
		card.Text = ""
		card.Parent = container

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 12)
		cardCorner.Parent = card

		local cardStroke = Instance.new("UIStroke")
		cardStroke.Color = Color3.fromHex("#0f3460")
		cardStroke.Thickness = 2
		cardStroke.Parent = card

		-- Nom de la classe
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, 0, 0.25, 0)
		nameLabel.Position = UDim2.new(0, 0, 0.1, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = classData.displayName
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.Font = Enum.Font.GothamBlack
		nameLabel.TextSize = 22
		nameLabel.Parent = card

		-- Description
		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(0.9, 0, 0.4, 0)
		descLabel.Position = UDim2.new(0.05, 0, 0.4, 0)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = classData.description
		descLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextSize = 14
		descLabel.TextWrapped = true
		descLabel.Parent = card

		-- Hover effect
		card.MouseEnter:Connect(function()
			TweenService:Create(cardStroke, TweenInfo.new(0.2), {
				Color = Color3.fromHex("#e94560")
			}):Play()
		end)

		card.MouseLeave:Connect(function()
			TweenService:Create(cardStroke, TweenInfo.new(0.2), {
				Color = Color3.fromHex("#0f3460")
			}):Play()
		end)

		-- Click
		card.MouseButton1Click:Connect(function()
			Events:WaitForChild("RequestSelectClass"):FireServer(className)
			
			-- Désactiver le Modal pour refermer la souris
			bg.Modal = false
			
			-- Cacher le curseur de la souris pour le gameplay FPS
			local UserInputService = game:GetService("UserInputService")
			UserInputService.MouseIconEnabled = false
			player.CameraMode = Enum.CameraMode.LockFirstPerson
			
			-- Fermer l'UI
			TweenService:Create(bg, TweenInfo.new(0.3), {
				BackgroundTransparency = 1
			}):Play()
			task.delay(0.3, function()
				screenGui:Destroy()
			end)
		end)
	end

	-- Vote Hardcore
	local hardcoreBtn = Instance.new("TextButton")
	hardcoreBtn.Size = UDim2.new(0, 250, 0, 50)
	hardcoreBtn.Position = UDim2.new(0.5, -125, 0.85, 0)
	hardcoreBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
	hardcoreBtn.Text = "☠️ VOTER HARDCORE"
	hardcoreBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	hardcoreBtn.Font = Enum.Font.GothamBold
	hardcoreBtn.TextSize = 18
	hardcoreBtn.Parent = bg

	local hcCorner = Instance.new("UICorner")
	hcCorner.CornerRadius = UDim.new(0, 8)
	hcCorner.Parent = hardcoreBtn

	local voted = false
	hardcoreBtn.MouseButton1Click:Connect(function()
		voted = not voted
		Events:WaitForChild("RequestVoteHardcore"):FireServer(voted)
		if voted then
			hardcoreBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
			hardcoreBtn.Text = "☠️ HARDCORE VOTÉ ✓"
		else
			hardcoreBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
			hardcoreBtn.Text = "☠️ VOTER HARDCORE"
		end
	end)

	return screenGui
end

-- === SHOW CLASS SELECTION AU SPAWN ===

print("[UIController] Affichage instantané du menu à l'écran !")
createClassSelectionUI()

-- === ÉCOUTER LES BONUS ===

Events:WaitForChild("BonusActivated").OnClientEvent:Connect(function(bonusType)
	local displayName = Constants.BonusDisplayNames[bonusType] or bonusType
	-- L'affichage est déjà géré par ShowNotification dans le HUDController
end)

print("[UIController] Initialisé !")
