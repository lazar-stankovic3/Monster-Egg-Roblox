# Faza 6 — SizeConfig

Status 2026-09-20: završeno i potvrđeno korisnikovim testiranjem u Roblox Studio-u. Sve faze 1–11 i ranije odložene provere su potvrđene. Test koraci ispod ostaju kao referenca za regresiju.

## Fajlovi

| Fajl | Explorer lokacija | Uloga |
| --- | --- | --- |
| `src/modules/SizeConfig.luau` | `ReplicatedStorage > Modules > SizeConfig` | stabilne size definicije i income multiplikatori |
| `src/modules/EggConfig.luau` | `ReplicatedStorage > Modules > EggConfig` | postojeće `Scale` i `Weight` vrednosti za egg spawn |
| `src/modules/EggRoller.luau` | `ReplicatedStorage > Modules > EggRoller` | proverava da izabrani size iz EggConfig-a postoji u SizeConfig-u |

## Income multiplikatori

| Size | IncomeMultiplier | Postojeći Scale | Postojeći spawn Weight |
| --- | ---: | ---: | ---: |
| Tiny | 0.7 | 0.7 | 20 |
| Normal | 1 | 1 | 45 |
| Large | 1.5 | 1.4 | 22 |
| Huge | 2.5 | 1.9 | 10 |
| Titanic | 5 | 2.6 | 3 |

`Scale` nije income multiplier: koristi se isključivo za `Model:ScaleTo` pri spawn-u i zato je ostao u postojećem `EggConfig.Sizes`. `SizeConfig.GetIncomeMultiplier(sizeName)` vraća prihod multiplikator ili `nil` za nevažeći size. Faze 13 i 14 će ga koristiti u formuli prihoda; ova faza ne menja Cash, Speed niti fizičku veličinu jaja.

Carry movement penalty je naknadno dodat u fazi 7; vidi `FAZA_07.md`.

## Studio test

1. Pokreni **Play** i proveri da nema greške `SizeConfig mora biti ModuleScript` ili greške iz `EggRoller`.
2. Spawnuj više jaja i proveri da se i dalje pojavljuju Tiny, Normal, Large, Huge i Titanic sa nepromenjenim relativnim fizičkim veličinama.
3. U server Command Bar-u proveri API:

```lua
local size = require(game.ReplicatedStorage.Modules.SizeConfig)
assert(size.IsValid("Titanic"))
assert(size.GetIncomeMultiplier("Titanic") == 5)
assert(size.GetIncomeMultiplier("Unknown") == nil)
```

4. Privremeno promeni jedno `EggConfig.Sizes` ime u `Unknown`, pokreni Play i proveri da taj spawn bude odbijen uz poruku `ne postoji u SizeConfig`; vrati originalni naziv.
5. Ponovi pickup/carry/drop/deposit i proveri da `Size` i `Scale` atributi ostaju isti kao pre ove faze.

Rojo build nije zamena za Studio runtime test.
