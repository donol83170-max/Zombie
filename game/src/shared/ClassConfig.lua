-- ClassConfig.lua
-- Configuration des 4 classes joueur
-- Partagé entre client et serveur (ReplicatedStorage)

local ClassConfig = {}

ClassConfig.Classes = {
    Soldier = {
        displayName = "Soldier",
        description = "100 PV, +20% dégâts",
        maxHp = 100,
        damageMult = 1.2,      -- +20% dégâts
        speedMult = 1.0,
        moneyMult = 1.0,
        damageReduction = 0,
        healAura = false,
        icon = "rbxassetid://0", -- placeholder
    },
    Medic = {
        displayName = "Medic",
        description = "80 PV, soigne alliés 5 PV/s (rayon 15 studs)",
        maxHp = 80,
        damageMult = 1.0,
        speedMult = 1.0,
        moneyMult = 1.0,
        damageReduction = 0,
        healAura = true,
        healAuraRadius = 15,
        healAuraRate = 5,       -- PV/s
        icon = "rbxassetid://0",
    },
    Tank = {
        displayName = "Tank",
        description = "200 PV, vitesse -20%, -30% dégâts reçus",
        maxHp = 200,
        damageMult = 1.0,
        speedMult = 0.8,        -- -20% vitesse
        moneyMult = 1.0,
        damageReduction = 0.3,  -- -30% dégâts reçus
        healAura = false,
        icon = "rbxassetid://0",
    },
    Scout = {
        displayName = "Scout",
        description = "70 PV, vitesse +40%, 2x argent par hit",
        maxHp = 70,
        damageMult = 1.0,
        speedMult = 1.4,        -- +40% vitesse
        moneyMult = 2.0,        -- 2x argent
        damageReduction = 0,
        healAura = false,
        icon = "rbxassetid://0",
    },
}

ClassConfig.DefaultClass = "Soldier"

return ClassConfig
