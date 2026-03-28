# Plan de Production — Zombie Waves

> Découpage en Epics et Stories. Chaque story = une tâche codable en 1-4h.

---

## Epics

| # | Epic | PRD source | Priorité | Statut |
|---|------|-----------|----------|--------|
| E1 | Infrastructure (Rojo, DataStore, Events) | Architecture | CRITIQUE | [ ] |
| E2 | Core Combat (Wave Manager + Zombie AI) | PRD 01, 02, 09 | CRITIQUE | [ ] |
| E3 | Économie (Argent, Wall Buys, Doors) | PRD 05 | CRITIQUE | [ ] |
| E4 | HUD & UI | PRD 06 | CRITIQUE | [ ] |
| E5 | Zombies Spéciaux + Boss | PRD 09 | HAUTE | [ ] |
| E6 | Bonus Aléatoires | PRD 02 | HAUTE | [ ] |
| E7 | Classes / Rôles | PRD 07 | HAUTE | [ ] |
| E8 | Shop & Items | PRD 05, 08 | HAUTE | [ ] |
| E9 | Map Multi-Zones | PRD 03 | HAUTE | [ ] |
| E10 | Leaderboard | PRD 04 | MOYENNE | [ ] |
| E11 | Mode Hardcore | PRD 02 | MOYENNE | [ ] |
| E12 | Audio & Polish | PRD 10, 11 | MOYENNE | [ ] |
| E13 | Monétisation | PRD 12 | BASSE | [ ] |

---

## Stories par Epic

### E1 : Infrastructure

| # | Story | Critère de "fait" | Estimation |
|---|-------|-------------------|-----------|
| E1-S1 | Setup Rojo + structure dossiers | `rojo serve` fonctionne | 30min |
| E1-S2 | GameConfig + configs partagés | Constantes accessibles client+serveur | 1h |
| E1-S3 | DataManager (save/load) | Données persistent entre sessions | 2h |
| E1-S4 | RemoteEvents setup | Tous les events créés et fonctionnels | 1h |

### E2 : Core Combat

| # | Story | Critère de "fait" | Estimation |
|---|-------|-------------------|-----------|
| E2-S1 | WaveManager — spawn et comptage | Zombies spawn, manche incrémente | 2h |
| E2-S2 | BasicZombie AI | Zombie marche vers joueur, inflige dégâts | 3h |
| E2-S3 | Système de dégâts serveur-side | Joueur peut tuer un zombie, zombie peut tuer joueur | 2h |

### E3 : Économie

| # | Story | Critère de "fait" | Estimation |
|---|-------|-------------------|-----------|
| E3-S1 | EconomyManager — argent par hit | +10$ par hit visible dans leaderstats | 1h |
| E3-S2 | WallBuySystem | Achat d'arme via ProximityPrompt | 2h |
| E3-S3 | DoorSystem | Porte s'ouvre pour tous, zone débloquée | 2h |

### E4 : HUD & UI

| # | Story | Critère de "fait" | Estimation |
|---|-------|-------------------|-----------|
| E4-S1 | HUD — vie, argent, manche, munitions | Tous les éléments affichés et mis à jour | 3h |
| E4-S2 | Notifications (manche, bonus, achat) | Notifications apparaissent et disparaissent | 2h |
| E4-S3 | Écran Game Over | Stats affichées, bouton rejouer | 1h |

### E5 : Zombies Spéciaux + Boss

| # | Story | Critère de "fait" | Estimation |
|---|-------|-------------------|-----------|
| E5-S1 | 3 types de zombies spéciaux | Rapide/Tank/Explosif fonctionnels | 3h |
| E5-S2 | BossManager (3 phases) | Boss spawn, change de phase, meurt | 3h |

### E6-E13 : Systèmes secondaires

| # | Story | Estimation |
|---|-------|-----------|
| E6-S1 | BonusManager (5 bonus) | 2h |
| E7-S1 | ClassManager (4 classes) | 2h |
| E8-S1 | ShopManager (3 onglets) | 2h |
| E10-S1 | LeaderboardManager | 2h |
| E11-S1 | HardcoreManager | 1h |

---

## Ordre de développement

```
SEMAINE 1 : Infrastructure + Core
E1-S1 → E1-S2 → E1-S3 → E1-S4 → E2-S1 → E2-S2 → E2-S3

SEMAINE 2 : Économie + UI
E3-S1 → E3-S2 → E3-S3 → E4-S1 → E4-S2 → E4-S3

SEMAINE 3 : Zombies spéciaux + Boss + Bonus
E5-S1 → E5-S2 → E6-S1

SEMAINE 4 : Classes + Shop + Systèmes
E7-S1 → E8-S1 → E10-S1 → E11-S1

POST-MVP : Audio, Polish, Monétisation
E12 → E13
```
