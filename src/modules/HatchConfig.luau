local Config = {}
local RunService = game:GetService("RunService")

Config.Timers = { Common = 3, Uncommon = 5, Rare = 8, Epic = 15, Legendary = 30, Mythic = 60 }
-- Studio-only smoke test: the first roll in a play session is Floragon.
-- This is ignored outside Studio and automatically disables itself after one roll.
Config.TestFirstMonster = "floragon"
local firstStudioRollAvailable = true
Config.Monsters = require(script.Parent:WaitForChild("MonsterConfig")).Definitions
Config.Pools = {
	hatchling_egg = {{"green_slime", 70}, {"leaf_bunny", 20}, {"baby_goblin", 8}, {"forest_dragon", 2}, {"floragon", 2}},
	forest_egg = {{"leaf_bunny", 60}, {"baby_goblin", 30}, {"forest_dragon", 10}, {"floragon", 10}},
	slime_egg = {{"green_slime", 100}},
	magma_egg = {{"magma_slime", 75}, {"flame_goblin", 25}},
	inferno_egg = {{"flame_goblin", 80}, {"inferno_dragon", 20}},
	dragon_egg = {{"inferno_dragon", 100}},
	basic_egg = {{"green_slime", 70}, {"leaf_bunny", 20}, {"baby_goblin", 8}, {"forest_dragon", 2}, {"floragon", 2}},
}

function Config.Roll(eggType, random)
	if RunService:IsStudio() and firstStudioRollAvailable and Config.TestFirstMonster then
		firstStudioRollAvailable = false
		return Config.TestFirstMonster
	end
	local pool = Config.Pools[eggType]
	if not pool or #pool == 0 then return nil end
	local total = 0
	for _, entry in ipairs(pool) do
		if not Config.Monsters[entry[1]] or type(entry[2]) ~= "number"
			or entry[2] ~= entry[2] or entry[2] <= 0 or entry[2] == math.huge then return nil end
		total += entry[2]
	end
	local choice = random:NextNumber() * total
	for _, entry in ipairs(pool) do
		choice -= entry[2]
		if choice < 0 then return entry[1] end
	end
	return pool[#pool][1]
end

return Config
