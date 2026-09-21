--!strict

-- Zameni 0 stvarnim ID-em iz Creator Dashboard-a.
-- Developer Products mogu da se kupe vise puta.
-- Game Pass kartice su namerno iskljucene dok njihovi perkovi ne budu implementirani.

local Config = {}

Config.GamePasses = {
	EXTRASLOTSCard = {
		Id = 0,
		Attribute = "OwnsExtraSlotsPass",
		Enabled = false,
	},
	FASTHATCHCard = {
		Id = 0,
		Attribute = "OwnsFastHatchPass",
		Enabled = false,
	},
	LUCKYCard = {
		Id = 0,
		Attribute = "OwnsLuckyPass",
		Enabled = false,
	},
	VIPCard = {
		Id = 0,
		Attribute = "OwnsVIPPass",
		Enabled = false,
	},
}

Config.DeveloperProducts = {
	["SPEED+10Card"] = {
		Id = 0,
		DisplayName = "SPEED +1K",
		Grant = { Stat = "Speed", Amount = 1000 },
	},
	["SPEED+25Card"] = {
		Id = 0,
		DisplayName = "SPEED +1M",
		Grant = { Stat = "Speed", Amount = 1000000 },
	},
	["SPEED+50Card"] = {
		Id = 0,
		DisplayName = "SPEED +1B",
		Grant = { Stat = "Speed", Amount = 1000000000 },
	},
	MAXSPEEDCard = {
		Id = 0,
		DisplayName = "COSMIC SPEED",
		Grant = { Stat = "Speed", Minimum = 250000000000 },
	},
	["10KCOINSCard"] = {
		Id = 0,
		DisplayName = "250K COINS",
		Grant = { Stat = "Cash", Amount = 250000 },
	},
	["100KCOINSCard"] = {
		Id = 0,
		DisplayName = "250M COINS",
		Grant = { Stat = "Cash", Amount = 250000000 },
	},
	["1MCOINSCard"] = {
		Id = 0,
		DisplayName = "250B COINS",
		Grant = { Stat = "Cash", Amount = 250000000000 },
	},
	["10MCOINSCard"] = {
		Id = 0,
		DisplayName = "250T COINS",
		Grant = { Stat = "Cash", Amount = 250000000000000 },
	},
}

function Config.GetProductById(productId: number)
	for cardName, definition in pairs(Config.DeveloperProducts) do
		if definition.Id == productId and productId > 0 then
			return cardName, definition
		end
	end
	return nil
end

function Config.GetPassById(passId: number)
	for cardName, definition in pairs(Config.GamePasses) do
		if definition.Id == passId and passId > 0 then
			return cardName, definition
		end
	end
	return nil
end

return Config
