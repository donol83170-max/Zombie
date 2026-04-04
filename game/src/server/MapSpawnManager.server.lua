-- MapSpawnManager.server.lua
-- Génère des points de spawn zombies aléatoires sur map1
-- Utilise les limites détectées par BoundaryManager (plus de coordonnées hardcodées)

local SPAWN_COUNT = 20        -- nombre de points de spawn générés
local SPAWN_HEIGHT_ABOVE = 3  -- studs au dessus du sol

task.wait(3) -- Attendre BoundaryManager (qui attend 2s)

-- === RÉCUPÉRER LES LIMITES DYNAMIQUES ===

local MAP

if _G.MapBounds then
	MAP = {
		minX = _G.MapBounds.minX,
		maxX = _G.MapBounds.maxX,
		minZ = _G.MapBounds.minZ,
		maxZ = _G.MapBounds.maxZ,
		raycastFromY = 200,
	}
	print(string.format("[MapSpawnManager] Limites dynamiques : X[%.0f, %.0f] Z[%.0f, %.0f]",
		MAP.minX, MAP.maxX, MAP.minZ, MAP.maxZ))
else
	-- Fallback : détection locale si BoundaryManager n'a pas encore tourné
	warn("[MapSpawnManager] _G.MapBounds non trouvé, détection locale...")

	local function findMap()
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

	local mapModel = findMap()
	if mapModel then
		local minX, maxX = math.huge, -math.huge
		local minZ, maxZ = math.huge, -math.huge
		for _, part in ipairs(mapModel:GetDescendants()) do
			if part:IsA("BasePart") then
				local pos = part.Position
				local half = part.Size / 2
				minX = math.min(minX, pos.X - half.X)
				maxX = math.max(maxX, pos.X + half.X)
				minZ = math.min(minZ, pos.Z - half.Z)
				maxZ = math.max(maxZ, pos.Z + half.Z)
			end
		end
		MAP = { minX = minX, maxX = maxX, minZ = minZ, maxZ = maxZ, raycastFromY = 200 }
	else
		warn("[MapSpawnManager] Aucune map détectée ! Spawn impossible.")
		return
	end
end

-- === DOSSIER ZOMBIE SPAWNS ===

local zombieSpawns = workspace:FindFirstChild("ZombieSpawns")
if not zombieSpawns then
	zombieSpawns = Instance.new("Folder")
	zombieSpawns.Name = "ZombieSpawns"
	zombieSpawns.Parent = workspace
end

-- Supprimer les anciens points auto-générés (garder les manuels)
for _, child in ipairs(zombieSpawns:GetChildren()) do
	if child.Name:sub(1, 9) == "AutoSpawn" then
		child:Destroy()
	end
end

-- === RAYCAST POUR TROUVER LE SOL ===

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

-- Exclure les murs invisibles du raycast
local excludeList = {}
for _, obj in ipairs(workspace:GetChildren()) do
	if obj.Name:match("^Boundary_") then
		table.insert(excludeList, obj)
	end
end
rayParams.FilterDescendantsInstances = excludeList

local spawned = 0
local attempts = 0
local maxAttempts = SPAWN_COUNT * 5

while spawned < SPAWN_COUNT and attempts < maxAttempts do
	attempts += 1

	-- Position X/Z aléatoire dans la map
	local randX = math.random(math.floor(MAP.minX + 5), math.floor(MAP.maxX - 5))
	local randZ = math.random(math.floor(MAP.minZ + 5), math.floor(MAP.maxZ - 5))

	-- Raycast vers le bas pour trouver le sol
	local origin = Vector3.new(randX, MAP.raycastFromY, randZ)
	local direction = Vector3.new(0, -400, 0)
	local result = workspace:Raycast(origin, direction, rayParams)

	if result then
		local groundY = result.Position.Y + SPAWN_HEIGHT_ABOVE

		local part = Instance.new("Part")
		part.Name = "AutoSpawn_" .. spawned
		part.Anchored = true
		part.CanCollide = false
		part.Transparency = 1
		part.Size = Vector3.new(4, 1, 4)
		part.Position = Vector3.new(randX, groundY, randZ)
		part.Parent = zombieSpawns

		spawned += 1
	end
end

print(string.format("[MapSpawnManager] %d points de spawn générés (%d tentatives)", spawned, attempts))
