# PRD 07 — Social — Zombie Waves

---

## Mode multijoueur

| | Détail |
|---|--------|
| **Type** | Coopératif (PvE) |
| **Joueurs** | 1 à 4 joueurs par serveur |
| **Matchmaking** | Serveur public ou privé (invite) |
| **Communication** | Chat Roblox natif (TextChatService) |

---

## Système de classes (élément social)

Les 4 classes créent des synergies naturelles qui encouragent la coopération :

| Classe | Rôle social | Synergie |
|--------|------------|----------|
| Soldier | DPS principal | Se concentre sur le kill |
| Medic | Support | Soigne les alliés à portée (15 studs, 5 PV/s) |
| Tank | Frontline | Absorbe les dégâts, protège l'équipe |
| Scout | Éclaireur / Farmer | Rapide, gagne 2x argent pour ouvrir les portes |

**Composition idéale :** 1 Soldier + 1 Medic + 1 Tank + 1 Scout

---

## Interactions sociales

| Interaction | Mécanisme |
|------------|-----------|
| Acheter une porte | Un joueur paie, tous en bénéficient |
| Heal (Medic) | Automatique dans le rayon — encourage la proximité |
| Bonus Heal All | Soigne toute l'équipe |
| Boss kill | Récompense partagée (500$ à tous) |
| Vote Hardcore | Unanimité requise — discussion nécessaire |

---

## Leaderboard global

- Sauvegardé via DataStoreService
- Top 10 affiché sur panneau au Lobby
- Catégories : Meilleure manche, Zombies tués, Argent total gagné

---

## Questions clés

- [x] Le multijoueur ajoute-t-il du fun ? → Oui, synergie de classes
- [x] Un joueur solo peut-il s'amuser ? → Oui, le jeu est complet en solo
- [x] Les interactions sociales sont-elles naturelles ? → Oui, portes partagées, heal aura
