# Zombie Waves

## Ce qui est implemente et fonctionnel

### Systeme d'armes (Fe Weapon Kit)
- **Nouveau systeme d'armes** base sur le Fe Weapon Kit (remplace l'ancien systeme custom)
- Les armes, le viewmodel (bras FPS), les animations de tir et reload sont geres par le Fe Kit
- Les armes sont des Tools dans le Backpack du joueur
- BindableEvents (`gunEvent`, `viewmodelEvent`) et BindableFunctions (`gunFunction`, `viewmodelFunction`) dans ReplicatedStorage.Events
- **WeaponConfig.lua** restaure dans `src/shared/` : table des armes (degats, RPM, portee, prix, sons)
- **Animation idle custom** sur les armes (SIGSAUERP250, etc.)
- **OnHitEventModules** : systeme du Fe Kit pour executer du code custom quand une balle touche (dans ServerScriptService > ReplicateServerScript > OnHitEventModules)

### Economie (Serveur-Autoritaire)
- **Reward par kill** : argent donne au joueur le plus proche quand un zombie meurt
- **Reward par tir** : via `OnHitEventModules/DamageZombieEvent` — +$10 body shot, +$50 headshot
- **OnHitEventName** dans la config d'arme (Setting > 1) : mettre `"DamageZombieEvent"` pour activer
- **Argent de depart** : 0$ (configurable dans `GameConfig.STARTING_MONEY`)
- Validation cote serveur -- anti-triche
- Multiplicateur de classe et bonus double argent

### Zombies
- **Modeles custom avec animations et sons** : glisser vos modeles dans `ServerStorage > ZombieTemplates`
- **Variantes aleatoires** : mettre plusieurs modeles dans un **Folder** (ex : `ZombieTemplates/Zombie/Variant_1`, `Variant_2`) -> un modele est choisi au hasard a chaque spawn
- **Template unique** : ou mettre un seul Model directement (ex : `ZombieTemplates/Zombie`)
- Recherche du template par nom : `Enemy_Basic` -> `Basic` -> `displayName` (ex : "Zombie")
- Les scripts parasites du modele (Respawn, Script) sont supprimes au spawn, les scripts utiles (Animate, sons) sont conserves
- Vie evolutive selon la manche (config dans `ZombieConfig.lua`)
- Types : Basic (100 HP), Rapide (50 HP), Tank (500 HP), Explosif (75 HP), Boss (2000 HP)

#### Analyse des 3 modeles de zombies (animations)
- **Zombie 1 & 3** : ancien script Animate, cherche `waitForChild(Figure, "Zombie")` — animations Roblox par defaut (IDs `5077xxxxx`)
- **Zombie 2** : script Animate plus recent avec walk/run blending, height scaling, emote hooks — memes IDs d'animation par defaut
- **Zombie Rufus14** : animations **procedurales** (lerp + sine waves sur Motor6D) — bras tendus a 100 degres, corps penche, style zombie classique. Pas de sprint distinct, une seule animation walk. Inclut sa propre IA (chase, random walk, infection)
- **Conclusion** : les 3 zombies ont les memes animations par defaut. Seul le zombie Rufus14 a un vrai look zombie (bras devant). Pour differencier les types, il faudrait des AnimationId custom ou des animations procedurales par type

### Wall Buy (Achat d'armes aux murs) -- Style COD
- **Placement libre** : place n'importe quel modele ou objet dans le dossier `WallBuys` de Workspace
- **Nommage simple** : renomme l'objet en `WallBuy_NomArme` (ex : `WallBuy_Pistol`, `WallBuy_AK47`)
- Le script detecte automatiquement l'objet et ajoute le **ProximityPrompt** d'achat avec nom + prix
- Fonctionne avec des **Parts** et des **Models**
- Detection dynamique : les wall buys ajoutes en cours de jeu sont detectes aussi
- Achat = clone l'arme depuis ServerStorage/WeaponTemplates dans le Backpack du joueur
- Prix configures dans `WallBuyPrices` (table inline dans WallBuyManager)

