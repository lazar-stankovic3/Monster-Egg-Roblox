# Faza 12 — HatchService

Status 2026-09-20: implementirano; čeka korisnički Studio test. Faze 1–11 ostaju potvrđene.

## Ponašanje

Postavljanje jajeta automatski pokreće server timer i odbrojavanje iznad jajeta. Common 3s, Uncommon 5s, Rare 8s, Epic 15s, Legendary 30s, Mythic 60s. Kada timer istekne, server zamenjuje jaje jednim monsterom na istom mestu i prikazuje ime monstera.

Jedna centralna Heartbeat provera na 0.1s obrađuje sva aktivna jaja. Nema posebne petlje po jajetu. Reset karaktera ne prekida hatch. Izlazak vlasnika ili uklanjanje jajeta otkazuje hatch i čisti pripremljeni model. Nema naknadnog hatch-a za novog vlasnika istog plota.

Priprema i server izbor monstera obavljaju se pre trošenja Tool-a. Greška konfiguracije/modela odbija placement i ostavlja jaje u inventaru. Klijent ne bira monstera niti trajanje i ne može pozvati hatch remote. Ponovljeni klik ne duplira model.

## Privremeni modeli

Korisnik nema monster modele. Za test se automatski generišu jednostavni obojeni modeli sa očima; zec ima uši, zmaj krila. Imaju Placeholder=true. Nije potrebna nova Studio postavka.

Kasnije opciono dodaj ServerStorage.MonsterModels (Folder), pa Model-e sa bar jednim BasePart-om i sledećim imenima: GreenSlime, LeafBunny, BabyGoblin, ForestDragon, MagmaSlime, FlameGoblin, InfernoDragon. PrimaryPart je preporučen; bez njega koristi se prvi BasePart. Modeli se koriste kao statičan prikaz, sa uklonjenim skriptama/vezama/silama, usidreni i bez kolizije. Ako model ne postoji, koristi se privremeni model.

## Početni pool-ovi

- Hatchling Egg i legacy Basic Egg: Green Slime 70%, Leaf Bunny 20%, Baby Goblin 8%, Forest Dragon 2% (iz gameplay specifikacije).
- Forest Egg: Leaf Bunny 60%, Baby Goblin 30%, Forest Dragon 10%.
- Slime Egg: Green Slime 100%.
- Magma Egg: Magma Slime 75%, Flame Goblin 25%.
- Inferno Egg: Flame Goblin 80%, Inferno Dragon 20%.
- Dragon Egg: Inferno Dragon 100%.

Pool-ovi osim Hatchling-a su početne vrednosti za test; menjaju se u HatchConfig.Pools. Monster nasleđuje Biome, Rarity, Size i Scale jajeta u ovoj fazi. Puna MonsterConfig/economy pravila dolaze u fazi 13.

## Veličina, mesto i podaci

Jaje i dalje zadržava punu originalnu veličinu u ruci, preview-u i na plotu. Na korisnikov zahtev monster zadržava tačan Scale jajeta: Tiny 0.7, Normal 1, Large 1.4, Huge 1.9, Titanic 2.6. Nema umanjivanja prema otisku jajeta. Size/Scale i VisualScale odgovaraju nasleđenoj veličini. Širi monster može preći nekadašnji otisak jajeta ili ivicu površine; naredni placement proverava njegove stvarne dimenzije. Donja površina monstera ostaje na istom mestu kao donja površina jajeta, uključujući rotirane plotove.

Monster dobija nov UID i SourceEggUID koji povezuje izvorno jaje. Čuva EggType, EggName, Biome, Rarity, Size, Scale, OwnerUserId; dodaje MonsterId, MonsterName, IsMonster=true, VisualScale i HatchedAt. Jaje tokom čekanja ima HatchEndsAt i HatchState=Incubating.

U ovoj fazi Workspace.Plots.PlotN.PlacedEggs sadrži i jaja i izležene monstere. IsMonster ih razlikuje. Oboje zauzimaju kapacitet, pa hatch ne otvara sedmo mesto. Postojeća provera placement-a koristi stvarne dimenzije modela. PlotService čisti ovaj namenski runtime folder na izlasku vlasnika.

Nema income-a, Index unlock-a, animacije monstera ili DataStore čuvanja u ovoj fazi; ostaju za planirane faze.

## Explorer / kod

- ReplicatedStorage.Modules.HatchConfig — timeri, weighted pool-ovi i nazivi privremenih monstera.
- ServerScriptService.Server.HatchService — priprema modela, countdown, centralni scheduler i zamena jajeta.
- ServerScriptService.Server.EggPlacementSystem — pokreće servis i hatch posle uspešnog placement-a.
- Svako jaje dobija HatchCountdown (BillboardGui); pri hatch-u isti GUI postaje MonsterLabel.

## Studio test

1. Stop → Rojo sync → nova Play sesija. Deponuj i postavi Common jaje: odbrojavanje počinje na 3s, pa jedan monster zameni jaje na istom mestu. Ime je vidljivo iznad njega, a model ima Placeholder=true.
2. Probaj Uncommon/Rare/Epic/Legendary i proveri 5/8/15/30s. Mythic timer 60s je podešen za buduća Mythic jaja.
3. Postavi više jaja: svaki timer radi nezavisno, bez dupliranja. Hatchling može dati četiri navedena ishoda; mali uzorak ne mora imati tačne procente.
4. Proveri UID, SourceEggUID, OwnerUserId, Biome, Rarity, Size i Scale. Inventory zapis i Tool izvornog jajeta ne vraćaju se posle hatch-a ili respawna.
5. Probaj Tiny i Titanic i jaje blizu ivice Place dela. Jaje i monster se ne umanjuju; proveri nasleđeni scale i da monster stoji na površini.
6. Popuni šest mesta i sačekaj hatch: sedmo jaje ne može da se postavi. Preview je crven preko monstera.
7. Resetuj tokom dužeg timera: hatch se normalno završava. Izađi iz servera tokom timera: stari hatch se ne pojavljuje na plotu sledećeg vlasnika. Testiraj i dva igrača istovremeno.
8. Proveri regresiju pickup/deposit/Tool/preview i da nema crvenih Output grešaka.

Rojo build i statičke provere nisu Studio runtime potvrda. Ova faza ostaje nepotvrđena do korisničkog testiranja.