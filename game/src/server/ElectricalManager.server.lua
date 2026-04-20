-- ElectricalManager.server.lua
-- Gestion de la boîte électrique + porte de garage
-- 1. Le joueur ouvre la boîte électrique gratuitement (pivote 90°)
-- 2. Quand l'électricité est réparée (_G.RepairElectricity) :
--    - la boîte se referme
--    - la porte du garage s'ouvre (se translate vers le haut)

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local ShowNotification = Events:WaitForChild("ShowNotification")

-- Event pour notifier les clients (future lampe torche, sons, etc.)
local ElectricityRepaired = Events:FindFirstChild("ElectricityRepaired")
if not ElectricityRepaired then
	ElectricityRepaired = Instance.new("RemoteEvent")
	ElectricityRepaired.Name = "ElectricityRepaired"
	ElectricityRepaired.Parent = Events
end

-- Ouverture de la boîte électrique
local HANDLE_SIDE = "left"        -- de quel côté est la poignée vu par le joueur : "right" ou "left"
local SWING_ANGLE = 90            -- amplitude d'ouverture (degrés)
local SWING_TIME = 1.0
local GARAGE_TIME = 2.0

task.wait(2) -- attendre que la map soit chargée

-- === RECHERCHE DES MODÈLES ===

local function findByName(...)
	local names = { ... }
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Model") or obj:IsA("Folder") then
			local lname = obj.Name:lower()
			for _, n in ipairs(names) do
				if lname == n then return obj end
			end
		end
	end
	return nil
end

local electricalBox = findByName("electrical box", "electricalbox")
local garage = findByName("garage")

if not electricalBox then
	warn("[Electrical] 'Electrical box' introuvable dans le workspace")
	return
end
if not garage then
	warn("[Electrical] 'Garage' introuvable dans le workspace")
	return
end

local electricalDoor = electricalBox:FindFirstChild("door", true)
	or electricalBox:FindFirstChild("Door", true)
local garageDoor = garage:FindFirstChild("garagedoor", true)
	or garage:FindFirstChild("GarageDoor", true)

if not electricalDoor then
	warn("[Electrical] 'door' introuvable dans ElectricalBox")
	return
end
if not garageDoor then
	warn("[Electrical] 'garagedoor' introuvable dans Garage")
	return
end

-- === UTILS ===

local function collectParts(obj)
	local parts = {}
	if obj:IsA("BasePart") then
		table.insert(parts, { part = obj, originalCFrame = obj.CFrame })
	else
		for _, p in ipairs(obj:GetDescendants()) do
			if p:IsA("BasePart") then
				table.insert(parts, { part = p, originalCFrame = p.CFrame })
			end
		end
	end
	return parts
end

local function getBoundingBox(parts)
	local minX, maxX = math.huge, -math.huge
	local minY, maxY = math.huge, -math.huge
	local minZ, maxZ = math.huge, -math.huge
	for _, data in ipairs(parts) do
		local pos = data.originalCFrame.Position
		local half = data.part.Size / 2
		minX = math.min(minX, pos.X - half.X) maxX = math.max(maxX, pos.X + half.X)
		minY = math.min(minY, pos.Y - half.Y) maxY = math.max(maxY, pos.Y + half.Y)
		minZ = math.min(minZ, pos.Z - half.Z) maxZ = math.max(maxZ, pos.Z + half.Z)
	end
	return minX, maxX, minY, maxY, minZ, maxZ
end

local function rotateAroundHinge(parts, hinge, axis, angle, duration)
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local rotation = CFrame.fromAxisAngle(axis, math.rad(angle))
	local lastTween
	for _, data in ipairs(parts) do
		local target = CFrame.new(hinge) * rotation * CFrame.new(-hinge) * data.originalCFrame
		local t = TweenService:Create(data.part, tweenInfo, { CFrame = target })
		t:Play()
		lastTween = t
	end
	return lastTween
end

local function tweenToCFrame(parts, duration)
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local lastTween
	for _, data in ipairs(parts) do
		local t = TweenService:Create(data.part, tweenInfo, { CFrame = data.originalCFrame })
		t:Play()
		lastTween = t
	end
	return lastTween
end

-- === BOÎTE ÉLECTRIQUE ===

local elecParts = collectParts(electricalDoor)
for _, data in ipairs(elecParts) do
	data.part.Anchored = true
	data.part.CanCollide = true
end

