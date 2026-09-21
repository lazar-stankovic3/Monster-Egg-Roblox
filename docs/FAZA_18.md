# Faza 18 — offline income

Status 2026-09-21: implementirano, čeka Roblox Studio/DataStore potvrdu.

## Ponašanje

- `LastLogoutTime` se čuva zajedno sa Cash-em i trenutnim monsterima pri svakom
  autosave-u i završnom save-u.
- Pri sledećem ulasku server računa prihod samo iz monstera koji se nalaze u
  sačuvanom zapisu.
- Offline period je ograničen na šest sati.
- Cash isplata i pomeranje timestamp-a rade u jednom `UpdateAsync` pozivu. Time
  isti offline period ne može biti isplaćen dva puta pri brzom reconnect-u ili
  preklapanju servera.
- Igrač dobija kratku poruku sa zarađenim iznosom i vremenom odsustva. Server
  objavljuje `OfflineIncomeAmount` i `OfflineIncomeSeconds` atribute na Player-u.
- Prvi ulazak nema offline isplatu. Neispravni ili nepoznati monster zapisi ne
  proizvode prihod.

## Studio test

1. Objavi test experience i uključi **Game Settings → Security → Enable Studio
   Access to API Services**.
2. Izlegni monster i sačekaj da `PlayerDataStatus` bude `Ready`.
3. Zapiši Cash, izađi i sačekaj najmanje jedan minut.
4. Ponovo uđi. Monster mora biti vraćen, Cash uvećan za
   `CashPerSecond × vreme odsustva`, a poruka mora prikazati offline zaradu.
5. Odmah ponovo izađi i uđi. Prethodni period ne sme biti ponovo isplaćen.
6. Za proveru limita vrati `LastLogoutTime` u test DataStore zapisu više od šest
   sati unazad. Isplata mora biti ograničena na tačno šest sati.
7. Sa dva igrača proveri da svaki dobija prihod samo od svojih sačuvanih monstera.

Rojo build proverava pakovanje. Pravi DataStore, protek vremena i sprečavanje
duple isplate moraju se potvrditi u objavljenom Studio testu.
