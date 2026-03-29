-- InputController.client.lua
-- Gestion des contrôles : tir, rechargement, interaction
-- Système combat (Critique)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = ReplicatedStorage:WaitForChild("Events")
local WeaponConfig = require(Shared:WaitForChild("WeaponConfig"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local UpdateAmmo = Events:WaitForChild("UpdateAmmo")

-- State
local isShooting = false
local isReloading = false
local lastShotTime = 0

-- ViewModel (Arme FPS)
local currentViewModel = nil
local currentWeaponNameCache = ""
local recoilOffset = CFrame.new(0, 0, 0)

-- === FONCTIONS ===

local function getWeaponData()
	local sessionData = player:FindFirstChild("SessionData")
	if not sessionData then return nil end
	local weaponName = sessionData:FindFirstChild("WeaponName")
	if not weaponName then return nil end
	return WeaponConfig.Weapons[weaponName.Value], weaponName.Value
end

local function getCurrentAmmo()
	local sessionData = player:FindFirstChild("SessionData")
	if not sessionData then return 0, 0 end
	local current = sessionData:FindFirstChild("CurrentAmmo")
	local reserve = sessionData:FindFirstChild("ReserveAmmo")
	return current and current.Value or 0, reserve and reserve.Value or 0
end

local function setAmmo(current, reserve)
	local sessionData = player:FindFirstChild("SessionData")
	if not sessionData then return end
	if sessionData:FindFirstChild("CurrentAmmo") then
		sessionData.CurrentAmmo.Value = current
	end
	if sessionData:FindFirstChild("ReserveAmmo") then
		sessionData.ReserveAmmo.Value = reserve
	end
end

local function updateViewModel(weaponName)
	if currentWeaponNameCache == weaponName then return end

	local weaponsFolder = ReplicatedStorage:FindFirstChild("Weapons")
	local gunTemplate = weaponsFolder and weaponsFolder:FindFirstChild(weaponName)

	if not gunTemplate or not gunTemplate:IsA("Model") then
		-- PISTOLET DE TEST (SI L'UTILISATEUR S'EST TROMPÉ)
		currentWeaponNameCache = weaponName

		if currentViewModel then currentViewModel:Destroy() end

		currentViewModel = Instance.new("Model")
		currentViewModel.Name = "DummyGun"

		local part = Instance.new("Part")
		part.Size = Vector3.new(0.4, 0.4, 2)
		part.Color = Color3.fromRGB(255, 0, 0)
		part.Material = Enum.Material.Neon
		part.Anchored = true
		part.CanCollide = false
		part.Parent = currentViewModel
		
		currentViewModel.PrimaryPart = part
		currentViewModel.Parent = workspace -- Attacher au Workspace pour empêcher Roblox de rendre la caméra invisible !
		print("[InputController] ALERTE: Modèle '" .. weaponName .. "' introuvable ou mal nommé ! Pistolet Laser de Triche équipé !")
		return
	end
	
	-- On verrouille le cache uniquement si on a trouvé la vraie arme
	currentWeaponNameCache = weaponName

	-- Détruire l'ancienne arme s'il y en avait une
	if currentViewModel then
		currentViewModel:Destroy()
		currentViewModel = nil
	end

	currentViewModel = gunTemplate:Clone()
	
	-- Nettoyer les scripts parasites et fixer les collisions
	for _, desc in ipairs(currentViewModel:GetDescendants()) do
		if desc:IsA("Script") or desc:IsA("LocalScript") then
			desc:Destroy()
		elseif desc:IsA("BasePart") then
			desc.Anchored = true
			desc.CanCollide = false
		end
	end
	
	currentViewModel.Parent = workspace
	print("[InputController] Arme FPS générée avec succès : " .. weaponName)
end

local function shoot()
	local weaponData, weaponId = getWeaponData()
	if not weaponData then return end
	if isReloading then return end

	local currentAmmo, reserveAmmo = getCurrentAmmo()
	if currentAmmo <= 0 then
		-- Auto reload
		reload()
		return
	end

	-- Vérifier le cooldown (RPM)
	local now = tick()
	local fireInterval = 60 / weaponData.rpm
	if now - lastShotTime < fireInterval then return end
	lastShotTime = now

	-- Consommer une balle
	currentAmmo -= 1
	setAmmo(currentAmmo, reserveAmmo)

	-- Animations de Tir !
	-- Appliquer un effet de recul brut sur l'arme 3D (elle recule et se lève)
	recoilOffset = CFrame.new(0, 0, 0.4) * CFrame.Angles(math.rad(8), 0, 0)

	-- Raycast pour détecter les hits
	local char = player.Character
	if not char or not char:FindFirstChild("Head") then return end

	local origin = char.Head.Position
	local direction = (mouse.Hit.Position - origin).Unit * (weaponData.range or 100)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {char}

	local result = workspace:Raycast(origin, direction, raycastParams)

	if result then
		local hit = result.Instance
		-- Vérifier si on a touché un zombie
		local model = hit:FindFirstAncestorOfClass("Model")
		if model and model.Name:sub(1, 6) == "Enemy_" then
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				-- Appliquer les dégâts côté client pour le feedback
				-- (le serveur validera les dégâts réels)
				
				-- Multiplicateur headshot
				local damage = weaponData.damage
				if hit.Name == "Head" then
					damage *= (weaponData.headshotMult or 1)
				end

				-- Appliquer les dégâts
				-- (Dans une version production, c'est le serveur qui calcule)
				humanoid:TakeDamage(damage)

				-- Feedback visuel : flash rouge sur le zombie
				local originalColor = hit.Color
				hit.Color = Color3.fromRGB(255, 0, 0)
				task.delay(0.1, function()
					if hit and hit.Parent then
						hit.Color = originalColor
					end
				end)
			end
		end

		-- Impact visuel
		local impact = Instance.new("Part")
		impact.Size = Vector3.new(0.3, 0.3, 0.3)
		impact.Shape = Enum.PartType.Ball
		impact.Position = result.Position
		impact.Anchored = true
		impact.CanCollide = false
		impact.Color = Color3.fromRGB(255, 200, 0)
		impact.Material = Enum.Material.Neon
		impact.Parent = workspace

		task.delay(0.2, function()
			if impact and impact.Parent then impact:Destroy() end
		end)
	end

	-- Mettre à jour l'affichage munitions
	UpdateAmmo:FireServer(currentAmmo, reserveAmmo, weaponData.displayName)

	-- Feedback local
	local ammoFrame = player.PlayerGui:FindFirstChild("HUD")
	if ammoFrame then
		local ammoLabel = ammoFrame:FindFirstChild("AmmoFrame")
		if ammoLabel then
			local al = ammoLabel:FindFirstChild("AmmoLabel")
			if al then al.Text = currentAmmo .. " / " .. reserveAmmo end
		end
	end
end

function reload()
	if isReloading then return end

	local weaponData = getWeaponData()
	if not weaponData then return end

	local currentAmmo, reserveAmmo = getCurrentAmmo()
	if reserveAmmo <= 0 then return end
	if currentAmmo >= weaponData.magSize then return end

	isReloading = true

	-- Notification rechargement
	local hud = player.PlayerGui:FindFirstChild("HUD")
	if hud then
		local ammoFrame = hud:FindFirstChild("AmmoFrame")
		if ammoFrame then
			local al = ammoFrame:FindFirstChild("AmmoLabel")
			if al then al.Text = "Rechargement..." end
		end
	end

	task.wait(weaponData.reloadTime or 2)

	-- Recharger
	local needed = weaponData.magSize - currentAmmo
	local toLoad = math.min(needed, reserveAmmo)
	currentAmmo += toLoad
	reserveAmmo -= toLoad
	setAmmo(currentAmmo, reserveAmmo)

	-- MAJ UI
	if hud then
		local ammoFrame = hud:FindFirstChild("AmmoFrame")
		if ammoFrame then
			local al = ammoFrame:FindFirstChild("AmmoLabel")
			if al then al.Text = currentAmmo .. " / " .. reserveAmmo end
		end
	end

	isReloading = false
end

-- === INPUT BINDINGS ===

-- Clic gauche : tirer
mouse.Button1Down:Connect(function()
	isShooting = true
end)

mouse.Button1Up:Connect(function()
	isShooting = false
end)

-- R : recharger
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.R then
		reload()
	end
end)

-- Boucle Principale
RunService.RenderStepped:Connect(function(dt)
	-- Gérer le tir automatique
	if isShooting then
		shoot()
	end
	
	-- Mettre à jour l'arme tenue
	local weaponData, weaponName = getWeaponData()
	if weaponName then
		updateViewModel(weaponName)
	end
	
	-- Positionner visuellement l'arme devant la caméra
	if currentViewModel and weaponData then
		
		-- Récupérer le réglage sur mesure de l'arme
		local offsetPos = weaponData.fpsOffset or Vector3.new(0.5, -0.5, -2.0)
		local offsetRot = weaponData.fpsRotation or Vector3.new(0, 0, 0)
		
		-- Créer le CFrame parfait (Position + Rotation)
		local baseOffset = CFrame.new(offsetPos) * CFrame.Angles(
			math.rad(offsetRot.X), 
			math.rad(offsetRot.Y), 
			math.rad(offsetRot.Z)
		)
		
		-- Ramener le recul vers la position de base doucement (Lerp)
		recoilOffset = recoilOffset:Lerp(CFrame.new(0, 0, 0), dt * 15)
		
		-- PivotTo déplace le modèle physiquement à chaque image
		currentViewModel:PivotTo(workspace.CurrentCamera.CFrame * baseOffset * recoilOffset)
	end
end)

print("[InputController] Initialisé !")
