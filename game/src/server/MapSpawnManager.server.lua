-- MapSpawnManager.server.lua
-- Génère des points de spawn zombies aléatoires sur map1
-- Utilise un raycast vers le bas pour trouver le sol exact

local SPAWN_COUNT = 20        -- nombre de points de spawn générés
local SPAWN_HEIGHT_ABOVE = 3  -- studs au dessus du sol

-- Limites de map1 (identiques à BoundaryManager)
local MAP = {
    minX =  83,
    maxX = 248,
    minZ = -79,
    maxZ =  65,
    raycastFromY = 100,  -- hauteur de départ du raycast vers le bas
}

-- Dossier ZombieSpawns
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

-- Raycast params : ignore les murs invisibles et les triggers
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.FilterDescendantsInstances = { workspace:FindFirstChild("Wall_Nord"), workspace:FindFirstChild("Wall_Sud"), workspace:FindFirstChild("Wall_Ouest"), workspace:FindFirstChild("Wall_Est") }

local spawned = 0
local attempts = 0
local maxAttempts = SPAWN_COUNT * 5

while spawned < SPAWN_COUNT and attempts < maxAttempts do
    attempts += 1

    -- Position X/Z aléatoire dans la map
    local randX = math.random(MAP.minX + 5, MAP.maxX - 5)
    local randZ = math.random(MAP.minZ + 5, MAP.maxZ - 5)

    -- Raycast vers le bas pour trouver le sol
    local origin = Vector3.new(randX, MAP.raycastFromY, randZ)
    local direction = Vector3.new(0, -200, 0)
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

print(string.format("[MapSpawnManager] %d points de spawn générés sur map1 (%d tentatives)", spawned, attempts))
