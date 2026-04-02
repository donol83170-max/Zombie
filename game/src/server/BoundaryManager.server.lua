-- BoundaryManager.server.lua
-- Murs invisibles autour de la base plate de map1
-- Côté forteresse (Est) ouvert pour accès au portail

local BOUNDARY = {
    minX =  83,   -- bord gauche de la base
    maxX = 248,   -- bord droit de la base
    minZ = -79,   -- bord nord de la base
    maxZ =  65,   -- bord sud de la base
}

local WALL_HEIGHT    = 60
local WALL_THICKNESS = 10
local WALL_Y         = 26

local function createWall(name, pos, size)
    local wall = Instance.new("Part")
    wall.Name = "Boundary_" .. name
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

-- 3 murs seulement — côté Est (forteresse/portail) ouvert
createWall("Nord",  Vector3.new(cx, y, BOUNDARY.minZ - t/2), Vector3.new(lenX + t*2, h, t))
createWall("Sud",   Vector3.new(cx, y, BOUNDARY.maxZ + t/2), Vector3.new(lenX + t*2, h, t))
createWall("Ouest", Vector3.new(BOUNDARY.minX - t/2, y, cz), Vector3.new(t, h, lenZ))
-- Wall_Est retiré : passage libre vers forteresse + portail

print("[BoundaryManager] 3 murs invisibles créés (côté forteresse ouvert)")
