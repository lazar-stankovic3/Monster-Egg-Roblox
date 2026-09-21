# ShopController

Postojeci Studio `Shop` GUI je povezan bez menjanja njegove strukture ili dizajna.

## Konfiguracija

Otvori `src/modules/ShopConfig.luau` i zameni svaki `Id = 0` odgovarajucim ID-em iz Creator Dashboard-a.

- `DeveloperProducts`: osam ponovljivih kupovina za Speed i Cash. Vidljive nagrade su uskladjene sa velikim-brojevi balansom: +1K/+1M/+1B/Cosmic Speed i 250K/250M/250B/250T Cash.
- `GamePasses`: Extra Slots, Fast Hatch, Lucky i VIP. Trenutno imaju `Enabled = false`, pa UI prikazuje `COMING SOON`. Nemoj ih ukljucivati dok perk stvarno ne bude implementiran.
- Featured Buy One/Three/Ten nije povezan jer jos nije definisano sta igrac dobija.

Cena u dugmetu se ucitava direktno sa Roblox-a; broj upisan u Studio UI nije izvor istine.

## Bezbednost

- Klijent samo poziva Roblox purchase prompt.
- Server bira nagradu iskljucivo prema `ProductId` iz `ProcessReceipt`.
- `PurchaseId` se upisuje u isti `MonsterEggPlayerData_v1` profil zajedno sa nagradom.
- Ponovljen receipt vraca `PurchaseGranted` bez ponovnog davanja nagrade.
- Ako profil igraca jos nije spreman, server vraca `NotProcessedYet` da Roblox pokusa ponovo.

## Test

1. Napravi Developer Products u Creator Dashboard-u i unesi njihove ID-eve.
2. Objavi iskustvo; pravi Robux prompt nije pouzdan u neobjavljenom lokalnom mestu.
3. Uključi Studio API Services za DataStore test.
4. Kupi najjeftiniji test proizvod i proveri da se nagrada dodeli jednom.
5. Rejoin: kupljeni Cash/Speed mora ostati sacuvan.
