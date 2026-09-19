# Preostali zadaci

## Trenutni status

- [x] Faza 7: Studio potvrda carry movement penalty-ja.
- Aktivna faza 9: vizuelni Egg Tool je implementiran; ceka Studio provere prema docs/FAZA_09.md. Korisnik je zatrazio nastavak 2026-09-19; preostale provere faze 8 su odlozene, nisu oznacene kao prosle.
- Korisnik je potvrdio da ragdoll radi nakon dodavanja AnimationConstraint podrške. Poslednja izmena protiv sudara jajeta sa odbačenim igračem još čeka potvrdu.

Procitati GAMEPLAY.md pre rada. Implementirati samo aktivnu fazu. Brisati stavku kada je zavrsena i proverena; ne brisati samo zato sto je kod napisan. Ne preskakati Studio potvrdu.

## Odloženo — faza 4 (Studio potvrda)

- [ ] U Studio postaviti modele iz ServerStorage.EggModels i `Biome` Attribute na svim EggSpawnPoints prema docs/FAZA_04.md.
- [ ] Potvrditi Studio testove iz docs/FAZA_04.md: pool-ove, atribute, pickup/carry/drop/deposit i respawn bez regresije.

## Odloženo — faza 5 (Studio potvrda)

- [ ] Potvrditi RarityConfig i validaciju egg rarity-ja u Studio-u prema docs/FAZA_05.md. Kod je dodat; income se ne menja do faza 13/14.

## Odloženo — faza 6 (Studio potvrda)

- [ ] Potvrditi SizeConfig, validaciju size imena i očuvani scale spawn u Studio-u prema docs/FAZA_06.md. Kod je dodat; income se ne menja do faza 13/14.

## Odloženo — faza 8 (Studio potvrda)

- [ ] Potvrditi poslednji fix: ispušteno jaje ne zaustavlja odbacivanje; probati Tiny/Titanic i različite smerove gledanja.
- [ ] Potvrditi jačinu odbacivanja 95 horizontalno / 42 vertikalno, ustajanje, vraćanje animacija i pickup-a, ponovljene udarce i reset tokom ragdoll-a.
- [ ] Potvrditi kontinuirano praćenje, prepreke i zaustavljanje na drop/deposit/smrt/izlazak/safe zonu prema docs/FAZA_08.md.
- [ ] Potvrditi biome/rarity brzine i dva istovremena lopova sa odvojenim Guardian targetima.
- [ ] Potvrditi regresioni test na legacy Motor6D rig-u; korisnikov rig sa AnimationConstraint zglobovima već aktivira ragdoll.

## Aktivno — faza 9 (Studio potvrda)

- [ ] Potvrditi lobby deposit -> vizuelni Egg Tool, sacuvane metadata/ownership, jedan zapis i Tool po UID-u, equip/unequip bez dupliranja, respawn u istoj sesiji i dva igraca prema docs/FAZA_09.md.

## Sledece faze — tek nakon potvrde prethodne
- [ ] Faza 10: PlotService, dodela/cleanup OwnerUserId i pocetnih 6 EggSlots; ponasanje kada nema slobodnih plotova.
- [ ] Faza 11: Place Egg prompt, ownership/proximity/slot/Tool validacija, prenos egg podataka na slot.
- [ ] Faza 12: HatchService, rarity timer, countdown, weighted monster pool i zamena jajeta monsterom.
- [ ] Faza 13: MonsterConfig/MonsterService, modeli i metadata, income formula i trajni slot ownership.
- [ ] Faza 14: centralni IncomeService i zbir Cash/sec svih monstera vlasnika.
- [ ] Faza 15: treadmill shop, konfiguracija Starter/Metal/Turbo/Neon/Void, server naplata, ownership i zamena na plotu.
- [ ] Faza 16: povezati postojeci Index UI, unlock tek na hatch-u, detalji, Best Size Found, globalni/per-biome counts i DataStore pamcenje; zatim objediniti sa fazom 17.
- [ ] Faza 17: PlayerDataService za sve podatke iz GAMEPLAY.md, stabilni UID-evi, autosave/PlayerRemoving/BindToClose, obrada load/save gresaka i zastita od prepisivanja podataka neuspesnog load-a.
- [ ] Faza 18 (kasnije): LastLogoutTime, offline income do 6h i prikaz zarade bez duple isplate.
- [ ] Faza 19: server kupovina plot upgrades 6/8/12/16 slotova i persistence.
- [ ] Faza 20: UI polish, animacije, zvuci, chase muzika, rarity VFX, particles, floating Speed/income i tranzicije.
