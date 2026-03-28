-- BonusManager.server.lua
-- Bonus aléatoire après chaque manche
-- Système #7 (Haute)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = ReplicatedStorage:WaitForChild("Events")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local WeaponConfig = require(Shared:WaitForChild("WeaponConfig"))
local Constants = require(Shared:WaitForChild("Constants"))

local WaveCompleted = Events:WaitForChild("WaveCompleted")
local ShowNotification = Events:WaitForChild("ShowNotification")
local BonusActivated = Events:WaitForChild("BonusActivated")
local UpdateAmmo = Events:WaitForChild("UpdateAmmo")
local UpdateHealth = Events:WaitForChild("UpdateHealth")

-- === FONCTIONS BONUS ===

local function rollBonus()
	local totalWeight = 0
	for _, entry in ipairs(GameConfig.BONUS_PROBABILITIES) do
		totalWeight += entry.weight
	end
	local roll = math.random(1, totalWeight)
	local cumulative = 0
	for _, entry in ipairs(GameConfig.BONUS_PROBABILITIES) do
		cumulative += entry.weight
		if roll <= cumulative then
			return entry.name
		end
	end
	return "HealAll" -- fallback
end

local function applyBonus(bonusType)
	local displayName = Constants.BonusDisplayNames[bonusType] or bonusType

	if bonusType == "DoubleMoney" then
		-- Double argent pour le prochain round
		local economy = _G.EconomyManager
		if economy then
			for _, player in ipairs(Players:GetPlayers()) do
				economy.setDoubleMoney(player, true)
			end
		end
		ShowNotification:FireAllClients(displayName, "#FFD700", 3)

		-- Désactiver après la prochaine manche (approximé à 60 secondes)
		task.delay(60, function()
			local economy2 = _G.EconomyManager
			if economy2 then
				for _, player in ipairs(Players:GetPlayers()) do
					economy2.setDoubleMoney(player, false)
				end
			end
		end)

	elseif bonusType == "HealAll" then
		-- Soigner tous les joueurs à 100%
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			if char then
				local humanoid = char:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.Health = humanoid.MaxHealth
					UpdateHealth:FireClient(player, humanoid.Health, humanoid.MaxHealth)
				end
			end
		end
		ShowNotification:FireAllClients(displayName, "#00FF00", 3)

	elseif bonusType == "AmmoDrop" then
		-- Recharge complète pour tous
		for _, player in ipairs(Players:GetPlayers()) do
			local sessionData = player:FindFirstChild("SessionData")
			if sessionData then
				local weaponName = sessionData:FindFirstChild("WeaponName")
				if weaponName then
					local weaponData = WeaponConfig.Weapons[weaponName.Value]
					if weaponData then
						sessionData.CurrentAmmo.Value = weaponData.magSize
						sessionData.ReserveAmmo.Value = weaponData.reserveAmmo
						UpdateAmmo:FireClient(player, weaponData.magSize, weaponData.reserveAmmo, weaponData.displayName)
					end
				end
			end
		end
		ShowNotification:FireAllClients(displayName, "#00AAFF", 3)

	elseif bonusType == "SpeedBoost" then
		-- Vitesse x1.5 pendant 30 secondes
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			if char then
				local humanoid = char:FindFirstChildOfClass("Humanoid")
				if humanoid then
					local originalSpeed = humanoid.WalkSpeed
					humanoid.WalkSpeed = originalSpeed * GameConfig.SPEED_BOOST_MULTIPLIER

					task.delay(GameConfig.SPEED_BOOST_DURATION, function()
						if humanoid and humanoid.Parent then
							humanoid.WalkSpeed = originalSpeed
						end
					end)
				end
			end
		end
		ShowNotification:FireAllClients(displayName, "#00FFFF", 3)

	elseif bonusType == "Nuke" then
		-- Tuer TOUS les zombies instantanément
		ShowNotification:FireAllClients(displayName, "#FF4444", 4)
		for _, child in ipairs(workspace:GetChildren()) do
			if child:IsA("Model") and child.Name:sub(1, 6) == "Enemy_" then
				local humanoid = child:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 then
					humanoid.Health = 0
				end
			end
		end
	end

	BonusActivated:FireAllClients(bonusType)
	print("[BonusManager] Bonus activé: " .. bonusType)
end

-- === ÉCOUTER LES FINS DE MANCHE ===

-- Surveiller les fins de manche via le WaveCompleted event
-- Le WaveCompleted est un RemoteEvent (serveur→client)
-- On va écouter un _G callback à la place

_G.OnWaveCompleted = function(waveNumber)
	-- Lancer le bonus après un petit délai
	task.delay(2, function()
		local bonus = rollBonus()
		applyBonus(bonus)
	end)
end

-- Fallback : écouter les leaderstats
task.spawn(function()
	local lastWave = 0
	while true do
		task.wait(2)
		for _, player in ipairs(Players:GetPlayers()) do
			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats and leaderstats:FindFirstChild("Wave") then
				local wave = leaderstats.Wave.Value
				if wave > lastWave then
					-- Nouvelle manche détectée, le bonus a été lancé la manche précédente
					if lastWave > 0 then
						local bonus = rollBonus()
						task.delay(1, function()
							applyBonus(bonus)
						end)
					end
					lastWave = wave
					break
				end
			end
		end
	end
end)

print("[BonusManager] Initialisé !")
