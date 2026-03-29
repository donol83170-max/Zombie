# 🧟 Zombie Waves — À LIRE

## ✅ Ce qui est implémenté et fonctionnel

### 🔫 Système de Combat (FPS)
- **Tir raycast** depuis la tête du joueur — les balles traversent le brouillard et les décors transparents
- **Arme exclue du raycast** — les balles ne touchent plus le modèle 3D de l'arme
- **Muzzle Flash** — le flash sort du bout du canon (attachement `MuzzleFlash` dans `Handle`)
- **Recul + Balancement** (Sway) de l'arme à chaque tir
- **Hitmarker sonore** quand un zombie est touché
- **Rechargement** : touche `R` à tout moment, hint "Appuyer sur R" quand le chargeur est vide

### 💰 Économie (Serveur-Autoritaire)
- **+10$** par tir au corps
- **+50$** par tir à la tête
- Validation côté serveur — anti-triche
- Fonctionne avec **tous les modèles de zombies** de la Toolbox (recherche récursive du Humanoid)

### 🧟 Zombies
- Nom obligatoire : `Enemy_XYZ` (ex : `Enemy_Basic`, `Enemy_Boss`)
- Les dégâts sont appliqués via `HumanoidRootPart:TakeDamage()`
- Vie évolutive selon la manche (config dans `ZombieConfig.lua`)

### 🗺️ Map & Décor
- Les objets de décor transparents (brouillard, effets visuels) ne bloquent plus les balles
- Collision correcte : le joueur peut traverser les décors non-solides

---

## ⚙️ Architecture Technique

| Fichier | Rôle |
|---------|------|
| `src/client/InputController.client.lua` | Tir, rechargement, arme FPS, raycast |
| `src/server/EconomyManager.server.lua` | Dégâts + argent (serveur autoritaire) |
| `src/client/HUDController.client.lua` | HUD : vie, argent, manche, munitions |
| `src/shared/WeaponConfig.lua` | Config armes (dégâts, cadence, prix) |
| `src/shared/ZombieConfig.lua` | Config zombies (PV, vitesse, récompense) |
| `game/muzzle_fix.lua` | Script utilitaire : repositionne le flash au bout du canon |

---

## 🔧 Utilisation de `muzzle_fix.lua`

Si le flash de ton arme ne part pas du bout du canon :
1. Copie le contenu de `game/muzzle_fix.lua`
2. Colle-le dans la **Barre de commande** de Roblox Studio
3. Appuie sur **Entrée**
4. Relance le jeu (F5)

---

## 🚀 Lancer le projet

```bash
# Dans le dossier game/
rojo serve
```
Puis connecte le plugin **Rojo** dans Roblox Studio.

---

## 📋 Prochaines étapes suggérées
- [ ] Perks (Juggernog, Speed Cola, Double Tap...)
- [ ] Pack-a-Punch (amélioration d'armes)
- [ ] Nouvelles armes avec leurs modèles 3D
- [ ] Zones secrètes et Easter Eggs sur la map
