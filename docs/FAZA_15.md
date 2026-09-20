# Faza 15 — Treadmill nivoi i trening

Status 2026-09-20: potvrđeno korisnikovim Studio testiranjem, uključujući animaciju treninga. Faza 14 je potvrđena. Korisnik zahteva kupovinu nivoa redom, privremene modele i zaključavanje u centru trake do skoka.

## Postavka

Postojeći Workspace.Plots.Plot1–Plot6 modeli treba da imaju direktne Part-ove TreadmillPos i TreadmillUpgradePart. TreadmillPos označava sredinu/podnožje privremenog modela, a TreadmillUpgradePart mesto ProximityPrompt kupovine. Obe oznake usidri, učini providnim i isključi CanCollide. Ne menjaju se Build i ostali asset-i.

Servis automatski kreira OwnedTreadmill na dodeljenom plotu: privremeni model sa trakom, rukohvatom i nevidljivim TrainingZone delom. Svaki nivo ima svoju boju. Ne treba ručno dodavati modele. Opcioni ServerStorage.TreadmillModels može kasnije sadržati Model-e Starter, Metal, Turbo, Neon i Void; svaki mora imati direktan TrainingZone Part i pivot usklađen sa TreadmillPos. Donja površina TrainingZone treba da bude površina trake; zona treba da obuhvati HumanoidRootPart stojećeg igrača.

## Kupovina isključivo redom

| Nivo | Naziv | Cena upgrade-a | Speed/sec |
|---|---|---|---|
| 1 | Starter | Besplatno pri dodeli | 20 |
| 2 | Metal | 1000 | 60 |
| 3 | Turbo | 10000 | 200 |
| 4 | Neon | 100000 | 700 |
| 5 | Void | 1000000 | 2000 |

Prompt na TreadmillUpgradePart prikazuje trenutno ime/brzinu i samo sledeći nivo sa cenom. Drži E 0.5s za kupovinu. Server uzima isključivo trenutni nivo + 1; klijent ne šalje željeni nivo, cenu ili gain. Proveravaju se vlasnik plota, živ karakter, udaljenost do 12 studa, dovoljno Stats.Cash i cooldown 0.75s. Model se priprema pre naplate, pa se stari zameni bez yield-a. Greška modela ne troši novac. Na nivou 5 prompt je isključen. Nedovoljno novca ostavlja stanje nepromenjeno i postavlja Player.TreadmillPurchaseStatus=NotEnoughCash.

Player atributi: TreadmillLevel, OwnedTreadmill, TreadmillPurchaseStatus. Plot ima TreadmillLevel; model ima OwnerUserId, Level i SpeedGain. Privatni server state određuje nivo, ne klijentski atributi. Respawn zadržava kupljeni nivo u istoj sesiji. Izlazak briše runtime model/prompt; novi vlasnik dobija Starter. Persistence dolazi u fazi 17.

## Centriranje i izlazak skokom

Kada živ igrač uđe u TrainingZone sopstvenog treadmilla, server poravnava karakter na sredinu, usidrava root i isključuje AutoRotate. Ne može hodanjem da siđe. JumpRequest (Space, odnosno platformina komanda za skok) šalje zahtev za oslobađanje; server vraća prethodno anchored/AutoRotate stanje i pokreće skok. Trening prestaje odmah po oslobađanju.

Igrač se ne zaključava ponovo dok prvo ne izađe iz iste zone. Smrt/reset, uklanjanje trake, izlazak i zamena modela takođe oslobađaju karakter. Player.TreadmillLocked i TrainingSpeedPerSecond služe za inspekciju.

Prethodni TreadmillSystem sada samo pokreće TreadmillService. Centralna provera na 0.25s zamenjuje Touch brojače, kako privatna i stara javna traka ne bi davale dupli Speed. Postojeći Workspace.Treadmills ostaje podržan preko TrainingZone/SpeedGain; javne trake mogu svi koristiti. Preklopljene zone ne sabiraju zaradu. Novi nivoi se odnose na sopstvenu kupljenu traku, dok postojeći javni asset-i ostaju sa svojim SpeedGain vrednostima.

## Explorer / kod

- ReplicatedStorage.Modules.TreadmillConfig: cene, redosled, SpeedGain i boje.
- ServerScriptService.Server.TreadmillService: dodela/zamena, server kupovina, centriranje i centralni trening.
- ServerScriptService.Server.TreadmillSystem: pokretač.
- StarterPlayer.StarterPlayerScripts.Client.TreadmillControls: zahtev za izlazak skokom.
- ReplicatedStorage.TreadmillJumpEvent: server ga automatski kreira; može samo osloboditi već zaključanog igrača.

## Studio test

1. Stop → Rojo sync → Play. Na svom plotu proveri Starter i prompt za Metal ($1000). Početni Cash je 1000; za test nedovoljnog novca privremeno postavi Cash ispod 1000.
2. Stani na traku: karakter treba da se centrira, hodanje ne pomera karakter i Stats.Speed raste za 20/sec. Space oslobađa i skače; Speed prestaje da raste. Izađi iz zone, pa se vrati i proveri novi lock.
3. Testiraj reset/smrt na traci: novi karakter nije ukočen, nivo ostaje isti. Ponovi izlazak i ulazak više puta.
4. Za test možeš u server Explorer-u privremeno povećati Stats.Cash. Kupi Metal: skida tačno 1000, samo jedan model ostaje, gain je 60/sec. Sledeća ponuda je Turbo, pa Neon, pa Void. Nema preskakanja ni kupovine istog nivoa ponovo.
5. Brzo ponavljaj prompt i probaj sa drugog plota ili drugim igračem: nema neovlašćene naplate/zamene. Maksimalni nivo ne može dalje da se kupi.
6. Proveri zamenu modela dok je igrač na traci, dva igrača, izlazak vlasnika i dodelu njegovog plota drugome. Ne ostaju zaključani karakteri ili stare privatne trake.
7. Postojeće javne trake i dalje rade; stajanje van TrainingZone ne trenira. Ne dobija se dupli gain na preklopu.
8. Proveri da Cash od monstera, Tool, preview, hatch i nasleđivanje veličine i dalje rade.

Rojo build potvrđuje pakovanje. Runtime prompt, skok, fizika i kupovine čekaju Studio potvrdu.
Korisnik je zatražio Starter 20 Speed/sec i početni Stats.Cash=1000. Svi nivoi proporcionalno su uvećani 20 puta u odnosu na prvobitni balans: 20/60/200/700/2000 Speed/sec. Cene su ostale iste, kao i obavezna kupovina redom.

## Animacija treninga

TreadmillAnimation LocalScript pokreće postojeću run animaciju dok je TreadmillLocked=true, iako je karakter fizički nepomičan. Animacija je loopovana; skok/otključavanje, smrt i respawn je čiste. Test: stani na traku, proveri trčanje u mestu, zatim skoči i proveri povratak normalnim animacijama. Ponovi ulazak i reset da potvrdiš da se animacije ne dupliraju.
