-- HardcoreManager.server.lua
-- Mode Hardcore : vote unanime, 1 vie, argent x3
-- Système #10 (Moyenne)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = ReplicatedStorage:WaitForChild("Events")

local RequestVoteHardcore = Events:WaitForChild("RequestVoteHardcore")
local ShowNotification = Events:WaitForChild("ShowNotification")

local isHardcoreActive = false

-- === VOTE SYSTEM ===

RequestVoteHardcore.OnServerEvent:Connect(function(player, vote)
	local sessionData = player:FindFirstChild("SessionData")
	if not sessionData or not sessionData:FindFirstChild("HardcoreVote") then return end

	sessionData.HardcoreVote.Value = (vote == true)

	-- Vérifier si tous les joueurs ont voté OUI
	local allPlayers = Players:GetPlayers()
	if #allPlayers == 0 then return end

	local allVotedYes = true
	local voteCount = 0
	for _, p in ipairs(allPlayers) do
		local sd = p:FindFirstChild("SessionData")
		if sd and sd:FindFirstChild("HardcoreVote") then
			if sd.HardcoreVote.Value then
				voteCount += 1
			else
				allVotedYes = false
			end
		end
	end

	-- Notifier l'état du vote
	ShowNotification:FireAllClients(
		"☠️ Vote Hardcore: " .. voteCount .. "/" .. #allPlayers,
		"#FF4444", 2
	)

	if allVotedYes and #allPlayers > 0 then
		isHardcoreActive = true
		_G.IsHardcore = true
		ShowNotification:FireAllClients(
			"☠️ MODE HARDCORE ACTIVÉ ! Une seule vie, argent x3 !",
			"#FF0000", 5
		)

		-- Appliquer le x3 argent
		local economy = _G.EconomyManager
		if economy then
			for _, p in ipairs(allPlayers) do
				-- Le multiplicateur sera géré par le ClassConfig + un flag
			end
		end

		print("[HardcoreManager] Mode Hardcore activé !")
	end
end)

-- Rendre l'état accessible
_G.IsHardcore = false

print("[HardcoreManager] Initialisé !")
