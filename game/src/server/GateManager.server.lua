-- GateManager.server.lua
-- Gestion des portails interactifs (ouverture avec ProximityPrompt)
-- Fonctionne avec des positions relatives : déplacer le portail ne casse rien

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local ShowNotification = Events:WaitForChild("ShowNotification")
local UpdateMoney = Events:WaitForChild("UpdateMoney")

local OPEN_ANGLE = 90 -- degrés d'ouverture
local OPEN_TIME = 1.5 -- secondes pour l'animation
local GATE_PRICE = 50

local function setupGate(gateModel)
	-- Trouver les deux battants
	local innerGate = gateModel:FindFirstChild("Gate")
	if not innerGate then
		warn("[GateManager] Pas de sous-model 'Gate' trouvé dans", gateModel:GetFullName())
		return
	end

	local doorL = innerGate:FindFirstChild("DoorCLoseL")
	local doorR = innerGate:FindFirstChild("DoorCloseR")
	if not doorL or not doorR then
		warn("[GateManager] DoorCLoseL ou DoorCloseR introuvable")
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
	prompt.MaxActivationDistance = 10
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
			prompt.ActionText = "Fermer"
			isOpen = true
		else
			isAnimating = true
			rotateDoorAroundHinge(doorLParts, hingeL, 0, OPEN_TIME)
			rotateDoorAroundHinge(doorRParts, hingeR, 0, OPEN_TIME)
			prompt.ActionText = "Ouvrir — $" .. GATE_PRICE
			isOpen = false
		end

		task.wait(OPEN_TIME)
		isAnimating = false
	end)

	print("[GateManager] Portail configuré : " .. gateModel:GetFullName())
end

-- Chercher tous les portails dans le workspace (récursif)
local function findGates(parent)
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("Model") and child.Name == "Gate" then
			local innerGate = child:FindFirstChild("Gate")
			if innerGate and innerGate:FindFirstChild("DoorCLoseL") then
				setupGate(child)
			end
		end
		findGates(child)
	end
end

task.wait(2) -- Attendre que la map soit chargée
findGates(workspace)

print("[GateManager] Initialisé !")
