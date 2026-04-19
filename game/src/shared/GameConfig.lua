-- GameConfig.lua
-- Constantes globales du jeu Zombie Waves
-- Partagé entre client et serveur (ReplicatedStorage)

local GameConfig = {}

-- === VAGUES ===
GameConfig.STARTING_WAVE = 1
GameConfig.ZOMBIES_BASE = 5
GameConfig.ZOMBIES_PER_WAVE = 3         -- formule: ZOMBIES_BASE + (wave * ZOMBIES_PER_WAVE)
GameConfig.SPAWN_INTERVAL_MIN = 0.5
GameConfig.SPAWN_INTERVAL_MAX = 1.5
GameConfig.WAVE_DELAY = 5               -- secondes entre les manches
GameConfig.BOSS_EVERY_N_WAVES = 5

-- === ZOMBIES ===
GameConfig.ZOMBIE_BASE_HP = 100
GameConfig.ZOMBIE_HP_PER_WAVE = 10      -- formule: BASE_HP + (wave * HP_PER_WAVE)
GameConfig.ZOMBIE_BASE_SPEED = 12
GameConfig.ZOMBIE_DAMAGE = 10           -- dégâts par seconde au contact
GameConfig.ZOMBIE_ATTACK_RANGE = 5
GameConfig.ZOMBIE_DESPAWN_TIME = 3

-- === ZOMBIES SPÉCIAUX (apparaissent dès manche 5) ===
GameConfig.SPECIAL_ZOMBIE_START_WAVE = 5
GameConfig.SPECIAL_ZOMBIE_CHANCE = 0.2  -- 20% chance de remplacement

-- === BOSS ===
GameConfig.BOSS_BASE_HP = 2000
GameConfig.BOSS_HP_PER_WAVE = 200
GameConfig.BOSS_PHASE2_THRESHOLD = 0.6  -- 60% HP
GameConfig.BOSS_PHASE3_THRESHOLD = 0.3  -- 30% HP
GameConfig.BOSS_PHASE2_SPEED_MULT = 1.5
GameConfig.BOSS_PHASE3_SUMMON_INTERVAL = 10
GameConfig.BOSS_PHASE3_SUMMON_COUNT = 5
GameConfig.BOSS_REWARD = 500

-- === ÉCONOMIE ===
GameConfig.MONEY_PER_HIT = 10
GameConfig.STARTING_MONEY = 2000

-- === JOUEUR ===
GameConfig.DEFAULT_MAX_HP = 100
GameConfig.RESPAWN_TIME = 5             -- secondes (mode normal)

-- === PORTES ===
GameConfig.DOOR_PRICES = {
    Door_Zone2 = 750,
    Door_Zone3 = 2000,
}

-- === FORTERESSE ===
GameConfig.FORTRESS_PRICE = 1500  -- les deux portes s'ouvrent ensemble

-- === BONUS (probabilités) ===
GameConfig.BONUS_PROBABILITIES = {
    { name = "DoubleMoney",  weight = 30 },
    { name = "HealAll",      weight = 25 },
    { name = "AmmoDrop",     weight = 20 },
    { name = "SpeedBoost",   weight = 15 },
    { name = "Nuke",         weight = 10 },
}
GameConfig.SPEED_BOOST_DURATION = 30
GameConfig.SPEED_BOOST_MULTIPLIER = 1.5

-- === CONSOMMABLES ===
GameConfig.CONSUMABLES = {
    Shield   = { price = 300, duration = 30, absorption = 50 },
    Speed    = { price = 200, duration = 30, multiplier = 2 },
    Grenade  = { price = 150, radius = 10, damage = 100 },
}

-- === UI COULEURS ===
GameConfig.UI_COLORS = {
    Primary     = Color3.fromHex("#1a1a2e"),
    Secondary   = Color3.fromHex("#e94560"),
    Accent      = Color3.fromHex("#0f3460"),
    Gold        = Color3.fromHex("#f5c518"),
    HealthGreen = Color3.fromRGB(0, 200, 0),
    HealthOrange= Color3.fromRGB(255, 165, 0),
    HealthRed   = Color3.fromRGB(255, 0, 0),
    White       = Color3.fromRGB(255, 255, 255),
    Black       = Color3.fromRGB(0, 0, 0),
}

return GameConfig
