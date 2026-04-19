-- FlashlightController.client.lua
-- Lampe torche activée quand l'apocalypse démarre (ouverture de la Gate)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local Events = ReplicatedStorage:WaitForChild("Events")
local ApocalypseStarted = Events:WaitForChild("ApocalypseStarted", 30)
if not ApocalypseStarted then return end

ApocalypseStarted.OnClientEvent:Connect(function()
	-- Part invisible ancrée qui suit la caméra chaque frame
	local lightPart = Instance.new("Part")
	lightPart.Size = Vector3.new(0.1, 0.1, 0.1)
	lightPart.Transparency = 1
	lightPart.CanCollide = false
	lightPart.CanQuery = false
	lightPart.Anchored = true
	lightPart.CastShadow = false
	lightPart.Parent = workspace

	-- SpotLight principal : éclaire ce qui est devant
	local spotlight = Instance.new("SpotLight")
	spotlight.Brightness = 10
	spotlight.Range = 70
	spotlight.Angle = 45
	spotlight.Shadows = true
	spotlight.Face = Enum.NormalId.Front
	spotlight.Parent = lightPart

	-- PointLight proche : illumine les bras et l'arme (viewmodel)
	local pointlight = Instance.new("PointLight")
	pointlight.Brightness = 3
	pointlight.Range = 8
	pointlight.Color = Color3.fromRGB(255, 240, 200)
	pointlight.Parent = lightPart

	RunService.RenderStepped:Connect(function()
		lightPart.CFrame = camera.CFrame
	end)
end)
