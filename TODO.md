# Preostali zadaci

## Trenutni status — 2026-09-20

- [x] Sve faze 1–11 su završene i potvrđene korisnikovim testiranjem u Roblox Studio-u.
- Potvrda obuhvata sve ranije odložene provere, poslednje ispravke Guardian-a i Egg Tool fizike, originalnu veličinu jajeta u ruci/preview-u/na plotu, poziciju miša i slobodno postavljanje.
- Nema preostalih nepotvrđenih provera za faze 1–11.
- Faza 13 je potvrđena korisnikovim testiranjem. Faza 14 je potvrđena. Faza 15 je potvrđena korisnikovim testiranjem. Faza 16 — IndexUi je implementirana i čeka Studio/UI potvrdu. Faza 17 — objedinjeni PlayerData je implementirana i čeka Studio/DataStore potvrdu. Monster kretanje po plotu je implementirano pre faze 18 i čeka potvrdu prema docs/MONSTER_WANDER.md.

Pročitati GAMEPLAY.md pre rada. Implementirati jednu fazu po jednu. Završene provere uklonjene su iz liste na osnovu izričite korisničke potvrde, ne samo prolaska build-a.

## Sledece faze — tek nakon potvrde prethodne
- [ ] Faza 12 (preostale provere): weighted pool, metadata, kapacitet šest mesta i multiplayer cleanup prema docs/FAZA_12.md. Hatch i nasleđivanje veličine korisnik je potvrdio; koriste se privremeni modeli.
- [ ] Faza 16: potvrditi postojeći IndexUi, Volcano naziv, unlock tek na hatch-u, 3D prikaze/detalje, Best Size, brojače i DataStore prema docs/FAZA_16.md. Objediniti save sa fazom 17 uz migraciju MonsterEggIndex_v1.
- [ ] Faza 17: potvrditi objedinjeni PlayerDataService, stabilne UID-eve, restore hatch timera, autosave/PlayerRemoving/BindToClose, migraciju Index-a i zaštitu od prepisivanja posle neuspešnog load-a prema docs/FAZA_17.md.
- [ ] Pre faze 18: potvrditi da monsteri hodaju, zastaju, ostaju unutar svog plota, izbegavaju zauzete destinacije i nastavljaju posle učitavanja prema docs/MONSTER_WANDER.md.
- [ ] Faza 18 (kasnije): LastLogoutTime, offline income do 6h i prikaz zarade bez duple isplate.
- [ ] Faza 19: server kupovina plot upgrades 6/8/12/16 slotova i persistence.
- [ ] Faza 20: UI polish, animacije, zvuci, chase muzika, rarity VFX, particles, floating Speed/income i tranzicije.


