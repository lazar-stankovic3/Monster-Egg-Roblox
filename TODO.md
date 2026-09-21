# Preostali zadaci

## Trenutni status — 2026-09-20

- [x] Sve faze 1–11 su završene i potvrđene korisnikovim testiranjem u Roblox Studio-u.
- Potvrda obuhvata sve ranije odložene provere, poslednje ispravke Guardian-a i Egg Tool fizike, originalnu veličinu jajeta u ruci/preview-u/na plotu, poziciju miša i slobodno postavljanje.
- Nema preostalih nepotvrđenih provera za faze 1–11.
- Faza 13 je potvrđena korisnikovim testiranjem. Faza 14 je potvrđena. Faza 15 je potvrđena korisnikovim testiranjem. Faza 16 — IndexUi je implementirana i čeka Studio/UI potvrdu. Faza 17 i čuvanje monstera potvrđeni su 2026-09-21 nakon povezivanja PlayerData bootstrap-a. Korisnik je potvrdio da sve radi nakon faze 18. Faza 19 — plot upgrades je implementirana i čeka potvrdu prema docs/FAZA_19.md.

Pročitati GAMEPLAY.md pre rada. Implementirati jednu fazu po jednu. Završene provere uklonjene su iz liste na osnovu izričite korisničke potvrde, ne samo prolaska build-a.

## Sledece faze — tek nakon potvrde prethodne
- [ ] Faza 12 (preostale provere): weighted pool, metadata, kapacitet šest mesta i multiplayer cleanup prema docs/FAZA_12.md. Hatch i nasleđivanje veličine korisnik je potvrdio; koriste se privremeni modeli.
- [ ] Faza 16: potvrditi postojeći IndexUi, Volcano naziv, unlock tek na hatch-u, 3D prikaze/detalje, Best Size, brojače i DataStore prema docs/FAZA_16.md. Objediniti save sa fazom 17 uz migraciju MonsterEggIndex_v1.
- [x] Faza 17: čuvanje i vraćanje monstera potvrđeno 2026-09-21; objedinjeni PlayerData bootstrap sada se garantovano pokreće iz EggSystem-a.
- [ ] Pre faze 18: potvrditi da monsteri hodaju, zastaju, ostaju unutar svog plota, izbegavaju zauzete destinacije i nastavljaju posle učitavanja prema docs/MONSTER_WANDER.md.
- [x] Faza 18: korisnik je 2026-09-21 potvrdio da sve radi nakon testa persistence-a i offline income implementacije.
- [ ] Faza 19: potvrditi kupovinu 6/8/12/16 slotova, tačno skidanje Cash-a, server validaciju i persistence prema docs/FAZA_19.md.
- [ ] Faza 20: UI polish, animacije, zvuci, chase muzika, rarity VFX, particles, floating Speed/income i tranzicije.


