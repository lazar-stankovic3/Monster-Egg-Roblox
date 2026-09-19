# Faza 8 — GuardianService

Status (2026-09-18): kod je dodat; faza 8 je i dalje aktivna. Korisnik je potvrdio da ragdoll radi nakon AnimationConstraint ispravke. Poslednja izmena protiv sudara ispuštenog jajeta i odbačenog igrača još čeka Studio potvrdu. Faza 7 je potvrđena; faza 9 nije započeta. Rojo build prolazi, ali ne potvrđuje runtime ponašanje.

## Evidencija urađenog

- GuardianService: target lopov, po jedan Guardian za svako ukradeno jaje, biome brzine i rarity bonusi, forced drop i stop uslovi.
- Opcioni GuardianTemplate i automatski generisan ljubičasto-zeleni NPC; raycast traži tlo za spawn umesto postavljanja iznad cele BiomeZone.
- Kontinuirano praćenje na 0.05 s, pozadinsko računanje putanje na 0.35 s, horizontalna provera waypoint-a i serversko upravljanje fizikom NPC-a.
- GuardianHitService i GuardianRagdoll LocalScript: odbacivanje, privremeni zglobovi i collision delovi, prekid animacija, vraćanje kontrole i blokada pickup-a dok traje ragdoll.
- Podrška za Motor6D i noviji AnimationConstraint; ranija greška „No supported body Motor6D joints“ otkrila je nedostajuću podršku. Korisnik je zatim potvrdio ragdoll.
- Jačina odbacivanja povećana na 95 horizontalno / 42 vertikalno na zahtev korisnika.
- Poslednji fix: samo pogođeni karakter i ispušteno jaje privremeno ne kolidiraju; ostaju sudari jajeta sa terenom i drugim igračima. Ova promena još čeka test.

## Pravilo

Kada igrač podigne world egg, server pravi nezavisan Guardian klon za to konkretno jaje. Guardian prati samo `CarrierUserId` tog jajeta, koristi server-side pathfinding i na udaljenosti od 5 studova zahteva serveru da ispusti jaje. Igrač ne može klijentski odrediti target, brzinu ni drop.

Guardian nestaje kada se jaje ispusti, deponuje, igrač umre/izađe ili uđe u `LobbyDepositZone` (sa 4 studa tolerancije). U safe zoni Guardian ne izaziva drop.

Više igrača istovremeno: svako ukradeno jaje dobija sopstveni klon istog biome template-a. Zato dva lopova, čak i u istom biomu, imaju odvojene targete i ne mogu preuzeti jedan drugome Guardian-a.

## Balans

| Biome | Bazna Guardian brzina |
| --- | ---: |
| HatchlingFields | 25 |
| Volcano | 45 |
| Void | 70 |
| ostali/nepoznat biome | 25 |

Rarity dodaje procenat na baznu brzinu: Common 0%, Uncommon 2.5%, Rare 5%, Epic 10%, Legendary 20%, Mythic 30%. Na primer, Volcano Legendary Guardian ima `45 × 1.2 = 54` WalkSpeed.

Sve vrednosti su u `ReplicatedStorage.Modules.GuardianConfig`.

## Studio postavka

Ako želiš sopstveni model čuvara, opcioni template postavi na ovaj put:

```text
Workspace
  Biomes
    HatchlingFields                 (Model; ime mora odgovarati Egg Biome attribute-u)
      GuardianTemplate              (Model)
        Humanoid
        HumanoidRootPart            (BasePart)
```

`GuardianTemplate` je opcioni običan NPC rig. Sačuvaj ga na željenoj početnoj poziciji u biomu; može ostati `Anchored` dok je template, jer servis odsidrava samo klon. Model mora imati `Humanoid` i `HumanoidRootPart`. Ne dodavati ga u `ActiveGuardians`: taj Folder servis kreira i čisti sam.

Ako template ne postoji, servis automatski stvara neon ljubičasto-zelenog, jednostavnog humanoidnog Guardian-a na tlu koje raycast pronađe kod centra `BiomeZone`. Ako raycast ne nađe tlo, rezervna pozicija je iznad zone. Čim kasnije dodaš template, on ima prioritet.

Za Volcano koristi `Workspace.Biomes.Volcano.GuardianTemplate`; isto važi za druge biome modele. Ako template nedostaje, pickup i ostali egg sistemi rade normalno uz automatski generisanog Guardian-a. Chase se preskače samo ako biome nema ni `GuardianTemplate` ni `BiomeZone`.

## Studio test

Pri Guardian udarcu iskljucuje se samo sudar ispustenog jajeta sa pogodjenim karakterom, ukljucujuci accessory delove i privremene ragdoll collidere. NoCollisionConstraint parovi nastaju pre prvog physics frame-a i uklanjaju se pri oporavku/smrti/respawnu. Jaje i dalje udara u teren i ostale igrace; provera sletanja ignorise to jaje.

Provera: ponoviti hvatanje sa Tiny i Titanic jajetom, gledajuci ka Guardianu i od njega. Jaje ne sme prekinuti let ni pokrenuti prerano ustajanje. Posle oporavka ponovo podici jaje; proveriti i reset tokom leta da privremeni `GuardianDroppedEggNoCollision` objekti ne ostanu.

