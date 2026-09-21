--!strict

-- ReplicatedStorage.Modules.RarityConfig
-- Faza 5
--
-- Jedini izvor istine za stabilna rarity imena i njihove income multipliere.
-- Mnozilac se jos ne primenjuje na Cash: to radi Monster/Income sistem u fazama 13 i 14.

export type RarityName =
	"Common"
	| "Uncommon"
	| "Rare"
	| "Epic"
	| "Legendary"
	| "Mythic"

export type Definition = {
	Name: RarityName,
	IncomeMultiplier: number,
}

local RarityConfig = {}

local definitions: { [string]: Definition } = {
	Common = {
		Name = "Common",
		IncomeMultiplier = 1,
	},
	Uncommon = {
		Name = "Uncommon",
		IncomeMultiplier = 2,
	},
	Rare = {
		Name = "Rare",
		IncomeMultiplier = 5,
	},
	Epic = {
		Name = "Epic",
		IncomeMultiplier = 12,
	},
	Legendary = {
		Name = "Legendary",
		IncomeMultiplier = 30,
	},
	Mythic = {
		Name = "Mythic",
		IncomeMultiplier = 75,
	},
}

RarityConfig.Definitions = definitions

function RarityConfig.IsValid(rarityName: unknown): boolean
	return type(rarityName) == "string"
		and definitions[rarityName] ~= nil
end

function RarityConfig.GetDefinition(
	rarityName: unknown
): Definition?
	if type(rarityName) ~= "string" then
		return nil
	end

	return definitions[rarityName]
end

function RarityConfig.GetIncomeMultiplier(
	rarityName: unknown
): number?
	local definition = RarityConfig.GetDefinition(rarityName)

	if not definition then
		return nil
	end

	return definition.IncomeMultiplier
end

return RarityConfig
