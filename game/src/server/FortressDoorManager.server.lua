-- FortressDoorManager.server.lua
-- Les deux portes de la forteresse s'ouvrent ENSEMBLE pour 1500$
-- Un seul ProximityPrompt, un seul paiement, animation simultanée

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local ShowNotification = Events:WaitForChild("ShowNotification")
local DoorOpened = Events:WaitForChild("DoorOpened")

-- === CONFIGURATION ===
local FORTRESS_PRICE = 1500
local OPEN_ANGLE = 90
local OPEN_TIME  = 1.5

-- Configuration par porte :
--   angle      = sens de rotation (+90 ou -90)
--   hingeEdge  = "min" (bord gauche/avant) ou "max" (bord droit/arrière)
local DOOR_CONFIG = {
	["Porte 1"] = { angle = -OPEN_ANGLE, hingeEdge = "max" },
	["Porte 2"] = { angle =  OPEN_ANGLE, hingeEdge = "min" },
}

-- === FONCTIONS UTILITAIRES ===

local function collectParts(model)
	local parts = {}
	for _, obj in ipairs(model:GetDescendants()) do
		if obj:IsA("BasePart") then
			table.insert(parts, {
				part = obj,
				originalCFrame = obj.CFrame,
			})
		end
	end
	return parts
end

local function getBoundingBox(doorParts)
	local minX, maxX = math.huge, -math.huge
	local minY, maxY = math.huge, -math.huge
	local minZ, maxZ = math.huge, -math.huge

	for _, data in ipairs(doorParts) do
		local pos = data.originalCFrame.Position
		local half = data.part.Size / 2
		minX = math.min(minX, pos.X - half.X)
		maxX = math.max(maxX, pos.X + half.X)
		minY = math.min(minY, pos.Y - half.Y)
		maxY = math.max(maxY, pos.Y + half.Y)
		minZ = math.min(minZ, pos.Z - half.Z)
		maxZ = math.max(maxZ, pos.Z + half.Z)
	end

	return minX, maxX, minY, maxY, minZ, maxZ
end

local function findHingePosition(doorModel, doorParts, hingeEdge)
	local hingePart = doorModel:FindFirstChild("Charniere")
		or doorModel:FindFirstChild("Hinge")
	if hingePart and hingePart:IsA("BasePart") then
		return hingePart.Position
	end

	local minX, maxX, minY, maxY, minZ, maxZ = getBoundingBox(doorParts)
	local sizeX = maxX - minX
	local sizeZ = maxZ - minZ
	local avgY = (minY + maxY) / 2

	-- hingeEdge "max" = charnière sur le bord opposé (bord droit)
	local useMax = (hingeEdge == "max")

	if sizeX >= sizeZ then
		-- Porte orientée en X
		local hx = useMax and maxX or minX
		return Vector3.new(hx, avgY, (minZ + maxZ) / 2)
	else
		-- Porte orientée en Z
		local hz = useMax and maxZ or minZ
		return Vector3.new((minX + maxX) / 2, avgY, hz)
	end
end

local function rotateDoorAroundHinge(doorParts, hingePos, angle, duration)
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	for _, data in ipairs(doorParts) do
		local relativeCF = CFrame.new(hingePos):Inverse() * data.originalCFrame
		local targetCFrame = CFrame.new(hingePos) * CFrame.Angles(0, math.rad(angle), 0) * relativeCF
		TweenService:Create(data.part, tweenInfo, { CFrame = targetCFrame }):Play()
	end
end

-- === RECHERCHE ET SETUP ===

task.wait(2)

local function findForteresse()
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj.Name:lower() == "forteresse"
			and (obj:IsA("Model") or obj:IsA("Folder")) then
			return obj
		end
	end
	return nil
end

local forteresse = findForteresse()
if not forteresse then
	warn("[FortressDoorManager] 'Forteresse' introuvable !")
	return
end

print("[FortressDoorManager] Forteresse trouvée :", forteresse:GetFullName())

-- Trouver toutes les portes (enfants directs OU descendants)
local doors = {} -- { { parts, hinge, angle, model }, ... }
local allCenters = {}

