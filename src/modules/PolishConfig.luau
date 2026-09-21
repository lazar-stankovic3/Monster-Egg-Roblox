--!strict

-- Faza 20: jedan izvor istine za UI/VFX boje i zvukove.
-- ChaseMusicId namerno ostaje konfigurabilan jer audio asset mora da bude
-- u vlasnistvu grupe/iskustva da bi pouzdano radio u objavljenoj igri.

local Config = {}

Config.RarityColors = {
	Common = Color3.fromRGB(205, 215, 225),
	Uncommon = Color3.fromRGB(91, 224, 104),
	Rare = Color3.fromRGB(74, 151, 255),
	Epic = Color3.fromRGB(187, 86, 255),
	Legendary = Color3.fromRGB(255, 181, 45),
	Mythic = Color3.fromRGB(255, 64, 120),
}

Config.RarityBurstCount = {
	Common = 18,
	Uncommon = 24,
	Rare = 32,
	Epic = 42,
	Legendary = 56,
	Mythic = 72,
}

Config.Sounds = {
	Pickup = "rbxasset://sounds/swoosh.wav",
	Deposit = "rbxasset://sounds/button.wav",
	Hatch = "rbxasset://sounds/electronicpingshort.wav",
	-- Postavi na rbxassetid://ID audio fajla koji pripada iskustvu/grupi.
	ChaseMusicId = "",
}

return Config
