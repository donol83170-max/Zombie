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
local WeaponConfig = require(Shared:WaitForChild("WeaponConfig"))
local DamageZombie = Events:WaitForChild("DamageZombie")

-- Mouvement (Sprint)
local sprintTimer = 0

-- === SON HITMARKER ===
local hitmarkerSound = Instance.new("Sound")
hitmarkerSound.Name = "CustomHitmarker"
hitmarkerSound.SoundId = "rbxassetid://160432334" -- Son hitmarker standard
hitmarkerSound.Volume = 1
hitmarkerSound.Parent = workspace

local lastZombieHitTime = 0

-- État du tir
local isHoldingFire = false
local fireLoopRunning = false

local UserInputService = game:GetService("UserInputService")

-- === MUZZLE FLASH ===
local function triggerMuzzleFlash()
	local char = player.Character
	if not char then return end
	local tool = char:FindFirstChildOfClass("Tool")
	if not tool then return end
	local handle = tool:FindFirstChild("Handle")
	if not handle then return end
	local muzzle = handle:FindFirstChild("MuzzleFlashEffect") or tool:FindFirstChild("MuzzleFlashEffect")
	if not muzzle then return end

	local vmStorage = workspace.CurrentCamera:FindFirstChild("ViewmodelStorage")
	local viewmodel = vmStorage and vmStorage:FindFirstChild("v_" .. tool.Name)
	if viewmodel then
		local barrelPart = nil
		for _, child in ipairs(viewmodel:GetDescendants()) do
			if child:IsA("BasePart") and (child.Name == "bout" or child.Name == "barrel") then
				barrelPart = child
				break
			end
		end
		if barrelPart then
			if barrelPart.Name == "barrel" then
				muzzle.WorldPosition = (barrelPart.CFrame * CFrame.new(0, 0, barrelPart.Size.Z / 2)).Position
			else
				muzzle.WorldPosition = barrelPart.Position
			end
		end
	end

	for _, child in ipairs(muzzle:GetChildren()) do
		if child:IsA("ParticleEmitter") then
			if child.Name == "SmokeEffect" then
				child:Emit(2)
			else
				child:Emit(3)
			end
		elseif child:IsA("PointLight") then
			task.spawn(function()
				child.Enabled = true
				task.wait(0.05)
				child.Enabled = false
			end)
		end
	end
end

-- === RAYCAST ZOMBIE ===
local function doZombieRaycast()
	local char = player.Character
	if not char or not char:FindFirstChild("Head") then return end

	local tool = char:FindFirstChildOfClass("Tool")
	if not tool then return end

	-- Utilisation de l'écran 2D avec prise en compte du décalage (GuiInset) de Roblox
	local location = UserInputService:GetMouseLocation()
	local ray = workspace.CurrentCamera:ViewportPointToRay(location.X, location.Y)
	
	local currentOrigin = ray.Origin
	local currentDirection = ray.Direction * 300

	-- Au lieu d'exclure péniblement les dizaines de particules générées par le fusil (fumée, douilles),
	-- on passe en mode WHITELIST : le rayon ne peut frapper QUE la map et les zombies.
	local whitelist = {workspace.Terrain}
	for _, obj in ipairs(workspace:GetChildren()) do
		local lowerName = obj.Name:lower()
		-- Inclure les zombies
		if obj:IsA("Model") and obj.Name:sub(1, 6) == "Enemy_" then
			table.insert(whitelist, obj)
		-- Inclure la map et le sol
		elseif lowerName:find("map") or lowerName:find("baseplate") then
			table.insert(whitelist, obj)
		end
	end

	-- 5 tentatives pour ignorer les vitres ou grilles (CanCollide = false) de la map
	for attempt = 1, 5 do
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = whitelist

		local res = workspace:Raycast(currentOrigin, currentDirection, params)
		if not res then break end

		local hit = res.Instance
		local current = hit
		local zombieRoot = nil
		
		-- Vérifier si ça fait partie d'un zombie
		for _ = 1, 5 do
			if current == nil or current == workspace then break end
			if current:IsA("Model") and current.Name:sub(1, 6) == "Enemy_" then
				zombieRoot = current
				break
			end
			current = current.Parent
		end

		if zombieRoot then
			local humanoid = zombieRoot:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				local isHeadshot = (hit.Name == "Head")
				DamageZombie:FireServer(zombieRoot, isHeadshot, tool.Name)
				
				hitmarkerSound:Play()
				
				local originalColor = hit.Color
				hit.Color = Color3.fromRGB(255, 0, 0)
				task.delay(0.1, function()
					if hit and hit.Parent then hit.Color = originalColor end
				end)
			end
			return
		end
		
		-- Si on touche la vraie géométrie de la map (sol, murs), on arrête le tir
		-- Les objets CanCollide = true arrêtent la balle.
		if hit.CanCollide and hit.Transparency < 1 then
			return
		end
		
		-- Objet de la map non bloquant (vitre), on le retire de la whitelist pour passer à travers
		for i, w in ipairs(whitelist) do
			if w == hit or hit:IsDescendantOf(w) then
				-- Ne pas retirer la map entière, mais juste s'assurer qu'on avance le rayon !
				break
			end
		end
		-- On avance un tout petit peu l'origine pour traverser la vitre
		currentOrigin = res.Position + currentDirection.Unit * 0.1
		currentDirection = (ray.Direction * 300) - (currentOrigin - ray.Origin)
	end