### Portail Interactif
- **Touche E** pour ouvrir le portail
- **Coute $1500** pour ouvrir (ouverture definitive)
- Les deux battants s'ouvrent avec une animation fluide (TweenService, 1.5s)
- ProximityPrompt centre sur le portail avec affichage du prix
- Fonctionne avec n'importe quel Model nomme "Gate" contenant "DoorCloseL" et "DoorCloseR"
- **Positions relatives** : deplacer le portail dans Studio ne casse rien

### Portes payantes (Barn & Fencefarmgate)
Le GateManager est generalise : il gere maintenant plusieurs types de portes payantes configurables.

- **Barn** : Model `barn` avec portes `barndoorL` / `barndoorR` — $1000, s'ouvre vers l'exterieur, pas d'apocalypse
- **Fencefarmgate** : Model `fencefarmgate` avec portes `fencedoorL` / `fencedoorR` — $1000, s'ouvre vers l'exterieur, pas d'apocalypse

**Options configurables par porte** (dans `findGates` de `GateManager.server.lua`) :
| Option | Role |
|--------|------|
| `doorLName` / `doorRName` | Noms des deux battants (recherche recursive) |
| `price` | Prix d'ouverture |
| `triggersApocalypse` | `true`/`false` — declenche le passage en mode nuit/rouge |
| `objectText` | Texte affiche sur le ProximityPrompt |
| `openAngle` | Angle d'ouverture en degres (negatif = vers l'exterieur) |
| `hingeShiftL` | Decale la charniere gauche le long de l'axe (+ = vers la droite) pour ajustement fin |

**Supporte les portes en MeshPart seul** (pas besoin de Model contenant des parts) — la charniere est calculee automatiquement a partir du bounding box du mesh.

### Porte de garage (ElectricalManager)
- S'ouvre automatiquement apres reparation de l'electricite (`_G.RepairElectricity`)
- Animation de translation + rotation 90° (TweenService, 2s)
- **Son d'ouverture** : `rbxassetid://132068473451354`, volume 2, audible dans un rayon de ~80 studs (RollOffMin 10 / Max 80)
- Pour changer le son : modifier `garageSound.SoundId` dans `ElectricalManager.server.lua`

### HUD
- **Barre de vie** (haut-gauche) avec couleur dynamique (vert/orange/rouge)
- **Numero de manche** (haut-centre)
- **Argent** (bas-gauche)
- **Barre de vie du boss** (sous la manche, visible uniquement pendant un boss)
- **Notifications** (centre, avec animation de scale + fade)
- **Flash de degats** (ecran rouge quand le joueur est touche)
- **Ecran Game Over** avec stats (manche, kills, argent)

### Boutique (ShopManager)
- Catalogue : armes + consommables (Shield, Speed, Grenade)
- Achat d'armes = clone depuis ServerStorage/WeaponTemplates
- Consommables : bouclier (ForceField 30s), vitesse x2 (30s), grenade (explosion AOE)

### Bonus de manche (BonusManager)
- Bonus aleatoire apres chaque manche
- Types : DoubleMoney, HealAll, AmmoDrop, SpeedBoost, Nuke
- AmmoDrop recharge les valeurs Ammo des Tools dans le Backpack

### Selection de classe
- UI de selection au debut de la partie
- Classes configurees dans `ClassConfig.lua`

### Map & Decor
- Map "lucas 2" avec portail
- Spawn aleatoire de zombies sur la Map 1
- Murs invisibles

---

## Architecture Technique

