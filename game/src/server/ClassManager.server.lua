-- ClassManager.server.lua
-- Gestion des 4 classes joueur (Soldier, Medic, Tank, Scout)
-- Système #8 (Haute)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = ReplicatedStorage:WaitForChild("Events")
local ClassConfig = require(Shared:WaitForChild("ClassConfig"))

local RequestSelectClass = Events:WaitForChild("RequestSelectClass")
local ClassSelected = Events:WaitForChild("ClassSelected")
local ShowNotification = Events:WaitForChild("ShowNotification")

-- === SÉLECTION DE CLASSE ===

local function applyClassStats(player, className)
	local classData = ClassConfig.Classes[className]
	if not classData then
		warn("[ClassManager] Classe inconnue: " .. className)
		return
	end

	-- Stocker la classe dans SessionData
	local sessionData = player:FindFirstChild("SessionData")
	if sessionData and sessionData:FindFirstChild("Class") then
		sessionData.Class.Value = className
	end

	-- Appliquer les stats au personnage
	local char = player.Character
	if char then
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.MaxHealth = classData.maxHp
			humanoid.Health = classData.maxHp
			humanoid.WalkSpeed = 16 * classData.speedMult
		end
	end

	-- Notifier le client
	ClassSelected:FireClient(player, className, classData)
	ShowNotification:FireClient(player, "🎖️ Classe sélectionnée : " .. classData.displayName, "#00AAFF", 2)

	print("[ClassManager] " .. player.Name .. " → " .. className)
end

-- === MEDIC HEAL AURA ===

local function medicHealLoop()
	while true do
		task.wait(1)
		for _, player in ipairs(Players:GetPlayers()) do
			local sessionData = player:FindFirstChild("SessionData")
			if sessionData and sessionData:FindFirstChild("Class") and sessionData.Class.Value == "Medic" then
				local classData = ClassConfig.Classes.Medic
				local char = player.Character
				if char and char:FindFirstChild("HumanoidRootPart") then
					local pos = char.HumanoidRootPart.Position
					-- Soigner les alliés dans le rayon
					for _, otherPlayer in ipairs(Players:GetPlayers()) do
						if otherPlayer ~= player then
							local otherChar = otherPlayer.Character
							if otherChar and otherChar:FindFirstChild("HumanoidRootPart") then
								local dist = (otherChar.HumanoidRootPart.Position - pos).Magnitude
								if dist <= classData.healAuraRadius then
									local otherHum = otherChar:FindFirstChildOfClass("Humanoid")
									if otherHum and otherHum.Health > 0 and otherHum.Health < otherHum.MaxHealth then
										otherHum.Health = math.min(otherHum.MaxHealth, otherHum.Health + classData.healAuraRate)
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

-- === RÉDUCTION DE DÉGÂTS (TANK) ===

local function setupDamageReduction(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")

		-- Appliquer les stats de classe
		local sessionData = player:FindFirstChild("SessionData")
		if sessionData and sessionData:FindFirstChild("Class") then
			local className = sessionData.Class.Value
			local classData = ClassConfig.Classes[className]
			if classData then
				humanoid.MaxHealth = classData.maxHp
				humanoid.Health = classData.maxHp
				humanoid.WalkSpeed = 16 * classData.speedMult
			end
		end
	end)
end

-- === EVENTS ===

RequestSelectClass.OnServerEvent:Connect(function(player, className)
	if not ClassConfig.Classes[className] then
		ShowNotification:FireClient(player, "❌ Classe invalide", "#FF0000", 2)
		return
	end
	applyClassStats(player, className)
end)

-- Appliquer la classe par défaut à chaque joueur
Players.PlayerAdded:Connect(function(player)
	setupDamageReduction(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		local sessionData = player:FindFirstChild("SessionData")
		if sessionData and sessionData:FindFirstChild("Class") then
			applyClassStats(player, sessionData.Class.Value)
		end
	end)
end)

-- Lancer la boucle de soin du Medic
task.spawn(medicHealLoop)

print("[ClassManager] Initialisé !")
