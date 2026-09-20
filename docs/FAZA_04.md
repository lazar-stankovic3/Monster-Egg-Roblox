# Faza 4 — Egg pools i metadata

Status 2026-09-20: završeno i potvrđeno korisnikovim testiranjem u Roblox Studio-u. Sve faze 1–11 i ranije odložene provere su potvrđene. Test koraci ispod ostaju kao referenca za regresiju.

Faza 4 zadržava postojeći tok: pickup → carry → death drop → lobby deposit → respawn. Server bira tip jajeta iz biome pool-a, dodeljuje kompletan metadata set i kopira relevantne vrednosti u `Player.EggInventory` pri deposit-u.

## Fajlovi

| Fajl | Explorer lokacija | Uloga |
| --- | --- | --- |
| `src/modules/EggConfig.luau` | `ReplicatedStorage > Modules > EggConfig` | stabilni tipovi jaja, rarity, biome pool-ovi i postojeće size šanse |
| `src/modules/EggRoller.luau` | `ReplicatedStorage > Modules > EggRoller` | validiran weighted izbor egg tipa i size-a |
| `src/server/EggSystem.server.lua` | `ServerScriptService > Server > EggSystem` | spawn, atributi, pickup/carry/drop/deposit/respawn |

Rojo već sinhronizuje ove fajlove preko `default.project.json`. Modeli jaja i postojeća mapa nisu deo Rojo stabla, zato se postavljaju u Roblox Studio-u.

## Studio struktura

```text
ServerStorage
└── EggModels                              (Folder)
    ├── BasicEgg                            (Model, legacy fallback)
    ├── HatchlingEgg                        (Model)
    ├── ForestEgg                           (Model)
    ├── SlimeEgg                            (Model)
    ├── MagmaEgg                            (Model)
    ├── InfernoEgg                          (Model)
    └── DragonEgg                           (Model)

Workspace
├── EggSpawnPoints                          (postojeći Folder)
│   ├── HatchlingSpawnA                     (BasePart, Biome = "HatchlingFields")
│   ├── HatchlingSpawnB                     (BasePart, Biome = "HatchlingFields")
│   └── VolcanoSpawnA                       (BasePart, Biome = "Volcano")
└── LobbyDepositZone                        (postojeći BasePart)
```

`EggModels` mora biti Folder u `ServerStorage`. Svaki model mora imati postavljen `PrimaryPart` i najmanje jedan `BasePart`. Nazivi su case-sensitive i moraju odgovarati `ModelName` vrednostima iz `EggConfig` tabele. Nemoj stavljati modele u Workspace — server ih klonira iz `ServerStorage` pri svakom spawn-u.

Svaki `EggSpawnPoints` child koji je `BasePart` mora imati jedinstveno ime. Za biome pool dodaj mu String Attribute `Biome`. Neostavljen Attribute je podržan samo kao legacy slučaj: tada se bira `BasicEgg` sa biome-om `Legacy`. Prazan, neniz ili nepostojeći biome pool se namerno odbija i spawn se preskače uz upozorenje u Output-u.

## Egg pool-ovi

| Biome Attribute | EggType | Prikazano ime | Model | Rarity | Težina |
| --- | --- | --- | --- | --- | ---: |
| `HatchlingFields` | `hatchling_egg` | Hatchling Egg | HatchlingEgg | Common | 60 |
| `HatchlingFields` | `forest_egg` | Forest Egg | ForestEgg | Uncommon | 30 |
| `HatchlingFields` | `slime_egg` | Slime Egg | SlimeEgg | Rare | 10 |
| `Volcano` | `magma_egg` | Magma Egg | MagmaEgg | Rare | 60 |
| `Volcano` | `inferno_egg` | Inferno Egg | InfernoEgg | Epic | 30 |
| `Volcano` | `dragon_egg` | Dragon Egg | DragonEgg | Legendary | 10 |

Težine ne moraju imati zbir 100. Podešavaju se samo u `EggConfig.BiomePools`; `EggRoller` pre izbora proverava svaki weight, referencirani `EggType`, model ime i rarity. `EggType` je stabilan ID — ne menjati ga zbog kasnijeg preimenovanja asset-a ili UI teksta.

## Atributi

Svaki world egg dobija sledeće atribute na Model-u:

| Attribute | Tip | Značenje |
| --- | --- | --- |
| `UID` | String | novi server-generisan GUID za svako spawnovano jaje |
| `EggName` | String | prikazano ime |
| `EggType` | String | stabilni tip jajeta |
| `Biome` | String | biome izvornog spawn point-a |
| `Rarity` | String | metadata rarity-ja |
| `Size` | String | Tiny, Normal, Large, Huge ili Titanic |
| `Scale` | Number | stvarni `Model:ScaleTo` faktor |
| `SpawnPoint` | String | jedinstveno ime izvornog spawn point-a |
| `Carried` | Boolean | da li ga trenutno neko nosi |
| `CarrierUserId` | Number | UserId nosioca, odnosno 0 kada nije nošeno |

Pri lobby deposit-u `EggInventory` stavka čuva `UID`, `EggName`, `EggType`, `Biome`, `Rarity`, `Size` i `Scale`. Faza 9 će tu metadata koristiti za stvarni Egg Tool; sada ne pravi Tool i ne menja inventory sem postojećeg Folder zapisa.

## Studio test

Pokreni **Play** (ne Run), otvori Output i proveri da nema upozorenja iz `EggSystem` ili `EggRoller`.

1. Sa najmanje jednim `HatchlingFields` i jednim `Volcano` spawn point-om proveri da svaki prikazani egg koristi odgovarajući model i da Output pri spawn-u navodi EggType, Biome, Rarity, SpawnPoint i UID.
2. U Explorer-u proveri svih 10 navedenih atributa na world egg Model-u. Sačekaj nekoliko respawn ciklusa: `UID` mora biti nov pri svakom novom jajetu, dok `SpawnPoint` ostaje isti.
3. Napravi više spawn point-ova za svaki biome i pusti više respawn-ova. Hatchling Fields sme da daje samo Hatchling/Forest/Slime, a Volcano samo Magma/Inferno/Dragon. Privremeno promeni jednu težinu u `EggConfig` na veliku vrednost radi determinističnije provere, zatim je vrati.
4. Podigni jaje. Prompt nestaje, `Carried = true`, `CarrierUserId` je tvoj UserId i Run UI se pojavi. Drop preko smrti mora vratiti prompt, `Carried = false` i `CarrierUserId = 0`.
5. Odnesi jaje u `LobbyDepositZone`. Stavka u `Player > EggInventory` mora imati kopirane atribute; world egg nestaje i tačno njegov spawn point dobija jedno novo jaje nakon osam sekundi.
6. Dok ga nosiš resetuj karakter, potom probaj drugi egg. Ponovi pickup/deposit dva puta i proveri da ne nastaju duplikati world eggova niti više inventory stavki iz jednog deposit-a.
7. Privremeno stavi nepostojeći `Biome` ili pogrešan `ModelName`. Output treba jasno da prijavi problem, a samo taj spawn da bude preskočen; zatim vrati ispravnu konfiguraciju.
8. Proveri trening i biome Recommended Speed UI iz faze 3 dok se jaja spawn-uju i nose.

Rojo build potvrđuje pakovanje projekta, ali nije zamena za ovaj Studio runtime test. Korisnik je potvrdio prolaz 2026-09-20; završene provere su uklonjene iz TODO.md.
