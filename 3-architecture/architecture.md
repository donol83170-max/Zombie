# Architecture Technique — Zombie Waves

> Plan technique complet pour Roblox Studio + Rojo.

---

## Vue d'ensemble

### Stack technique

| Composant | Technologie |
|-----------|------------|
| **Engine** | Roblox Studio |
| **Langage** | Luau (Roblox Lua) |
| **Sync externe** | Rojo (filesystem → Studio) |
| **Persistence** | DataStoreService + OrderedDataStore (leaderboard) |
| **Communication** | RemoteEvents / RemoteFunctions |
| **UI** | ScreenGui, BillboardGui |
| **IA ennemis** | PathfindingService |
| **Audio** | SoundService |

### Architecture Client/Serveur

```
┌─────────────────────────────────────────────────────┐
│                    SERVEUR                           │
│  ServerScriptService/                               │
│  ├── Init.server.lua           (bootstrap)          │
│  ├── WaveManager.server.lua    (manches, spawns)    │
│  ├── EconomyManager.server.lua (argent, achats)     │
│  ├── WallBuyManager.server.lua (armes murales)      │
│  ├── DoorManager.server.lua    (portes payantes)    │
│  ├── BossManager.server.lua    (boss multi-phases)  │
│  ├── BonusManager.server.lua   (bonus aléatoires)   │
│  ├── ClassManager.server.lua   (rôles joueur)       │
│  ├── ShopManager.server.lua    (boutique)           │
│  ├── LeaderboardManager.server.lua (DataStore)      │
│  ├── HardcoreManager.server.lua (mode hardcore)     │
│  └── DataManager.server.lua    (save/load)          │
│                                                      │
│  ServerStorage/                                      │
│  ├── ZombieTemplates/   (modèles de zombies)        │
│  └── WeaponTemplates/   (modèles d'armes)           │
├──────────────────────┬──────────────────────────────┤
│   RemoteEvents       │    RemoteFunctions            │
├──────────────────────┴──────────────────────────────┤
│                    CLIENT                            │
│  StarterPlayerScripts/                               │
│  ├── HUDController.client.lua  (mise à jour HUD)    │
│  ├── UIController.client.lua   (menus, notifs)       │
│  └── InputController.client.lua (contrôles)          │
│                                                      │
│  ReplicatedStorage/                                  │
│  ├── GameConfig.lua     (constantes globales)        │
│  ├── Constants.lua      (enums, types)               │
│  ├── WeaponConfig.lua   (table des armes)            │
│  ├── ZombieConfig.lua   (table des zombies)          │
│  └── ClassConfig.lua    (table des classes)           │
└─────────────────────────────────────────────────────┘
```

---

## Structure Rojo (filesystem)

```
game/
├── default.project.json
└── src/
    ├── server/                  → ServerScriptService
    ├── client/                  → StarterPlayerScripts
    ├── shared/                  → ReplicatedStorage
    └── gui/                     → StarterGui
```

---

## Schéma DataStore

### Structure de sauvegarde par joueur

```lua
PlayerData = {
    version = 1,
    firstJoin = timestamp,
    lastJoin = timestamp,
    
    -- Stats globales
    bestWave = number,          -- meilleure manche atteinte
    totalKills = number,        -- zombies tués total
    totalMoneyEarned = number,  -- argent gagné total
    totalBossKills = number,    -- boss tués total
    totalGamesPlayed = number,  -- parties jouées
    
    -- Hardcore
    hardcoreBestWave = number,  -- meilleure manche en hardcore
    
    -- Paramètres
    settings = {
        musicVolume = 0.5,
        sfxVolume = 0.7,
    },
}
```

### Stratégie de sauvegarde

| | Détail |
|---|--------|
| **Fréquence auto-save** | Toutes les 5 minutes |
| **Save on leave** | Oui — BindToClose + PlayerRemoving |
| **Retry en cas d'échec** | 3 tentatives avec backoff exponentiel |
| **Version du schéma** | v1 (numéroté pour migrations) |

---

## Map des RemoteEvents

### Client → Serveur

| Event | Payload | Validation serveur |
|-------|---------|-------------------|
| `RequestBuyWallWeapon` | `{ wallBuyId }` | Vérifier fonds, proximité |
| `RequestBuyDoor` | `{ doorId }` | Vérifier fonds, proximité |
| `RequestBuyShopItem` | `{ itemId }` | Vérifier fonds, item existe |
| `RequestSelectClass` | `{ className }` | Vérifier classe valide, en lobby |
| `RequestVoteHardcore` | `{ vote: bool }` | Vérifier en lobby |

### Serveur → Client

| Event | Payload | Usage |
|-------|---------|-------|
| `UpdateMoney` | `{ amount }` | MAJ affichage argent |
| `UpdateWave` | `{ waveNumber }` | MAJ numéro de manche |
| `UpdateHealth` | `{ hp, maxHp }` | MAJ barre de vie |
| `UpdateAmmo` | `{ current, reserve, weaponName }` | MAJ munitions |
| `ShowNotification` | `{ text, color, duration }` | Afficher notification |
| `WaveCompleted` | `{ waveNumber, bonusType }` | Fin de manche + bonus |
| `BossSpawned` | `{ bossHp }` | Afficher barre de vie boss |
| `BossHealthUpdate` | `{ hp, maxHp }` | MAJ barre boss |
| `GameOver` | `{ wave, kills, money }` | Écran de fin |
| `ClassSelected` | `{ className, stats }` | Confirmer la classe |

---

## Sécurité & Anti-triche

| Menace | Protection |
|--------|-----------|
| Argent hacké | Économie 100% server-side, client n'envoie que des requêtes |
| Dégâts hackés | Dégâts calculés sur le serveur uniquement |
| Speed hack | Vitesse contrôlée par les stats de classe côté serveur |
| Spam RemoteEvents | Rate limiting (max 10 requêtes/seconde) |

---

## Services Roblox utilisés

| Service | Usage |
|---------|------|
| DataStoreService | Sauvegarde stats joueurs |
| OrderedDataStoreService | Leaderboard global |
| Players | Gestion connexion/déconnexion |
| RunService | Heartbeat pour IA zombies |
| PathfindingService | Navigation des zombies |
| TweenService | Animations UI + portes |
| CollectionService | Tags zombies, wall buys, portes |
| SoundService | Musique et SFX |
| BadgeService | Badges/Achievements |
| ProximityPromptService | Interactions wall buys et portes |
