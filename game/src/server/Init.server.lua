-- Init.server.lua
-- Point d'entrée serveur — Zombie Waves
-- Initialise tous les systèmes dans le bon ordre

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Attendre que les modules partagés soient disponibles
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Constants = require(Shared:WaitForChild("Constants"))

print("[ZombieWaves] Serveur en cours d'initialisation...")

-- Références aux managers (ils s'initialisent eux-mêmes via .server.lua)
-- L'ordre d'exécution est géré par les dépendances dans chaque script

-- Setup leaderstats pour chaque joueur qui rejoint
Players.PlayerAdded:Connect(function(player)
	-- Créer leaderstats  
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Value = GameConfig.STARTING_MONEY
	money.Parent = leaderstats

	local wave = Instance.new("IntValue")
	wave.Name = "Wave"
	wave.Value = 0
	wave.Parent = leaderstats

	-- Créer un folder pour les données de session
	local sessionData = Instance.new("Folder")
	sessionData.Name = "SessionData"
	sessionData.Parent = player

	local className = Instance.new("StringValue")
	className.Name = "Class"
	className.Value = "Soldier"
	className.Parent = sessionData

	local kills = Instance.new("IntValue")
	kills.Name = "Kills"
	kills.Value = 0
	kills.Parent = sessionData

	local isAlive = Instance.new("BoolValue")
	isAlive.Name = "IsAlive"
	isAlive.Value = true
	isAlive.Parent = sessionData

	local hardcoreVote = Instance.new("BoolValue")
	hardcoreVote.Name = "HardcoreVote"
	hardcoreVote.Value = false
	hardcoreVote.Parent = sessionData

	-- Weapon data
	local weaponName = Instance.new("StringValue")
	weaponName.Name = "WeaponName"
	weaponName.Value = "Pistol"
	weaponName.Parent = sessionData

	local currentAmmo = Instance.new("IntValue")
	currentAmmo.Name = "CurrentAmmo"
	currentAmmo.Value = 12
	currentAmmo.Parent = sessionData

	local reserveAmmo = Instance.new("IntValue")
	reserveAmmo.Name = "ReserveAmmo"
	reserveAmmo.Value = 48
	reserveAmmo.Parent = sessionData

	print("[ZombieWaves] Joueur connecté: " .. player.Name)
end)

print("[ZombieWaves] Serveur initialisé avec succès !")
