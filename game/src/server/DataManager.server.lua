-- DataManager.server.lua
-- Sauvegarde et chargement des données joueur via DataStoreService
-- Système infrastructure

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DATASTORE_NAME = "ZombieWaves_PlayerData_v1"
local AUTO_SAVE_INTERVAL = 300 -- 5 minutes

local dataStore = DataStoreService:GetDataStore(DATASTORE_NAME)
local playerDataCache = {}

-- === TEMPLATE DE DONNÉES ===

local function getDefaultData()
	return {
		version = 1,
		firstJoin = os.time(),
		lastJoin = os.time(),

		-- Stats globales
		bestWave = 0,
		totalKills = 0,
		totalMoneyEarned = 0,
		totalBossKills = 0,
		totalGamesPlayed = 0,

		-- Hardcore
		hardcoreBestWave = 0,

		-- Paramètres
		settings = {
			musicVolume = 0.5,
			sfxVolume = 0.7,
		},
	}
end

-- === SAVE / LOAD ===

local function loadData(player)
	local key = "Player_" .. player.UserId
	local success, data = pcall(function()
		return dataStore:GetAsync(key)
	end)

	if success and data then
		-- Migration de version si nécessaire
		if not data.version then
			data.version = 1
		end
		playerDataCache[player.UserId] = data
		print("[DataManager] Données chargées pour " .. player.Name)
	else
		playerDataCache[player.UserId] = getDefaultData()
		print("[DataManager] Nouvelles données créées pour " .. player.Name)
	end

	-- Mettre à jour la dernière connexion
	playerDataCache[player.UserId].lastJoin = os.time()
	playerDataCache[player.UserId].totalGamesPlayed += 1
end

local function saveData(player)
	local key = "Player_" .. player.UserId
	local data = playerDataCache[player.UserId]
	if not data then return end

	-- Mettre à jour avec les stats de session actuelles
	local leaderstats = player:FindFirstChild("leaderstats")
	local sessionData = player:FindFirstChild("SessionData")

	if leaderstats and leaderstats:FindFirstChild("Wave") then
		local wave = leaderstats.Wave.Value
		if wave > data.bestWave then
			data.bestWave = wave
		end
	end

	if sessionData then
		if sessionData:FindFirstChild("Kills") then
			data.totalKills += sessionData.Kills.Value
		end
	end

	if leaderstats and leaderstats:FindFirstChild("Money") then
		data.totalMoneyEarned += leaderstats.Money.Value
	end

	-- Sauvegarder avec retry
	local success, err
	for attempt = 1, 3 do
		success, err = pcall(function()
			dataStore:SetAsync(key, data)
		end)
		if success then
			print("[DataManager] Données sauvegardées pour " .. player.Name)
			break
		end
		warn("[DataManager] Tentative " .. attempt .. " échouée: " .. tostring(err))
		task.wait(2 ^ attempt)
	end

	if not success then
		warn("[DataManager] ÉCHEC SAUVEGARDE pour " .. player.Name)
	end
end

-- === EVENTS ===

Players.PlayerAdded:Connect(function(player)
	loadData(player)
end)

Players.PlayerRemoving:Connect(function(player)
	saveData(player)
	playerDataCache[player.UserId] = nil
end)

-- Auto-save périodique
task.spawn(function()
	while true do
		task.wait(AUTO_SAVE_INTERVAL)
		for _, player in ipairs(Players:GetPlayers()) do
			task.spawn(function()
				saveData(player)
			end)
		end
	end
end)

-- Save on close
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		saveData(player)
	end
end)

-- API
_G.DataManager = {
	getData = function(player)
		return playerDataCache[player.UserId]
	end,
	saveData = saveData,
}

print("[DataManager] Initialisé !")