end

-- === GESTION DU TIR (Auto / Semi) ===
local function getFireInterval(tool)
	local weaponData = WeaponConfig.Weapons[tool.Name]
	if not weaponData then return 0.15 end
	if weaponData.fireMode == "continuous" then return weaponData.tickRate or 0.1 end
	if (weaponData.rpm or 0) <= 0 then return 0.1 end
	return 60 / weaponData.rpm
end

local function isAutoWeapon(tool)
	local weaponData = WeaponConfig.Weapons[tool.Name]
	return weaponData and (weaponData.fireMode == "auto" or weaponData.fireMode == "continuous")
end

mouse.Button1Down:Connect(function()
	isHoldingFire = true

	local char = player.Character
	if not char then return end
	local tool = char:FindFirstChildOfClass("Tool")
	if not tool then return end

	-- Premier tir immédiat respectant l'anti-spam max
	local now = tick()
	local magValue = tool:FindFirstChild("ValueFolder") and tool.ValueFolder:FindFirstChild("1") and tool.ValueFolder["1"]:FindFirstChild("Mag")
	if now - lastZombieHitTime >= 0.05 and (not magValue or magValue.Value > 0) then
		lastZombieHitTime = now
		triggerMuzzleFlash()
		doZombieRaycast()
	end

	-- Boucle auto
	if isAutoWeapon(tool) and not fireLoopRunning then
		fireLoopRunning = true
		local interval = getFireInterval(tool)

		task.spawn(function()
			task.wait(interval)
			while isHoldingFire do
				local cChar = player.Character
				if not cChar then break end
				local cTool = cChar:FindFirstChildOfClass("Tool")
				if not cTool then break end

				local cMag = cTool:FindFirstChild("ValueFolder") and cTool.ValueFolder:FindFirstChild("1") and cTool.ValueFolder["1"]:FindFirstChild("Mag")
				if cMag and cMag.Value <= 0 then break end
				lastZombieHitTime = tick()
				triggerMuzzleFlash()
				doZombieRaycast()
				task.wait(getFireInterval(cTool))
			end
			fireLoopRunning = false
		end)
	end
end)

mouse.Button1Up:Connect(function()
	isHoldingFire = false
end)

-- === BOUCLE PRINCIPALE (Sprint + fix physique) ===
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

		-- Fix physique
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

print("[InputController] Initialisé - Sprint + détection zombies auto + Hitmarker")
