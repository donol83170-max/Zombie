-- GateManager.server.lua
-- Gestion des portails interactifs (ouverture avec ProximityPrompt)
-- Fonctionne avec des positions relatives : déplacer le portail ne casse rien

local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local ShowNotification = Events:WaitForChild("ShowNotification")
local UpdateMoney = Events:WaitForChild("UpdateMoney")

-- Créer l'event pour notifier les clients (lampe torche)
local ApocalypseStarted = Instance.new("RemoteEvent")
ApocalypseStarted.Name = "ApocalypseStarted"
ApocalypseStarted.Parent = Events

local OPEN_ANGLE = 90 -- degrés d'ouverture
local OPEN_TIME = 1.5 -- secondes pour l'animation
local GATE_PRICE = 1500

local apocalypseDone = false

local function triggerApocalypse()
	if apocalypseDone then return end
	apocalypseDone = true

	local tweenInfo = TweenInfo.new(5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

	-- Transition : nuit sombre, légère teinte rouge, encore jouable avec lampe torche
	TweenService:Create(Lighting, tweenInfo, {
		Ambient          = Color3.fromRGB(25, 10, 10),
		OutdoorAmbient   = Color3.fromRGB(20, 8, 8),
		Brightness       = 0.8,
		ClockTime        = 0,
		ColorShift_Top   = Color3.fromRGB(60, 20, 20),
		ColorShift_Bottom = Color3.fromRGB(15, 5, 5),
		FogColor         = Color3.fromRGB(30, 8, 8),
		FogStart         = 40,
		FogEnd           = 180,
	}):Play()

	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Parent = Lighting
	end
	TweenService:Create(atmosphere, tweenInfo, {
		Density   = 0.55,
		Offset    = 0.1,
		Color     = Color3.fromRGB(60, 15, 15),
		Decay     = Color3.fromRGB(20, 5, 5),
		Glare     = 0,
		Haze      = 2,
	}):Play()

	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	if not cc then
		cc = Instance.new("ColorCorrectionEffect")
		cc.Parent = Lighting
	end
	TweenService:Create(cc, tweenInfo, {
		TintColor  = Color3.fromRGB(255, 190, 190),
		Saturation = -0.2,
		Brightness = -0.05,
		Contrast   = 0.15,
	}):Play()

	-- Notifier tous les clients pour activer la lampe torche
	ApocalypseStarted:FireAllClients()

	print("[GateManager] Apocalypse déclenchée !")
end

local function setupGate(gateModel)
	-- Trouver les deux battants (supporte Gate>Gate>Doors OU Gate>Doors directement)
	local innerGate = gateModel:FindFirstChild("Gate") or gateModel

	local doorL = innerGate:FindFirstChild("DoorCloseL") or innerGate:FindFirstChild("DoorCLoseL")
	local doorR = innerGate:FindFirstChild("DoorCloseR")
	if not doorL or not doorR then
		warn("[GateManager] DoorCloseL ou DoorCloseR introuvable dans", gateModel:GetFullName())
		return
	end

	-- Sauvegarder les CFrames initiales de toutes les parts
	local doorLParts = {}
	local doorRParts = {}

	for _, part in ipairs(doorL:GetDescendants()) do
		if part:IsA("BasePart") then
			table.insert(doorLParts, { part = part, originalCFrame = part.CFrame })
		end
	end
	for _, part in ipairs(doorR:GetDescendants()) do
		if part:IsA("BasePart") then
			table.insert(doorRParts, { part = part, originalCFrame = part.CFrame })
		end
	end

	if #doorLParts == 0 or #doorRParts == 0 then
		warn("[GateManager] Pas de BasePart trouvé dans les portes")
		return
	end

	-- Centre de chaque porte
	local function getDoorCenter(doorParts)
		local sum = Vector3.new(0, 0, 0)
		for _, data in ipairs(doorParts) do
			sum = sum + data.originalCFrame.Position
		end
		return sum / #doorParts
	end

	local centerL = getDoorCenter(doorLParts)
	local centerR = getDoorCenter(doorRParts)

	-- Direction de la porte gauche vers la porte droite (axe du portail)
	local gateDir = (centerR - centerL).Unit

	-- La charnière de chaque porte est à son bord OPPOSÉ à l'autre porte
	-- = le point le plus éloigné de l'autre porte le long de l'axe du portail
	local function getHinge(doorParts, awayDir)
		local bestPos = nil
		local bestDot = -math.huge
		for _, data in ipairs(doorParts) do
			local pos = data.originalCFrame.Position
			local dot = pos:Dot(awayDir)
			if dot > bestDot then
				bestDot = dot
				bestPos = pos
			end
		end
		-- Utiliser le Y moyen de la porte
		local avgY = getDoorCenter(doorParts).Y
		return Vector3.new(bestPos.X, avgY, bestPos.Z)
	end

	-- Porte gauche : charnière côté gauche (direction opposée à droite)
	local hingeL = getHinge(doorLParts, -gateDir)
	-- Porte droite : charnière côté droite (direction opposée à gauche)
	local hingeR = getHinge(doorRParts, gateDir)

	print("[GateManager] Charnière L:", hingeL, "Charnière R:", hingeR)

	-- Créer une part invisible au centre du portail pour le ProximityPrompt
	local gateCenter = (centerL + centerR) / 2
	local promptPart = Instance.new("Part")
	promptPart.Size = Vector3.new(1, 1, 1)
	promptPart.Transparency = 1
	promptPart.Anchored = true
	promptPart.CanCollide = false
	promptPart.Position = Vector3.new(gateCenter.X, gateCenter.Y - 1, gateCenter.Z) -- Légèrement plus bas
	promptPart.Parent = innerGate

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Ouvrir — $" .. GATE_PRICE
	prompt.ObjectText = "Portail"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 30
	prompt.RequiresLineOfSight = false  -- les barreaux du portail bloquent la vue
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = promptPart

	local isOpen = false
	local isAnimating = false

	local function rotateDoorAroundHinge(doorParts, hingePos, angle, duration)
		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		for _, data in ipairs(doorParts) do
			local relativeCF = CFrame.new(hingePos):Inverse() * data.originalCFrame
			local targetCFrame = CFrame.new(hingePos) * CFrame.Angles(0, math.rad(angle), 0) * relativeCF
			local tween = TweenService:Create(data.part, tweenInfo, { CFrame = targetCFrame })
			tween:Play()
		end
	end

	prompt.Triggered:Connect(function(player)
		if isAnimating then return end

		if not isOpen then
			-- Vérifier l'argent pour ouvrir
			local economy = _G.EconomyManager
			if not economy then return end

			if not economy.canAfford(player, GATE_PRICE) then
				ShowNotification:FireClient(player, "Fonds insuffisants !", "#FF0000", 2)
				return
			end

			local success = economy.removeMoney(player, GATE_PRICE)
			if not success then return end

			isAnimating = true
			rotateDoorAroundHinge(doorLParts, hingeL, OPEN_ANGLE, OPEN_TIME)
			rotateDoorAroundHinge(doorRParts, hingeR, -OPEN_ANGLE, OPEN_TIME)
			isOpen = true

			task.wait(OPEN_TIME)
			isAnimating = false

			triggerApocalypse()

			-- Une fois ouverte, on désactive le prompt définitivement
			prompt.Enabled = false
			return
		end
	end)

	print("[GateManager] Portail configuré : " .. gateModel:GetFullName())
end

-- Chercher tous les portails dans le workspace (récursif)
local function findGates(parent)
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("Model") and child.Name == "Gate" then
			local innerGate = child:FindFirstChild("Gate") or child
			local doorL = innerGate:FindFirstChild("DoorCloseL") or innerGate:FindFirstChild("DoorCLoseL")
			if doorL then
				setupGate(child)
			end
		end
		findGates(child)
	end
end

task.wait(2) -- Attendre que la map soit chargée
findGates(workspace)

-- DEBUG : si aucun portail trouvé, afficher tout ce qui s'appelle Gate
print("[GateManager] === DEBUG : recherche de tous les Gate ===")
for _, obj in ipairs(workspace:GetDescendants()) do
	if obj.Name == "Gate" then
		print("[GateManager] Trouvé:", obj:GetFullName(), "| IsModel:", obj:IsA("Model"), "| Class:", obj.ClassName)
		for _, child in ipairs(obj:GetChildren()) do
			print("  └──", child.Name, "| Class:", child.ClassName)
		end
	end
end

print("[GateManager] Initialisé !")
