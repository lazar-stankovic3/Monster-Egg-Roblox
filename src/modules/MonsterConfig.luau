local RarityConfig = require(script.Parent:WaitForChild("RarityConfig"))
local SizeConfig = require(script.Parent:WaitForChild("SizeConfig"))
local Config = {}

-- Initial base rates. Rarity is the species default; hatched instances inherit egg rarity.
local function definition(name, biome, rarity, income, modelName, indexId, color)
	return { MonsterName = name, Biome = biome, Rarity = rarity, BaseIncome = income,
		ModelName = modelName, IndexId = indexId, Icon = "", Color = color }
end

Config.Definitions = {
	green_slime = definition("Green Slime", "HatchlingFields", "Common", 2, "GreenSlime", "green_slime", Color3.fromRGB(80, 210, 100)),
	leaf_bunny = definition("Leaf Bunny", "HatchlingFields", "Uncommon", 4, "LeafBunny", "leaf_bunny", Color3.fromRGB(170, 225, 100)),
	baby_goblin = definition("Baby Goblin", "HatchlingFields", "Rare", 8, "BabyGoblin", "baby_goblin", Color3.fromRGB(90, 150, 65)),
	forest_dragon = definition("Forest Dragon", "HatchlingFields", "Legendary", 20, "ForestDragon", "forest_dragon", Color3.fromRGB(35, 125, 75)),
	-- First production monster model. Put the rig at ServerStorage.MonsterModels.Floragon.
	-- Its walk animation is read from an Animation named "WalkAnimation" inside the model,
	-- or from the model's WalkAnimationId attribute.
	floragon = definition("Floragon", "HatchlingFields", "Legendary", 20, "Floragon", "floragon", Color3.fromRGB(74, 176, 91)),
	magma_slime = definition("Magma Slime", "Volcano", "Rare", 12, "MagmaSlime", "magma_slime", Color3.fromRGB(255, 115, 35)),
	flame_goblin = definition("Flame Goblin", "Volcano", "Epic", 25, "FlameGoblin", "flame_goblin", Color3.fromRGB(210, 65, 40)),
	inferno_dragon = definition("Inferno Dragon", "Volcano", "Legendary", 60, "InfernoDragon", "inferno_dragon", Color3.fromRGB(150, 35, 35)),
}

function Config.CalculateIncome(monsterId, rarity, size)
	local entry = Config.Definitions[monsterId]
	local rarityMultiplier = RarityConfig.GetIncomeMultiplier(rarity)
	local sizeMultiplier = SizeConfig.GetIncomeMultiplier(size)
	if not entry or not rarityMultiplier or not sizeMultiplier then return nil end
	local base = entry.BaseIncome
	if type(base) ~= "number" or base ~= base or base < 0 or base == math.huge then return nil end
	return base * rarityMultiplier * sizeMultiplier
end

return Config