AvatarJointUpgrade: ragdoll podrzava i `AnimationConstraint` zglobove novijih avatara i stare `Motor6D` zglobove. Oba tipa privremeno se iskljucuju dok privremeni BallSocket drzi telo; originalni rig attachments i parametri se ne menjaju. Pri ustajanju originalni zglobovi ponovo se ukljucuju. Nije potrebno iskljucivati AvatarJointUpgrade u Studio-u. [Roblox AnimationConstraint dokumentacija](https://create.roblox.com/docs/reference/engine/classes/AnimationConstraint/MaxForce).

Regresiona provera: na novom R15 rig-u ponoviti udarac dva puta, proveriti da je `GuardianRagdollJointCount > 0`, da se udovi opustaju i da nakon ustajanja animacije rade. Isto proveriti sa legacy Motor6D rig-om. Tokom efekta oznaceni originalni zglobovi moraju biti `Enabled = false`, a posle oporavka `Enabled = true` bez privremenih collider-a i socket-a.

### Guardian udarac i privremeni ragdoll

Hvatanje prvo ispusta isto noseno jaje, zatim `GuardianHitService` odbacuje igraca od pozicije Guardiana (horizontalna brzina 95, vertikalna 42). Privremeni BallSocket zglobovi podrzavaju R6 i R15; GuardianRagdoll attribute na karakteru blokira pickup tokom efekta. Speed stat se ne menja. Server upravlja fizikom dok efekat traje.

`StarterPlayerScripts.Client.GuardianRagdoll` privremeno zaustavlja lokalne animacije, iskljucuje oznacene motore i odrzava Physics stanje. Server koristi zavarene nevidljive collision delove i primenjuje impuls po assembly-ju posle jednog physics frame-a. Pri oporavku vracaju se animacije i motori, a collision delovi se uklanjaju. Za dijagnostiku tokom efekta proveriti Character attribute `GuardianRagdollJointCount`: mora biti veci od nule. Ako je nula, Output prijavljuje nepodrzane zglobove.

Posle najmanje 1 s, telo mora biti blizu tla i usporeno tokom 0.4 s pre ustajanja. Najduze trajanje je 5 s ako igrac ostane zaglavljen ili nastavi da pada. Vraca se prethodno stanje zglobova, kolizija, AutoRotate i PlatformStand; privremeni objekti se uklanjaju i pri smrti/respawnu.

Provere u Studio-u:

- Dozvoli hvatanje na ravnom tlu: jaje pada, telo leti od Guardiana, ruke/noge se opustaju, pa karakter ustaje i normalno hoda/skace.
- Pokusaj pickup dok lezis: mora biti odbijen; posle ustajanja ponovo radi. Ponovi hvatanje nekoliko puta.
- Testiraj stepenice/pad sa ivice: nema trenutnog ustajanja u letu; postoji maksimalno trajanje od 5 s.
- Resetuj karakter tokom ragdoll-a: novi karakter mora normalno da se krece i ne dobija naknadni efekat prethodnog udarca.
- Proveri dva igraca i po mogucnosti R6/R15: efekat dobija samo uhvaceni nosilac jajeta. Safe zone/deposit i dalje prekidaju chase bez udarca.

API reference: [Humanoid](https://create.roblox.com/docs/reference/engine/classes/Humanoid) i [network ownership](https://create.roblox.com/docs/physics/network-ownership).

Praćenje se osvežava svakih 0.05 s. Na slobodnom, prohodnom terenu Guardian ide ka trenutnoj poziciji igrača; iza prepreka nastavlja po waypoint-ima dok se nova putanja računa u pozadini, najviše jednom na 0.35 s po NPC-u. Provera dostignutog waypoint-a koristi horizontalnu udaljenost, jer je HumanoidRootPart iznad tla. NPC fizikom upravlja server.

Za proveru kontinuiranog praćenja trči cik-cak na ravnom terenu, zatim iza zida i oko ugla. Guardian treba da prati promene smera bez čekanja na završetak računanja putanje. Probaj i drop/deposit dok se računa putanja: završeni proračun ne sme ponovo pokrenuti ugašen chase. Rojo build proverava pakovanje; ovaj test u Studio-u je obavezan za potvrdu kretanja.

1. Poveži Rojo, zatim pokreni novi Play test. U Output-u proveri `[GuardianService] Phase 8 guardian service loaded.`
2. U `Workspace.ActiveGuardians` potvrdi da na startu nema klonova.
3. Podigni jaje. Mora nastati `Guardian_<UID>` sa attributes `TargetUserId`, `TargetEggUID` i `Biome`; bez template-a koristi se generisani neon Guardian na pronađenom tlu. `Humanoid.WalkSpeed` mora odgovarati biome + rarity tabeli.
4. Guardian mora pratiti samo igrača koji nosi baš to jaje. Priđi mu na manje od 5 studova: jaje se server-side ispušta, `CarryMovementPenalty` postaje 0, pojavi se PickupPrompt, a Guardian nestaje.
5. Podigni jaje i ručno ga ispusti: Guardian odmah nestaje. Ponovi sa smrću igrača i potvrdi isto.
6. Donesi jaje do `LobbyDepositZone`: Guardian mora nestati bez forced drop-a, a postojeći deposit mora normalno prebaciti jaje u EggInventory.
7. U Test > Start sa dva igrača, neka oba podignu jaja istog biome-a. Moraju nastati dva Guardian klona; svaki ima svoj `TargetUserId` i prati samo svog lopova. Drop jednog jajeta ne sme ugastiti chase drugog.
8. Probaj teren sa preprekama: Guardian treba da koristi putanje; ako Roblox navmesh ne nađe put, prelazi na direktan `MoveTo` pokušaj umesto da zaustavi servis.