local function prepareDoor(doorModel)
	local parts = collectParts(doorModel)
	if #parts == 0 then
		warn("[FortressDoorManager] Aucun BasePart dans", doorModel:GetFullName())
		return
	end

	-- Garantir fermée au démarrage
	for _, data in ipairs(parts) do
		data.part.Anchored = true
		data.part.CanCollide = true
	end

	local cfg = DOOR_CONFIG[doorModel.Name] or {}
	local hinge = findHingePosition(doorModel, parts, cfg.hingeEdge)
	local angle = cfg.angle or OPEN_ANGLE
	local minX, maxX, minY, maxY, minZ, maxZ = getBoundingBox(parts)
	local center = Vector3.new((minX + maxX) / 2, (minY + maxY) / 2, (minZ + maxZ) / 2)

	table.insert(doors, {
		parts = parts,
		hinge = hinge,
		angle = angle,
		model = doorModel,
	})
	table.insert(allCenters, center)

	print(string.format("[FortressDoorManager] %s : %d parts, charnière %s",
		doorModel.Name, #parts, tostring(hinge)))
end

-- Chercher les portes
for _, obj in ipairs(forteresse:GetDescendants()) do
	if obj.Name:match("^Porte") and (obj:IsA("Model") or obj:IsA("Folder")) then
		prepareDoor(obj)
	end
end

if #doors == 0 then
	warn("[FortressDoorManager] AUCUNE porte trouvée !")
	return
end

-- === UN SEUL PROMPT ENTRE LES DEUX PORTES ===

-- Calculer le point central entre toutes les portes
local totalCenter = Vector3.new(0, 0, 0)
for _, c in ipairs(allCenters) do
	totalCenter = totalCenter + c
end
totalCenter = totalCenter / #allCenters

local promptPart = Instance.new("Part")
promptPart.Name = "FortressPrompt"
promptPart.Size = Vector3.new(1, 1, 1)
promptPart.Transparency = 1
promptPart.Anchored = true
promptPart.CanCollide = false
promptPart.Position = totalCenter
promptPart.Parent = forteresse

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Ouvrir la Forteresse — $" .. FORTRESS_PRICE
prompt.ObjectText = "Forteresse"
prompt.HoldDuration = 0.5
prompt.MaxActivationDistance = 15
prompt.RequiresLineOfSight = false
prompt.KeyboardKeyCode = Enum.KeyCode.E
prompt.Parent = promptPart

local isOpen = false
local isAnimating = false

prompt.Triggered:Connect(function(player)
	if isAnimating or isOpen then return end

	local economy = _G.EconomyManager
	if not economy then return end

	if not economy.canAfford(player, FORTRESS_PRICE) then
		ShowNotification:FireClient(player, "Fonds insuffisants ! ($" .. FORTRESS_PRICE .. " requis)", "#FF0000", 2)
		return
	end

	local success = economy.removeMoney(player, FORTRESS_PRICE)
	if not success then return end

	-- === OUVRIR LES DEUX PORTES EN MÊME TEMPS ===
	isAnimating = true
	for _, door in ipairs(doors) do
		rotateDoorAroundHinge(door.parts, door.hinge, door.angle, OPEN_TIME)
	end
	isOpen = true

	task.wait(OPEN_TIME)

	-- Désactiver les collisions
	for _, door in ipairs(doors) do
		for _, data in ipairs(door.parts) do
			data.part.CanCollide = false
		end
	end

	isAnimating = false
	prompt.Enabled = false

	ShowNotification:FireAllClients(player.Name .. " a ouvert la Forteresse !", "#00FF00", 3)
	DoorOpened:FireAllClients("Forteresse")

	print("[FortressDoorManager]", player.Name, "a ouvert la forteresse pour $" .. FORTRESS_PRICE)
end)

print(string.format("[FortressDoorManager] %d portes configurées — prix: $%d — Prêt !",
	#doors, FORTRESS_PRICE))

-- === MURS DE BARRAGE COLLÉS À LA FORTERESSE ===
-- Empêche les joueurs de contourner les portes

local function createBarrier(name, pos, size)
	local wall = Instance.new("Part")
	wall.Name = "FortressBarrier_" .. name
	wall.Anchored = true
	wall.CanCollide = true
	wall.Transparency = 1
	wall.Size = size
	wall.Position = pos
	wall.Parent = workspace
	return wall
end

-- Calculer la position des barrages à partir des PORTES (pas du bounding box forteresse)
-- On utilise les charnières des portes qui donnent la position exacte de l'entrée
local mapBounds = _G.MapBounds
if mapBounds and #doors >= 2 then
	-- Trouver le bounding box des portes uniquement
	local dMinX, dMaxX = math.huge, -math.huge
	local dMinY, dMaxY = math.huge, -math.huge
	local dMinZ, dMaxZ = math.huge, -math.huge
	for _, door in ipairs(doors) do
		local mx1, mx2, my1, my2, mz1, mz2 = getBoundingBox(door.parts)
		dMinX = math.min(dMinX, mx1) dMaxX = math.max(dMaxX, mx2)
		dMinY = math.min(dMinY, my1) dMaxY = math.max(dMaxY, my2)
		dMinZ = math.min(dMinZ, mz1) dMaxZ = math.max(dMaxZ, mz2)
	end

	local SIDE_OFFSET   = 20  -- ← décalage latéral des murs (studs) — augmente pour plus d'espace
	local barrierHeight = 60
	local barrierThick  = 4
	local barrierY      = (dMinY + dMaxY) / 2
	local entryX        = dMinX

	-- Mur NORD : de la map jusqu'au bord nord des portes, décalé vers le nord
	local northLen = (dMinZ - SIDE_OFFSET) - mapBounds.minZ
	if northLen > 1 then
		createBarrier("Nord", Vector3.new(
			entryX - barrierThick/2,
			barrierY,
			mapBounds.minZ + northLen/2
		), Vector3.new(barrierThick, barrierHeight, northLen))
	end

	-- Mur SUD : du bord sud des portes décalé vers le sud jusqu'à la map
	local southStart = dMaxZ + SIDE_OFFSET
	local southLen = mapBounds.maxZ - southStart
	if southLen > 1 then
		createBarrier("Sud", Vector3.new(
			entryX - barrierThick/2,
			barrierY,
			southStart + southLen/2
		), Vector3.new(barrierThick, barrierHeight, southLen))
	end

	print(string.format("[FortressDoorManager] Barrages créés à X=%.0f | Portes Z[%.0f → %.0f]",
		entryX, dMinZ, dMaxZ))
else
	warn("[FortressDoorManager] _G.MapBounds non trouvé ou moins de 2 portes, barrages ignorés")
end
