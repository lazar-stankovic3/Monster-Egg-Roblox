# Faza 9 — Vizuelni Egg Tool

Status 2026-09-19: implementirano, ceka Studio potvrdu. Korisnik je zatrazio nastavak; nepotvrdjene provere faze 8 ostaju odlozene u TODO.md.

## Implementacija

- `ServerScriptService.Server.EggInventoryService` pravi server inventory zapis i vizuelni Tool pri uspesnom lobby deposit-u. EggSystem unistava world egg i zakazuje respawn tek kada servis vrati uspeh.
- `Players.<igrac>.EggInventory.<UID>` je Folder zapis. `Players.<igrac>.Backpack` sadrzi odgovarajuci Tool; pri equip-u ista instanca prelazi u Character, a pri unequip-u nazad. Nema stvaranja kopije na svaki equip.
- Zapis i Tool cuvaju `UID`, `EggType`, `EggName`, `Biome`, `Rarity`, `Size`, `Scale`, `OwnerUserId`. Tool dodatno ima `IsEggTool = true`. Ponavljanje depozita istog UID-a se odbija pre upisa.
- Tool ima nevidljivi Handle i EggVisual klon stvarnog jajeta, zavaren i bez kolizija. Carry weldovi, promptovi, skripte i world atributi uklanjaju se iz vizuelnog klona. Rucni drop Tool-a je iskljucen.
- Prikaz u ruci zadržava punu originalnu veličinu prema Scale atributu, bez umanjivanja. Tool ne pokrece Guardian chase niti carry penalty.
- Posle smrti u istoj sesiji ponovo se pravi po jedan Tool iz serverskog zapisa. Ne koristi se StarterGear, da ne bi postojao drugi mehanizam kloniranja. Uklanjanje zapisa uklanja i Tool; izlazak igraca cisti serverske template-e i konekcije.
- Nema DataStore cuvanja posle napustanja servera (faza 17), plot placement-a (faza 11) ni hatch-a (faza 12).

Modeli vec postoje u EggSystem-u; nije potrebna nova Studio postavka. Povezati Rojo i pokrenuti novu Play sesiju. [Roblox Tool dokumentacija](https://create.roblox.com/docs/reference/engine/classes/Tool/GripPos).

## Studio provera

1. Ukradi jaje i deponuj ga u lobby. Proveri jedan Tool u hotbaru, jedan Folder zapis u EggInventory, uklonjen world egg i normalan respawn na spawn point-u.
2. Poredi sve metadata atribute zapisa i Tool-a sa jajetom pre depozita. OwnerUserId mora biti tvoj UserId.
3. Izaberi Tool tasterom 1 ili klikom na hotbar: odgovarajuci model mora biti vidljiv u ruci. Ne sme vuci karakter, aktivirati pickup prompt ili Guardian-a.
4. Equip/unequip ponovi deset puta: zbir Tool-ova sa tim UID-em u Backpack-u i Character-u mora ostati 1; EggInventory mora imati samo jedan zapis.
5. Deponuj dva jajeta istog tipa: imaju razlicite UID-eve i dva Tool-a. Ponovni dodir lobby zone bez world jajeta ne dodaje nista.
6. Probaj Tiny i Titanic i razlicite modele. Veliko jaje mora ostati iste veličine kao pre deposit-a, uz originalne Size i Scale atribute.
7. Resetuj sa equipovanim Tool-om, pa sa Tool-om u Backpack-u: posle svakog respawna svaki zapis ima tacno jedan Tool. Jaje ukradeno ali NE deponovano i dalje koristi stari death drop.
8. Backspace ne sme ispustiti Tool. Proveri da pickup, Guardian hit/ragdoll, carry penalty i lobby deposit i dalje rade normalno.
9. Test sa dva igraca: svaki dobija svoje zapise/Tool-ove i OwnerUserId; depozit jednog ne menja inventory drugog.

Rojo build proverava pakovanje, ne runtime equip, fiziku ili respawn; ove provere ostaju otvorene do Studio potvrde.
