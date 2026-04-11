-- MapSpawnManager.server.lua
-- Génère des points de spawn zombies autour des joueurs
-- Fonctionne sur n'importe quelle map

local Players = game:GetService("Players")

local SPAWN_COUNT     = 20   -- nombre de points de spawn générés
local MIN_DIST        = 40   -- distance minimale du joueur (studs)
local MAX_DIST        = 80   -- distance maximale du joueur (studs)
local SPAWN_HEIGHT    = 3    -- studs au dessus du sol
local MAX_ATTEMPTS    = 200  -- tentatives max pour trouver des positions valides

task.wait(2)

-- === DOSSIER ZOMBIE SPAWNS ===

local zombieSpawns = workspace:FindFirstChild("ZombieSpawns")
if not zombieSpawns then
	zombieSpawns = Instance.new("Folder")
	zombieSpawns.Name = "ZombieSpawns"
	zombieSpawns.Parent = workspace
end

local function clearAutoSpawns()
	for _, child in ipairs(zombieSpawns:GetChildren()) do
		if child.Name:sub(1, 9) == "AutoSpawn" then
			child:Destroy()
		end
	end
end

-- === RAYCAST VERS LE SOL ===

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function getGroundY(x, z)
	local origin = Vector3.new(x, 500, z)
	local result = workspace:Raycast(origin, Vector3.new(0, -600, 0), rayParams)
	if result then
		return result.Position.Y + SPAWN_HEIGHT
	end
	return nil
end

-- === GÉNÉRATION DES POINTS AUTOUR DES JOUEURS ===

local function generateSpawnPoints()
	clearAutoSpawns()

	local playerPositions = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			table.insert(playerPositions, hrp.Position)
		end
	end

	if #playerPositions == 0 then
		warn("[MapSpawnManager] Aucun joueur trouvé, spawn impossible.")
		return
	end

	local spawned = 0
	local attempts = 0

	while spawned < SPAWN_COUNT and attempts < MAX_ATTEMPTS do
		attempts += 1

		-- Choisir un joueur aléatoire comme centre
		local center = playerPositions[math.random(1, #playerPositions)]

		-- Angle et distance aléatoires dans l'anneau MIN_DIST..MAX_DIST
		local angle = math.random() * 2 * math.pi
		local dist  = MIN_DIST + math.random() * (MAX_DIST - MIN_DIST)
		local x = center.X + math.cos(angle) * dist
		local z = center.Z + math.sin(angle) * dist

		local groundY = getGroundY(x, z)
		if not groundY then continue end

		local part = Instance.new("Part")
		part.Name       = "AutoSpawn_" .. spawned
		part.Anchored   = true
		part.CanCollide = false
		part.Transparency = 1
		part.Size       = Vector3.new(4, 1, 4)
		part.Position   = Vector3.new(x, groundY, z)
		part.Parent     = zombieSpawns

		spawned += 1
	end

	print(string.format("[MapSpawnManager] %d points de spawn générés (%d tentatives)", spawned, attempts))
end

-- Générer au démarrage puis à chaque nouvelle manche
generateSpawnPoints()

-- Exposer la fonction pour que WaveManager puisse régénérer avant chaque manche
_G.RegenerateSpawnPoints = generateSpawnPoints
