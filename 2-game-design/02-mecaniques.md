# PRD 02 — Mécaniques de jeu — Zombie Waves

> Chaque mécanique détaillée : comment ça marche exactement.

---

## Liste des mécaniques

| # | Mécanique | Catégorie | Priorité MVP |
|---|-----------|-----------|-------------|
| 1 | Déplacement | Mouvement | Oui |
| 2 | Tir / Combat | Combat | Oui |
| 3 | Achat Wall Buy | Économie | Oui |
| 4 | Ouverture de porte | Exploration | Oui |
| 5 | Sélection de classe | Social | Non |
| 6 | Achat Shop | Économie | Non |
| 7 | Vote Hardcore | Social | Non |

---

## Détail par mécanique

### Mécanique : Tir / Combat

**Résumé :** Le joueur tire sur les zombies avec son arme équipée pour les éliminer et gagner de l'argent.

**Inputs joueur :**
| Input | Action | Plateforme |
|-------|--------|-----------|
| Clic gauche / maintenu | Tirer | PC |
| Bouton Tir | Tirer | Mobile |
| RT / R2 | Tirer | Manette |
| R | Recharger | PC |

**Comportement :**
1. Quand le joueur clique → le client envoie `RequestShoot` au serveur
2. Le serveur vérifie : a-t-il des munitions ? le cooldown est-il terminé ?
3. Si OK → Raycast depuis l'arme, détecte les hits, applique les dégâts serveur-side
4. Si KO → Feedback "pas de munitions" / attend le cooldown

**Règles :**
- Chaque arme a sa cadence de tir (RPM), ses dégâts et son chargeur
- Les dégâts sont calculés côté serveur uniquement
- Le rechargement prend un temps fixe par arme

**Feedback :**
- Visuel : flash de tir, impact sur le zombie, particules
- Sonore : son de tir unique par arme, son d'impact, son de rechargement
- UI : compteur munitions qui descend, +$10 qui pop au kill

### Mécanique : Achat Wall Buy

**Résumé :** Le joueur s'approche d'un panneau mural pour acheter une arme avec ProximityPrompt.

**Comportement :**
1. Le joueur s'approche du panneau (< 8 studs)
2. ProximityPrompt apparaît : "Acheter [Arme] — $[Prix]"
3. Le joueur active le prompt → serveur vérifie les fonds
4. Si OK → l'arme est donnée, l'argent déduit
5. Si KO → message "Fonds insuffisants !"

**Règles :**
- On peut acheter la même arme plusieurs fois (recharge les munitions)
- L'arme remplace l'arme actuelle (1 arme à la fois)

### Mécanique : Ouverture de porte

**Résumé :** Le joueur achète l'ouverture d'une porte pour accéder à une nouvelle zone.

**Comportement :**
1. ProximityPrompt sur la porte : "Ouvrir — $[Prix]"
2. Activation → serveur vérifie les fonds
3. Si OK → porte s'ouvre (Tween), zone débloquée pour tous les joueurs
4. Si KO → message "Fonds insuffisants !"

**Règles :**
- L'ouverture est permanente pour la partie entière
- Un seul joueur paie, tous en bénéficient
- Portes : 750$, 2000$, 5000$

---

## Contrôles complets

### PC

| Touche | Action |
|--------|--------|
| WASD / ZQSD | Mouvement |
| Espace | Saut |
| Clic gauche | Tirer |
| R | Recharger |
| E | Interagir (ProximityPrompt) |
| Tab | Ouvrir le shop |

### Mobile

| Geste | Action |
|-------|--------|
| Joystick virtuel | Mouvement |
| Bouton Tir | Tirer |
| Bouton Recharger | Recharger |
| Tap ProximityPrompt | Interagir |

---

## Formules de calcul

| Formule | Expression | Exemple |
|---------|-----------|---------|
| Zombies par manche | `5 + (manche × 3)` | Manche 5 = 20 zombies |
| PV zombie basique | `100 + (manche × 10)` | Manche 10 = 200 PV |
| PV Boss | `2000 + (manche × 200)` | Manche 10 = 4000 PV |
| Argent par hit | `10$` (fixe) | — |
| Argent par boss kill | `500$` (fixe, tous joueurs) | — |

---

## Questions clés

- [x] Chaque mécanique est-elle intuitive sans tutoriel ? → Oui, tirer + acheter = simple
- [x] Les contrôles sont-ils confortables sur TOUTES les plateformes ? → Oui, ProximityPrompt marche partout
- [x] Les formules sont-elles équilibrées ? → Testable et ajustable via GameConfig
- [x] Chaque mécanique a-t-elle un feedback clair ? → Oui, visuel + sonore + UI
