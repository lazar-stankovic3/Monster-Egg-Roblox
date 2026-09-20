# Steal a Monster Egg — trajni kontekst

## Važeći status — 2026-09-20

Korisnik je izričito potvrdio da je testirao sve dosadašnje faze. **Faze 1–11 su završene i potvrđene**, uključujući ranije odložene provere i poslednje ispravke. Faza 13 je potvrđena korisnikovim testiranjem. Faza 14 je potvrđena korisnikovim testiranjem. Aktivna je faza 15 — treadmill upgrade-i isključivo redom, privremeni modeli i zaključavanje na sredini do skoka; implementirana i čeka Studio potvrdu prema docs/FAZA_15.md. Ovaj status zamenjuje sve ranije navode o nepotvrđenim fazama u istorijskim zapisima ispod.


## Gameplay loop

Igrac trenira Speed na treadmill-u, odlazi u biome, krade monster egg i bezi od Guardian-a nazad u lobby. Lobby prebacuje jaje u inventory/hotbar. Igrac postavlja jaje na svoj plot; posle hatch timer-a dobija monstera koji ostaje u slotu i proizvodi Cash/sec. Cash kupuje bolje treadmill-e, veci Speed olaksava kradju u tezim biomima, a tezi biomi imaju bolja jaja i monstere. Monster se otkljucava u Index-u tek pri prvom hatch-u.

## Pravila arhitekture

- Implementirati jednu fazu po jednu. Ne prelaziti dalje dok trenutna faza nije testirana i potvrdjena.
- Ne menjati prethodne sisteme osim kada je potrebno za tekucu fazu.
- Server donosi sve vazne odluke: Speed, Cash, ownership, pickup, purchases, placement, hatch, income, unlocks.
- Klijent prikazuje UI i salje zahteve; nije izvor istine za gameplay.
- Modularni ModuleScripts umesto jednog velikog Script-a. Centralne provere/income tick umesto petlje za svakog monstera.
- Svaka faza ima kompletan kod, Explorer lokacije/tipove objekata, Attributes i kratak Studio test.
- Stabilni UID-evi za jaja i monstere; DataStore cuva samo serijalizovane Lua podatke, nikada Instance.

## Specifikacija i balans (pocetne vrednosti)

