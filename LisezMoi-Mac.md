# 🚀 Guide d'installation — Zombie Waves (Mac)

Bienvenue dans le projet **Zombie Waves** ! Pour qu'on puisse travailler ensemble sur le code du jeu sans s'écraser, on utilise **GitHub** et **Rojo**. 

Voici comment tout configurer sur ton Mac :

---

## 🛠️ Étape 1 : Installer les outils nécessaires

Ouvre ton application **Terminal** (tu peux la trouver via Spotlight 🔍) et prépare ton Mac pour le dev Roblox.

### 1. Installer Git (si tu ne l'as pas)
Dans ton terminal, tape cette commande pour voir si Git est installé :
```bash
git --version
```
*Si un message te propose d'installer les "Command Line Tools", accepte et attends la fin de l'installation.*

### 2. Installer Rokit (le gestionnaire de plugins Roblox)
Copie-colle cette ligne dans ton terminal et fais "Entrée" :
```bash
curl -fsSL https://raw.githubusercontent.com/rojo-rbx/rokit/main/install.sh | sh
```
*Ferme ton terminal et rouvre-le pour que l'installation soit prise en compte.*

---

## 📥 Étape 2 : Récupérer le code du jeu

Dans ton terminal, place-toi dans le dossier où tu veux ranger les projets (par exemple tes Documents) :
```bash
cd ~/Documents
```

Maintenant, clone le projet depuis GitHub :
```bash
git clone https://github.com/donol83170-max/Zombie.git
```
Puis, rentre dans le dossier du jeu :
```bash
cd Zombie/game
```

---

## ⚙️ Étape 3 : Configurer Rojo le projet

Maintenant que tu as le code, dis à Rokit d'installer **Rojo** pour ce projet spécifique :
```bash
rokit init
rokit add rojo-rbx/rojo
```

---

## 🎮 Étape 4 : Travailler sur Roblox Studio !

### Côté Terminal
À chaque fois que tu veux programmer ou tester le jeu, ouvre un terminal dans `Zombie/game` et tape :
```bash
rojo serve
```
*Le terminal va afficher `Rojo server listening`. Ne le ferme pas, il reste en arrière-plan pour synchroniser notre code.*

### Côté Roblox Studio
1. Ouvre **Roblox Studio**.
2. Va dans le **Creator Marketplace** (Toolbox) et cherche le plugin **Rojo** pour l'ajouter à tes plugins.
3. Ouvre la map du jeu (ou un Baseplate vide si on teste juste le code).
4. En haut, clique sur l'onglet **Plugins** → **Rojo** → **Connect**.
5. ✅ Tous nos scripts vont apparaître comme par magie dans la fenêtre `Explorer` !

---

## 🤝 Étape 5 : Comment coder ensemble sans conflit ?

Puisqu'on est à deux sur le projet, prends ce rythme :

**1. Avant de commencer à bosser (IMPORTANT) :**
Toujours récupérer mes modifications pour être à jour !
```bash
git pull
```

**2. Pendant que tu bosses :**
Tes modifications dans les fichiers `.lua` (sur VS Code ou un autre éditeur) seront envoyées en direct sur Roblox Studio grâce à Rojo.

**3. Quand tu as fini :**
On envoie tes modifications sur GitHub pour que je puisse les récupérer. Traverse ces 3 commandes magiques :
```bash
git add -A
git commit -m "Explication de ce que j'ai fait"
git push
```

Amuse-toi bien ! 🧟‍♂️
