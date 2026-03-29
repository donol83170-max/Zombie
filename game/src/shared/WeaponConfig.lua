-- WeaponConfig.lua
-- Table de toutes les armes du jeu
-- Partagé entre client et serveur (ReplicatedStorage)

local WeaponConfig = {}

WeaponConfig.Weapons = {
    Pistol = {
        displayName = "Pistolet",
        price = 0,                -- gratuit (arme de départ)
        damage = 15,
        rpm = 300,                -- rounds per minute
        magSize = 12,
        reserveAmmo = 48,
        reloadTime = 1.5,         -- secondes
        fireMode = "semi",        -- semi / auto / burst
        range = 100,
        headshotMult = 2.0,
        
        -- Configuration Visuelle FPS
        fpsOffset = Vector3.new(0.5, -1, -2.0),
        fpsRotation = Vector3.new(0, -180, 0), -- Tourne l'arme de 90 degrés pour la mettre droite
        
        -- Sons
        fireSound = "rbxassetid://104267069535370", -- Son de tir classique de Roblox
    },
    SMG = {
        displayName = "SMG",
        price = 800,
        damage = 12,
        rpm = 600,
        magSize = 30,
        reserveAmmo = 120,
        reloadTime = 2.0,
        fireMode = "auto",
        range = 80,
        headshotMult = 1.5,
    },
    Shotgun = {
        displayName = "Shotgun",
        price = 1500,
        damage = 50,              -- par pellet (8 pellets, spread)
        rpm = 90,
        magSize = 8,
        reserveAmmo = 32,
        reloadTime = 3.0,
        fireMode = "semi",
        range = 30,
        pellets = 8,
        spread = 8,               -- degrés
        headshotMult = 1.5,
    },
    AK47 = {
        displayName = "AK-47",
        price = 2500,
        damage = 25,
        rpm = 450,
        magSize = 30,
        reserveAmmo = 120,
        reloadTime = 2.5,
        fireMode = "auto",
        range = 120,
        headshotMult = 2.0,
    },
    Sniper = {
        displayName = "Sniper",
        price = 4000,
        damage = 100,
        rpm = 40,
        magSize = 5,
        reserveAmmo = 20,
        reloadTime = 3.5,
        fireMode = "semi",
        range = 300,
        headshotMult = 3.0,
    },
    Flamethrower = {
        displayName = "Lance-flammes",
        price = 6000,
        damage = 8,               -- dégâts par tick (continuous)
        rpm = 0,                  -- continuous fire
        magSize = 100,
        reserveAmmo = 200,
        reloadTime = 4.0,
        fireMode = "continuous",
        range = 25,
        headshotMult = 1.0,
        tickRate = 0.1,           -- dégâts toutes les 0.1s
    },
}

-- Mapping wall buys par zone
WeaponConfig.WallBuys = {
    Zone1 = { "Pistol", "Shotgun" },
    Zone2 = { "SMG", "AK47" },
    Zone3 = { "Sniper", "Flamethrower" },
}

-- Armes du shop
WeaponConfig.ShopWeapons = { "Pistol", "SMG", "Shotgun", "AK47", "Sniper", "Flamethrower" }

return WeaponConfig
