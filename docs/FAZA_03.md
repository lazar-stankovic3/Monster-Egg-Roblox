# Faza 3 — Biome Recommended Speed

Status: kod implementiran; potrebno je potvrditi testove u Roblox Studio pre faze 4.
Postojeci PlayerStats, TreadmillSystem i EggSystem nisu menjani.

## 1. Fajlovi i kompletan kod

Kompletan kod je u ovim fajlovima, bez izostavljenih delova:

| Fajl | Roblox tip | Explorer lokacija |
| --- | --- | --- |
| [BiomeService.luau](../src/server/BiomeService.luau) | ModuleScript | ServerScriptService > Server > BiomeService |
| [BiomeSystem.server.luau](../src/server/BiomeSystem.server.luau) | Script | ServerScriptService > Server > BiomeSystem |
| [BiomeUI.client.luau](../src/client/BiomeUI.client.luau) | LocalScript | StarterPlayer > StarterPlayerScripts > Client > BiomeUI |

Projekat vec koristi Rojo. `rojo serve` iz korena projekta i povezivanje Studio Rojo plugina sinhronizuju ove fajlove preko postojeceg default.project.json.
Client je postojeci LocalScript sa init.client.luau, pa je BiomeUI njegov child LocalScript; izvrsava se kada se kopira u PlayerScripts.

Ako kopiras rucno: napravi Folder `Server` u ServerScriptService ako ne postoji, dodaj navedeni ModuleScript i Script i nalepi ceo sadrzaj odgovarajucih fajlova. BiomeUI LocalScript mozes staviti direktno u StarterPlayerScripts; nema zavisnost od parent skripte. Nemoj praviti i rucnu i Rojo kopiju skripti.

`BiomeService.Start()` automatski pravi `Workspace.Biomes` Folder ako nedostaje i `ReplicatedStorage.BiomeUIEvent` RemoteEvent ako nedostaje. Ako postoje, koristi ih. Istoimeni objekat pogresne klase daje jasnu gresku u Output-u.

Za ovu fazu koristimo eksplicitno trazenu putanju `ReplicatedStorage.BiomeUIEvent`, u skladu sa postojecim RunUIEvent stilom. Nemoj praviti drugi BiomeUIEvent u Remotes folderu. Kasnije se svi remotes mogu zajedno premestiti uz promenu obe reference.

## 2. Rucno postavljanje bioma u Studio (u Edit modu)

1. U Workspace napravi Folder `Biomes` ako ne postoji.
2. U Biomes napravi Model `HatchlingFields`.
3. Na MODEL dodaj Number Attribute `RecommendedSpeed = 100`.
4. Opciono na MODEL dodaj String Attribute `DisplayName = Hatchling Fields`. Bez njega UI koristi ime modela.
5. U model dodaj Part `BiomeZone`. Mora biti direktan child modela.
6. Postavi sledece Properties:

| Property | Vrednost |
| --- | --- |
| Shape | Block |
| Anchored | true |
| CanCollide | false |
| CanTouch | false |
| CanQuery | false |
| Transparency | 1 (privremeno 0.7 tokom postavljanja) |
| Size | zapremina koja pokriva biome; probno 80, 40, 80 |
| Position | centar bioma; za izolovan test na originalnoj baseplate: 100, 20, 0 |

Zona nije tanak pod. Ona mora da obuhvati HumanoidRootPart igraca i prostor za skakanje. Gornji probni primer pokriva X 60–140, Y 0–40, Z -40–40; prilagodi svojoj mapi. Provera radi i za rotiran pravougaoni Part. Za druge oblike i dalje se koristi pravougaona zapremina Part-a.

Ne postavljamo probnu zonu automatski jer lokacija pravog bioma u tvojoj Studio mapi nije poznata.

Za novi biome dupliciraj model, daj mu jedinstveno ime, pomeri zonu i promeni RecommendedSpeed. Nije potreban novi Script. Primeri narednih vrednosti su 500, 2500 i 10000. Model bez ispravnog BiomeZone-a ili konacnog nenegativnog Number RecommendedSpeed-a se ignorise; ne koristi podrazumevani prag koji bi prikrio gresku konfiguracije.

## 3. Explorer struktura

```text
Workspace
├── Treadmills                         (postojeci Folder)
└── Biomes                             (Folder)
    └── HatchlingFields                (Model)
        │ Attributes: RecommendedSpeed = 100
        │             DisplayName = "Hatchling Fields" (opciono)
        └── BiomeZone                  (Part)

ReplicatedStorage
└── BiomeUIEvent                       (RemoteEvent, automatski tokom Play)

ServerScriptService
└── Server                             (postojeci Rojo Folder)
    ├── PlayerStats                    (postojeci Script)
    ├── TreadmillSystem                (postojeci Script)
    ├── EggSystem                      (postojeci Script)
    ├── BiomeService                   (NOV ModuleScript)
    └── BiomeSystem                    (NOV Script)

StarterPlayer
└── StarterPlayerScripts
    └── Client                         (postojeci Rojo LocalScript)
        └── BiomeUI                    (NOV LocalScript)

Players                               (tokom Play)
└── TvojPlayer
    └── PlayerGui
        └── BiomeUI                    (ScreenGui, automatski)
            └── Panel                 (Frame sa UI labels)
```

