# Preostali zadaci

## Trenutni status — 2026-09-20

- [x] Sve faze 1–11 su završene i potvrđene korisnikovim testiranjem u Roblox Studio-u.
- Potvrda obuhvata sve ranije odložene provere, poslednje ispravke Guardian-a i Egg Tool fizike, originalnu veličinu jajeta u ruci/preview-u/na plotu, poziciju miša i slobodno postavljanje.
- Nema preostalih nepotvrđenih provera za faze 1–11.
- Faza 13 je potvrđena korisnikovim testiranjem. Aktivna faza 14 — IncomeService: implementirana, čeka Studio potvrdu prema docs/FAZA_14.md.

Pročitati GAMEPLAY.md pre rada. Implementirati jednu fazu po jednu. Završene provere uklonjene su iz liste na osnovu izričite korisničke potvrde, ne samo prolaska build-a.

## Sledece faze — tek nakon potvrde prethodne
- [ ] Faza 12 (preostale provere): weighted pool, metadata, kapacitet šest mesta i multiplayer cleanup prema docs/FAZA_12.md. Hatch i nasleđivanje veličine korisnik je potvrdio; koriste se privremeni modeli.
- [ ] Faza 14: Studio potvrda centralne Cash isplate, zbira CashPerSecond, decimalne zarade, respawna i odvojenih prihoda dva igrača prema docs/FAZA_14.md.
- [ ] Faza 15: treadmill shop, konfiguracija Starter/Metal/Turbo/Neon/Void, server naplata, ownership i zamena na plotu.
- [ ] Faza 16: povezati postojeci Index UI, unlock tek na hatch-u, detalji, Best Size Found, globalni/per-biome counts i DataStore pamcenje; zatim objediniti sa fazom 17.
- [ ] Faza 17: PlayerDataService za sve podatke iz GAMEPLAY.md, stabilni UID-evi, autosave/PlayerRemoving/BindToClose, obrada load/save gresaka i zastita od prepisivanja podataka neuspesnog load-a.
- [ ] Faza 18 (kasnije): LastLogoutTime, offline income do 6h i prikaz zarade bez duple isplate.
- [ ] Faza 19: server kupovina plot upgrades 6/8/12/16 slotova i persistence.
- [ ] Faza 20: UI polish, animacije, zvuci, chase muzika, rarity VFX, particles, floating Speed/income i tranzicije.


