# Faza 7 — Carry movement penalty

Status: carry penalty je implementiran na serveru. Ne menja `Player.Stats.Speed`; utiče samo na stvarni `Humanoid.WalkSpeed` dok igrač nosi world egg.

## Pravilo

| Size | Penalty | WalkSpeed dok se nosi jaje |
| --- | ---: | --- |
| Tiny | 0% | `calculatedWalkSpeed × 1` |
| Normal | 0% | `calculatedWalkSpeed × 1` |
| Large | 5% | `calculatedWalkSpeed × 0.95` |
| Huge | 10% | `calculatedWalkSpeed × 0.90` |
| Titanic | 20% | `calculatedWalkSpeed × 0.80` |

`calculatedWalkSpeed` je postojeća formula iz `PlayerStats`: `16 + 12 * log10(Speed / 10 + 1)`. Penalty se primenjuje nakon formule, nikada na sam `Stats.Speed` broj. Postojeći `SlowMode` i dalje ima prioritet i zadržava svoju fiksnu brzinu 8.

## Izmene

| Fajl | Promena |
| --- | --- |
| `src/modules/SizeConfig.luau` | svaka size definicija sada sadrži `CarryMovementPenalty`; API `GetCarryMovementPenalty(sizeName)` vraća broj ili `nil` |
| `src/server/EggSystem.server.lua` | pri uspešnom pickup-u čita veličinu server-side i postavlja `player.CarryMovementPenalty`; resetuje je na drop, deposit, smrt, uklanjanje jajeta i PlayerRemoving |
| `src/server/PlayerStats.server.lua` | reaguje na promenu `CarryMovementPenalty` i ponovo računa stvarni WalkSpeed |

`CarryMovementPenalty` je serverom upravljan Number Attribute na Player-u. Početna i reset vrednost je `0`. Egg sa nepostojećim size-om ne može biti podignut, pa se ne može primeniti nepoznat penalty.

## Studio test

1. Pokreni **Play**, postavi `Stats.Speed` na 100 i potvrdi da bez jajeta WalkSpeed iznosi približno 28.
2. Podigni Tiny ili Normal egg: Speed stat i WalkSpeed ostaju isti.
3. Podigni Large, Huge i Titanic egg. Za osnovnu brzinu približno 28 očekuj približno 26.6, 25.2 i 22.4. U Explorer-u proveri `Player.CarryMovementPenalty` (0.05, 0.1 ili 0.2).
4. Dok nosiš jaje, promeni `Stats.Speed`. WalkSpeed se mora odmah ponovo izračunati sa istim penalty-jem.
5. Ispusti jaje smrću: `CarryMovementPenalty` postaje 0 i posle respawn-a se vraća puna izračunata brzina.
6. Odnesi jaje u `LobbyDepositZone`: penalty se odmah uklanja, pre nego što se jaje uništi.
7. Ponovi pickup/drop više puta, zatim resetuj bez nošenog jajeta. Attribute mora ostati 0; ne sme postojati trajno usporenje.
8. Uključi postojeći SlowMode dok nosiš Huge/Titanic egg: WalkSpeed ostaje 8. Isključi ga i proveri da se carry penalty ponovo primeni.

Rojo build potvrđuje pakovanje, ali Studio runtime test potvrđuje stvarno kretanje.
