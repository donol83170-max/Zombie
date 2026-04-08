-- InputController.client.lua
-- Sprint + Détection zombies (le Fe Kit gère les tirs/sons/munitions)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = ReplicatedStorage:WaitForChild("Events")
local ClassConfig = require(Shared:WaitForChild("ClassConfig"))
local DamageZombie = Events:WaitForChild("DamageZombie")

-- Mouvement (Sprint)
local sprintTimer = 0

-- Détection zombie : quand le joueur tire (clic gauche), on fait un raycast parallèle
-- pour détecter si un zombie a été touché. Le Fe Kit gère le reste.
local lastZombieHitTime = 0

mouse.Button1Down:Connect(function()
	-- Anti-spam : max 10 hits par seconde
	local now = tick()
	if now - lastZombieHitTime < 0.1 then return end
	lastZombieHitTime = now

	local char = player.Character
	if not char or not char:FindFirstChild("Head") then return end
	
	-- Vérifier qu'on tient une arme
	local tool = char:FindFirstChildOfClass("Tool")
	if not tool then return end

	local origin = char.Head.Position
	local direction = (mouse.Hit.Position - origin).Unit * 300

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	local excluded = {char}
	-- Exclure le viewmodel du Fe Kit (dans la caméra)
	local camStorage = workspace.CurrentCamera:FindFirstChild("ViewmodelStorage")
	if camStorage then table.insert(excluded, camStorage) end
	raycastParams.FilterDescendantsInstances = excluded

	local result = workspace:Raycast(origin, direction, raycastParams)
	if not result then return end

	local hit = result.Instance
	-- Trouver le zombie racine (nom commençant par Enemy_)
	local current = hit
	for _ = 1, 10 do
		if current == nil or current == workspace then break end
		if current:IsA("Model") and current.Name:sub(1, 6) == "Enemy_" then
			local humanoid = current:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				local isHeadshot = (hit.Name == "Head")
				DamageZombie:FireServer(current, isHeadshot, tool.Name)
				
				-- Feedback visuel : flash rouge
				local originalColor = hit.Color
				hit.Color = Color3.fromRGB(255, 0, 0)
				task.delay(0.1, function()
					if hit and hit.Parent then hit.Color = originalColor end
				end)
			end
			return
		end
		current = current.Parent
	end
end)

-- Boucle Principale (Sprint + fix physique)
RunService.RenderStepped:Connect(function(dt)
	local char = player.Character
	if char then
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local sessionData = player:FindFirstChild("SessionData")
			local className = sessionData and sessionData:FindFirstChild("Class") and sessionData.Class.Value or "Soldier"
			local classData = ClassConfig.Classes[className]
			local baseSpeed = (classData and classData.speedMult or 1.0) * 16

			if humanoid.MoveDirection.Magnitude > 0.1 then
				sprintTimer = math.min(sprintTimer + dt, 3.0)
				local sprintMultiplier = 1.0 + (0.5 * (sprintTimer / 3.0))
				humanoid.WalkSpeed = baseSpeed * sprintMultiplier
			else
				humanoid.WalkSpeed = baseSpeed
				sprintTimer = 0
			end
		end

		-- Fix physique : neutraliser les pièces des armes équipées
		for _, child in ipairs(char:GetChildren()) do
			if child:IsA("Tool") then
				for _, p in ipairs(child:GetDescendants()) do
					if p:IsA("BasePart") then
						p.Massless = true
						p.CanCollide = false
					end
				end
			end
		end
	end
end)

print("[InputController] Initialisé - Sprint + détection zombies + fix physique !")
