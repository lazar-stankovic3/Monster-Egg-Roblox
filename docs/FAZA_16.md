# Faza 16 — IndexUi

Status 2026-09-20: implementirano, čeka Studio potvrdu. Čuvanje Index-a je u fazi 17 prebačeno u objedinjeni PlayerData store. Korisnik je potvrdio fazu 15 i dostavio strukturu postojećeg StarterGui.IndexUi. Thermal Chamber u Index-u treba da se zove Volcano.

## Postojeći UI

IndexUI LocalScript u StarterPlayerScripts.Client povezuje PlayerGui.IndexUi.Frame.BottomFrame.BiomeScroller i MonsterDetails, bez zamene korisnikovog ScreenGui asset-a. Promene se primenjuju pri pokretanju: BiomeSection_4.BiomePreview.BiomeName postaje Volcano. Edit-mode StarterGui ostaje sa svojim sačuvanim sadržajem; runtime binder koristi ispravan naziv.

Hatchling Fields ima četiri trenutno definisane vrste, Volcano tri. Višak od osam slotova po biome-u i sekcije bez definisanih monstera se sakrivaju. Globalni broj je 7, ne lažnih 64; početni mock brojači se zamenjuju stvarnim podacima. Katalog MonsterConfig je izvor imena, biome-a, podrazumevane rarity vrste, BaseIncome i stabilnog IndexId.

Zaključani slot pokazuje ? i ???. Klik na slot prikazuje detalje, a zaključani detalji ostaju skriveni. Otključani slot dobija ime i 3D viewport modela. ReplicatedStorage.IndexPreviews automatski sadrži očišćene modele u normalnoj veličini (postojeći privremeni modeli, ili pravi ako su dostupni).

MonsterDetails dobija BaseIncome i BestSizeFound TextLabel-e kloniranjem postojećeg Biome stila. Slika i tekstualni redovi se raspoređuju u istom panelu da ostane prostor za nove podatke. Rarity u Index-u predstavlja katalog vrste (BaseRarity), dok konkretan monster na plotu i dalje nasleđuje rarity jajeta. Base Income je osnovna vrednost, bez rarity/size multiplikatora.

ExitButton zatvara Frame; taster I otvara/zatvara Index. Postojeća spoljna dugmad i dalje mogu da upravljaju istim ScreenGui/Frame-om. Binder se ponovo povezuje nakon respawna bez dupliranja konekcija.

## Otključavanje i Best Size

IndexService.RecordHatch poziva se samo na serveru nakon stvarne zamene jajeta monsterom. Pickup, deposit, placement i priprema budućeg modela ne otključavaju Index. Vlasnik dobija Player.IndexUnlocks.<IndexId> (Folder) sa BestSizeFound atributom.

Red veličina je Tiny < Normal < Large < Huge < Titanic. Ponovni hatch iste vrste ne povećava broj unlock-a; samo veća veličina poboljšava zapis. Svi klijentski prikazi čitaju server repliku. Nema remote-a kojim klijent može tražiti otključavanje.

## Čuvanje Index-a

Index unlock-i i Best Size sada se čuvaju u `MonsterEggPlayerData_v1` zajedno sa ostalim podacima igrača. Stari `MonsterEggIndex_v1` čita se samo pri prvoj migraciji. `UpdateAsync` zadržava najveći Best Size, a neuspelo ili nepoznato učitavanje blokira save. Detalji i testovi su u docs/FAZA_17.md. `Player.IndexDataStatus` i dalje daje Loading/Ready/LoadFailed/SaveFailed radi postojećeg UI-a.

Za stvaran save test objavi test experience i uključi Game Settings → Security → Enable Studio Access to API Services. Bez dostupnog DataStore-a moguće je testirati samo session unlock. Faza 17 kasnije objedinjuje ovaj Index save sa ostalim podacima; migracija postojećeg Index store-a tada mora sačuvati napredak.

## Studio test

1. Stop → Rojo sync → Play. Otvori I: vidi se postojeći dizajn, Volcano umesto Thermal Chamber, četiri Hatchling vrste i tri Volcano vrste, stvarni globalni/biome brojači i nova polja u detaljima.
2. Ukradi/deponuj/postavi jaje: Index se još ne otključava. Sačekaj hatch: samo vlasniku se otključava prava vrsta, ažuriraju se brojači i pojavljuje 3D prikaz.
3. Klikni otključanu vrstu: ime, katalog rarity, biome, Base Income i Best Size Found su ispravni. Klikni zaključanu: ostaje ???.
4. Izlegni istu vrstu ponovo: brojač ne raste. Veći Size poboljšava Best Size, manji ga ne smanjuje.
5. Zatvori, otvori i resetuj: nema duplih dugmadi/konekcija i podaci ostaju isti. Proveri panel i scroll na manjoj rezoluciji.
6. Sa dostupnim DataStore-om sačekaj autosave ili izađi, pa se vrati: unlock-i i Best Size ostaju. Proveri IndexDataStatus=Ready i PlayerDataStatus=Ready.
7. Bez API pristupa proveri session-only stanje, bez rušenja hatch-a i bez pokušaja prepisivanja podataka posle neuspešnog load-a.
8. Dva igrača imaju različite Index zapise; hatch jednog ne otključava drugom. Prethodni gameplay sistemi i dalje rade.

Rojo build proverava pakovanje; stvaran UI izgled i DataStore ponašanje moraju se potvrditi u Studio-u.
