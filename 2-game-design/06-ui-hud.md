# PRD 06 — UI & HUD — Zombie Waves

---

## HUD principal (en jeu)

```
┌──────────────────────────────────────────────────────┐
│ [❤ Barre de vie]                    MANCHE 5         │
│ [vert > orange > rouge]                              │
│                                                      │
│                                                      │
│                   ZONE DE JEU                        │
│                                                      │
│                                                      │
│                                                      │
│ [$1250]                              [AK-47 30/90]   │
│ [Minimap alliés]                     [Munitions]     │
└──────────────────────────────────────────────────────┘
```

### Éléments du HUD

| Élément | Position | Toujours visible ? | Info affichée |
|---------|----------|-------------------|---------------|
| Barre de vie | Haut-gauche | Oui | HP actuel (couleur dynamique vert→orange→rouge) |
| Numéro de manche | Haut-centre | Oui | "MANCHE X" en gros |
| Solde argent ($) | Bas-gauche | Oui | Montant en temps réel avec icône 💰 |
| Munitions | Bas-droite | Oui | "[chargeur actuel] / [réserve]" + nom arme |
| Minimap | Bas-gauche (sous $) | Oui | Positions des alliés (points colorés) |
| Classe | Haut-gauche (sous vie) | Oui | Icône + nom de la classe |

---

## Écrans & Menus

### Arborescence

```
Lobby
├── Sélection de classe (4 boutons)
├── Vote Hardcore (bouton toggle)
├── Shop
│   ├── Armes
│   ├── Skins
│   └── Consommables
├── Leaderboard (panneau physique)
└── Bouton JOUER

En jeu
├── HUD (permanent)
├── Notification manche terminée (popup 3s)
├── Notification bonus (popup 3s)
├── Écran de mort
│   ├── Stats de la partie
│   └── Bouton Rejouer / Quitter
└── Panneau Game Over (mode hardcore)
```

---

## Notifications & Popups

| Notification | Quand | Durée | Position | Style |
|-------------|-------|-------|----------|-------|
| Manche terminée | Fin de vague | 3s | Centre | Grand texte doré, animation scale |
| Bonus obtenu | Après manche | 3s | Centre | Icône + nom du bonus, fond coloré |
| Fonds insuffisants | Achat raté | 2s | Bas-centre | Texte rouge |
| Arme achetée | Achat réussi | 2s | Bas-centre | Texte vert |
| Boss incoming | Manche 5/10/15... | 3s | Centre | Texte rouge clignotant, son alarme |
| Joueur mort | HP = 0 | Jusqu'à respawn | Plein écran | Écran noir semi-transparent, texte blanc |

---

## Thème visuel UI

| Propriété | Choix |
|-----------|-------|
| Style | Militaire / Post-apocalyptique |
| Couleur primaire | #1a1a2e (noir bleuté) |
| Couleur secondaire | #e94560 (rouge danger) |
| Couleur accent | #0f3460 (bleu foncé) |
| Couleur argent | #f5c518 (or) |
| Typographie | GothamBold (Roblox) |
| Coins des boutons | Arrondis (8px UICorner) |
| Animations | Subtiles — TweenService pour apparition/disparition |

---

## Questions clés

- [x] Le joueur peut-il trouver n'importe quelle info en 2 clics max ? → Oui
- [x] Le HUD ne surcharge pas l'écran ? → Non, 4 éléments principaux bien placés
- [x] Les boutons sont assez gros pour le tactile ? → Oui, UICorner + taille min 48px
- [x] Les notifications sont visibles mais pas intrusives ? → Oui, 2-3s auto-dismiss