| Fichier | Role |
|---------|------|
| `src/client/HUDController.client.lua` | HUD : vie, argent, manche, boss HP, notifications |
| `src/client/UIController.client.lua` | Selection de classe, menus, camera LockFirstPerson |
| `src/server/EconomyManager.server.lua` | Argent, rewards (serveur autoritaire) |
| `src/server/GameInit.server.lua` | Init joueur : armes, slots, munitions |
| `src/server/ShopManager.server.lua` | Boutique : armes, consommables |
| `src/server/WallBuyManager.server.lua` | Achat d'armes aux murs (detection auto) |
| `src/server/GateManager.server.lua` | Portails interactifs (ouverture/fermeture) |
| `src/server/BonusManager.server.lua` | Bonus aleatoires apres chaque manche |
| `src/server/WaveManager.server.lua` | Gestion des manches et spawn de zombies |
| `src/server/BossManager.server.lua` | Spawn et gestion des boss |
| `src/shared/GameConfig.lua` | Config globale du jeu |
| `src/shared/ClassConfig.lua` | Config des classes joueur |
| `src/shared/ZombieConfig.lua` | Config zombies (PV, vitesse, recompense) |
| `src/shared/WeaponConfig.lua` | Config des armes (degats, RPM, portee, prix, sons) |
| `src/shared/Constants.lua` | Constantes du jeu |

### Fe Weapon Kit (dans le .rbxl)

| Emplacement | Role |
|-------------|------|
| `ServerScriptService/ReplicateServerScript` | Script serveur du Fe Kit |
| `ReplicateServerScript/OnHitEventModules` | Modules custom executes quand une balle touche |
| `ReplicateServerScript/OnShootEventModules` | Modules custom executes quand le joueur tire |
| `Tool/Setting/1` | Config de l'arme (degats, spread, animations, `OnHitEventName`) |
| `Tool/GunServer` | Script serveur de l'arme |
| `Tool/GunClient` | Script client de l'arme |

---

## Configuration Rojo (default.project.json)

- `$ignoreUnknownInstances: true` sur **ServerScriptService** et **StarterPlayerScripts** : empeche Rojo de supprimer les scripts du Fe Weapon Kit lors du sync
- `$ignoreUnknownInstances: true` sur ServerStorage, StarterGui, Workspace : protege les assets du .rbxl

---

## Bugs resolus

- [x] **Animation idle ne s'affichait pas** : l'animation etait creee a partir d'un rig/module n'appartenant pas au compte owner de l'experience. Resolu en recreant l'animation sur un rig appartenant au bon compte
- [x] **Infinite yield WeaponConfig** : UIController attendait WeaponConfig dans ReplicatedStorage.Shared -- resolu en restaurant WeaponConfig.lua
- [x] **Rojo supprimait les scripts Fe Kit** : ajout de `$ignoreUnknownInstances: true` sur ServerScriptService et StarterPlayerScripts
- [x] **Camera en Classic au lieu de FPS** : remis `LockFirstPerson` dans UIController
- [x] **Fe Weapon Kit supprime par Rojo** : resolu par ignoreUnknownInstances
- [x] **Scripts parasites dans les modeles zombie** (Respawn, Script, Health) : causaient des erreurs Torso/HumanoidRootPart/Humanoid. Resolu en ne supprimant que les scripts inutiles (Respawn, Script) et en gardant Animate + sons
- [x] **Animations zombie ne marchaient pas** : WaveManager supprimait tous les scripts dont Animate. Resolu en ciblant uniquement les scripts parasites
- [x] **Un seul zombie spawnait malgre plusieurs modeles** : ajout du support Folder avec variantes aleatoires dans WaveManager
- [x] **Caractere Unicode `ae` dans Setting** : un caractere special au debut du fichier config de l'arme causait un crash du Fe Kit (bras invisibles). Resolu en supprimant le caractere
- [x] **JOUEUR S'ENVOLE EN EQUIPPANT UNE ARME** : voir section detaillee ci-dessous

---

## Bug resolu : Joueur propulse dans les airs (ou sous terre) en equipant une arme

### Symptome
Quand le joueur equipait la M16A4 ou le SIGSAUERP250, il etait violemment propulse vers l'arriere, vers le haut ou vers le bas. Sans arme equipee, tout fonctionnait normalement.

