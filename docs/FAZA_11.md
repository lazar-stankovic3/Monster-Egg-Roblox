# Faza 11 — Slobodno postavljanje jajeta

Status: implementirano 2026-09-20 na korisnikov zahtev; čeka Studio test. Provere faza 9 i 10 nisu označene kao prošle.

## Postavka postojećih plotova

Workspace.Plots (Folder) sadrži šest Model-a sa jedinstvenim imenima Plot1–Plot6. Svaki ima direktno u sebi Place (BasePart), Anchored=true i CanQuery=true. Njegova gornja površina je dozvoljena površina postavljanja. Build, PlayerSpawn, OfflinePart, PlotUpgradePart, TreadmillPos i TreadmillUpgradePart ostaju sačuvani. Nema potrebe za PlotOrigin-om ili EggSlots-om. Staro uputstvo za automatske fiksne slotove više ne važi.

Server kreira PlacedEggs (Folder) u svakom ispravnom plotu. Folder je isključivo za runtime jaja; nemoj ručno stavljati dekoraciju ili trajne modele u njega jer se prazni na inicijalizaciji i promeni vlasnika. OwnerUserId i SlotCapacity=6 ostaju na plotu. Player atribut PlotName pokazuje koji plot ti pripada. Respawn ga zadržava, izlazak oslobađa plot i briše postavljena jaja. Nema čuvanja između sesija do faze 17.

## Ponašanje

- Equip deponovanog Egg Tool-a uključuje lokalni preview stvarnog modela jajeta. Pomeri miš i klikni levim dugmetom na gornju površinu svog Place dela.
- Providno sivo (Transparency=0.6) znači dozvoljeno, providno crveno znači nedozvoljeno. Nema zelene boje. Teksture i vizuelni efekti uklonjeni su samo iz preview kopije.
- Preview je crven van sopstvenog Place dela, na drugom jajetu, na ivici gde ceo model ne staje, kada je svih šest mesta zauzeto ili kada si udaljen više od 30 studa od cilja. Kada miš pokazuje u nebo, prikazuje se crveno na udaljenosti 30 studa od kamere.
- Nema mreže ili fiksnih mesta. Jaje se poravnava sa orijentacijom Place površine. Oko drugih jaja mora biti 0.25 studa razmaka između bounding box-ova.
- Tool, preview i postavljeno jaje koriste punu originalnu veličinu prema Scale atributu. Nema ograničenja na 4 studa; provera granica i preklapanja koristi stvarne dimenzije velikog jajeta.
- Klik šalje UID i poziciju serveru. Server ponovo proverava vlasništvo plota, stvarni equipovani Tool i inventarski zapis, živog igrača, udaljenost, granice, kapacitet i preklapanje. Ne veruje klijentskoj boji preview-a.
- Uspeh troši zapis i Tool jednom i stvara model pod PlacedEggs sa istim UID, EggType, EggName, Biome, Rarity, Size, Scale, OwnerUserId i Placed=true. Višestruki klik ne pravi kopije. Neuspeh ostavlja jaje u inventaru.
- Unequip, smrt i uspešno postavljanje uklanjaju preview. Reset ne vraća potrošeno jaje u hotbar. Jaje ostaje na plotu do izlaska vlasnika.
- Ova faza ne pokreće hatch; on dolazi u fazi 12. Kontrola je trenutno miš/levi klik.

## Kod / Explorer

- ServerScriptService.Server.PlotService: dodela postojećih plotova sa Place delom, cleanup i red čekanja.
- ServerScriptService.Server.EggInventoryService: autoritativna provera equipovanog jajeta i jednokratno trošenje.
- ServerScriptService.Server.EggPlacementSystem: obrada zahteva; koristi ReplicatedStorage.PlaceEggEvent (RemoteEvent), definisan u default.project.json. ServerReady atribut postaje true nakon povezivanja server handler-a.
- ReplicatedStorage.Modules.EggPlacement: geometrija površine, kapacitet, udaljenost i razmak, zajednički za preview i server.
- StarterPlayer.StarterPlayerScripts.Client.EggPlacement: lokalni preview i klik.

## Studio provera

1. Sinhronizuj Rojo i pokreni novu Play sesiju. Proveri Player.PlotName i da je na tom plotu OwnerUserId jednak tvom UserId. Svih šest postojećih modela treba da ostane sačuvano, bez novih fiksnih slotova.
2. Deponuj jaje, equipuj ga i pomeraj miš po svom Place delu. Preview mora biti providno siv, bez originalnih tekstura. Izađi mišem van površine ili na tuđi plot: mora biti crven, bez postavljanja na klik.
3. Klikni na slobodno sivo mesto: stvarno jaje je na istoj poziciji kao preview, a njegov Tool i EggInventory zapis nestaju. Uporedi metadata novog modela sa prethodnim zapisom.
4. Brzo klikni više puta i zatim resetuj: jedan UID mora imati samo jedan postavljen model i nijedan Tool ili inventory zapis. Nepostavljena jaja treba normalno da se vrate nakon respawna.
5. Probaj Tiny/Titanic, ivice površine, razmak do drugog jajeta, rotiran Place i udaljenost veću od 30 studa. Crveni preview ne sme potrošiti Tool. Dekoracija preko površine blokira raycast i daje crveni preview.
6. Postavi šest jaja. Sedmo ostaje u inventaru i daje crveni preview. Isprobaj dva igrača: svaki postavlja samo na svom plotu.
7. Unequip i smrt uklanjaju preview. Izlazak vlasnika prazni PlacedEggs i oslobađa plot. Za test reda čekanja privremeno koristi dva plota i tri igrača.
8. Proveri da trening, krađa, Guardian i deposit i dalje rade i da nema crvenih Output grešaka.

Rojo build potvrđuje pakovanje, ne runtime raycast, izgled preview-a i multiplayer ponašanje. Ove provere ostaju otvorene do Studio potvrde.

