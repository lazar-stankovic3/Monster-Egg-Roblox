# Faza 5 — RarityConfig

Status: `RarityConfig` je dodat i EggRoller sada koristi isti centralni izvor za validaciju rarity-ja. Faza 4 je korisničkim izborom odložena bez Studio potvrde; njen test ostaje u `FAZA_04.md`.

## Fajlovi

| Fajl | Explorer lokacija | Uloga |
| --- | --- | --- |
| `src/modules/RarityConfig.luau` | `ReplicatedStorage > Modules > RarityConfig` | jedini izvor istine za rarity definicije i income multipliere |
| `src/modules/EggRoller.luau` | `ReplicatedStorage > Modules > EggRoller` | proverava da svaki EggConfig rarity postoji u RarityConfig-u |
| `src/modules/EggConfig.luau` | `ReplicatedStorage > Modules > EggConfig` | egg tipovi i njihovi rarity nazivi; više nema dupliranu listu validnih rarity-ja |

## Definicije

| Rarity | IncomeMultiplier |
| --- | ---: |
| Common | 1 |
| Uncommon | 1.5 |
| Rare | 2.5 |
| Epic | 5 |
| Legendary | 10 |
| Mythic | 25 |

`RarityConfig.IsValid(rarityName)` proverava da li je rarity podržan. `GetDefinition(rarityName)` vraća definiciju ili `nil`, a `GetIncomeMultiplier(rarityName)` vraća broj ili `nil`. API namerno ne bira podrazumevanu vrednost za nepoznat rarity — server koji ga bude koristio mora takvu grešku eksplicitno obraditi.

Ova faza još ne menja Cash, niti dodaje income tick. Multiplikator će biti primenjen tek kada faze 13 i 14 uvedu monster metadata i centralni `IncomeService`. Zato postojeći pickup, carry, drop, deposit, respawn, Speed i Cash ostaju nepromenjeni.

## Studio test

Pokreni **Play** i otvori server Output.

1. Proveri da nema greške `RarityConfig mora biti ModuleScript` ili drugih novih grešaka iz `EggRoller`.
2. Sa ispravnim EggConfig-om proveri da se jaja iz postojećih pool-ova i dalje spawn-uju; Common, Uncommon, Rare, Epic i Legendary definicije moraju biti prihvaćene.
3. Privremeno postavi `Rarity = "Invalid"` na jednom egg tipu u `EggConfig`, zaustavi i ponovo pokreni Play. Taj biome spawn mora biti preskočen uz jasnu poruku da rarity nije validan. Vrati originalnu vrednost.
4. U server Command Bar-u možeš proveriti API:

```lua
local rarity = require(game.ReplicatedStorage.Modules.RarityConfig)
assert(rarity.IsValid("Rare"))
assert(rarity.GetIncomeMultiplier("Rare") == 2.5)
assert(not rarity.IsValid("Invalid"))
assert(rarity.GetIncomeMultiplier("Invalid") == nil)
```

5. Ponovi postojeći egg pickup/carry/drop/deposit tok kako bi potvrdio da validacija nema regresiju.

Rojo build proverava pakovanje, ali nije zamena za Studio runtime test.
