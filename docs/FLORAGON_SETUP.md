# Floragon model i walk animacija

Floragon je registrovan kao `Legendary` monster iz `HatchlingFields` bioma. Može da se izlegne iz:

- `Hatchling Egg` (weight 2)
- `Forest Egg` (weight 10)
- legacy `Basic Egg` (weight 2)

Tokom Roblox Studio Play testa prvi hatch u toj sesiji je privremeno garantovan kao Floragon. To važi samo u Studio-u i samo jednom po pokretanju servera; objavljena igra koristi normalne šanse.

## Gde ide model

U Roblox Studiju napravi sledeću strukturu:

```text
ServerStorage
└── MonsterModels
    └── Floragon (Model)
        ├── ... rig delovi / skinned mesh / bones ...
        └── WalkAnimation (Animation)
```

Imena `Floragon` i `WalkAnimation` moraju biti potpuno ista, uključujući velika slova.

1. `Floragon` mora biti Roblox `Model` i mora imati bar jedan `BasePart` ili `MeshPart`.
2. Podesi `PrimaryPart` modela na glavni/root deo riga (obično `HumanoidRootPart` ili root `MeshPart`).
3. Ubaci `Animation` objekat bilo gde unutar modela, nazovi ga `WalkAnimation` i njegov `AnimationId` podesi na `rbxassetid://TVOJ_ID`.
4. Animacija mora biti objavljena pod istim nalogom ili grupom koja poseduje experience, inače Roblox neće dozvoliti učitavanje.
5. Rig mora odgovarati rigu na kome je animacija napravljena. Motor6D spojevi i Bones se sada čuvaju pri hatchovanju.

Umesto `WalkAnimation` objekta možeš na `Floragon` Model da dodaš string atribut `WalkAnimationId` sa vrednošću ID-a. Ugrađeni `WalkAnimation` objekat ima prednost ako postoje oba.

Walk animacija se automatski uključuje samo dok je `WanderState` jednak `Walking`, a zaustavlja se kada Floragon stane. Isti sistem radi posle hatchovanja i nakon ponovnog učitavanja sačuvanog monstera.
