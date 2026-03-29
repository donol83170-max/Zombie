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
local isSwitching = false
local lastShotTime = 0

-- ViewModel (Bras + Arme FPS)
local armsTemplate = ReplicatedStorage:WaitForChild("Weapons"):WaitForChild("Arms")
local currentViewModel = nil
local currentWeaponNameCache = ""
local recoilOffset = CFrame.new(0, 0, 0)
local swayOffset = CFrame.new(0, 0, 0)

-- Mouvement (Sprint)
local sprintTimer = 0
local currentBaseSpeed = 17.6

-- === FONCTIONS ===

local function switchToSlot(slot)
	if isSwitching or isReloading then return end
	local sessionData = player:FindFirstChild("SessionData")
	if not sessionData then return end

	local activeSlot = sessionData:FindFirstChild("ActiveSlot")
	if not activeSlot then return end
	if activeSlot.Value == slot then return end -- Déjà sur ce slot

	isSwitching = true
	isShooting = false

	if slot == 1 then
		-- Revenir à l'arme primaire : restaurer les munitions sauvegardées
		local primaryName = sessionData:FindFirstChild("PrimaryWeaponName")
		local primaryAmmo = sessionData:FindFirstChild("PrimaryAmmo")
		local primaryReserve = sessionData:FindFirstChild("PrimaryReserve")
		if primaryName then
			sessionData.WeaponName.Value = primaryName.Value
		end
		if primaryAmmo then
			sessionData.CurrentAmmo.Value = primaryAmmo.Value
		end
		if primaryReserve then
			sessionData.ReserveAmmo.Value = primaryReserve.Value
		end
		activeSlot.Value = 1
		print("[InputController] Switch -> Slot 1 : " .. sessionData.WeaponName.Value)
	elseif slot == 2 then
		-- Sauvegarder les munitions de l'arme primaire avant de switch
		if activeSlot.Value == 1 then
			local primaryAmmo = sessionData:FindFirstChild("PrimaryAmmo")
			local primaryReserve = sessionData:FindFirstChild("PrimaryReserve")
			if primaryAmmo then
				primaryAmmo.Value = sessionData.CurrentAmmo.Value
			end
			if primaryReserve then
				primaryReserve.Value = sessionData.ReserveAmmo.Value
			end
		end
		-- Équiper le couteau
		sessionData.WeaponName.Value = "KNIFE"
		sessionData.CurrentAmmo.Value = 0
		sessionData.ReserveAmmo.Value = 0
		activeSlot.Value = 2
		print("[InputController] Switch -> Slot 2 : Couteau")
	end

	-- Forcer le changement de modèle 3D
	currentWeaponNameCache = ""

	-- Petit délai de switch
	task.wait(0.3)
	isSwitching = false

	-- Mettre à jour le HUD munitions
	local weaponData = WeaponConfig.Weapons[sessionData.WeaponName.Value]
	if weaponData then
		UpdateAmmo:FireServer(sessionData.CurrentAmmo.Value, sessionData.ReserveAmmo.Value, weaponData.displayName)
	end
end

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
	currentWeaponNameCache = weaponName

	-- Détruire l'ancien modèle
	if currentViewModel then
		currentViewModel:Destroy()
		currentViewModel = nil
	end

	-- Cloner les bras
	local arms = armsTemplate:Clone()

	-- Nettoyer les bras (scripts, collision, cacher le Handle)
	for _, desc in ipairs(arms:GetDescendants()) do
		if desc:IsA("Script") or desc:IsA("LocalScript") then
			desc:Destroy()
		elseif desc:IsA("BasePart") then
			desc.Anchored = true
			desc.CanCollide = false
			if desc.Name == "Handle" then
				desc.Transparency = 1
			end
		end
	end

	-- Chercher le modèle d'arme
	local weaponsFolder = ReplicatedStorage:FindFirstChild("Weapons")
	local gunTemplate = weaponsFolder and weaponsFolder:FindFirstChild(weaponName)
	local handle = arms:FindFirstChild("Handle")

	if gunTemplate and handle then
		local gun
		if gunTemplate:IsA("Model") then
			gun = gunTemplate:Clone()
		elseif gunTemplate:IsA("BasePart") then
			-- Si c'est un MeshPart/Part, l'envelopper dans un Model
			gun = Instance.new("Model")
			gun.Name = weaponName
			local clonedPart = gunTemplate:Clone()
			clonedPart.Parent = gun
			gun.PrimaryPart = clonedPart
		end

		if gun then
			-- Nettoyer l'arme
			for _, desc in ipairs(gun:GetDescendants()) do
				if desc:IsA("Script") or desc:IsA("LocalScript") then
					desc:Destroy()
				elseif desc:IsA("BasePart") then
					desc.Anchored = true
					desc.CanCollide = false
				elseif desc:IsA("ParticleEmitter") then
					desc.Rate = 0
				elseif desc:IsA("Light") then
					desc.Enabled = false
				end
			end

			-- Positionner l'arme au Handle des bras avec rotation et offset par arme
			local wData = WeaponConfig.Weapons[weaponName]
			local rot = wData and wData.fpsRotation or Vector3.new(0, -90, 0)
			local gripOff = wData and wData.gripOffset or Vector3.new(0, 0, 0)
			gun:PivotTo(handle.CFrame * CFrame.new(gripOff) * CFrame.Angles(math.rad(rot.X), math.rad(rot.Y), math.rad(rot.Z)))
			gun.Parent = arms
		end
	else
		print("[InputController] ALERTE: Modèle '" .. weaponName .. "' introuvable !")
	end

	-- PrimaryPart = HumanoidRootPart pour le positionnement
	local hrp = arms:FindFirstChild("HumanoidRootPart")
	if hrp then
		arms.PrimaryPart = hrp
	end

	arms.Parent = workspace
	currentViewModel = arms
	print("[InputController] Bras + " .. weaponName .. " générés avec succès")
