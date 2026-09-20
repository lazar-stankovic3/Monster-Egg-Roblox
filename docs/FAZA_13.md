# Faza 13 — MonsterConfig / MonsterService

Status: potvrđeno korisnikovim Studio testiranjem 2026-09-20. Korisnik je potvrdio hatch i nasleđivanje veličine i zatražio nastavak. Ostale provere faze 12 ostaju dostupne u FAZA_12.md.

## Implementacija

MonsterConfig je novi centralni katalog sedam postojećih monstera: MonsterName, Biome, Rarity (podrazumevana rarity vrste), BaseIncome, ModelName, Icon i stabilan IndexId. Ikone su za sada prazne jer asset-i nisu dostavljeni. HatchConfig zadržava timere i pool-ove, ali koristi isti katalog umesto kopije definicija.

MonsterService.Create preuzima pravljenje i pripremu modela iz HatchService-a. Zadržava fallback privremene modele, punu veličinu nasleđenu od jajeta, UID i SourceEggUID. Pravi modeli se i dalje mogu dodati u ServerStorage.MonsterModels prema FAZA_12.md.

Rarity izležene instance i dalje dolazi od jajeta, kao u fazi 12. Podrazumevana rarity vrste čuva se kao BaseRarity i ne množi zaradu drugi put. Biome ostaje poreklo jajeta; MonsterBiome beleži biome vrste iz kataloga.

Formula: FinalIncome = BaseIncome × RarityConfig multiplier × SizeConfig multiplier. Vizuelni Scale nije income multiplier (npr. Large izgleda 1.4×, ali income multiplier je 1.5×). Decimalni rezultat se ne zaokružuje u podacima.

Početne BaseIncome vrednosti: Green Slime 2, Leaf Bunny 4, Baby Goblin 8, Forest Dragon 20, Magma Slime 12, Flame Goblin 25, Inferno Dragon 60. To su početne balans vrednosti koje mogu da se promene u MonsterConfig-u.

Model dobija BaseIncome, FinalIncome, BaseRarity, IndexId, Icon, ModelName, MonsterBiome, uz prethodne atribute. Iznad njega prikazuju se ime, nasleđeni rarity/size i $/sec.

MonsterService.GetIncome(player) sabira samo monstere u njegovom dodeljenom plotu sa ispravnim OwnerUserId i jedinstvenim UID-em; jaja se ne računaju. Ponovo računa formulu iz server konfiguracije umesto da veruje prikaznom atributu FinalIncome. Ovo je API za fazu 14; Cash se u fazi 13 još ne isplaćuje.

Monster zadržava vlasnika, mesto i UID nakon respawna u istoj sesiji, zauzima jedno od šest mesta i nestaje pri izlasku vlasnika kroz postojeći cleanup. Trajno čuvanje između sesija ostaje za fazu 17.

## Studio provera

1. Stop → Rojo sync → Play. Izlegni jaje. Iznad monstera proveri ime, rarity, size i $/sec, bez Output grešaka.
2. U modelu pod Workspace.Plots.PlotN.PlacedEggs proveri BaseIncome, FinalIncome, OwnerUserId, UID, SourceEggUID, IndexId, Size i Scale.
3. Green Slime Common/Normal treba da ima 2/sec; Rare/Large 7.5/sec; Rare/Titanic 25/sec. Rarity dolazi od jajeta, ne od BaseRarity.
4. Za proveru formule u server Command Bar-u: `local c = require(game.ReplicatedStorage.Modules.MonsterConfig); assert(c.CalculateIncome("green_slime", "Rare", "Large") == 7.5); assert(c.CalculateIncome("green_slime", "Rare", "Titanic") == 25); assert(c.CalculateIncome("missing", "Common", "Normal") == nil)`.
5. Reset ne menja vlasnika, UID, veličinu ili income monstera. Dva igrača imaju odvojene monstere; izlazak jednog prazni samo njegov plot.
6. Šest monstera blokira sedmo jaje. Postojeći hatch, preview, Tool fizika i veličina ostaju ispravni.
7. Cash ne raste od monstera u ovoj fazi; stvarna isplata dolazi u fazi 14.

Rojo build proverava pakovanje. Korisnik je potvrdio da faza 13 radi; testovi ostaju referenca za regresiju.