-- Trouver la BasePart principale pour lire son orientation
local doorBase
if electricalDoor:IsA("BasePart") then
	doorBase = electricalDoor
else
	doorBase = electricalDoor:FindFirstChildWhichIsA("BasePart", true)
end
if not doorBase then
	warn("[Electrical] Aucune BasePart trouvée dans la porte électrique")
	return
end

-- Position ouverte fournie manuellement par le joueur
-- Ouverte : pos (1204.087, 11.017, -692.849) | orient (0, 0, 0)
-- La position "fermée" est la position ACTUELLE de doorBase dans Studio
local elecOpenRefCF = CFrame.new(1203.887, 11.017, -692.849)
	* CFrame.fromOrientation(0, 0, 0)
-- Transformation monde : déplace doorBase de sa position actuelle à la position ouverte
local elecOpenTransform = elecOpenRefCF * doorBase.CFrame:Inverse()

-- Pré-calculer la CFrame cible ouverte pour chaque part
for _, data in ipairs(elecParts) do
	data.openCFrame = elecOpenTransform * data.originalCFrame
end

-- Pour placer le prompt
local eMinX, eMaxX, eMinY, eMaxY, eMinZ, eMaxZ = getBoundingBox(elecParts)
local eAvgY = (eMinY + eMaxY) / 2

local elecOpen = false
local elecAnimating = false
local repairPrompt -- défini plus bas, référencé depuis le prompt d'ouverture

