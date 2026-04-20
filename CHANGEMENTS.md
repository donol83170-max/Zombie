# 📜 CHANGEMENTS RÉCENTS (Changelog)

Ce fichier liste toutes les améliorations de confort de jeu et de débuggage apportées au moteur de base après les premiers tests en conditions réelles sur Roblox Studio.

### 🗓️ Mise à jour 20/04/2026 — Quête map Kalu (Électricité & Garage)

Nouveau fichier : `game/src/server/ElectricalManager.server.lua`.

**Boîte électrique** (modèle `ElectricalBox` avec enfant `door` dans le workspace) :
- ProximityPrompt **gratuit** "Ouvrir" (touche E).
- La porte s'ouvre comme une porte classique — animation de CFrame tweenée entre la position fermée actuelle et une position ouverte définie dans le code.
- Le prompt d'ouverture est désactivé dès la première ouverture.

**Outil de réparation** (modèle `RepairTool` placé n'importe où dans le workspace) :
- ProximityPrompt "Ramasser" — ramasser pose l'attribut `HasRepairTool` sur le joueur et détruit le modèle.
- Aucun équipement nécessaire (pas de Tool hotbar), c'est juste un flag invisible sur le joueur.

**Réparation de l'électricité** :
- Quand la boîte est ouverte, un second ProximityPrompt "Réparer" (touche F) apparaît dessus.
- Déclenche sans l'outil → message d'erreur rouge.
- Avec l'outil → consomme le flag, appelle `_G.RepairElectricity(player)`, le prompt se désactive.

**Porte de garage** (modèle `Garage` avec enfant `garagedoor` BasePart) :
- Fermée par défaut.
- Bascule à 90° (style porte de garage basculante) quand l'électricité est réparée — tween entre les 2 CFrames fournis manuellement.

**API exposée** :
- `_G.RepairElectricity(player)` — ferme la boîte, ouvre le garage, diffuse le RemoteEvent `ElectricityRepaired` (dans `ReplicatedStorage.Events`) pour futurs effets client (sons, lumière, etc.).

### 🛠️ Configuration & Système (Rojo)
- **Protection de la Map** : Ajout de la propriété de sécurité `ignoreUnknownInstances` dans la config Rojo. L'outil ne supprimera plus jamais la géométrie, les modèles 3D, ou les interfaces ajoutés manuellement dans Roblox Studio.
- **Restauration de Rojo** : Suppression/Remplacement du vieux dossier Script pour que le serveur compile sans erreur.
- **Spawns Robustes** : Si le dossier `ZombieSpawns` est vidé par erreur, le script serveur n'abandonne plus mais génère 4 ponts de spawn d'urgence.

### 🧟 Zombies & Difficulté
- **Zombies customisés** : Le jeu accepte maintenant vos modèles de la Toolbox (glissez-les dans `ServerStorage > ZombieTemplates` et nommez-les `Enemy_Basic`, etc.).
- **Désancrage Auto** : Sécurité ajoutée pour retirer automatiquement le statut "Anchored" des modèles de la Toolbox, pour garantir que les zombies puissent bouger.
- **Horde IA (Collisions)** : Implémentation de *PhysicsService CollisionGroups*. Les zombies se traversent entre eux sans se bloquer et ne se superposent plus (ils ne se montent plus sur la tête), rendant la poursuite terrifiante.
- **Vitesse progressive** : Les zombies sont beaucoup plus lents à la Manche 1 (60% de leur vitesse normale), et accélèrent progressivement pour atteindre leur vitesse maximale à la Manche 5.

### 🎮 Gameplay Joueur
- **Caméra FPS** : La caméra est désormais verrouillée à la première personne (`LockFirstPerson`).
- **Buff de Vitesse (+10%)** : La vitesse de déplacement de base passe de 16 à **17.6**. Les multiplicateurs de classe (ex: Scout rapide, Tank lent) se basent mathématiquement sur cette nouvelle vitesse.
- **Anti-OneShot (I-Frames)** : Implémentation d'une "fenêtre d'invincibilité" d'une seconde. Même si 8 zombies vous attaquent en même temps, vous ne recevrez qu'un seul coup par seconde.
- **Calcul Mortel** : Dégâts basiques bloqués à 25/hit (il faut exactement 4 coups successifs pour tomber à 0 PV depuis 100 PV).

### 🖥️ Interace / HUD
- **Décompte Lobby (15s)** : Le jeu ne démarre plus la Manche 1 instantanément. Un décompte visuel de 15 secondes au milieu de l'écran laisse à tous les joueurs le temps de choisir leur classe.
- **Effet de Sang (Damage Flash)** : L'écran flashe momentanément en rouge transparent avec une animation fluide dès qu'un joueur subit des dégâts.

### 🗓️ Mise à jour 28/03 (Soirée)
- **Menu Classe Fixé** : Affichage instantané du menu au lancement du jeu pour contrer les bugs de chargement Roblox (`Race Condition`).
- **Souris Intelligente (Modal)** : Le pointeur de la souris se débloque automatiquement pendant la sélection, puis disparaît et verrouille le joueur en FPS une fois la partie lancée.
- **Nettoyage Automatique** : Les vieux scripts Roblox parasites de la Toolbox intégrés dans les modèles de zombies sont maintenant systématiquement purgés pour ne pas faire crasher le serveur.
- **Vent & Herbe** : Activation du `GlobalWind` pour animer physiquement et aléatoirement l'herbe du Terrain 3D de Roblox.
- **Répartition Zombies Parfaite** : Application de l'algorithme `Fisher-Yates` avec le nouveau `Random.new()` de Roblox. Le spawn des hordes assure une distribution chronologique mathématiquement parfaite sur l'ensemble des plateformes créées (plus de zombies empilés sur une seule plateforme).
