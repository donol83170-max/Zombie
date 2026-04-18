-- HUDController.client.lua
-- Gestion du HUD en jeu : vie, argent, manche, munitions, boss HP
-- Système #14 (Critique)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Events = ReplicatedStorage:WaitForChild("Events")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Constants = require(Shared:WaitForChild("Constants"))

-- Attendre le GUI
local playerGui = player:WaitForChild("PlayerGui")

-- === CRÉER LE HUD PAR CODE ===

local function createHUD()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HUD"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- === BARRE DE VIE (haut-gauche) ===
	local healthFrame = Instance.new("Frame")
	healthFrame.Name = "HealthFrame"
	healthFrame.Size = UDim2.new(0, 250, 0, 30)
	healthFrame.Position = UDim2.new(0, 20, 0, 20)
	healthFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	healthFrame.BorderSizePixel = 0
	healthFrame.Parent = screenGui

	local healthCorner = Instance.new("UICorner")
	healthCorner.CornerRadius = UDim.new(0, 8)
	healthCorner.Parent = healthFrame

	local healthBar = Instance.new("Frame")
	healthBar.Name = "HealthBar"
	healthBar.Size = UDim2.new(1, 0, 1, 0)
	healthBar.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
	healthBar.BorderSizePixel = 0
	healthBar.Parent = healthFrame

	local healthBarCorner = Instance.new("UICorner")
	healthBarCorner.CornerRadius = UDim.new(0, 8)
	healthBarCorner.Parent = healthBar

	local healthLabel = Instance.new("TextLabel")
	healthLabel.Name = "HealthLabel"
	healthLabel.Size = UDim2.new(1, 0, 1, 0)
	healthLabel.BackgroundTransparency = 1
	healthLabel.Text = "100 / 100"
	healthLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	healthLabel.Font = Enum.Font.GothamBold
	healthLabel.TextSize = 16
	healthLabel.ZIndex = 2
	healthLabel.Parent = healthFrame

	-- === NUMÉRO DE MANCHE (haut-centre) ===
	local waveLabel = Instance.new("TextLabel")
	waveLabel.Name = "WaveLabel"
	waveLabel.Size = UDim2.new(0, 300, 0, 50)
	waveLabel.Position = UDim2.new(0.5, -150, 0, 15)
	waveLabel.BackgroundTransparency = 1
	waveLabel.Text = "MANCHE 1"
	waveLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	waveLabel.Font = Enum.Font.GothamBlack
	waveLabel.TextSize = 32
	waveLabel.TextStrokeTransparency = 0.5
	waveLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	waveLabel.Parent = screenGui

	-- === ARGENT (bas-gauche) ===
	local moneyLabel = Instance.new("TextLabel")
	moneyLabel.Name = "MoneyLabel"
	moneyLabel.Size = UDim2.new(0, 200, 0, 40)
	moneyLabel.Position = UDim2.new(0, 20, 1, -60)
	moneyLabel.BackgroundTransparency = 1
	moneyLabel.Text = "💰 $0"
	moneyLabel.TextColor3 = Color3.fromHex("#f5c518")
	moneyLabel.Font = Enum.Font.GothamBold
	moneyLabel.TextSize = 28
	moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
	moneyLabel.TextStrokeTransparency = 0.3
	moneyLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	moneyLabel.Parent = screenGui

	-- === NOTIFICATION (centre) ===
	local notifLabel = Instance.new("TextLabel")
	notifLabel.Name = "NotifLabel"
	notifLabel.Size = UDim2.new(0, 500, 0, 60)
	notifLabel.Position = UDim2.new(0.5, -250, 0.35, 0)
	notifLabel.BackgroundTransparency = 1
	notifLabel.Text = ""
	notifLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	notifLabel.Font = Enum.Font.GothamBlack
	notifLabel.TextSize = 36
	notifLabel.TextStrokeTransparency = 0
	notifLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	notifLabel.TextTransparency = 1
	notifLabel.Parent = screenGui

	-- === BARRE DE VIE BOSS (haut, sous la manche) ===
	local bossFrame = Instance.new("Frame")
	bossFrame.Name = "BossFrame"
	bossFrame.Size = UDim2.new(0, 400, 0, 25)
	bossFrame.Position = UDim2.new(0.5, -200, 0, 70)
	bossFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	bossFrame.BorderSizePixel = 0
	bossFrame.Visible = false
	bossFrame.Parent = screenGui

	local bossCorner = Instance.new("UICorner")
	bossCorner.CornerRadius = UDim.new(0, 6)
	bossCorner.Parent = bossFrame

	local bossBar = Instance.new("Frame")
	bossBar.Name = "BossBar"
	bossBar.Size = UDim2.new(1, 0, 1, 0)
	bossBar.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
	bossBar.BorderSizePixel = 0
	bossBar.Parent = bossFrame

	local bossBarCorner = Instance.new("UICorner")
	bossBarCorner.CornerRadius = UDim.new(0, 6)
	bossBarCorner.Parent = bossBar

	local bossLabel = Instance.new("TextLabel")
	bossLabel.Name = "BossLabel"
	bossLabel.Size = UDim2.new(1, 0, 1, 0)
	bossLabel.BackgroundTransparency = 1
	bossLabel.Text = "BOSS"
	bossLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	bossLabel.Font = Enum.Font.GothamBold
	bossLabel.TextSize = 14
	bossLabel.ZIndex = 2
	bossLabel.Parent = bossFrame

	-- === GAME OVER (plein écran) ===
	local gameOverFrame = Instance.new("Frame")
	gameOverFrame.Name = "GameOverFrame"
	gameOverFrame.Size = UDim2.new(1, 0, 1, 0)
	gameOverFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	gameOverFrame.BackgroundTransparency = 0.3
	gameOverFrame.Visible = false
	gameOverFrame.ZIndex = 10
	gameOverFrame.Parent = screenGui

	local goTitle = Instance.new("TextLabel")
	goTitle.Size = UDim2.new(1, 0, 0.2, 0)
	goTitle.Position = UDim2.new(0, 0, 0.15, 0)
	goTitle.BackgroundTransparency = 1
	goTitle.Text = "GAME OVER"
	goTitle.TextColor3 = Color3.fromRGB(255, 0, 0)
	goTitle.Font = Enum.Font.GothamBlack
	goTitle.TextSize = 64
	goTitle.ZIndex = 11
	goTitle.Parent = gameOverFrame

	local goStats = Instance.new("TextLabel")
	goStats.Name = "GOStats"
	goStats.Size = UDim2.new(1, 0, 0.3, 0)
	goStats.Position = UDim2.new(0, 0, 0.4, 0)
	goStats.BackgroundTransparency = 1
	goStats.Text = ""
	goStats.TextColor3 = Color3.fromRGB(255, 255, 255)
	goStats.Font = Enum.Font.GothamBold
	goStats.TextSize = 24
	goStats.ZIndex = 11
	goStats.Parent = gameOverFrame

	-- === DAMAGE FLASH (plein écran) ===
	local damageFlash = Instance.new("Frame")
	damageFlash.Name = "DamageFlash"
	damageFlash.Size = UDim2.new(1, 0, 1, 0)
	damageFlash.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	damageFlash.BackgroundTransparency = 1
	damageFlash.BorderSizePixel = 0
	damageFlash.ZIndex = 0
	damageFlash.Parent = screenGui

	return screenGui