### Cause racine
Le **Fe Weapon Kit** utilise un module `ViewmodelHandler` (dans `ReplicatedStorage/Modules`) qui cree les bras FPS du joueur. Dans ce module (ligne ~130), il appelle :
```lua
PhysicsService:SetPartCollisionGroup(child, "Viewmodel")
```
Le probleme : le groupe de collision **"Viewmodel"** n'avait **jamais ete enregistre** dans le jeu ! L'appel echouait silencieusement, et toutes les pieces des bras FPS restaient dans le groupe **"Default"** — ce qui leur permettait de **collisionner physiquement** avec le corps du joueur. Le moteur physique de Roblox detectait une penetration entre les bras et la tete du joueur, et ejectait le personnage violemment.

### Pourquoi les anciens patchs ne marchaient pas
Plusieurs tentatives ont ete faites cote **serveur** (Heartbeat loop, ChildAdded, etc.) pour forcer `Massless = true` et `CanCollide = false` sur les pieces des armes. **Aucune n'a marche** car le personnage du joueur appartient au **client** cote reseau (Network Ownership). Les modifications serveur sur les parts attachees au personnage sont **ignorees** par le moteur physique client.

### Solution (3 corrections)

#### 1. Enregistrement du groupe "Viewmodel" (`GameInit.server.lua`)
```lua
PhysicsService:RegisterCollisionGroup("Viewmodel")
PhysicsService:CollisionGroupSetCollidable("Viewmodel", "Default", false)
PhysicsService:CollisionGroupSetCollidable("Viewmodel", "Zombies", false)
```
Le nom **"Viewmodel"** (singulier, sans 's') correspond exactement a ce que le Fe Kit attend. Maintenant, quand le Fe Kit appelle `SetPartCollisionGroup(child, "Viewmodel")`, l'appel reussit et les bras ne peuvent plus collisionner avec le joueur ni les zombies.

#### 2. Fix physique cote client (`InputController.client.lua`)
Une boucle `RenderStepped` qui force `Massless = true` et `CanCollide = false` sur toutes les `BasePart` des Tools equipes dans le Character du joueur. Ceci est fait **cote client** car c'est le client qui a l'autorite reseau sur son personnage.

#### 3. Protection Rojo (`default.project.json`)
Ajout des dossiers **Modules**, **Miscs** et **Remotes** avec `$ignoreUnknownInstances: true` dans la config Rojo. Sans ca, Rojo supprimait ces dossiers critiques du Fe Kit a chaque synchronisation, causant des erreurs "Infinite yield".

