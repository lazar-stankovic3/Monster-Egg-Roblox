# Faza 19 — plot upgrades

Status 2026-09-21: implementirano, čeka Roblox Studio potvrdu.

## Kapacitet i cene

| Nivo | Kapacitet | Cena sledećeg nivoa |
| --- | ---: | ---: |
| 1 | 6 | $5,000 |
| 2 | 8 | $50,000 |
| 3 | 12 | $500,000 |
| 4 | 16 | MAX |

`ReplicatedStorage.Modules.PlotUpgradeConfig` je jedini izvor kapaciteta i cena.
Klijent ne šalje željeni nivo niti cenu, već samo zahtev za kupovinu. Server zatim
proverava `PlayerDataStatus`, vlasništvo plota, trenutni nivo i Cash, naplaćuje i
postavlja sledeći dozvoljeni kapacitet.

`PlotUpgradeUI` se pravi automatski na desnoj strani ekrana. Prikazuje trenutni
broj mesta, sledeći kapacitet i cenu. Nisu potrebni novi Part-ovi u mapi.

`SlotCapacity` se već čuva u objedinjeni `MonsterEggPlayerData_v1`. Promena
kapaciteta sada pokreće i trenutni debounced save PlayerData sistema.

## Studio test

1. Posle Rojo sync-a pokreni novi Play test i proveri poruke
   `[PlotUpgradeService] Phase 19 service started.` i
   `[EggSystem] PlotUpgradeService bootstrap complete.`
2. Sa manje od $5,000 klikni upgrade. Cash i kapacitet moraju ostati isti, a
   dugme prikazuje da nema dovoljno novca.
3. Postavi Cash na najmanje $555,000 i kupi nivoe redom: 6 → 8 → 12 → 16.
   Proveri tačno skidanje $5,000, $50,000 i $500,000.
4. Na 16 mesta dugme mora prikazati `MAX CAPACITY (16)` i više ne sme naplaćivati.
5. Na svakom nivou postavi jaja do kapaciteta. Sledeće postavljanje mora biti
   odbijeno server-side.
6. Izađi i ponovo uđi. Kapacitet, preostali Cash i sadržaj plota moraju biti
   vraćeni, a UI mora prikazati učitani nivo.
7. Sa dva igrača proveri da kupovina menja samo plot kupca.

Rojo build potvrđuje pakovanje. Kupovina, Cash i DataStore restore moraju se
potvrditi u objavljenom Studio testu.
