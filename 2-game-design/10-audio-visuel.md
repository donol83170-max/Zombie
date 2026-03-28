# PRD 10 — Audio & Visuel — Zombie Waves

---

## Style visuel

| | Choix |
|---|-------|
| **Style 3D** | Roblox stylisé — low-poly avec éclairage atmosphérique |
| **Palette** | Sombre : gris béton, vert toxique (#39ff14), rouge sang (#e94560), bleu nuit (#0f3460) |
| **Éclairage** | Faible éclairage ambiant, lampes directionnelles, ombres projetées |
| **Effets** | Brouillard léger, particules de poussière, flash de tir |
| **Post-processing** | Bloom léger, ColorCorrection (saturation réduite) |

---

## Effets visuels (VFX)

| Effet | Trigger | Description |
|-------|---------|-------------|
| Flash de tir | Tir d'arme | Lumière jaune flash (PointLight 0.1s) |
| Impact zombie | Balle touche zombie | Particules rouges |
| Mort zombie | PV = 0 | Animation ragdoll + fondu + disparition |
| Explosion (zombie explosif) | Zombie explose | Cercle d'onde de choc + particules feu |
| Boss aura | Boss spawn | Particules rouges tournoyantes |
| Nuke | Bonus Nuke | Flash blanc plein écran + onde de choc |
| Heal | Bonus Heal | Particules vertes montantes sur tous les joueurs |
| Speed boost | Bonus Speed | Traînée bleue derrière le joueur |

---

## Audio

### Musique

| Piste | Quand | Style | Volume |
|-------|-------|-------|--------|
| Lobby | Au lobby | Ambient calme, militaire | 0.3 |
| Combat | Pendant les manches | Électro-dark, percussions intenses | 0.5 |
| Boss | Pendant un boss | Musique épique, cuivres + batterie | 0.6 |
| Game Over | Mort du joueur | Lent, sombre, fade out | 0.4 |

### SFX

| Son | Quand | Priorité MVP |
|-----|-------|-------------|
| Tir pistolet | Tir au pistolet | Oui |
| Tir shotgun | Tir au shotgun | Oui |
| Tir AK-47 | Tir à l'AK | Oui |
| Tir sniper | Tir au sniper | Oui |
| Rechargement | Recharge arme | Oui |
| Hit sur zombie | Balle touche zombie | Oui |
| Zombie grognement | Zombie idle/aggro | Oui |
| Zombie mort | Zombie meurt | Oui |
| Explosion | Zombie explosif / grenade | Oui |
| Achat réussi | Wall buy / shop | Oui |
| Achat échoué | Pas assez d'argent | Oui |
| Porte ouvre | Porte s'ouvre | Oui |
| Manche terminée | Fin de vague | Oui |
| Boss roar | Boss spawn | Oui |
| Nuke | Bonus nuke | Non (post-MVP) |

---

## Questions clés

- [x] L'ambiance visuelle est-elle cohérente ? → Oui, post-apo sombre uniforme
- [x] Les sons sont-ils informatifs ? → Oui, chaque action a un feedback sonore
- [x] Les effets ne nuisent pas aux performances ? → Surveillé via MicroProfiler
