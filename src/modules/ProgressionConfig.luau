--!strict

local Config = {}

-- BaseIncomeBand je cilj za buduce monstere pre rarity/size multiplikatora.
-- RecommendedSpeed je stat, ne Humanoid.WalkSpeed.
Config.Biomes = {
	HatchlingFields = {
		Order = 1,
		DisplayName = "Hatchling Fields",
		RecommendedSpeed = 100,
		BaseIncomeBand = { 25, 1500 },
	},
	BioMarsh = {
		Order = 2,
		DisplayName = "Bio Marsh",
		RecommendedSpeed = 2500,
		BaseIncomeBand = { 2000, 100000 },
	},
	SporeLab = {
		Order = 3,
		DisplayName = "Spore Lab",
		RecommendedSpeed = 50000,
		BaseIncomeBand = { 200000, 10000000 },
	},
	Volcano = {
		Order = 4,
		DisplayName = "Volcano",
		RecommendedSpeed = 1000000,
		BaseIncomeBand = { 20000000, 1000000000 },
	},
	CryoSector = {
		Order = 5,
		DisplayName = "Cryo Sector",
		RecommendedSpeed = 25000000,
		BaseIncomeBand = { 2000000000, 100000000000 },
	},
	FossilLab = {
		Order = 6,
		DisplayName = "Fossil Lab",
		RecommendedSpeed = 500000000,
		BaseIncomeBand = { 200000000000, 10000000000000 },
	},
	MutationCore = {
		Order = 7,
		DisplayName = "Mutation Core",
		RecommendedSpeed = 10000000000,
		BaseIncomeBand = { 20000000000000, 1000000000000000 },
	},
	CosmicIncubator = {
		Order = 8,
		DisplayName = "Cosmic Incubator",
		RecommendedSpeed = 250000000000,
		BaseIncomeBand = { 2000000000000000, 100000000000000000 },
	},
}

local function normalize(value: string): string
	return string.lower((string.gsub(value, "[^%w]", "")))
end

function Config.GetBiome(value: unknown)
	if type(value) ~= "string" then return nil end
	local wanted = normalize(value)
	for key, definition in pairs(Config.Biomes) do
		if normalize(key) == wanted or normalize(definition.DisplayName) == wanted then
			return definition, key
		end
	end
	return nil
end

return Config
