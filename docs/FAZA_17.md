# Faza 17 — objedinjeni PlayerData

Status 2026-09-20: implementirano, čeka Roblox Studio i DataStore potvrdu.

## Šta se čuva

Jedan DataStore `MonsterEggPlayerData_v1`, ključ `u_<UserId>`, čuva verzionisan Lua zapis:

- `Stats.Speed` i `Stats.Cash`
- kupljeni treadmill nivo
- kapacitet plota
- EggInventory sa stabilnim UID-evima i svim gameplay atributima
- postavljena jaja, njihov položaj relativno na `Place`, unapred izabrani monster i vreme hatch-a
- hatchovani monsteri, stabilni UID-evi, vrsta, rarity, size i položaj
- Index unlock-i i najbolji pronađeni size

Autosave radi na 60 sekundi, a završni save na `PlayerRemoving` i `BindToClose`. Učitavanje i čuvanje pokušavaju do tri puta. Ako učitavanje ili format podataka nije ispravan, status postaje `LoadFailed` i servis odbija save da ne bi prepisao postojeće podatke praznim stanjem. Greška pri čuvanju daje `SaveFailed`; sledeći autosave pokušava ponovo.

`Player.PlayerDataStatus` prikazuje `Loading`, `Ready`, `LoadFailed` ili `SaveFailed`. `IndexDataStatus` prati isti objedinjeni save. Dok je učitavanje u toku, placement, prihod i treadmill trening/kupovina su privremeno zaustavljeni.

## Migracija Index-a

Ako objedinjeni zapis još ne postoji, servis čita stari `MonsterEggIndex_v1`. Postojeći unlock-i i Best Size prenose se u novi zapis. Ako čitanje starog store-a ne uspe, novi zapis se ne upisuje, da se stari Index ne bi izgubio. IndexService više nema sopstveni autosave i služi kao runtime katalog koji PlayerDataService uvozi i izvozi.

## Studio test

1. Objavi test experience i uključi **Game Settings → Security → Enable Studio Access to API Services**.
2. Uđi i proveri da `PlayerDataStatus` i `IndexDataStatus` postanu `Ready`.
3. Promeni Speed i Cash, kupi treadmill, uzmi nekoliko jaja, jedno ostavi u inventaru, jedno postavi i sačekaj da drugo postane monster.
4. Izađi iz igre, ponovo uđi i proveri tačne vrednosti, treadmill nivo, inventar, položaj postavljenog jajeta/monstera i Index.
5. Izađi dok jaje još ima hatch timer. Posle povratka timer treba da nastavi prema stvarnom proteklom vremenu; ako je vreme isteklo, hatch se završava odmah.
6. Reset Character ne sme da duplira Tool-ove ili promeni UID. Dva igrača moraju dobiti odvojene podatke i plot sadržaj.
7. Sa isključenim API pristupom proveri `LoadFailed`: gameplay ostaje upotrebljiv u toj sesiji, Output ima upozorenje i servis ne pokušava da upiše prazne podatke.
8. Za migraciju koristi nalog sa postojećim Index zapisom, bez novog player-data zapisa. Nakon ulaska stari unlock-i moraju ostati vidljivi i ući u novi save.

Rojo build proverava strukturu i sintaksu projekta. DataStore, napuštanje servera, restore modela i migracija moraju se potvrditi u objavljenom Studio testu.
