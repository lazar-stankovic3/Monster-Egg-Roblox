# Faza 14 — IncomeService

Status 2026-09-20: implementirano, čeka Studio potvrdu. Korisnik je potvrdio fazu 13 i zatražio nastavak.

IncomeSystem pokreće IncomeService, oba u ServerScriptService.Server. Jedna centralna Heartbeat veza na interval od jedne sekunde računa zbir preko MonsterService.GetIncome(player) i dodaje ga u Player.Stats.Cash. Start je idempotentan i ne pravi duple isplate ako se pozove ponovo.

Računaju se samo izleženi monsteri u dodeljenom plotu, sa odgovarajućim vlasnikom i jedinstvenim UID-em. Formula dolazi iz server konfiguracije. Jaja, Backpack, tuđi modeli i prikazni FinalIncome atribut ne određuju isplatu. Nema klijentskog remote-a za dodavanje novca.

Player.CashPerSecond (Number Attribute) prikazuje ukupnu trenutnu stopu, osveženu na svakom tick-u. Nema novog HUD-a u ovoj fazi. Postojeći leaderstats.Cash automatski prikazuje ceo broj; Stats.Cash ostaje NumberValue sa decimalama (npr. 7.5/sec se ne skraćuje na 7).

Prva isplata je na sledećem centralnom tick-u posle hatch-a, u roku oko jedne sekunde. To je obračun trenutnog stanja po tick-u, bez proporcionalnog obračuna dela sekunde. Pri dugom zastoju servera ne ponavljaju se propušteni tick-ovi sa novim stanjem. Nema offline zarade ili naknadne isplate propuštenog vremena.

Respawn ne prekida prihod postojećih monstera. Bez plota ili monstera stopa je 0. Izlazak igrača uklanja ga iz centralnog obračuna, a postojeći PlotService čisti modele. Neispravan ili nedostajući Stats.Cash preskače isplatu, bez rušenja servisa. Neispravne/beskonačne vrednosti se ne upisuju.

## Studio provera

1. Stop → Rojo sync → Play. Bez monstera Cash ne raste, a Player.CashPerSecond je 0.
2. Izlegni Common/Normal Green Slime: Stats.Cash raste za 2 na svakom tick-u, CashPerSecond je 2.
3. Izlegni drugog monstera: zbir CashPerSecond treba da odgovara zbiru prikazanih stopa svih tvojih monstera. Proveri razliku Stats.Cash kroz deset tick-ova.
4. Rare/Large Green Slime daje 7.5/sec. U Stats.Cash se čuvaju decimale; leaderstats prikazuje zaokruženo naniže.
5. Dok jaje čeka hatch ne donosi prihod. Novi monster ulazi u zbir nakon hatch-a. Brzi klikovi ne dupliraju prihod.
6. Resetuj karakter: prihod se nastavlja jednom po tick-u, bez dupliranja.
7. Test dva igrača: svaki dobija samo prihod svojih monstera. Izlazak vlasnika i nova dodela plota ne prenose stari prihod novom vlasniku.
8. U server Command Bar-u pozovi IncomeService.Start() ponovo: broj isplata ostaje isti. Proveri da nema Output grešaka i da trening, Tool, placement i hatch i dalje rade.

DataStore ostaje za fazu 17, offline income za fazu 18. Rojo build proverava pakovanje, ne zamenjuje Studio test.