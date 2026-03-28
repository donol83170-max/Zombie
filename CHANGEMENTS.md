# 📜 CHANGEMENTS RÉCENTS (Changelog)

Ce fichier liste toutes les améliorations de confort de jeu et de débuggage apportées au moteur de base après les premiers tests en conditions réelles sur Roblox Studio.

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
