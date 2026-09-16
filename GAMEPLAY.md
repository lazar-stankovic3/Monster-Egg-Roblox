# Steal a Monster Egg — trajni kontekst

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
- Plot automatski dobija slobodnog vlasnika (OwnerUserId), pocetno 6 EggSlots. Place Egg ProximityPrompt: validirati plot ownership, udaljenost, slobodan slot i stvarno posedovanje equipovanog Tool-a. Prenos jaja mora spreciti dupliranje.
- Hatch timer primeri: Common 3s, Rare 8s, Epic 15s, Legendary 30s; ostale definisati kasnije. Countdown iznad jajeta. Hatchling Egg monster pool: 70% Green Slime, 20% Leaf Bunny, 8% Baby Goblin, 2% Forest Dragon.
- Monster config: MonsterName, Biome, Rarity, BaseIncome, ModelName, Icon, IndexId. FinalIncome = BaseIncome * RarityMultiplier * SizeMultiplier. Primer: 2 * 2.5 * 1.5 = 7.5/sec. Pravilo nasledjivanja egg/monster rarity precizirati u odgovarajucoj fazi.
- Centralni IncomeService sabira income svih igracevih monstera i svake sekunde dodaje Cash.
- Treadmill shop (Cost / SpeedGain): Starter 0/1; Metal 1000/3; Turbo 10000/10; Neon 100000/35; Void 1000000/100. Server naplacuje, cuva ownership i postavlja treadmill na plot.
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
Faza 3 kod je dodat; runtime potvrda u Studio jos nije uradjena. Uputstvo: docs/FAZA_03.md. Preostali zadaci: TODO.md.
