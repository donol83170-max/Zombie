# PRD 04 — Progression — Zombie Waves

---

## Système de progression

> Zombie Waves n'a pas de système de niveaux classique. La progression se fait **par manche** au sein d'une partie, et **par statistiques sauvegardées** entre les parties.

| | Détail |
|---|--------|
| **Progression en partie** | Numéro de manche atteint |
| **Progression globale** | Record de manches, zombies tués total, argent gagné total |
| **Sources de progression** | Manches survivées, boss tués, zones débloquées |
| **Affichage** | Numéro de manche (HUD), stats dans leaderboard |

---

## Courbe de difficulté

```
Difficulté
  ▲
  │                           ★Boss15   ╱
  │                    ★Boss10  ╱╱╱╱╱╱
  │              ★Boss5  ╱╱╱╱╱
  │           ╱╱╱╱╱╱╱╱
  │       ╱╱╱╱
  │   ╱╱╱
  │ ╱╱
  │╱
  └────────────────────────────────────> Manches
  1    5     10     15     20     25+
```

- **Manches 1-4 :** Facile — zombies basiques, pistolet suffit, apprentissage
- **Manches 5-9 :** Moyen — zombies spéciaux apparaissent, premier boss, besoin d'armes meilleures
- **Manches 10-14 :** Difficile — zombies tankés, gestion des munitions critique
- **Manches 15-19 :** Très difficile — multiples types simultanés, boss dangereux
- **Manches 20+ :** Hardcore — survie pure, seuls les meilleurs y arrivent

---

## Déverrouillages en partie

| Type | Ce qui se débloque | Comment |
|------|-------------------|---------|
| Zones | Zone 2, Zone 3 | Argent (portes) |
| Armes | Shotgun, AK-47, Sniper, etc. | Argent (wall buys / shop) |
| Ennemis | Zombies spéciaux | Manche 5+ |
| Boss | Boss multi-phases | Toutes les 5 manches |
| Bonus | Bonus aléatoires | Fin de chaque manche |

---

## Achievements / Badges Roblox

| Badge | Condition | Difficulté |
|-------|-----------|------------|
| First Blood | Tuer son premier zombie | Facile |
| Wave 10 | Atteindre la manche 10 | Moyen |
| Boss Slayer | Tuer son premier boss | Moyen |
| Wave 20 | Atteindre la manche 20 | Difficile |
| Hardcore Survivor | Atteindre manche 20 en mode Hardcore | Très difficile |
| Nuke! | Obtenir le bonus Nuke | Facile (chance) |
| Team Player | Finir une partie en équipe de 4 | Facile |
| All Zones | Ouvrir toutes les portes en une partie | Moyen |

---

## Questions clés

- [x] Le joueur sent-il qu'il progresse à chaque session ? → Oui, manche + argent + armes
- [x] Les récompenses sont-elles bien espacées ? → Oui, bonus chaque manche, boss toutes les 5
- [x] Y a-t-il toujours un prochain objectif ? → Oui, prochaine manche, prochaine arme, prochaine zone
- [x] L'endgame est-il prévu ? → Oui, leaderboard + mode hardcore + badges
