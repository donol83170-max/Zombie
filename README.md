# Zombie Waves

## Ce qui est implemente et fonctionnel

### Systeme d'armes (Fe Weapon Kit)
- **Nouveau systeme d'armes** base sur le Fe Weapon Kit (remplace l'ancien systeme custom)
- Les armes, le viewmodel (bras FPS), les animations de tir et reload sont geres par le Fe Kit
- Les armes sont des Tools dans le Backpack du joueur
- BindableEvents (`gunEvent`, `viewmodelEvent`) et BindableFunctions (`gunFunction`, `viewmodelFunction`) dans ReplicatedStorage.Events
- **WeaponConfig.lua** restaure dans `src/shared/` : table des armes (degats, RPM, portee, prix, sons)
- **Animation idle custom** sur les armes (SIGSAUERP250, etc.)

### Economie (Serveur-Autoritaire)
- **Reward par kill** : argent donne au joueur le plus proche quand un zombie meurt
- **DamageZombie event** : conserve pour bridge futur entre Fe Kit et economie serveur
- Validation cote serveur -- anti-triche
- Multiplicateur de classe et bonus double argent

### Zombies
- **Modeles custom avec animations et sons** : glisser vos modeles dans `ServerStorage > ZombieTemplates`
- **Variantes aleatoires** : mettre plusieurs modeles dans un **Folder** (ex : `ZombieTemplates/Zombie/Variant_1`, `Variant_2`) → un modele est choisi au hasard a chaque spawn
- **Template unique** : ou mettre un seul Model directement (ex : `ZombieTemplates/Zombie`)
- Recherche du template par nom : `Enemy_Basic` → `Basic` → `displayName` (ex : "Zombie")
- Les scripts parasites du modele (Respawn, Script) sont supprimes au spawn, les scripts utiles (Animate, sons) sont conserves
- Vie evolutive selon la manche (config dans `ZombieConfig.lua`)
- Types : Basic (100 HP), Rapide (50 HP), Tank (500 HP), Explosif (75 HP), Boss (2000 HP)

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

---

## Configuration Rojo (default.project.json)

- `$ignoreUnknownInstances: true` sur **ServerScriptService** et **StarterPlayerScripts** : empeche Rojo de supprimer les scripts du Fe Weapon Kit lors du sync
- `$ignoreUnknownInstances: true` sur ServerStorage, StarterGui, Workspace : protege les assets du .rbxl

---

## Bugs resolus

- [x] **Animation idle ne s'affichait pas** : l'animation etait creee a partir d'un rig/module n'appartenant pas au compte owner de l'experience. Resolu en recreant l'animation sur un rig appartenant au bon compte
- [x] **Infinite yield WeaponConfig** : UIController attendait WeaponConfig dans ReplicatedStorage.Shared — resolu en restaurant WeaponConfig.lua
- [x] **Rojo supprimait les scripts Fe Kit** : ajout de `$ignoreUnknownInstances: true` sur ServerScriptService et StarterPlayerScripts
- [x] **Camera en Classic au lieu de FPS** : remis `LockFirstPerson` dans UIController
- [x] **Fe Weapon Kit supprime par Rojo** : resolu par ignoreUnknownInstances
- [x] **Scripts parasites dans les modeles zombie** (Respawn, Script, Health) : causaient des erreurs Torso/HumanoidRootPart/Humanoid. Resolu en ne supprimant que les scripts inutiles (Respawn, Script) et en gardant Animate + sons
- [x] **Animations zombie ne marchaient pas** : WaveManager supprimait tous les scripts dont Animate. Resolu en ciblant uniquement les scripts parasites
- [x] **Un seul zombie spawnait malgre plusieurs modeles** : ajout du support Folder avec variantes aleatoires dans WaveManager

## Bugs restants

- [ ] **Erreur ProjectileHandler:519** : `argument #1 expects a string, but EnumItem was passed` dans MakeImpactFX — fix : `hitResult.Material.Name` au lieu de `hitResult.Material` (dans le .rbxl)
- [ ] **Son non approuve** : `rbxassetid://3802437361` — asset pas approuve pour le compte

---

## Notes importantes pour les animations

- Les animations doivent etre **publiees sous le meme compte** que le proprietaire de l'experience
- Les animations doivent etre **creees a partir d'un rig/module appartenant au meme compte** — sinon elles tournent en arriere-plan mais ne s'affichent pas visuellement
- Verifier avec `GetPlayingAnimationTracks()` dans la Command Bar pour debugger

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
- [ ] **Connecter le Fe Kit a l'economie** : fire `DamageZombie` depuis le Fe Kit pour gagner de l'argent par tir
- [ ] **Verifier le reward par kill** : tester que l'argent est bien donne quand un zombie meurt
- [ ] Ajouter animations idle/tir/reload sur toutes les armes
- [ ] Perks (Juggernog, Speed Cola, Double Tap...)
- [ ] Pack-a-Punch (amelioration d'armes)
- [ ] Nouvelles armes avec leurs modeles 3D
- [ ] Zones secretes et Easter Eggs sur la map
