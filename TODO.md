# Preostali zadaci

Procitati GAMEPLAY.md pre rada. Implementirati samo aktivnu fazu. Brisati stavku kada je zavrsena i proverena; ne brisati samo zato sto je kod napisan. Ne preskakati Studio potvrdu.

## Aktivno — faza 3

- [ ] Postaviti Biomes modele i BiomeZone zapremine u stvarnoj Studio mapi prema docs/FAZA_03.md.
- [ ] Potvrditi Studio testove iz docs/FAZA_03.md: ulaz/izlaz, prag 100, promena Speed-a, reset/teleport, vise bioma, preklapanje, dva igraca i regresija treninga/egg sistema. Kod implementiran; runtime test jos nije izvrsen.

## Sledece faze — tek nakon potvrde prethodne

- [ ] Faza 4: EggConfig, biome egg pools, razliciti modeli jaja i svi egg Attributes; integracija sa postojecim EggSystem bez regresije pickup/carry/drop/deposit/respawn.
- [ ] Faza 5: RarityConfig sa Common/Uncommon/Rare/Epic/Legendary/Mythic i multipliers.
- [ ] Faza 6: SizeConfig income multipliers za Tiny/Normal/Large/Huge/Titanic; sacuvati postojece scale podatke.
- [ ] Faza 7: carry movement penalty na calculated WalkSpeed i pouzdano uklanjanje na drop/deposit/smrt.
- [ ] Faza 8: GuardianService, biome guardian speed, rarity bonus, pathfinding, target lopov, stop uslovi i forced drop; odrediti ponasanje kada vise igraca krade istovremeno.
- [ ] Faza 9: lobby deposit -> pravi vizuelni Egg Tool u Backpack, metadata i ownership, equip bez dupliranja.
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
