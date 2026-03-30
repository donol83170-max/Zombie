# Zombie Waves

## Ce qui est implemente et fonctionnel

### Systeme de Combat (FPS)
- **Tir raycast** depuis la tete du joueur -- les balles traversent le brouillard et les decors transparents
- **Arme exclue du raycast** -- les balles ne touchent plus le modele 3D de l'arme
- **Muzzle Flash** -- le flash sort du bout du canon (attachement `MuzzleFlash` dans `Handle`)
- **Recul + Balancement** (Sway) de l'arme a chaque tir
- **Hitmarker sonore** quand un zombie est touche
- **Rechargement** : touche `R` a tout moment, hint "Appuyer sur R" quand le chargeur est vide

### Bras FPS (VMTemplate)
- **Nouveau modele de bras realiste** (VMTemplate) avec Humanoid, Body Colors et Shirt
- Les bras suivent la camera avec recul et sway
- Le modele "VMTemplate" est dans `ReplicatedStorage/Weapons/VMTemplate`
- Chaque arme est attachee au **RightGripAttachment** du `Right Arm` avec rotation et offset configurables
- Camera et ThumbnailCamera du modele sont supprimes automatiquement en jeu (preview Studio uniquement)
- Position de la camera FPS optimisee (bras descendus et recules pour un meilleur rendu)
- **Fix collision** : le Humanoid du ViewModel est desactive (EvaluateStateMachine = false) et toutes les parts sont en CanCollide/CanQuery/CanTouch = false pour eviter les collisions fantomes

### Systeme de Slots (Switch d'armes)
- **Touche 1** : equipe l'arme primaire (pistolet par defaut, ou celle achetee)
- **Touche 2** : equipe le couteau (melee)
- Les munitions de l'arme primaire sont sauvegardees lors du switch
- Animation de switch avec delai de 0.3s
- Achat d'arme (shop ou wall buy) met a jour automatiquement le slot primaire

### Couteau (KNIFE)
- **35 degats**, mode melee, pas de munitions
- Portee courte (8 studs)
- Animation de slash vers l'avant au lieu du recul
- Rotation et position configurables via `fpsRotation` et `gripOffset` dans WeaponConfig
- Le HUD affiche "---" au lieu des munitions

### Economie (Serveur-Autoritaire)
- **+10$** par tir au corps
- **+50$** par tir a la tete
- Validation cote serveur -- anti-triche
- Fonctionne avec **tous les modeles de zombies** de la Toolbox (recherche recursive du Humanoid)

### Zombies
- Nom obligatoire : `Enemy_XYZ` (ex : `Enemy_Basic`, `Enemy_Boss`)
- Les degats sont appliques via `HumanoidRootPart:TakeDamage()`
- Vie evolutive selon la manche (config dans `ZombieConfig.lua`)
- Types : Basic (100 HP), Rapide (50 HP), Tank (500 HP), Explosif (75 HP), Boss (2000 HP)

### Wall Buy (Achat d'armes aux murs) -- Style COD
- **Placement libre** : place n'importe quel modele ou objet dans le dossier `WallBuys` de Workspace
- **Nommage simple** : renomme l'objet en `WallBuy_NomArme` (ex : `WallBuy_Pistol`, `WallBuy_AK47`)
- Le script detecte automatiquement l'objet et ajoute le **ProximityPrompt** d'achat avec nom + prix
- Plus de texte flottant (BillboardGui) : tout est affiche directement dans le **ProximityPrompt**
- Fonctionne avec des **Parts** et des **Models** (cherche la PrimaryPart ou la premiere Part)
- Detection dynamique : les wall buys ajoutes en cours de jeu sont detectes aussi
- Nettoyage automatique des espaces dans les noms
- **Astuce visuel** : ajouter un **Highlight** sur le modele (OutlineColor blanc, FillTransparency 1) pour un effet contour lumineux style COD

### Portail Interactif
- **Touche E** pour ouvrir/fermer le portail
- **Coute $1500** pour ouvrir (ouverture definitive, ne peut pas etre refermee)
- Les deux battants s'ouvrent avec une animation fluide (TweenService, 1.5s)
- ProximityPrompt centre sur le portail avec affichage du prix
- Fonctionne avec n'importe quel Model nomme "Gate" contenant "DoorCLoseL" et "DoorCloseR"
- **Positions relatives** : deplacer le portail dans Studio ne casse rien