Ne treba rucno praviti ScreenGui ili TextLabel-e. LocalScript pravi ceo UI, zadrzava ga pri respawn-u i na pocetku ga skriva.

## 4. Kako radi

Server svakih 0.15 sekundi proverava polozaj HumanoidRootPart-a u lokalnim koordinatama zone. Ne koristi Touched/TouchEnded niti broji body partove. Kada se ime bioma, zona, RecommendedSpeed ili Stats.Speed promeni, salje samo tom igracu:

```lua
{
    Visible = true,
    BiomeName = "Hatchling Fields",
    RecommendedSpeed = 100,
    PlayerSpeed = 72,
    Status = "DANGEROUS", -- READY kada PlayerSpeed >= RecommendedSpeed
}
```

Pri izlasku, smrti ili nedostupnom karakteru salje `{ Visible = false }` jednom. Teleport je prepoznat na sledecoj proveri. Prelazak koji u potpunosti prodje kroz zonu izmedju dve provere nije registrovan; zona treba da pokriva ceo biome. Ovo je sistem upozorenja, a ne anti-cheat za kretanje.

Klijent salje samo `Ready` nakon povezivanja listener-a, da ne propusti pocetni prikaz pri spawn-u unutar zone. Server sam racuna odgovor; ogranicava ponovni Ready na jednom u 2 sekunde. Klijent ne bira biome, Speed ili status. Nepromenjeno stanje ne salje nove poruke.

Ako se zone preklapaju, prednost ima veci RecommendedSpeed, zatim ime modela abecedno. Koristi jedinstvena imena i izbegni neplanirano preklapanje. Promena Attributes, dodavanje i uklanjanje biome modela prepoznaju se tokom rada.

Speed se cita iz `player.Stats.Speed`. Leaderstats i Humanoid.WalkSpeed se ne koriste za odluku. Ovaj sistem ne menja statove, ne usporava i ne blokira ulaz.

API reference: [CFrame koordinatne transformacije](https://create.roblox.com/docs/reference/engine/datatypes/CFrame), [RemoteEvent komunikacija](https://create.roblox.com/docs/scripting/events/remote).

## 5. Kratak test u Studio

Pokreni Play, ne samo Run. Otvori Output i proveri da nema novih gresaka iz BiomeSystem/BiomeService/BiomeUI.

1. Van zone panel je skriven. Udji sa Speed 0: prikazuje HATCHLING FIELDS, Recommended Speed 100, Your Speed 0 i DANGEROUS. Ulaz je dozvoljen.
2. Dok si unutra, u **server** prikazu Explorer-a promeni Players > tvoje ime > Stats > Speed > Value na 72, zatim 143. UI prelazi sa DANGEROUS na READY bez ponovnog ulaska. Za 100 mora biti READY. Ne menjaj leaderstats.
3. Izadji iz zone: panel nestaje za najvise oko 0.15 sekundi plus mrezno kasnjenje. Ponovi ulaz/izlaz i skaci unutar zapremine: nema duplih panela ili reakcija na svaki deo tela.
4. Resetuj karakter unutar zone: panel nestaje; posle respawn-a prikazuje se samo ako si opet u zoni. Teleportuj karakter van/unutra preko servera i proveri isto.
5. Napravi drugi biome sa 500. Predji direktno iz prve zone u drugu: ime i preporuka se menjaju. U preklapanju prikazuje se 500; po izlasku iz druge nazad u prvu prikazuje se 100.
6. Dok stojis unutra promeni RecommendedSpeed na modelu sa 100 na 200: status se osvezava. Ukloni model tokom Play: UI nestaje ili se prebacuje na drugu zonu ako si u preklapanju.
7. Studio Server & Clients sa 2 igraca: jedan unutra, drugi napolju. Samo prvi vidi UI. Promena Speed-a jednog igraca ne menja UI drugog.
8. Proveri da trening i postojeci egg pickup/carry/deposit i dalje rade.

Za probnu zonu mozes koristiti server Command Bar (zameni IME_IGRACA):

```lua
local p = game.Players:FindFirstChild("IME_IGRACA")
p.Stats.Speed.Value = 72
p.Character:PivotTo(CFrame.new(100, 5, 0))
```

Ne prelaziti na fazu 4 dok ovi testovi ne prodju. Rojo build proverava pakovanje projekta; ne zamenjuje Studio runtime test.