- Pravi statovi: Player.Stats.Speed i Cash; leaderstats samo prikaz. Speed nije WalkSpeed. Postojeca formula: 16 + 12 * log10(Speed / 10 + 1), priblizno 16 / 28 / 40 / 52 za 0 / 100 / 1000 / 10000.
- Workspace.Treadmills sadrzi modele sa TrainingZone Part-om i Number SpeedGain Attribute-om; server trening daje SpeedGain/sec.
- Biomi su modeli u Workspace.Biomes sa BiomeZone Part-om i RecommendedSpeed: 100, 500, 2500, 10000. Nema hard lock-a, samo READY/DANGEROUS risk/reward UI.
- Egg Attributes: UID, EggName, EggType, Biome, Rarity, Size, Scale, SpawnPoint, Carried, CarrierUserId. Svaki biome ima egg pool. Hatchling Fields: Hatchling/Forest/Slime Egg; Volcano: Magma/Inferno/Dragon Egg.
- Rarity income multipliers: Common 1; Uncommon 1.5; Rare 2.5; Epic 5; Legendary 10; Mythic 25.
- Size income multipliers: Tiny 0.7; Normal 1; Large 1.5; Huge 2.5; Titanic 5.
- Carry penalty na calculated WalkSpeed: Tiny/Normal 0%; Large 5%; Huge 10%; Titanic 20%. Speed stat ostaje isti; drop/deposit uklanjaju penalty.
- Guardian juri samo lopova svog jajeta; pathfinding po potrebi. Prestaje na safe/lobby zoni, drop-u ili smrti; hvatanje izaziva drop. Biome speeds primeri: Hatchling 25, Volcano 45, Void 70. Rarity dodatak primeri: Common 0%, Rare 5%, Epic 10%, Legendary 20%; ostale vrednosti definisati u toj fazi.
- Deposit stvara vizuelni Egg Tool u Backpack-u sa UID, EggType, Biome, Rarity, Size, Scale; zadrzati i EggName gde treba. Equip prikazuje egg.
- Plot automatski dobija vlasnika (OwnerUserId), početni kapacitet je šest jaja. Na korisnikov zahtev: slobodno postavljanje mišem na Place Part, bez fiksnih slotova i prompta. Preview je providno siv kada je mesto dozvoljeno i crven kada nije. Levi klik postavlja jaje. Server proverava ownership, udaljenost, granice, razmak, kapacitet i stvarni equipovani Tool; prenos sprečava dupliranje.
- Hatch timer primeri: Common 3s, Rare 8s, Epic 15s, Legendary 30s; ostale definisati kasnije. Countdown iznad jajeta. Hatchling Egg monster pool: 70% Green Slime, 20% Leaf Bunny, 8% Baby Goblin, 2% Forest Dragon.
- Monster config: MonsterName, Biome, Rarity, BaseIncome, ModelName, Icon, IndexId. FinalIncome = BaseIncome * RarityMultiplier * SizeMultiplier. Primer: 2 * 2.5 * 1.5 = 7.5/sec. Pravilo nasledjivanja egg/monster rarity precizirati u odgovarajucoj fazi.
- Centralni IncomeService sabira income svih igracevih monstera i svake sekunde dodaje Cash.
- Treadmill shop (Cost / SpeedGain): Starter 0/20; Metal 1000/60; Turbo 10000/200; Neon 100000/700; Void 1000000/2000. Server naplacuje, cuva ownership i postavlja treadmill na plot.
- Postojeci Index UI treba povezati: grupisanje po biome-u, zakljucano ? / ???, broj otkljucanih po biome-u i globalno. Detalji: Monster Name, Rarity, Biome, Base Income, Best Size Found. Prvi hatch otkljucava; novi bolji size unapredjuje zapis. DataStore trajno pamti.
- Save: Speed, Cash, OwnedTreadmill, IndexUnlocks, EggInventory, PlacedEggs, Monsters, Plot upgrades. Autosave, PlayerRemoving, BindToClose, stabilni podaci.
- Kasnije offline income: LastLogoutTime, vreme odsustva, income monstera, cap 6h i prikaz zarade po povratku; bez duplog isplacivanja.
- Plot upgrades: 6 -> 8 -> 12 -> 16 slotova, server validira ownership i cenu.
- Polish: +Speed floating text, Cash/sec, biome popup i status, pickup/hatch/spawn animacije, RUN!, chase muzika, rarity VFX, floating income, zvuci, particles, UI transitions.

## Smer modularizacije

ReplicatedStorage.Modules: BiomeConfig, EggConfig, MonsterConfig, RarityConfig, SizeConfig, TreadmillConfig kada budu potrebni.
Server servisi: PlayerDataService, SpeedService, TreadmillService, BiomeService, EggService, GuardianService, PlotService, HatchService, MonsterService, IncomeService, IndexService.
LocalScripts za UI. Ciljno Remotes folder; faza 3 koristi eksplicitno trazeni ReplicatedStorage.BiomeUIEvent. Ne menjati sve ranije putanje unapred.

## Postojece stanje

Korisnik je potvrdio postojeci EggSystem (pickup/carry/deposit/respawn), PlayerStats i Training/Treadmill sa SpeedGain. Kod se nalazi u src/server. Mapa, modeli i postojeci Index UI nisu sacuvani u ovom Rojo repozitorijumu; postojece Studio asset-e treba sacuvati.
Faza 3 je implementirana i korisnik je potvrdio Studio testiranje 2026-09-20. Uputstvo: docs/FAZA_03.md. Preostali zadaci: TODO.md.

## Istorijski zapis — 2026-09-18

Istorijski zapis; za trenutno stanje videti noviji zapis ispod.

Faza 7 je u celosti potvrđena od korisnika. Aktivna je faza 8; ne prelaziti na fazu 9 bez njene potvrde. Faze 4–6 zadržavaju ranije odložene Studio provere.

