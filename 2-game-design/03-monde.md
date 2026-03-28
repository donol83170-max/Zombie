# PRD 03 — Monde & Map — Zombie Waves

---

## Vue d'ensemble

**Type de monde :** Semi-ouvert (zones verrouillées par portes)
**Taille estimée :** Moyenne
**Nombre de zones :** 3 zones + Lobby
**Style général :** Post-apocalyptique urbain — sombre, béton, néons cassés, végétation envahissante

---

## Carte des zones

```
[Lobby — Sélection classe/mode]
         │
    ┌────┘
    ▼
[Zone 1 — Rue Abandonnée] ← Spawn de départ
    │     Wall Buys : Pistolet (gratuit), Shotgun (1500$)
    │     Porte : 750$
    ▼
[Zone 2 — Laboratoire]
    │     Wall Buys : AK-47 (2500$), SMG (800$)
    │     Zombies spéciaux dès manche 5
    │     Porte : 2000$
    ▼
[Zone 3 — Usine]
          Wall Buys : Sniper (4000$), Lance-flammes (6000$)
          Zone Boss — arène de combat
```

---

## Détail par zone

### Zone : Lobby

| | Détail |
|---|--------|
| **Thème** | Salle d'attente militaire |
| **Ambiance** | Lumineux, calme, sécurisé |
| **Taille** | Petite |
| **Accès** | Libre (point d'entrée) |
| **Fonction gameplay** | Sélection de classe, vote hardcore, leaderboard, shop |

### Zone : Zone 1 — Rue Abandonnée

| | Détail |
|---|--------|
| **Thème** | Rue de ville abandonnée, voitures retournées, réverbères cassés |
| **Ambiance** | Sombre, ouvert, dangereux |
| **Taille** | Moyenne |
| **Accès** | Libre (zone de départ en jeu) |
| **Fonction gameplay** | Premières manches, premiers wall buys, apprentissage |

**Contenu :**
- Ennemis : Zombies basiques uniquement (manches 1-4)
- Wall Buys : Pistolet (gratuit), Shotgun (1500$)
- Points d'intérêt : Barricades, voitures retournées (couverture)
- Spawn zombies : 4 points aux extrémités de la rue

### Zone : Zone 2 — Laboratoire

| | Détail |
|---|--------|
| **Thème** | Laboratoire souterrain, tubes brisés, lumière verte toxique |
| **Ambiance** | Claustrophobe, dangereux, scientifique |
| **Taille** | Moyenne |
| **Accès** | Porte 750$ depuis Zone 1 |
| **Fonction gameplay** | Zombies spéciaux, meilleures armes |

**Contenu :**
- Ennemis : Zombies spéciaux (Rapide, Tank, Explosif) dès manche 5
- Wall Buys : AK-47 (2500$), SMG (800$)
- Points d'intérêt : Tables de labo, cellules de confinement

### Zone : Zone 3 — Usine

| | Détail |
|---|--------|
| **Thème** | Usine rouillée, machines industrielles, flammes |
| **Ambiance** | Oppressant, bruyant (ambiance), dangereux |
| **Taille** | Grande |
| **Accès** | Porte 2000$ depuis Zone 2 |
| **Fonction gameplay** | Armes top-tier, arène boss |

**Contenu :**
- Ennemis : Tous types + Boss
- Wall Buys : Sniper (4000$), Lance-flammes (6000$)
- Points d'intérêt : Arène boss (espace ouvert central), plateforme surélevée

---

## Spawn & Respawn

- **Spawn initial :** Zone 1 — Rue Abandonnée (centre)
- **Respawn après mort :** Même position après 5 secondes (mode normal) / Pas de respawn (mode hardcore)
- **Respawn ennemis :** Contrôlé par WaveManager, spawn aux points par zone
- **Sauvegarde position :** Non — chaque partie repart de zéro

---

## Questions clés

- [x] Le joueur sait toujours où il est et où aller ? → Oui, progression linéaire Zone 1→2→3
- [x] Chaque zone a une raison gameplay d'exister ? → Oui, armes + ennemis + difficulté
- [x] La navigation est fluide ? → Oui, portes clairement marquées avec prix
- [x] Le monde est assez grand sans être vide ? → Oui, 3 zones de taille moyenne