### Nettoyage effectue
- **Supprime** : `ViewmodelController.client.lua` (ancien systeme maison de bras FPS qui entrait en conflit avec le Fe Kit)
- **Nettoye** : `InputController.client.lua` (suppression de l'ancien systeme de tir/rechargement/raycast maison — le Fe Kit gere tout ca)
- Les armes utilisent maintenant l'**inventaire natif Roblox** (Backpack, touches 1/2/3) au lieu d'un systeme custom de slots

### Lecons apprises
1. **Toujours verifier les noms exacts** des groupes de collision attendus par les kits tiers
2. **Les modifications physiques doivent etre cote client** quand elles concernent le personnage du joueur
3. **Proteger tous les dossiers Fe Kit dans Rojo** avec `$ignoreUnknownInstances: true` (Modules, Miscs, Remotes, Weapons)

---

## Bug resolu : Sons et effets visuels des armes muets (Fe Weapon Kit)

### Symptome
Les armes tiraient (douilles ejectees, zombies tues) mais aucun son de tir ne se produisait pour le tireur. Le muzzle flash ne s'affichait pas non plus.

### Cause racine
Le `GunClient` du Fe Weapon Kit ne joue pas les sons directement. Dans la fonction `Fire()`, il delègue la lecture audio via :
```lua
gunEvent:Fire("PlayAudio", { Instance = Track, ... })
```
Ce `gunEvent` est un `BindableEvent` dans `ReplicatedStorage.Events`. Le module `AudioHandler` (dans `ReplicatedStorage.Modules`) est cense ecouter cet evenement et jouer le son -- mais **il n'etait jamais `require()`-e par aucun script**. Resultat : `gunEvent:Fire("PlayAudio")` partait dans le vide, aucun son ne jouait jamais.

### Erreurs detectees en cours de diagnostic
- `GunGUI` absent du `GunClient` (le script bloquait sur `WaitForChild("GunGUI")`)
- `FireSounds` nomme `"Fire"` au lieu de `"FireSounds"` dans `Handle > 1`
- `FireSounds` place dans `Setting > 1` au lieu de `Handle > 1`
- `FireSounds` cree comme Folder au lieu de Sound
- Rojo servait depuis `Zombie/game/` mais les modifications etaient faites dans `game/` (mauvais dossier)

### Solution
Dans `ReplicatedStorage > Weapons > M16A4 > GunClient` et `SIGSAUERP250 > GunClient`, ajouter `Track:Play()` directement avant l'appel `gunEvent:Fire` dans la fonction `Fire()` (ligne ~1389) :

```lua
if Track ~= nil then
    Track:Play()  -- AJOUT : joue le son localement pour le tireur
    gunEvent:Fire("PlayAudio",
        {
            Instance = Track,
            Origin = ShootingHandle:FindFirstChild("GunMuzzlePoint"..CurrentFireMode),
            ...
        },
```

Pas de risque de double son car `gunEvent` n'etait connecte a rien.

### Structure correcte du Handle pour les sons
```
Tool
  └── Handle
       └── 1  (Attachment)
            ├── FireSounds  (Sound) ← son de tir
            ├── ReloadSound (Sound)
            ├── EquippedSound (Sound)
            └── ... (autres sons du kit)
```

### Lecons apprises
1. Toujours verifier que Rojo sert depuis le **bon dossier** (`Zombie/game/`, pas `game/`)
2. Le `GunClient` dans **ReplicatedStorage/Weapons** est celui qui tourne — pas celui dans StarterPack
3. `gunEvent:Fire()` est un BindableEvent local -- si rien ne l'ecoute, les sons ne jouent jamais
4. Utiliser la Command Bar Studio pour inspecter l'arbre d'instances en temps reel pendant le Play

---

## Muzzle Flash -- Probleme et Solution (19/04/2026)

### Probleme
Le Fe Weapon Kit utilise un **viewmodel separe** (`v_M16A4`) parenté a la Camera pour le rendu FPS. Le vrai Tool dans le character est invisible et positionne ailleurs. Donc tout tentative de lire la position des attachments du Tool Handle (GunFirePoint1, GunMuzzlePoint1) donnait une position incorrecte (dans le ciel ou au mauvais endroit).

### Solution
1. **Ajouter un Attachment** nomme `MuzzleFlashEffect` dans `StarterPack > M16A4 > Handle` contenant les ParticleEmitters + PointLight (depuis la Toolbox Roblox "Muzzle flash")
2. **Dans `InputController.client.lua`**, a chaque tir :
   - Trouver le viewmodel : `Camera.ViewmodelStorage.v_M16A4`
   - Trouver la Part `bout` dans ses descendants (c'est le bout du canon du viewmodel)
   - Assigner `muzzle.WorldPosition = bout.Position` avant d'emettre
   - Appeler `:Emit(5)` sur chaque ParticleEmitter
   - Allumer/eteindre le PointLight via `task.spawn` (0.05s)

```lua
local vmStorage = workspace.CurrentCamera:FindFirstChild("ViewmodelStorage")
local viewmodel = vmStorage and vmStorage:FindFirstChild("v_" .. tool.Name)
if viewmodel then
    for _, child in ipairs(viewmodel:GetDescendants()) do
        if child.Name == "bout" and child:IsA("BasePart") then
            muzzle.WorldPosition = child.Position
            break
        end
    end
end
```

### Pourquoi ca marche
La Part `bout` du viewmodel est la piece physique au bout du canon du modele FPS visible. Sa `.Position` est la position monde reelle du bout du canon, quelle que soit l'orientation de l'arme.

### Proprietes finales des ParticleEmitters (MuzzleFlashEffect)
Flash (ParticleEmitters du Toolbox) :
- Size : 0.3
- LightEmission : 0.5
- Lifetime : 0.04 - 0.07s
- Speed : 1 - 2
- Emit : 3 par tir

Fumee (ParticleEmitter "SmokeEffect" custom) :
- Texture : rbxassetid://1370765866
- Color : gris (180,180,180) → (100,100,100)
- Size : 0.05 → 0.12
- Lifetime : 0.1 - 0.2s
- Speed : 0.2 - 0.5
- Transparency : 0.2 → 1
- Emit : 2 par tir

---

## Bugs restants

- [ ] **Erreur ProjectileHandler:519** : `argument #1 expects a string, but EnumItem was passed` dans MakeImpactFX -- fix : `hitResult.Material.Name` au lieu de `hitResult.Material` (dans le .rbxl)
- [ ] **Son non approuve** : `rbxassetid://3802437361` -- asset pas approuve pour le compte

---

## Notes importantes pour les animations

- Les animations doivent etre **publiees sous le meme compte** que le proprietaire de l'experience
- Les animations doivent etre **creees a partir d'un rig/module appartenant au meme compte** -- sinon elles tournent en arriere-plan mais ne s'affichent pas visuellement
- Verifier avec `GetPlayingAnimationTracks()` dans la Command Bar pour debugger
- Les animations Roblox par defaut utilisent les IDs `5077xxxxx` (idle, walk, run, jump, etc.)
- Pour des animations zombie custom, options : changer les AnimationId dans le script Animate, ou utiliser des animations procedurales (lerp + sine waves)

---

## Comment connecter une arme a l'economie (Fe Kit)

1. Creer un **ModuleScript** dans `ServerScriptService/ReplicateServerScript/OnHitEventModules` nomme `DamageZombieEvent`
2. Y mettre le code qui donne de l'argent au joueur ($10 body, $50 headshot) via `_G.EconomyManager`
3. Dans la config de l'arme (**Setting > 1**), changer `OnHitEventName = "DamageZombieEvent";`
4. Faire ca pour **chaque arme** qui doit donner de l'argent

---

## Collaboration (2 joueurs)

Le jeu est developpe a deux (freres). Pour eviter les problemes de permissions sur les animations :
- **Creer un Groupe Roblox** (via roblox.com > Communautes)
- **Transferer le jeu au groupe**
- **Publier toutes les animations sous le groupe** (pas sous un compte perso)

Pour synchroniser le code :
1. `git clone` du depot
2. Ouvrir `Zombies Waves.rbxl` dans Roblox Studio
3. `rojo serve game/default.project.json` dans le terminal
4. Connecter le plugin Rojo dans Studio
5. `git commit` + `git push` / `git pull` pour partager les changements

**IMPORTANT** : ne jamais sync Rojo sans `$ignoreUnknownInstances: true` sur les dossiers contenant des scripts Fe Kit, sinon ils seront supprimes.

---

## Lancer le projet

```bash
rojo serve game/default.project.json
```
Puis connecte le plugin **Rojo** dans Roblox Studio.

---

## Prochaines etapes
- [ ] **Tester DamageZombieEvent** : verifier que l'argent est bien donne par tir ($10 body, $50 headshot)
- [ ] Ajouter des animations zombie custom (idle/walk differentes par type)
- [ ] Perks (Juggernog, Speed Cola, Double Tap...)
- [ ] Pack-a-Punch (amelioration d'armes)
- [ ] Nouvelles armes avec leurs modeles 3D
- [ ] Zones secretes et Easter Eggs sur la map
