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
local swayOffset = CFrame.new(0, 0, 0)

-- Mouvement (Sprint)
local sprintTimer = 0
local currentBaseSpeed = 17.6

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
	
	-- Nettoyer les scripts parasites (mais on GARDE les Sons !)
	for _, desc in ipairs(currentViewModel:GetDescendants()) do
		if desc:IsA("Script") or desc:IsA("LocalScript") then
			desc:Destroy()
		elseif desc:IsA("BasePart") then
			desc.Anchored = true
			desc.CanCollide = false
		elseif desc:IsA("ParticleEmitter") then
			desc.Rate = 0  -- Éteindre l'émission continue SANS bloquer Emit()
		elseif desc:IsA("Light") then
			desc.Enabled = false
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
		task.spawn(reload)
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

	-- Bruit de l'arme
	local snd = Instance.new("Sound")
	snd.SoundId = weaponData.fireSound or "rbxassetid://131138865"
	snd.Volume = 0.6
	snd.Parent = workspace.CurrentCamera
	snd:Play()
	task.delay(1.5, function() if snd then snd:Destroy() end end)

	-- Raycast pour détecter les hits
	local char = player.Character
	if not char or not char:FindFirstChild("Head") then return end

	local origin = char.Head.Position
	local direction = (mouse.Hit.Position - origin).Unit * (weaponData.range or 100)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	-- Exclure le joueur ET l'arme FPS (sinon les balles touchent l'arme !)
	local excluded = {char}
	if currentViewModel then table.insert(excluded, currentViewModel) end
	raycastParams.FilterDescendantsInstances = excluded

	local result = workspace:Raycast(origin, direction, raycastParams)
	
	-- SI ON A TOUCHÉ QUELQUE CHOSE DE TRANSPARENT (Brouillard / VFX), ON ESSAIE DE PASSER À TRAVERS
	if result and result.Instance and result.Instance.Transparency > 0.5 and not result.Instance:FindFirstAncestorOfClass("Model") then
		local newParams = RaycastParams.new()
		newParams.FilterType = Enum.RaycastFilterType.Exclude
		newParams.FilterDescendantsInstances = excluded
		result = workspace:Raycast(origin, direction, newParams)
	end

	-- EFFETS VISUELS (thread isolé = ne peut PAS bloquer les dégâts)
	task.spawn(function()
		if currentViewModel then
			for _, desc in ipairs(currentViewModel:GetDescendants()) do
				if desc:IsA("ParticleEmitter") then
					pcall(function() desc:Emit(5) end)
				elseif desc:IsA("PointLight") or desc:IsA("SurfaceLight") then
					pcall(function()
						desc.Enabled = true
						task.wait(0.06)
						desc.Enabled = false
					end)
				end
			end
		end
	end)
	
	if result then
		local hit = result.Instance
		print("[InputController] Raycast a touché :", hit.Name, "Parent:", hit.Parent and hit.Parent.Name or "None")
		
		-- Trouver le MODÈLE RACINE du zombie (nom commençant par Enemy_)
		-- On remonte la hiérarchie de façon sécurisée
		local zombieRoot = nil
		local current = hit
		for _ = 1, 10 do -- Maximum 10 niveaux de remontée
			if current == nil or current == workspace then break end
			if current:IsA("Model") and current.Name:sub(1, 6) == "Enemy_" then
				zombieRoot = current
				break
			end
			current = current.Parent
		end

		if zombieRoot then
			local humanoid = zombieRoot:FindFirstChildOfClass("Humanoid") or zombieRoot:FindFirstChild("Humanoid", true)
			if humanoid and humanoid.Health > 0 then
				print("[InputController] ZOMBIE DÉTECTÉ :", zombieRoot.Name)
				local isHeadshot = (hit.Name == "Head")
				
				-- Petit son de hit (Hitmarker)
				local hm = Instance.new("Sound")
				hm.SoundId = "rbxassetid://160432334"
				hm.Volume = 0.5
				hm.Parent = player:WaitForChild("PlayerGui")
				hm:Play()
				task.delay(1, function() hm:Destroy() end)
				
				-- Le Serveur gère la soustraction des PV et l'attribution de l'argent ($10 ou $50)
				Events.DamageZombie:FireServer(zombieRoot, isHeadshot, weaponId)

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
	local ammoModel = player.PlayerGui:FindFirstChild("HUD")
	if ammoModel then
		local hudFrame = ammoModel:FindFirstChild("AmmoFrame")
		if hudFrame then
			local al = hudFrame:FindFirstChild("AmmoLabel")
			if al then al.Text = currentAmmo .. " / " .. reserveAmmo end
			
			local rh = hudFrame:FindFirstChild("ReloadHint")
			if rh then
				rh.Visible = (currentAmmo <= 0 and reserveAmmo > 0)
			end
		end
	end
