local Config = {}

Config.Levels = {
	{ Capacity = 6, Cost = 0 },
	{ Capacity = 8, Cost = 250000 },
	{ Capacity = 12, Cost = 250000000 },
	{ Capacity = 16, Cost = 250000000000 },
}

function Config.GetLevel(capacity)
	for level, definition in ipairs(Config.Levels) do
		if definition.Capacity == capacity then return level, definition end
	end
	return nil
end

return Config
