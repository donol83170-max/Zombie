-- BoundaryManager.server.lua
-- Murs invisibles autour de la Map 1 (détection automatique des limites)
-- Plus de coordonnées hardcodées : s'adapte à toute taille de map

local WALL_HEIGHT    = 60
local WALL_THICKNESS = 10
local WALL_Y         = 26
local MARGIN         = 2   -- studs de marge autour de la map

task.wait(2) -- Attendre que la map soit chargée

-- === DÉTECTION AUTOMATIQUE DE LA MAP ===

local function findMapModel()
	-- Chercher la map par nom (toutes variantes)
	local names = { "map1", "Map1", "Map 1", "map 1", "Map" }
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj:IsA("Model") or obj:IsA("Folder") then
			for _, name in ipairs(names) do
				if obj.Name == name then
					return obj
				end
			end
		end
	end
	return nil
end

local function computeBounds(parent)
	local minX, maxX = math.huge, -math.huge
	local minY, maxY = math.huge, -math.huge
	local minZ, maxZ = math.huge, -math.huge
	local count = 0

	for _, part in ipairs(parent:GetDescendants()) do
		if part:IsA("BasePart") then
			local pos = part.Position
			local half = part.Size / 2
			minX = math.min(minX, pos.X - half.X)
			maxX = math.max(maxX, pos.X + half.X)
			minY = math.min(minY, pos.Y - half.Y)
			maxY = math.max(maxY, pos.Y + half.Y)
			minZ = math.min(minZ, pos.Z - half.Z)
			maxZ = math.max(maxZ, pos.Z + half.Z)
			count += 1
		end
	end

	return minX, maxX, minY, maxY, minZ, maxZ, count
end

-- Trouver la map
local mapModel = findMapModel()
local minX, maxX, minY, maxY, minZ, maxZ, partCount

if mapModel then
	minX, maxX, minY, maxY, minZ, maxZ, partCount = computeBounds(mapModel)
	print(string.format("[BoundaryManager] Map détectée : '%s' (%d parts)", mapModel.Name, partCount))
	print(string.format("[BoundaryManager] Limites : X[%.0f, %.0f] Y[%.0f, %.0f] Z[%.0f, %.0f]",
		minX, maxX, minY, maxY, minZ, maxZ))
else
	-- Fallback : chercher un Baseplate
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		local pos = baseplate.Position
		local half = baseplate.Size / 2
		minX = pos.X - half.X
		maxX = pos.X + half.X
		minY = pos.Y - half.Y
		maxY = pos.Y + half.Y
		minZ = pos.Z - half.Z
		maxZ = pos.Z + half.Z
		print("[BoundaryManager] Baseplate trouvée, limites calculées")
	else
		warn("[BoundaryManager] Aucune Map ni Baseplate trouvée ! Murs non créés.")
		-- Debug
		print("[BoundaryManager] === DEBUG : enfants du workspace ===")
		for _, obj in ipairs(workspace:GetChildren()) do
			print("  ", obj.Name, "|", obj.ClassName)
		end
		return
	end
end

-- Ajouter la marge
minX = minX - MARGIN
maxX = maxX + MARGIN
minZ = minZ - MARGIN
maxZ = maxZ + MARGIN

-- === CRÉATION DES MURS ===

-- Supprimer les anciens murs s'ils existent
for _, obj in ipairs(workspace:GetChildren()) do
	if obj.Name:match("^Boundary_") then
		obj:Destroy()
	end
end

local function createWall(name, pos, size)
	local wall = Instance.new("Part")
	wall.Name = "Boundary_" .. name
	wall.Anchored = true
	wall.CanCollide = true
	wall.Transparency = 1
	wall.Size = size
	wall.CFrame = CFrame.new(pos)
	wall.Parent = workspace
	return wall
end

local cx   = (minX + maxX) / 2
local cz   = (minZ + maxZ) / 2
local lenX = maxX - minX
local lenZ = maxZ - minZ
local t    = WALL_THICKNESS
local h    = WALL_HEIGHT
local y    = WALL_Y

-- 4 murs autour de toute la map (plus de trou)
createWall("Nord",  Vector3.new(cx, y, minZ - t/2), Vector3.new(lenX + t*2, h, t))
createWall("Sud",   Vector3.new(cx, y, maxZ + t/2), Vector3.new(lenX + t*2, h, t))
createWall("Ouest", Vector3.new(minX - t/2, y, cz), Vector3.new(t, h, lenZ))
createWall("Est",   Vector3.new(maxX + t/2, y, cz), Vector3.new(t, h, lenZ))

-- Stocker les limites dans _G pour que MapSpawnManager puisse les utiliser
_G.MapBounds = {
	minX = minX + MARGIN, -- remettre sans la marge pour les spawns
	maxX = maxX - MARGIN,
	minZ = minZ + MARGIN,
	maxZ = maxZ - MARGIN,
}

print(string.format("[BoundaryManager] 4 murs invisibles créés autour de la map (%.0fx%.0f studs)", lenX, lenZ))
