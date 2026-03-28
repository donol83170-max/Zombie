-- ZombieConfig.lua
-- Configuration des types de zombies
-- Partagé entre client et serveur (ReplicatedStorage)

local ZombieConfig = {}

ZombieConfig.Types = {
    Basic = {
        displayName = "Zombie",
        baseHp = 100,
        hpPerWave = 10,
        speed = 12,
        damage = 10,            -- dégâts par seconde au contact
        reward = 10,
        scale = 1,
        color = Color3.fromRGB(100, 130, 100),   -- vert grisâtre
    },
    Fast = {
        displayName = "Zombie Rapide",
        baseHp = 50,
        hpPerWave = 0,          -- PV fixes
        speed = 24,             -- 2x plus rapide
        damage = 10,
        reward = 20,
        scale = 0.8,
        color = Color3.fromRGB(150, 255, 150),    -- vert vif
    },
    Tank = {
        displayName = "Zombie Tank",
        baseHp = 500,
        hpPerWave = 0,          -- PV fixes
        speed = 4,              -- 3x plus lent
        damage = 25,
        reward = 100,
        scale = 2,
        color = Color3.fromRGB(80, 60, 60),       -- brun foncé
    },
    Explosive = {
        displayName = "Zombie Explosif",
        baseHp = 75,
        hpPerWave = 0,
        speed = 14,
        damage = 50,            -- dégâts d'explosion
        reward = 50,
        scale = 1,
        explosionRadius = 10,
        triggerDistance = 5,     -- explose quand < 5 studs du joueur
        color = Color3.fromRGB(255, 100, 0),      -- orange
    },
}

-- Distribution des zombies spéciaux (quand un spawn est "spécial")
ZombieConfig.SpecialDistribution = {
    { type = "Fast",      weight = 40 },
    { type = "Tank",      weight = 30 },
    { type = "Explosive", weight = 30 },
}

-- Boss config
ZombieConfig.Boss = {
    displayName = "BOSS",
    baseHp = 2000,
    hpPerWave = 200,
    speed = 10,
    damage = 30,
    reward = 500,
    scale = 3,
    color = Color3.fromRGB(200, 0, 0), -- rouge
}

return ZombieConfig
