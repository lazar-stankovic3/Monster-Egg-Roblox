# Potpuni balans progresije

Ovaj dokument opisuje aktivnu ekonomsku krivu. Veliki brojevi koriste kratice:

- K = thousand, M = million, B = billion
- T = trillion, Qa = quadrillion, Qi = quintillion
- zatim Sx, Sp, Oc, No, Dc i dalje do Vg; posle toga prikaz prelazi na naucnu notaciju

## Area progresija

| # | Area | Recommended Speed | Ciljni base income jednog monstera |
|---|---|---:|---:|
| 1 | Hatchling Fields | 100 | 25 - 1.5K/sec |
| 2 | Bio Marsh | 2.5K | 2K - 100K/sec |
| 3 | Spore Lab | 50K | 200K - 10M/sec |
| 4 | Volcano | 1M | 20M - 1B/sec |
| 5 | Cryo Sector | 25M | 2B - 100B/sec |
| 6 | Fossil Lab | 500M | 200B - 10T/sec |
| 7 | Mutation Core | 10B | 20T - 1Qa/sec |
| 8 | Cosmic Incubator | 250B | 2Qa - 100Qa/sec |

Base income se zatim mnozi rarity i size multiplikatorom, pa najbolji Cosmic monster moze preci u Qi/sec opseg.

## Rarity i size jackpot

Rarity multiplikatori: Common 1x, Uncommon 2x, Rare 5x, Epic 12x, Legendary 30x, Mythic 75x.

Size multiplikatori: Tiny 0.65x, Normal 1x, Large 1.75x, Huge 3.5x, Titanic 8x.

Kombinovani Mythic Titanic daje 600x base income. Ovo retkom hatch-u daje vidljiv skok bez potrebe da svaka obicna nagrada bude prevelika.

## Treadmill ekonomija

| Nivo | Cena | Speed/sec |
|---|---:|---:|
| Starter | 0 | 20 |
| Marsh Runner | 50K | 125 |
| Spore Turbo | 5M | 2.5K |
| Magma Drive | 500M | 50K |
| Cryo Reactor | 50B | 1.25M |
| Fossil Engine | 5T | 25M |
| Mutation Core | 500T | 500M |
| Cosmic Drive | 50Qa | 12.5B |

Sa odgovarajucim treadmill-om, osnovni Speed prag sledece area-e zahteva otprilike 20 sekundi aktivnog treninga. Cash cena sprecava preskakanje ekonomskog dela progresije.

## Plot kapacitet

- 6 slotova: besplatno
- 8 slotova: 250K
- 12 slotova: 250M
- 16 slotova: 250B

Upgrade-i su rasporedjeni kroz ranu, srednju i kasniju igru umesto da se svi kupe u prvoj area-i.

## Robux paketi

Postojeci nazivi Frame-ova ostaju isti zbog stabilnih UI putanja, ali ShopController menja vidljivo ime:

- Speed: +1K, +1M, +1B, Cosmic Speed (minimum 250B)
- Cash: 250K, 250M, 250B, 250T

ID-evi su i dalje 0 dok se proizvodi ne naprave u Creator Dashboard-u.

## Trenutni content gap

Kod trenutno sadrzi konkretne egg/monster definicije samo za Hatchling Fields i Volcano. `ProgressionConfig` vec cuva ciljne vrednosti svih osam area, ali Bio Marsh i Spore Lab moraju dobiti egg poolove i monstere pre nego sto put do Volcano bude potpuno gladak. Isto vazi za tri area-e posle Volcano-a.

Ne treba povecavati brojke nasumicno u pojedinacnim servisima. Menjati:

- `ProgressionConfig` za area pragove i buduce income bandove
- `MonsterConfig` za base income konkretnog monstera
- `TreadmillConfig` za cenu i Speed/sec
- `RarityConfig` i `SizeConfig` samo kada se menja globalni jackpot balans