end

local hud = createHUD()

-- === FONCTIONS DE MISE À JOUR ===

local lastHp = 100

local function updateHealth(hp, maxHp)
	local frame = hud:FindFirstChild("HealthFrame")
	if not frame then return end

	local bar = frame:FindFirstChild("HealthBar")
	local label = frame:FindFirstChild("HealthLabel")

	if bar then
		local ratio = math.clamp(hp / maxHp, 0, 1)
		TweenService:Create(bar, TweenInfo.new(0.3), {
			Size = UDim2.new(ratio, 0, 1, 0)
		}):Play()

		-- Couleur dynamique
		if ratio > 0.6 then
			bar.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
		elseif ratio > 0.3 then
			bar.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
		else
			bar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		end
	end

	if label then
		label.Text = math.floor(hp) .. " / " .. math.floor(maxHp)
	end

	if hp < lastHp and hp > 0 then
		local flash = hud:FindFirstChild("DamageFlash")
		if flash then
			flash.BackgroundTransparency = 0.5
			TweenService:Create(flash, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 1
			}):Play()
		end
	end
	lastHp = hp
end

local function showNotification(text, color, duration)
	local label = hud:FindFirstChild("NotifLabel")
	if not label then return end

	label.Text = text
	if color then
		label.TextColor3 = Color3.fromHex(color)
	end
	label.TextTransparency = 0
	label.TextStrokeTransparency = 0

	-- Animation de scale
	label.TextSize = 48
	TweenService:Create(label, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		TextSize = 36
	}):Play()

	-- Fade out
	task.delay(duration or 3, function()
		TweenService:Create(label, TweenInfo.new(0.5), {
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		}):Play()
	end)
