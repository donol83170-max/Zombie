-- InputController.client.lua
-- Gestion des contrôles spécifiques au jeu (Sprint + Fix physique armes)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ClassConfig = require(Shared:WaitForChild("ClassConfig"))

-- Mouvement (Sprint)
local sprintTimer = 0

-- Boucle Principale
RunService.RenderStepped:Connect(function(dt)
	-- Gérer le sprint (Crescendo d'élan)
	local char = player.Character
	if char then
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			-- Récupérer la vitesse de base de la classe
			local sessionData = player:FindFirstChild("SessionData")
			local className = sessionData and sessionData:FindFirstChild("Class") and sessionData.Class.Value or "Soldier"
			local classData = ClassConfig.Classes[className]
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

		-- Fix physique : neutraliser les pièces des armes équipées (côté CLIENT)
		-- Le serveur n'a pas autorité sur les parts du personnage du joueur
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

print("[InputController] Initialisé - mode Sprint + fix physique armes !")
