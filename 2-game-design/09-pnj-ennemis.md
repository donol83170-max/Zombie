# PRD 09 — PNJ & Ennemis — Zombie Waves

---

## Types d'ennemis

### Zombie Basique

| | Détail |
|---|--------|
| **PV** | 100 + (manche × 10) |
| **Vitesse** | 12 studs/s |
| **Dégâts** | 10 par seconde au contact |
| **Récompense** | 10$ par hit |
| **Apparition** | Dès manche 1 |
| **IA** | PathfindingService vers le joueur le plus proche |
| **Mort** | Animation de chute + son + disparition après 3s |

### Zombie Rapide

| | Détail |
|---|--------|
| **PV** | 50 |
| **Vitesse** | 24 studs/s (2x normal) |
| **Dégâts** | 10 par seconde au contact |
| **Récompense** | 20$ |
| **Apparition** | Dès manche 5, aléatoire |
| **Visuel** | Plus petit, posture courbée, traînée de vitesse |

### Zombie Tank

| | Détail |
|---|--------|
| **PV** | 500 |
| **Vitesse** | 4 studs/s (3x plus lent) |
| **Dégâts** | 25 par seconde au contact |
| **Récompense** | 100$ |
| **Apparition** | Dès manche 5, aléatoire |
| **Visuel** | Taille x2 (Scale), plus massif |

### Zombie Explosif

| | Détail |
|---|--------|
| **PV** | 75 |
| **Vitesse** | 14 studs/s |
| **Dégâts** | 50 (explosion rayon 10 studs quand < 5 studs du joueur) |
| **Récompense** | 50$ |
| **Apparition** | Dès manche 5, aléatoire |
| **Visuel** | Lueur verdâtre/orangée, particules toxiques |

---

## Boss

| | Détail |
|---|--------|
| **PV** | 2000 + (manche × 200) |
| **Vitesse** | 10 studs/s (Phase 1), 15 (Phase 2) |
| **Apparition** | Toutes les 5 manches |
| **Récompense** | 500$ à tous les joueurs |
| **Visuel** | Taille x3, aura rouge, barre de vie visible |

### Phases du Boss

| Phase | Condition | Comportement |
|-------|-----------|-------------|
| Phase 1 | 100% - 60% PV | Normal — marche vers le joueur le plus proche |
| Phase 2 | 60% - 30% PV | Vitesse x1.5, attaques plus rapides |
| Phase 3 | 30% - 0% PV | Invoque 5 zombies basiques toutes les 10 secondes |

---

## Spawn des ennemis

| | Détail |
|---|--------|
| **Points de spawn** | 4 par zone, aux extrémités |
| **Formule spawns** | 5 + (manche × 3) zombies par manche |
| **Spawn rate** | 1 zombie toutes les 0.5-1.5 secondes |
| **Zombies spéciaux** | 20% chance de remplacement dès manche 5 |
| **Distribution spéciaux** | 40% Rapide, 30% Tank, 30% Explosif |

---

## Questions clés

- [x] Chaque ennemi a-t-il un rôle gameplay distinct ? → Oui, vitesse/tank/AoE/boss
- [x] Le joueur peut-il différencier les types visuellement ? → Oui, taille + couleur + effets
- [x] L'IA est-elle prévisible mais dangereuse ? → Oui, pathfinding direct
- [x] Les boss sont-ils mémorables ? → Oui, 3 phases distinctes
