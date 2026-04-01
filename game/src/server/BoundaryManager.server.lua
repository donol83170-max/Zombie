-- BoundaryManager.server.lua
-- Murs invisibles calculés depuis la base plate (165 x 144 studs)
-- Centre de la base : X=165.2, Z=-7.2

local BOUNDARY = {
    minX =  83,   --  165.2 - 165/2
    maxX = 248,   --  165.2 + 165/2
    minZ = -79,   -- -7.2  - 144/2
    maxZ =  65,   -- -7.2  + 144/2
}

local WALL_HEIGHT    = 60
local WALL_THICKNESS = 10
local WALL_Y         = 26   -- hauteur centre des murs (sol à Y=-4)

local function createWall(name, pos, size)
    local wall = Instance.new("Part")
    wall.Name = name
    wall.Anchored = true
    wall.CanCollide = true
    wall.Transparency = 1
    wall.Size = size
    wall.CFrame = CFrame.new(pos)
    wall.Parent = workspace
end

local cx   = (BOUNDARY.minX + BOUNDARY.maxX) / 2
local cz   = (BOUNDARY.minZ + BOUNDARY.maxZ) / 2
local lenX = BOUNDARY.maxX - BOUNDARY.minX
local lenZ = BOUNDARY.maxZ - BOUNDARY.minZ
local t    = WALL_THICKNESS
local h    = WALL_HEIGHT
local y    = WALL_Y

-- Seuls Wall_Sud et Wall_Ouest restent — portail libre à X=240 côté Est/Nord
createWall("Wall_Sud",   Vector3.new(cx, y, BOUNDARY.maxZ + t/2), Vector3.new(lenX + t*2, h, t))
createWall("Wall_Ouest", Vector3.new(BOUNDARY.minX - t/2, y, cz), Vector3.new(t, h, lenZ))
-- Wall_Est et Wall_Nord retirés : passage libre vers le portail (X=240, Z=-20) et map lucas 2

print("[BoundaryManager] 4 murs invisibles créés autour de la base !")
