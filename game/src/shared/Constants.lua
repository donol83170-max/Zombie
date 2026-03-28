-- Constants.lua
-- Enums et constantes partagées
-- Partagé entre client et serveur (ReplicatedStorage)

local Constants = {}

-- États du jeu
Constants.GameState = {
    LOBBY = "Lobby",
    PLAYING = "Playing",
    INTERMISSION = "Intermission",
    GAME_OVER = "GameOver",
}

-- Types de bonus
Constants.BonusType = {
    DOUBLE_MONEY = "DoubleMoney",
    HEAL_ALL = "HealAll",
    AMMO_DROP = "AmmoDrop",
    SPEED_BOOST = "SpeedBoost",
    NUKE = "Nuke",
}

-- Noms d'affichage des bonus
Constants.BonusDisplayNames = {
    DoubleMoney = "💰 Double Money !",
    HealAll     = "❤️ Soin complet !",
    AmmoDrop    = "🔫 Recharge complète !",
    SpeedBoost  = "⚡ Vitesse x1.5 !",
    Nuke        = "☢️ NUKE !",
}

-- Types de zombies
Constants.ZombieType = {
    BASIC = "Basic",
    FAST = "Fast",
    TANK = "Tank",
    EXPLOSIVE = "Explosive",
    BOSS = "Boss",
}

-- Phases du boss
Constants.BossPhase = {
    PHASE1 = 1,
    PHASE2 = 2,
    PHASE3 = 3,
}

-- Types de notifications
Constants.NotifType = {
    SUCCESS = "Success",
    ERROR = "Error",
    INFO = "Info",
    WARNING = "Warning",
    WAVE = "Wave",
    BONUS = "Bonus",
    BOSS = "Boss",
}

return Constants