end

-- === ÉCOUTER LES EVENTS ===

Events:WaitForChild("UpdateMoney").OnClientEvent:Connect(function(amount)
	local label = hud:FindFirstChild("MoneyLabel")
	if label then
		label.Text = "💰 $" .. tostring(amount)
		-- Flash doré
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		TweenService:Create(label, TweenInfo.new(0.3), {
			TextColor3 = Color3.fromHex("#f5c518")
		}):Play()
	end
end)

Events:WaitForChild("UpdateWave").OnClientEvent:Connect(function(waveNumber)
	local label = hud:FindFirstChild("WaveLabel")
	if label then
		label.Text = "MANCHE " .. tostring(waveNumber)
	end
	showNotification("MANCHE " .. tostring(waveNumber), "#FFFFFF", 3)
end)

Events:WaitForChild("UpdateHealth").OnClientEvent:Connect(function(hp, maxHp)
	updateHealth(hp, maxHp)
end)

Events:WaitForChild("ShowNotification").OnClientEvent:Connect(function(text, color, duration)
	showNotification(text, color, duration)
end)

Events:WaitForChild("BossSpawned").OnClientEvent:Connect(function(bossHp)
	local frame = hud:FindFirstChild("BossFrame")
	if frame then
		frame.Visible = true
		local bar = frame:FindFirstChild("BossBar")
		if bar then bar.Size = UDim2.new(1, 0, 1, 0) end
	end
	showNotification("⚠️ BOSS INCOMING !", "#FF0000", 3)
end)

Events:WaitForChild("BossHealthUpdate").OnClientEvent:Connect(function(hp, maxHp)
	local frame = hud:FindFirstChild("BossFrame")
	if not frame then return end

	if maxHp <= 0 then
		frame.Visible = false
		return
	end

	local bar = frame:FindFirstChild("BossBar")
	if bar then
		local ratio = math.clamp(hp / maxHp, 0, 1)
		TweenService:Create(bar, TweenInfo.new(0.3), {
			Size = UDim2.new(ratio, 0, 1, 0)
		}):Play()
	end
end)

Events:WaitForChild("GameOver").OnClientEvent:Connect(function(wave, kills, money)
	local frame = hud:FindFirstChild("GameOverFrame")
	if frame then
		frame.Visible = true
		local stats = frame:FindFirstChild("GOStats")
		if stats then
			stats.Text = "Manche atteinte: " .. wave 
				.. "\nZombies tués: " .. kills 
				.. "\nArgent gagné: $" .. money
		end
	end
end)

-- === MISE À JOUR DE LA VIE LOCALE ===

task.spawn(function()
	while true do
		task.wait(0.2)
		local char = player.Character
		if char then
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if humanoid then
				updateHealth(humanoid.Health, humanoid.MaxHealth)
			end
		end
	end
end)

-- === MISE À JOUR ARGENT LOCALE ===

task.spawn(function()
	while true do
		task.wait(0.5)
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats and leaderstats:FindFirstChild("Money") then
			local label = hud:FindFirstChild("MoneyLabel")
			if label then
				label.Text = "💰 $" .. tostring(leaderstats.Money.Value)
			end
		end
	end
end)

local function fadeOutZombie(zombieModel)
	local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	for _, desc in ipairs(zombieModel:GetDescendants()) do
		if (desc:IsA("BasePart") or desc:IsA("Decal") or desc:IsA("Texture")) and desc.Name ~= "HumanoidRootPart" then
			TweenService:Create(desc, tweenInfo, {Transparency = 1}):Play()
		end
	end
end

Events:WaitForChild("ZombieDied").OnClientEvent:Connect(function(zombieType, reward, position, zombieModel)
	if not zombieModel or not zombieModel.Parent then return end
	task.delay(4, function()
		if zombieModel and zombieModel.Parent then
			fadeOutZombie(zombieModel)
		end
	end)
end)

print("[HUDController] Initialisé !")
