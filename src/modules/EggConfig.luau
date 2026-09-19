--!strict

-- ReplicatedStorage.Modules.EggConfig
-- Faza 4
--
-- Ovde se nalaze:
-- 1. stabilni EggType identifikatori
-- 2. display imena
-- 3. ModelName koji mora postojati u ServerStorage.EggModels
-- 4. rarity metadata
-- 5. biome egg pool-ovi
-- 6. postojeće size šanse
--
-- POOL WEIGHTS SU PODESIVI.
-- Trenutni početni balans je 60 / 30 / 10.

local EggConfig = {}

--------------------------------------------------
-- EGG DEFINITIONS
--------------------------------------------------
--
-- EggType je stabilni ID.
-- Ne menjaj postojeći EggType kasnije samo zato
-- što želiš drugo display ime ili drugi model.
--
-- EggName = ime koje vidi igrač.
-- ModelName = tačno ime Model-a u ServerStorage.EggModels.
-- Rarity = trenutno samo metadata.

EggConfig.EggTypes = {
	hatchling_egg = {
		EggType = "hatchling_egg",
		EggName = "Hatchling Egg",
		ModelName = "HatchlingEgg",
		Rarity = "Common",
	},

	forest_egg = {
		EggType = "forest_egg",
		EggName = "Forest Egg",
		ModelName = "ForestEgg",
		Rarity = "Uncommon",
	},

	slime_egg = {
		EggType = "slime_egg",
		EggName = "Slime Egg",
		ModelName = "SlimeEgg",
		Rarity = "Rare",
	},

	magma_egg = {
		EggType = "magma_egg",
		EggName = "Magma Egg",
		ModelName = "MagmaEgg",
		Rarity = "Rare",
	},

	inferno_egg = {
		EggType = "inferno_egg",
		EggName = "Inferno Egg",
		ModelName = "InfernoEgg",
		Rarity = "Epic",
	},

	dragon_egg = {
		EggType = "dragon_egg",
		EggName = "Dragon Egg",
		ModelName = "DragonEgg",
		Rarity = "Legendary",
	},
}

--------------------------------------------------
-- LEGACY FALLBACK
--------------------------------------------------
--
-- Koristi se ISKLJUČIVO kada spawn Part nema
-- Biome Attribute.
--
-- Ako Biome Attribute postoji, ali nije validan,
-- NE koristi se ovaj fallback.

EggConfig.LegacyBasicEgg = {
	EggType = "basic_egg",
	EggName = "Basic Egg",
	ModelName = "BasicEgg",
	Rarity = "Common",
	Biome = "Legacy",
}

--------------------------------------------------
-- BIOME POOLS
--------------------------------------------------
--
-- Weight vrednosti su podesive.
-- Ne moraju zbirno biti 100.
--
-- Primer:
-- 60 / 30 / 10 može kasnije biti
-- 70 / 25 / 5 bez promene EggSystem skripte.

EggConfig.BiomePools = {
	HatchlingFields = {
		{
			EggType = "hatchling_egg",
			Weight = 60,
		},
		{
			EggType = "forest_egg",
			Weight = 30,
		},
		{
			EggType = "slime_egg",
			Weight = 10,
		},
	},

	Volcano = {
		{
			EggType = "magma_egg",
			Weight = 60,
		},
		{
			EggType = "inferno_egg",
			Weight = 30,
		},
		{
			EggType = "dragon_egg",
			Weight = 10,
		},
	},
}

--------------------------------------------------
-- EXISTING SIZE CONFIG
--------------------------------------------------
--
-- Ovo su POSTOJEĆE faza 1/2 vrednosti.
-- Ne dodajemo income multiplier logiku.
--
-- Income multiplikatori su definisani u zasebnom SizeConfig modulu.

EggConfig.Sizes = {
	{
		Name = "Tiny",
		Scale = 0.7,
		Weight = 20,
	},

	{
		Name = "Normal",
		Scale = 1,
		Weight = 45,
	},

	{
		Name = "Large",
		Scale = 1.4,
		Weight = 22,
	},

	{
		Name = "Huge",
		Scale = 1.9,
		Weight = 10,
	},

	{
		Name = "Titanic",
		Scale = 2.6,
		Weight = 3,
	},
}

return EggConfig