local function openElectrical()
	if elecOpen or elecAnimating then return end
	elecAnimating = true
	local tweenInfo = TweenInfo.new(SWING_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	for _, data in ipairs(elecParts) do
		TweenService:Create(data.part, tweenInfo, { CFrame = data.openCFrame }):Play()
	end
	task.wait(SWING_TIME)
	for _, data in ipairs(elecParts) do
		data.part.CanCollide = false
	end
	elecOpen = true
	elecAnimating = false
end

local function closeElectrical()
	if not elecOpen or elecAnimating then return end
	elecAnimating = true
	for _, data in ipairs(elecParts) do
		data.part.CanCollide = true
	end
	tweenToCFrame(elecParts, SWING_TIME)
	task.wait(SWING_TIME)
	elecOpen = false
	elecAnimating = false
end

-- ProximityPrompt gratuit
local promptPart = Instance.new("Part")
promptPart.Name = "ElectricalPrompt"
promptPart.Size = Vector3.new(1, 1, 1)
promptPart.Transparency = 1
promptPart.Anchored = true
promptPart.CanCollide = false
promptPart.Position = Vector3.new((eMinX + eMaxX) / 2, eAvgY, (eMinZ + eMaxZ) / 2)
promptPart.Parent = electricalBox

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Ouvrir"
prompt.ObjectText = "Boîte électrique"
prompt.HoldDuration = 0.5
prompt.MaxActivationDistance = 8
prompt.RequiresLineOfSight = false
prompt.KeyboardKeyCode = Enum.KeyCode.E
prompt.Parent = promptPart

prompt.Triggered:Connect(function(player)
	if elecOpen or elecAnimating then return end
	prompt.Enabled = false
	openElectrical()
	-- Activer le prompt de réparation une fois la boîte ouverte
	if repairPrompt then repairPrompt.Enabled = true end
	ShowNotification:FireAllClients(player.Name .. " a ouvert la boîte électrique !", "#00FFFF", 3)
	print("[Electrical] Boîte ouverte par " .. player.Name)
end)

-- === PROMPT DE RÉPARATION (activé une fois la boîte ouverte) ===

local HAS_TOOL_ATTR = "HasRepairTool"

local repairPromptPart = Instance.new("Part")
repairPromptPart.Name = "RepairPromptPart"
repairPromptPart.Size = Vector3.new(1, 1, 1)
repairPromptPart.Transparency = 1
repairPromptPart.Anchored = true
repairPromptPart.CanCollide = false
repairPromptPart.Position = Vector3.new((eMinX + eMaxX) / 2, eAvgY, (eMinZ + eMaxZ) / 2)
repairPromptPart.Parent = electricalBox

repairPrompt = Instance.new("ProximityPrompt") -- assignation à la variable locale déclarée plus haut
repairPrompt.ActionText = "Réparer"
repairPrompt.ObjectText = "Boîte électrique"
repairPrompt.HoldDuration = 1.5
repairPrompt.MaxActivationDistance = 8
repairPrompt.RequiresLineOfSight = false
repairPrompt.KeyboardKeyCode = Enum.KeyCode.F
repairPrompt.Enabled = false
repairPrompt.Parent = repairPromptPart

repairPrompt.Triggered:Connect(function(player)
	if not player:GetAttribute(HAS_TOOL_ATTR) then
		ShowNotification:FireClient(player, "🔧 Il te faut l'outil de réparation !", "#FF5555", 3)
		return
	end
	player:SetAttribute(HAS_TOOL_ATTR, false)
	repairPrompt.Enabled = false
	_G.RepairElectricity(player)
end)

-- === RAMASSAGE DE L'OUTIL DE RÉPARATION ===

local function setupRepairToolPickup()
	local tool
	for _, obj in ipairs(workspace:GetDescendants()) do
		if (obj:IsA("Model") or obj:IsA("BasePart")) and obj.Name == "RepairTool" then
			tool = obj
			break
		end
	end
	if not tool then
		warn("[Electrical] Aucun 'RepairTool' trouvé dans le workspace")
		return
	end

	local anchor = tool:IsA("BasePart") and tool or tool:FindFirstChildWhichIsA("BasePart", true)
	if not anchor then
		warn("[Electrical] RepairTool sans BasePart")
		return
	end

	local pickupPrompt = Instance.new("ProximityPrompt")
	pickupPrompt.ActionText = "Ramasser"
	pickupPrompt.ObjectText = "Outil de réparation"
	pickupPrompt.HoldDuration = 0.5
	pickupPrompt.MaxActivationDistance = 8
	pickupPrompt.KeyboardKeyCode = Enum.KeyCode.E
	pickupPrompt.Parent = anchor

	pickupPrompt.Triggered:Connect(function(player)
		player:SetAttribute(HAS_TOOL_ATTR, true)
		ShowNotification:FireClient(player, "🔧 Outil de réparation ramassé !", "#00FF00", 3)
		print("[Electrical] " .. player.Name .. " a ramassé l'outil")
		tool:Destroy()
	end)
end

setupRepairToolPickup()

-- === PORTE DE GARAGE ===

if not garageDoor:IsA("BasePart") then
	warn("[Electrical] 'garagedoor' n'est pas une BasePart. Recherche d'une BasePart à l'intérieur.")
	for _, p in ipairs(garageDoor:GetDescendants()) do
		if p:IsA("BasePart") then
			garageDoor = p
			break
		end
	end
end

garageDoor.Anchored = true
local garageOpen = false

-- Transformation ouverte/fermée fournie manuellement par le joueur :
-- Fermée : pos (1224.034, 11.543, -626.904) | orient (0, 0, 0)
-- Ouverte : pos (1224.034, 17.143, -621.404) | orient (90, 0, 0)
-- Delta : translation (0, +5.6, +5.5), rotation +90° autour de X
local garageClosedCF = garageDoor.CFrame
local garageOpenCF = garageClosedCF * CFrame.new(0, 5.6, 5.5) * CFrame.Angles(math.rad(90), 0, 0)

local garageSound = Instance.new("Sound")
garageSound.Name = "GarageOpenSound"
garageSound.SoundId = "rbxassetid://132068473451354"
garageSound.Volume = 2
garageSound.RollOffMinDistance = 10
garageSound.RollOffMaxDistance = 80
garageSound.Parent = garageDoor

local function openGarage()
	if garageOpen then return end
	garageOpen = true
	garageSound:Play()
	local tweenInfo = TweenInfo.new(GARAGE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	TweenService:Create(garageDoor, tweenInfo, { CFrame = garageOpenCF }):Play()
	task.wait(GARAGE_TIME)
	garageDoor.CanCollide = false
end

-- === API GLOBALE POUR FUTUR ITEM DE RÉPARATION ===

_G.RepairElectricity = function(player)
	local playerName = (player and player.Name) or "Un joueur"
	ShowNotification:FireAllClients(playerName .. " a réparé l'électricité !", "#FFFF00", 4)
	print("[Electrical] Électricité réparée par " .. playerName)

	-- Désactiver le prompt définitivement
	prompt.Enabled = false

	-- Fermer la boîte électrique + ouvrir le garage en parallèle
	task.spawn(closeElectrical)
	task.spawn(openGarage)

	ElectricityRepaired:FireAllClients()
end

print("[Electrical] ElectricalBox & Garage configurés !")
