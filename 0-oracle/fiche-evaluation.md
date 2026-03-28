# Fiche d'évaluation — Zombie Waves

> Date : 2026-03-28
> Auteur(s) de l'idée : DL

---

## Pitch (1-2 phrases)

Survis le plus longtemps possible contre des vagues infinies de zombies de plus en plus puissants, en achetant des armes, débloquant des zones et coopérant avec jusqu'à 3 amis.

## Genre & Références

- **Genre principal :** Survie / Zombie Wave Defense
- **Jeux de référence :** Call of Duty Zombies (Treyarch), Project Lazarus (Roblox), Zombie Attack (Roblox)
- **Twist :** Système de classes/rôles (Soldier, Medic, Tank, Scout) + économie en temps réel + boss multi-phases + mode Hardcore à vote unanime

---

## Scoring

### FUN (/25)

| Critère | Score | Justification |
|---------|-------|---------------|
| Core loop addictif | 8/8 | Tuer → Argent → Acheter → Survivre plus longtemps. Boucle immédiate et satisfaisante. |
| Rejouabilité | 6/6 | Classes différentes, bonus aléatoires, mode hardcore, manches infinies. |
| Originalité | 4/5 | Les classes + bonus aléatoires ajoutent de la variété au genre classique. |
| Moment "wow" | 2/3 | Premier boss à la manche 5, Nuke bonus. |
| Flow/Rythme | 3/3 | Alternance parfaite : combat intense → achat/repos → combat plus dur. |
| **TOTAL FUN** | **23/25** | |

### MARCHÉ (/25)

| Critère | Score | Justification |
|---------|-------|---------------|
| Popularité du genre | 7/7 | Les jeux de zombies sont un evergreen sur Roblox. |
| Concurrence | 4/6 | Zombie Attack, Project Lazarus existent mais sont améliorables. |
| Recherche/Découverte | 5/5 | "zombie" est un terme très recherché sur Roblox. |
| Public cible clair | 4/4 | Joueurs 10-18 ans qui aiment le FPS et la coopération. |
| Timing | 3/3 | Le genre ne se démode jamais. |
| **TOTAL MARCHÉ** | **23/25** | |

**Top 5 concurrents :**

| Jeu | CCU estimé | Likes ratio | Force | Faiblesse |
|-----|-----------|-------------|-------|-----------|
| Zombie Attack | 5K+ | 90%+ | Simple, amusant | Répétitif, pas de profondeur |
| Project Lazarus | 1K+ | 85%+ | Fidèle à CoD Zombies | Vieillissant, UI datée |
| Those Who Remain | 2K+ | 80%+ | Atmosphère | Trop difficile pour casuals |

### FAISABILITÉ (/25)

| Critère | Score | Justification |
|---------|-------|---------------|
| Complexité technique | 5/8 | 14 systèmes à coder — complexité élevée mais gérable. |
| Assets nécessaires | 4/6 | Zombies, armes, map multi-zones — besoin de modèles. |
| Taille équipe | 4/5 | Faisable en solo avec IA assistée. |
| Compétences requises | 3/3 | Luau maîtrisé, PathfindingService connu. |
| Temps au MVP | 3/3 | MVP jouable en 3-4 semaines. |
| **TOTAL FAISABILITÉ** | **19/25** | |

**Systèmes techniques identifiés :**
1. Wave Manager
2. Economy System
3. Wall Buys
4. Basic Zombie AI
5. Zombies Spéciaux (3 types)
6. Boss System (multi-phases)
7. Bonus Aléatoires
8. Classes / Rôles
9. Door System
10. Mode Hardcore
11. Leaderboard (DataStore)
12. Shop Principal
13. Map Multi-Zones
14. HUD Interface

### MONÉTISATION (/25)

| Critère | Score | Justification |
|---------|-------|---------------|
| Game Passes naturels | 7/8 | VIP (2x argent), Extra Life, Classe exclusive — naturels et non pay-to-win. |
| Developer Products | 6/6 | Revive, Pack de dollars, Skip wave — achats répétables logiques. |
| Retention → Monétisation | 5/5 | Plus le joueur avance, plus il a envie de Game Passes pour battre son record. |
| Prix acceptable | 3/3 | 99-499 Robux pour Game Passes, 25-99 pour Dev Products. |
| Éthique | 3/3 | Tout est obtenable sans payer, les achats sont des accélérateurs. |
| **TOTAL MONÉTISATION** | **24/25** | |

**Idées de Game Passes :**
- [x] VIP Pass — 2x argent tous les rounds (299 Robux)
- [x] Extra Life — 1 revive gratuit par partie (149 Robux)
- [x] Starter Pack — Commence avec SMG + 500$ (99 Robux)

**Idées de Developer Products :**
- [x] Revive instantané (49 Robux)
- [x] 1000$ in-game (25 Robux)

---

## SCORE TOTAL : 89/100

## Verdict : GO

### Points forts
- Core loop ultra satisfaisant et prouvé (genre zombie waves)
- Rejouabilité massive grâce aux classes, bonus aléatoires et mode hardcore
- Monétisation naturelle et éthique
- Public cible large et demande constante

### Points faibles
- 14 systèmes → complexité de dev élevée
- Besoin d'assets 3D (modèles zombies, armes, map)
- Concurrence existante (mais améliorable)

### Conditions pour passer en Phase 1
- ✅ Score > 75 → GO confirmé

---

## Notes libres

La combinaison classes + bonus aléatoires + boss multi-phases est ce qui différencie ce jeu des concurrents. Le mode Hardcore avec vote unanime est un excellent hook social.