### Map & Decor
- Les objets de decor transparents (brouillard, effets visuels) ne bloquent plus les balles
- Collision correcte : le joueur peut traverser les decors non-solides
- Map "lucas 2" avec portail

### Armes disponibles

| Arme | Prix | Degats | Cadence | Chargeur | Portee |
|------|------|--------|---------|----------|--------|
| Couteau | 0$ | 35 | 120 RPM | -- | 8 |
| Pistolet | 250$ | 15 | 300 RPM | 12 | 100 |
| SMG | 800$ | 12 | 600 RPM | 30 | 80 |
| Shotgun | 1500$ | 50x8 | 90 RPM | 8 | 30 |
| AK-47 | 2500$ | 25 | 450 RPM | 30 | 120 |
| Sniper | 4000$ | 100 | 40 RPM | 5 | 300 |
| Lance-flammes | 6000$ | 8/tick | continu | 100 | 25 |

---

## Architecture Technique

| Fichier | Role |
|---------|------|
| `src/client/InputController.client.lua` | Tir, rechargement, switch d'armes, bras FPS, raycast |
| `src/server/EconomyManager.server.lua` | Degats + argent (serveur autoritaire) |
| `src/server/GameInit.server.lua` | Init joueur : armes, slots, munitions |
| `src/server/ShopManager.server.lua` | Boutique : armes, consommables |
| `src/server/WallBuyManager.server.lua` | Achat d'armes aux murs (detection auto des modeles) |
| `src/server/GateManager.server.lua` | Portails interactifs (ouverture/fermeture) |
| `src/client/HUDController.client.lua` | HUD : vie, argent, manche, munitions |
| `src/shared/WeaponConfig.lua` | Config armes (degats, cadence, prix, rotation, offset) |
| `src/shared/ZombieConfig.lua` | Config zombies (PV, vitesse, recompense) |

---

## Utilisation de `muzzle_fix.lua`

Si le flash de ton arme ne part pas du bout du canon :
1. Copie le contenu de `game/muzzle_fix.lua`
2. Colle-le dans la **Barre de commande** de Roblox Studio
3. Appuie sur **Entree**
4. Relance le jeu (F5)

---

## Guide pour ton frere (Collaboration)

Pour que ton frere puisse travailler sur le jeu, il doit suivre ces etapes :

1. **Telecharger le projet** : Il doit faire un `git clone` du depot GitHub sur son ordinateur.
2. **Ouvrir le jeu** : Il doit ouvrir le fichier **`Zombies Waves.rbxl`** qui se trouve a la racine du dossier. C'est la map et tous les objets du jeu.
3. **Installer Rojo** :
   - Il doit avoir l'extension Rojo dans son Visual Studio Code.
   - Il doit avoir le plugin Rojo dans son Roblox Studio.
4. **Synchroniser le code** :
   - Dans un terminal (dans le dossier `game/`), il tape : `rojo serve`
   - Dans Roblox Studio, il clique sur le bouton **Connect** du plugin Rojo.
5. **Travailler ensemble** :
   - Quand il change un script, il doit faire un `git commit` et `git push`.
   - Toi, tu devras faire un `git pull` pour voir ses changements, et vice-versa !

---

## Comment ajouter un Wall Buy sur la map

1. Dans Roblox Studio, ouvre le dossier `WallBuys` dans Workspace (il est cree automatiquement)
2. Place le modele ou objet de ton choix dans ce dossier
3. Renomme-le en `WallBuy_NomArme` :
   - `WallBuy_Pistol` (250$)
   - `WallBuy_SMG` (800$)
   - `WallBuy_Shotgun` (1500$)
   - `WallBuy_AK47` (2500$)
   - `WallBuy_Sniper` (4000$)
   - `WallBuy_Flamethrower` (6000$)
4. Anchor toutes les Parts du modele (Anchored = true)
5. (Optionnel) Ajoute un **Highlight** pour un effet contour lumineux :
   - Insert Object > Highlight
   - OutlineColor = Blanc
   - FillTransparency = 1

---

## Lancer le projet

```bash
rojo serve game/default.project.json
```
Puis connecte le plugin **Rojo** dans Roblox Studio.

---

## Prochaines etapes suggerees
- [ ] Animations de bras (idle, tir, rechargement)
- [ ] Animation de marche zombie
- [ ] Perks (Juggernog, Speed Cola, Double Tap...)
- [ ] Pack-a-Punch (amelioration d'armes)
- [ ] Nouvelles armes avec leurs modeles 3D
- [ ] Zones secretes et Easter Eggs sur la map
