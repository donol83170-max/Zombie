-- LeaderboardManager.server.lua
-- Sauvegarde et affichage du top 10 via DataStoreService
-- Système #11 (Moyenne)

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = ReplicatedStorage:WaitForChild("Events")

-- DataStores
local bestWaveStore = DataStoreService:GetOrderedDataStore("BestWave_v1")
local totalKillsStore = DataStoreService:GetOrderedDataStore("TotalKills_v1")
local totalMoneyStore = DataStoreService:GetOrderedDataStore("TotalMoney_v1")

local GameOver = Events:WaitForChild("GameOver")

-- === SAUVEGARDE ===

local function safeSave(store, key, value)
	local success, err
	for attempt = 1, 3 do
		success, err = pcall(function()
			store:SetAsync(key, value)
		end)
		if success then break end
		warn("[Leaderboard] Tentative " .. attempt .. " échouée: " .. tostring(err))
		task.wait(2 ^ attempt)
	end
	return success
end

local function savePlayerStats(player)
	local userId = tostring(player.UserId)
	local sessionData = player:FindFirstChild("SessionData")
	local leaderstats = player:FindFirstChild("leaderstats")

	if not sessionData or not leaderstats then return end

	local wave = leaderstats:FindFirstChild("Wave") and leaderstats.Wave.Value or 0
	local kills = sessionData:FindFirstChild("Kills") and sessionData.Kills.Value or 0
	local money = leaderstats:FindFirstChild("Money") and leaderstats.Money.Value or 0

	-- Sauvegarder uniquement si c'est un nouveau record
	pcall(function()
		local currentBest = bestWaveStore:GetAsync(userId) or 0
		if wave > currentBest then
			safeSave(bestWaveStore, userId, wave)
			print("[Leaderboard] Nouveau record pour " .. player.Name .. ": Manche " .. wave)
		end
	end)

	-- Ajouter aux totaux
	pcall(function()
		local currentKills = totalKillsStore:GetAsync(userId) or 0
		safeSave(totalKillsStore, userId, currentKills + kills)
	end)

	pcall(function()
		local currentMoney = totalMoneyStore:GetAsync(userId) or 0
		safeSave(totalMoneyStore, userId, currentMoney + money)
	end)
end

-- === LECTURE TOP 10 ===

local function getTop10(store)
	local success, result = pcall(function()
		local pages = store:GetSortedAsync(false, 10) -- top 10 descendant
		local data = pages:GetCurrentPage()
		local top = {}
		for rank, entry in ipairs(data) do
			table.insert(top, {
				rank = rank,
				userId = entry.key,
				value = entry.value,
			})
		end
		return top
	end)
	if success then
		return result
	else
		warn("[Leaderboard] Erreur lecture top 10: " .. tostring(result))
		return {}
	end
end

-- Rendre accessible pour l'UI
_G.GetLeaderboard = function(category)
	if category == "BestWave" then
		return getTop10(bestWaveStore)
	elseif category == "TotalKills" then
		return getTop10(totalKillsStore)
	elseif category == "TotalMoney" then
		return getTop10(totalMoneyStore)
	end
	return {}
end

-- === EVENTS ===

Players.PlayerRemoving:Connect(function(player)
	savePlayerStats(player)
end)

-- Sauvegarder aussi au game over
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		savePlayerStats(player)
	end
end)

print("[LeaderboardManager] Initialisé !")