Implementirani su GuardianService, GuardianConfig, GuardianHitService i klijentski GuardianRagdoll. Svako ukradeno jaje dobija zasebnog čuvara. Opcioni GuardianTemplate ima prednost; bez modela generiše se jednostavan NPC. Praćenje cilja osvežava se na 0.05 s, a putanja računa u pozadini sa intervalom 0.35 s. Udarac izaziva drop, odbacivanje od Guardiana i privremeni ragdoll sa ustajanjem nakon sletanja (maksimalno trajanje 5 s).

Korisnik je potvrdio da ragdoll radi nakon dodavanja podrške za AnimationConstraint pored Motor6D. Odbacivanje je zatim pojačano na 95 horizontalno / 42 vertikalno. Poslednje prijavljen problem bio je da veliko ispušteno jaje zaustavlja let. Dodat je privremeni NoCollisionConstraint između tog jajeta i svih delova pogođenog karaktera, uključujući ragdoll collidere; jaje se ignoriše i pri proveri sletanja. Ovaj poslednji fix još nije potvrđen u Studio-u.

Rojo build prolazi, ali proverava pakovanje, ne fizičko ponašanje u Studio-u. Detalji i preostali testovi: docs/FAZA_08.md i TODO.md. Mapa i modeli ostaju u korisnikovom Studio projektu; čuvati postojeće asset-e.

## Istorijski zapis — 2026-09-19

Na korisnikov zahtev za nastavak implementirana je faza 9. Nepotvrdjeni Studio testovi faze 8 su ostali odlozeni, bez oznacavanja da su prosli. Aktivna faza je 9, prema docs/FAZA_09.md.

EggInventoryService stvara zapis po UID-u i vizuelni Tool u Backpack-u pri lobby deposit-u. Tool cuva metadata i OwnerUserId, ima zavaren nekolizioni model jajeta i ne moze se rucno ispustiti. Equip premesta istu instancu. Naknadno je na zahtev korisnika uklonjeno ograničenje prikaza: jaje u ruci zadržava punu originalnu veličinu i Size/Scale. Server obnavlja Tool-ove nakon respawna u istoj sesiji. DataStore jos nije implementiran. Sledeci korak je Studio test faze 9, ne faza 10.

## Istorijski zapis — 2026-09-20

Na korisnikov zahtev „ajmo dalje” implementirana je faza 10. Provere faze 9 ostaju odložene, bez oznake da su prošle. Ovaj zapis zamenjuje ranije uputstvo da je aktivna faza 9.

PlotService automatski dodeljuje pripremljene Workspace.Plots modele igračima, održava OwnerUserId i šest početnih slotova, oslobađa plot na izlasku i dodeljuje ga sledećem igraču koji čeka. Respawn ne menja plot. Studio mapa zahteva postavku prema docs/FAZA_10.md; postojeći asset-i nisu menjani. Aktivna faza je 10 i čeka Studio potvrdu. Placement ostaje za fazu 11.


## Istorijski zapis — slobodno postavljanje, 2026-09-20

Korisnik je izričito zatražio preview i klik bilo gde na svom Place Part-u: providno sivo za dozvoljeno, crveno za nedozvoljeno, bez zelene. Implementirana je faza 11 i PlotService prilagođen postojećim Plot1–Plot6 modelima. Nema generisanja fiksnih slotova; SlotCapacity=6 označava limit jaja. PlacedEggs je namenski runtime folder. Studio mapa nije menjana iz repozitorijuma.

Aktivna faza je 11, prema docs/FAZA_11.md. Provere faza 9 i 10 ostaju otvorene. Hatch ostaje za fazu 12. Preview i postavljeno jaje koriste punu originalnu veličinu Tool-a, bez umanjivanja, uz očuvane Size/Scale atribute. Nema persistence-a do faze 17.


Korisnik je potvrdio da se monster stvorio u fazi 12 i zatražio nasleđivanje veličine bez umanjivanja prema otisku jajeta. Monster koristi isti Scale kao jaje (0.7/1/1.4/1.9/2.6). Ostale provere faze 12 ostaju otvorene.

Po korisničkom zahtevu početni Cash je 1000, a Starter treadmill daje 20 Speed/sec. Svi nivoi su proporcionalno balansirani prema Starter-u: 20/60/200/700/2000 Speed/sec, uz nepromenjene cene i kupovinu isključivo redom.