end

local function shoot()
	local weaponData, weaponId = getWeaponData()
	if not weaponData then return end
	if isReloading or isSwitching then return end

	local isMelee = (weaponData.fireMode == "melee")

	if not isMelee then
		local currentAmmo, reserveAmmo = getCurrentAmmo()
		if currentAmmo <= 0 then
			-- Auto reload
			task.spawn(reload)
			return
		end
	end

	-- Vérifier le cooldown (RPM)
	local now = tick()
	local fireInterval = 60 / weaponData.rpm
	if now - lastShotTime < fireInterval then return end
	lastShotTime = now

	if not isMelee then
		-- Consommer une balle
		local currentAmmo, reserveAmmo = getCurrentAmmo()
		currentAmmo -= 1
		setAmmo(currentAmmo, reserveAmmo)
	end

	-- Animations de Tir / Attaque !
	if isMelee then
		-- Slash vers l'avant pour le couteau
		recoilOffset = CFrame.new(0, 0, -0.6) * CFrame.Angles(math.rad(-30), 0, 0)
	else
		-- Recul classique pour les armes à feu
		recoilOffset = CFrame.new(0, 0, 0.4) * CFrame.Angles(math.rad(8), 0, 0)
	end

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
	if isMelee then
		UpdateAmmo:FireServer(0, 0, weaponData.displayName)
		local ammoModel = player.PlayerGui:FindFirstChild("HUD")
		if ammoModel then
			local hudFrame = ammoModel:FindFirstChild("AmmoFrame")
			if hudFrame then
				local al = hudFrame:FindFirstChild("AmmoLabel")
				if al then al.Text = "---" end
				local rh = hudFrame:FindFirstChild("ReloadHint")
				if rh then rh.Visible = false end
			end
		end
	else
		local currentAmmo, reserveAmmo = getCurrentAmmo()
		UpdateAmmo:FireServer(currentAmmo, reserveAmmo, weaponData.displayName)
		local ammoModel = player.PlayerGui:FindFirstChild("HUD")
		if ammoModel then
			local hudFrame = ammoModel:FindFirstChild("AmmoFrame")
			if hudFrame then
				local al = hudFrame:FindFirstChild("AmmoLabel")
				if al then al.Text = currentAmmo .. " / " .. reserveAmmo end
				local rh = hudFrame:FindFirstChild("ReloadHint")
				if rh then rh.Visible = (currentAmmo <= 0 and reserveAmmo > 0) end
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

-- R : recharger | 1 : arme primaire | 2 : couteau
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.R then
		task.spawn(reload)
	elseif input.KeyCode == Enum.KeyCode.One then
		task.spawn(switchToSlot, 1)
	elseif input.KeyCode == Enum.KeyCode.Two then
		task.spawn(switchToSlot, 2)
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
	
	-- Positionner visuellement les bras + arme devant la caméra
	if currentViewModel then

		-- Offset des bras (position fixe devant la caméra)
		local armsOffset = CFrame.new(0, -1, -1)

		-- Appliquer le recul
		recoilOffset = recoilOffset:Lerp(CFrame.new(0, 0, 0), dt * 15)

		-- Ajouter un léger balancement (Sway)
		local mouseDelta = UserInputService:GetMouseDelta()
		swayOffset = swayOffset:Lerp(CFrame.new(-mouseDelta.X/500, mouseDelta.Y/500, 0), dt * 5)

		-- PivotTo déplace les bras + arme à chaque image
		currentViewModel:PivotTo(workspace.CurrentCamera.CFrame * armsOffset * swayOffset * recoilOffset)
	end
end)

print("[InputController] Initialisé !")
