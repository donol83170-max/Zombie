# PRD 01 — Core Loop — Zombie Waves

> La boucle que le joueur répète sans s'en lasser.

---

## La boucle principale

### En une phrase
> TUER des zombies → GAGNER de l'argent → ACHETER des armes/ouvrir des portes → SURVIVRE plus longtemps → recommencer

### Détail minute par minute

| Temps | Ce que fait le joueur | Ce qu'il ressent |
|-------|----------------------|------------------|
| 0:00 - 0:30 | Spawn, découvre le HUD, première arme (pistolet gratuit) | Curiosité, orientation |
| 0:30 - 1:00 | Manche 1 : 8 zombies basiques, tire au pistolet | Contrôle, premiers kills satisfaisants |
| 1:00 - 2:00 | Fin manche 1, bonus aléatoire, achète au wall buy | Récompense, choix stratégique |
| 2:00 - 5:00 | Manches 2-3, argent qui monte, première porte achetée | Montée en puissance, excitation |
| 5:00 - 10:00 | Manches 4-5, zombies spéciaux apparaissent, premier boss | Tension, moment "wow" du boss |
| 10:00+ | Manches 6+, gestion des zones ouvertes, armes puissantes | Flow, challenge croissant, "encore une manche" |

### Boucle session (une session complète)

1. Le joueur se connecte → Lobby : choisit sa classe et le mode (normal/hardcore)
2. Il décide de battre son record de manches →
3. Il tue des zombies, achète des armes, ouvre des portes, bat des boss →
4. Il obtient de l'argent, des bonus, et voit son score grimper →
5. Il meurt et se déconnecte satisfait parce qu'il a battu son record / débloqué une nouvelle zone / essayé une nouvelle classe

### Boucle méta (progression long terme)

- **Jour 1 :** Découvre le jeu, atteint manche 5-8, comprend les wall buys
- **Jour 3 :** Essaie les 4 classes, arrive manche 10-15, découvre les portes et zones
- **Semaine 1 :** Optimise sa stratégie, explore le mode Hardcore, atteint manche 20+
- **Mois 1 :** Top 10 leaderboard, badge Hardcore Survivor, maîtrise toutes les classes
- **Mois 3+ :** Revient pour les événements, défie des amis, tente les records ultimes

---

## Piliers de gameplay

| Pilier | Description | Importance |
|--------|-------------|------------|
| Tirer / Survivre | Éliminer les zombies, esquiver, rester en vie | Principal |
| Acheter / Gérer | Gérer son argent, acheter les bonnes armes au bon moment | Principal |
| Explorer / Débloquer | Ouvrir des portes, accéder à de nouvelles zones et armes | Secondaire |
| Coopérer | Jouer en équipe, synergie de classes | Tertiaire |

---

## Rythme & Tension

### Courbe d'intensité d'une session typique

```
Intensité
  ▲
  │          ★Boss        ★Boss          ★Boss
  │     ╱╲   ╱╲      ╱╲   ╱╲       ╱╲   ╱╲
  │    ╱  ╲ ╱  ╲    ╱  ╲ ╱  ╲     ╱  ╲ ╱  ╲
  │   ╱    ╳    ╲  ╱    ╳    ╲   ╱    ╳    ╲
  │  ╱           ╲╱           ╲ ╱           ╲
  │ ╱  bonus      bonus       bonus          ╲
  │╱                                          ╲→ MORT
  └────────────────────────────────────────────> Manches
  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15
```

- **Pics d'intensité :** Boss toutes les 5 manches, zombies spéciaux dès manche 5
- **Moments de calme :** Entre les manches — bonus, achats, repositionnement
- **Climax de session :** Le boss qui meurt, le bonus Nuke qui élimine tout

---

## Feedback loops (boucles de rétroaction)

### Feedback immédiat (chaque action)
- Visuel : zombie touché flashe en rouge, particules de sang, animation de mort
- Sonore : son d'impact de balle, grognement zombie, son de kill
- Numérique : +10$ affiché en pop-up au-dessus du zombie

### Feedback court terme (chaque manche terminée)
- Récompense : bonus aléatoire (Nuke, Double Money, Heal, etc.)
- Notification : "MANCHE X TERMINÉE !" en gros au centre
- Animation : éclair de lumière, son victorieux

### Feedback long terme (progression globale)
- Statistiques : record de manches, zombies tués total, argent gagné total
- Déverrouillages : badges Roblox, rang leaderboard
- Statut social : position dans le top 10 global

---

## Questions clés à valider

- [x] Est-ce que la boucle est fun dès les 30 premières secondes ? → Oui, premier kill = premier $
- [x] Est-ce que le joueur sait toujours quoi faire ensuite ? → Tuer les zombies, acheter, survivre
- [x] Est-ce que la progression donne envie de continuer ? → Oui, "encore une manche"
- [x] Est-ce que le rythme alterne bien entre effort et récompense ? → Oui, combat/bonus/combat
- [x] Est-ce que la session a une fin naturelle (pas frustrant de quitter) ? → Oui, mort = fin naturelle
