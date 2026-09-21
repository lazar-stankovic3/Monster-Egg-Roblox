--!strict

-- ReplicatedStorage.Modules.SizeConfig
-- Faza 6
--
-- Jedini izvor istine za income multipliere velicine.
-- Vizuelni Scale i spawn Weight ostaju u EggConfig.Sizes, jer su deo postojeceg egg spawn balansa.

export type SizeName =
	"Tiny"
	| "Normal"
	| "Large"
	| "Huge"
	| "Titanic"

export type Definition = {
	Name: SizeName,
	IncomeMultiplier: number,
	CarryMovementPenalty: number,
}

local SizeConfig = {}

local definitions: { [string]: Definition } = {
	Tiny = { Name = "Tiny", IncomeMultiplier = 0.65, CarryMovementPenalty = 0 },
	Normal = { Name = "Normal", IncomeMultiplier = 1, CarryMovementPenalty = 0 },
	Large = { Name = "Large", IncomeMultiplier = 1.75, CarryMovementPenalty = 0.05 },
	Huge = { Name = "Huge", IncomeMultiplier = 3.5, CarryMovementPenalty = 0.1 },
	Titanic = { Name = "Titanic", IncomeMultiplier = 8, CarryMovementPenalty = 0.2 },
}

SizeConfig.Definitions = definitions

function SizeConfig.IsValid(sizeName: unknown): boolean
	return type(sizeName) == "string"
		and definitions[sizeName] ~= nil
end

function SizeConfig.GetDefinition(sizeName: unknown): Definition?
	if type(sizeName) ~= "string" then
		return nil
	end

	return definitions[sizeName]
end

function SizeConfig.GetIncomeMultiplier(sizeName: unknown): number?
	local definition = SizeConfig.GetDefinition(sizeName)

	if not definition then
		return nil
	end

	return definition.IncomeMultiplier
end

function SizeConfig.GetCarryMovementPenalty(sizeName: unknown): number?
	local definition = SizeConfig.GetDefinition(sizeName)

	if not definition then
		return nil
	end

	return definition.CarryMovementPenalty
end

return SizeConfig
