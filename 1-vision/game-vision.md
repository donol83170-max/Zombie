# Vision du Jeu — Zombie Waves

> Date : 2026-03-28
> Statut : VALIDÉ

---

## Elevator Pitch

> C'est un jeu où tu survis à des vagues infinies de zombies de plus en plus mortels, en achetant des armes aux murs, débloquant de nouvelles zones et coopérant avec tes amis pour battre des boss épiques.

---

## Core Loop (en une phrase)

> TUER des zombies → GAGNER de l'argent → ACHETER des armes et ouvrir des portes → SURVIVRE à des vagues plus difficiles → recommencer

---

## Les 3 boucles de gameplay

### Boucle Micro (30 secondes - 2 minutes)
Le joueur tire sur les zombies qui arrivent, esquive les attaques, ramasse l'argent des kills, et achète des armes ou consommables quand il en a besoin. Chaque zombie tué = feedback immédiat ($10 + son de hit).

### Boucle Session (10 - 30 minutes)
Le joueur essaie de survivre le plus de manches possible. Il progresse à travers les zones (Rue → Labo → Usine), affronte des boss toutes les 5 manches, gère ses ressources (argent, munitions, vie) et reçoit un bonus aléatoire entre chaque manche.

### Boucle Méta (jours - semaines)
Le joueur revient pour battre son record de manches, essayer d'autres classes, tenter le mode Hardcore, grimper dans le leaderboard, et débloquer les badges (Hardcore Survivor, Boss Slayer, etc.).

---

## Genre & Références

| | Détail |
|---|--------|
| **Genre principal** | Survie / Wave Defense |
| **Sous-genre** | Zombie Shooter coopératif |
| **Référence 1** | Call of Duty Zombies — On prend : wall buys, portes, économie. On change : plus de variété de bonus et classes. |
| **Référence 2** | Project Lazarus (Roblox) — On prend : le concept CoD Zombies sur Roblox. On change : UI moderne, boss system, classes. |
| **Référence 3** | Left 4 Dead — On prend : coopération intense, zombies spéciaux. On change : mode vagues au lieu de campagne linéaire. |

---

## Public cible

| | Détail |
|---|--------|
| **Tranche d'âge** | 10-18 ans |
| **Type de joueur** | Mid-core |
| **Profil** | Joueurs qui aiment les FPS coopératifs et le challenge progressif |
| **Temps de session visé** | 15-30 min |
| **Solo / Multi / Les deux** | Les deux (1-4 joueurs) |

---

## USP — Unique Selling Point

> Pourquoi un joueur choisirait CE jeu plutôt qu'un autre du même genre ?

1. **Système de classes** — 4 rôles avec synergies (Soldier/Medic/Tank/Scout) pour un vrai jeu d'équipe
2. **Boss multi-phases** — Boss épiques toutes les 5 manches avec 3 phases distinctes
3. **Bonus aléatoires** — Chaque fin de manche apporte un bonus surprise (Nuke, Double Money, Heal, etc.)

**Le "hook" en une phrase :** Dès la manche 1, tu tires, tu gagnes de l'argent, tu achètes une arme au mur — la boucle est immédiate et addictive.

---

## Ambiance & Mood

| | Choix |
|---|-------|
| **Ton** | Fun-épique avec tension croissante |
| **Palette couleurs** | Sombre avec accents néon rouge/vert toxique |
| **Style 3D** | Roblox stylisé — low-poly avec effets de lumière |
| **Musique** | Électro-dark / rock intense pendant les vagues, calme entre les manches |
| **Ambiance générale** | Survie post-apocalyptique urbaine — rue abandonnée, laboratoire sinistre, usine rouillée. Atmosphère oppressante qui s'intensifie à chaque manche. |

---

## Scope

### MVP (Version 1 — jouable)
> Le strict minimum pour que le jeu soit jouable et fun

- [x] Wave Manager (manches infinies)
- [x] Zombie basique (IA Pathfinding)
- [x] Economy System (argent par kill)
- [x] Wall Buys (4 armes)
- [x] HUD (vie, argent, manche, munitions)
- [x] Map Zone 1 (Rue abandonnée)
- [x] DataStore (sauvegarde stats)

### Version Complète
> Tout ce qu'on veut dans la version finale

- [x] Tout le MVP +
- [ ] Zombies spéciaux (Rapide, Tank, Explosif)
- [ ] Boss System (multi-phases)
- [ ] Door System (3 zones)
- [ ] 4 Classes joueur
- [ ] Bonus aléatoires (5 types)
- [ ] Shop complet (3 onglets)
- [ ] Mode Hardcore
- [ ] Leaderboard top 10

### Post-Launch (idées futures)
- [ ] Nouvelles maps (Hôpital, Centre commercial, Métro)
- [ ] Nouveaux types de zombies (Zombie Invisible, Zombie Guérisseur)
- [ ] Événements saisonniers (Halloween, Noël)
- [ ] Système de prestige / rebirth
- [ ] Armes légendaires avec effets spéciaux

---

## Risques identifiés

| Risque | Impact | Mitigation |
|--------|--------|------------|
| Trop de systèmes pour le MVP | Haut | MVP réduit à Zone 1 + zombie basique + wall buys |
| Pathfinding lent avec beaucoup de zombies | Moyen | Limiter à 30 zombies simultanés, pooling |
| Exploitation/triche (argent infini) | Haut | Toute l'économie est serveur-side, validation stricte |
| Balancing des classes déséquilibré | Moyen | Playtesting itératif, ajustement via GameConfig |

---

## Validation

- [x] Le pitch est clair et donne envie
- [x] Le core loop est identifié et semble fun
- [x] Le public cible est précis
- [x] L'USP est convaincant
- [x] Le scope MVP est réaliste
- [x] L'ambiance est cohérente avec le gameplay

**Validé par :** DL — **Date :** 2026-03-28
