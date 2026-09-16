-- ReplicatedStorage.Modules.EggRoller
-- Faza 4

local ReplicatedStorage =
	game:GetService("ReplicatedStorage")

local modulesFolder =
	ReplicatedStorage:WaitForChild("Modules")

local eggConfigModule =
	modulesFolder:WaitForChild("EggConfig")

if not eggConfigModule:IsA("ModuleScript") then
	error(
		"[EggRoller] EggConfig mora biti ModuleScript."
	)
end

local EggConfig =
	require(eggConfigModule)

local EggRoller = {}

--------------------------------------------------
-- ROLL EGG FOR BIOME
--------------------------------------------------

function EggRoller.RollEggForBiome(
	biomeKey,
	randomObject
)
	if type(biomeKey) ~= "string"
		or biomeKey == "" then

		return nil,
			"Biome key nije validan string."
	end

	local pool =
		EggConfig.BiomePools[biomeKey]

	if not pool then
		return nil,
			string.format(
				"Biome pool '%s' ne postoji u EggConfig.",
				biomeKey
			)
	end

	if #pool == 0 then
		return nil,
			string.format(
				"Biome pool '%s' je prazan.",
				biomeKey
			)
	end

	--------------------------------------------------
	-- TOTAL WEIGHT
	--------------------------------------------------

	local totalWeight = 0

	for index, entry in ipairs(pool) do
		if type(entry.Weight) ~= "number"
			or entry.Weight <= 0 then

			return nil,
				string.format(
					"Biome '%s' entry #%d ima nevalidan Weight.",
					biomeKey,
					index
				)
		end

		totalWeight += entry.Weight
	end

	if totalWeight <= 0 then
		return nil,
			string.format(
				"Biome '%s' ima totalWeight <= 0.",
				biomeKey
			)
	end

	--------------------------------------------------
	-- RANDOM ROLL
	--------------------------------------------------

	local roll =
		randomObject:NextNumber(
			0,
			totalWeight
		)

	local runningWeight = 0
	local selectedEntry = nil

	for _, entry in ipairs(pool) do
		runningWeight += entry.Weight

		if roll <= runningWeight then
			selectedEntry = entry
			break
		end
	end

	-- floating point fallback
	if not selectedEntry then
		selectedEntry = pool[#pool]
	end

	--------------------------------------------------
	-- EGG TYPE
	--------------------------------------------------

	local eggType =
		selectedEntry.EggType

	if type(eggType) ~= "string"
		or eggType == "" then

		return nil,
			string.format(
				"Biome '%s' ima pool entry bez validnog EggType.",
				biomeKey
			)
	end

	local definition =
		EggConfig.EggTypes[eggType]

	if not definition then
		return nil,
			string.format(
				"EggType '%s' iz biome-a '%s' ne postoji u EggConfig.EggTypes.",
				eggType,
				biomeKey
			)
	end

	--------------------------------------------------
	-- VALIDATE DEFINITION
	--------------------------------------------------

	if definition.EggType ~= eggType then
		return nil,
			string.format(
				"Egg definition '%s' ima pogrešan EggType '%s'.",
				eggType,
				tostring(
					definition.EggType
				)
			)
	end

	if type(definition.EggName) ~= "string"
		or definition.EggName == "" then

		return nil,
			string.format(
				"EggType '%s' nema validan EggName.",
				eggType
			)
	end

	if type(definition.ModelName) ~= "string"
		or definition.ModelName == "" then

		return nil,
			string.format(
				"EggType '%s' nema validan ModelName.",
				eggType
			)
	end

	if type(definition.Rarity) ~= "string"
		or not EggConfig.AllowedRarities[
			definition.Rarity
		] then

		return nil,
			string.format(
				"EggType '%s' ima nevalidan Rarity '%s'.",
				eggType,
				tostring(
					definition.Rarity
				)
			)
	end

	return definition, nil
end

--------------------------------------------------
-- ROLL SIZE
--------------------------------------------------

function EggRoller.RollSize(
	randomObject
)
	local sizes =
		EggConfig.Sizes

	if not sizes
		or #sizes == 0 then

		return nil,
			"EggConfig.Sizes je prazan."
	end

	local totalWeight = 0

	for index, sizeInfo in ipairs(
		sizes
	) do
		if type(sizeInfo.Weight) ~= "number"
			or sizeInfo.Weight <= 0 then

			return nil,
				string.format(
					"Size entry #%d ima nevalidan Weight.",
					index
				)
		end

		totalWeight += sizeInfo.Weight
	end

	if totalWeight <= 0 then
		return nil,
			"Size totalWeight je <= 0."
	end

	local roll =
		randomObject:NextNumber(
			0,
			totalWeight
		)

	local runningWeight = 0
	local selectedSize = nil

	for _, sizeInfo in ipairs(
		sizes
	) do
		runningWeight +=
			sizeInfo.Weight

		if roll <= runningWeight then
			selectedSize = sizeInfo
			break
		end
	end

	if not selectedSize then
		selectedSize =
			sizes[#sizes]
	end

	--------------------------------------------------
	-- VALIDATE SIZE
	--------------------------------------------------

	if type(selectedSize.Name) ~= "string"
		or selectedSize.Name == "" then

		return nil,
			"Odabrani size nema validan Name."
	end

	if type(selectedSize.Scale) ~= "number"
		or selectedSize.Scale <= 0 then

		return nil,
			string.format(
				"Size '%s' nema validan Scale.",
				tostring(
					selectedSize.Name
				)
			)
	end

	return selectedSize, nil
end

return EggRoller