end

function reload()
	print("[InputController] Touche R pressée. isReloading =", isReloading)
	if isReloading then return end

	local weaponData = getWeaponData()
	if not weaponData then print("[InputController] ERREUR : Pas de weaponData !") return end

	local currentAmmo, reserveAmmo = getCurrentAmmo()
	print(string.format("[InputController] Rechargement évalué. Ammo: %d, Réserve: %d, MagSize: %d", currentAmmo, reserveAmmo, weaponData.magSize))
	if reserveAmmo <= 0 then print("[InputController] Annulé : Plus de munitions en réserve.") return end
	if currentAmmo >= weaponData.magSize then print("[InputController] Annulé : Chargeur déjà plein.") return end

	isReloading = true

	-- Notification rechargement
	local hud = player.PlayerGui:FindFirstChild("HUD")
	if hud then
		local ammoFrame = hud:FindFirstChild("AmmoFrame")
		if ammoFrame then
			local al = ammoFrame:FindFirstChild("AmmoLabel")
			if al then al.Text = "Rechargement..." end
			
			local rh = ammoFrame:FindFirstChild("ReloadHint")
			if rh then rh.Visible = false end
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
			
			local rh = ammoFrame:FindFirstChild("ReloadHint")
			if rh then rh.Visible = false end
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
	if input.KeyCode == Enum.KeyCode.R then
		task.spawn(reload)
	end
end)

-- Boucle Principale
RunService.RenderStepped:Connect(function(dt)
	-- Gérer le tir automatique
	if isShooting then
		shoot()
	end
	
	-- Gérer le sprint (Crescendo d'élan)
	local char = player.Character
	if char then
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			-- Récupérer la vitesse de base de la classe
			local classConfig = require(Shared:WaitForChild("ClassConfig"))
			local sessionData = player:FindFirstChild("SessionData")
			local className = sessionData and sessionData:FindFirstChild("Class") and sessionData.Class.Value or "Soldier"
			local classData = classConfig.Classes[className]
			local baseSpeed = (classData and classData.speedMult or 1.0) * 16 -- 16 est le défaut Roblox

			-- Si le joueur avance
			if humanoid.MoveDirection.Magnitude > 0.1 then
				sprintTimer = math.min(sprintTimer + dt, 3.0) -- 3 secondes max
				local sprintMultiplier = 1.0 + (0.5 * (sprintTimer / 3.0)) -- De 1x à 1.5x (+50%)
				humanoid.WalkSpeed = baseSpeed * sprintMultiplier
			else
				-- Dès qu'il s'arrête, on réinitialise sa vitesse normale
				humanoid.WalkSpeed = baseSpeed
				sprintTimer = 0
			end
		end
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
		
		-- Appliquer le recul
		recoilOffset = recoilOffset:Lerp(CFrame.new(0, 0, 0), dt * 15)
		
		-- Ajouter un léger balancement (Sway)
		local mouseDelta = UserInputService:GetMouseDelta()
		swayOffset = swayOffset:Lerp(CFrame.new(-mouseDelta.X/500, mouseDelta.Y/500, 0), dt * 5)

		-- PivotTo déplace le modèle physiquement à chaque image
		currentViewModel:PivotTo(workspace.CurrentCamera.CFrame * baseOffset * swayOffset * recoilOffset)
	end
end)

print("[InputController] Initialisé !")
