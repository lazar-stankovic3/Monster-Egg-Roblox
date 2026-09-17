local Profiles = {}

Profiles.HatchlingFields = {
	Brightness = 2.5,
	ClockTime = 13,
	ExposureCompensation = 0.1,

	Ambient = Color3.fromRGB(145, 155, 130),
	OutdoorAmbient = Color3.fromRGB(170, 180, 160),

	Atmosphere = {
		Density = 0.18,
		Offset = 0.1,
		Color = Color3.fromRGB(210, 230, 190),
		Decay = Color3.fromRGB(120, 150, 100),
		Glare = 0.15,
		Haze = 0.5,
	},

	ColorCorrection = {
		Brightness = 0.03,
		Contrast = 0.05,
		Saturation = 0.1,
		TintColor = Color3.fromRGB(255, 250, 225),
	},
}

Profiles.BioMarsh = {
	Brightness = 1.8,
	ClockTime = 15,
	ExposureCompensation = -0.15,

	Ambient = Color3.fromRGB(75, 90, 70),
	OutdoorAmbient = Color3.fromRGB(95, 110, 85),

	Atmosphere = {
		Density = 0.4,
		Offset = 0,
		Color = Color3.fromRGB(130, 150, 105),
		Decay = Color3.fromRGB(50, 70, 45),
		Glare = 0,
		Haze = 2,
	},

	ColorCorrection = {
		Brightness = -0.05,
		Contrast = 0.12,
		Saturation = -0.2,
		TintColor = Color3.fromRGB(190, 210, 160),
	},
}

Profiles.Desert = {
	Brightness = 2.8,
	ClockTime = 14,
	ExposureCompensation = 0.05,

	Ambient = Color3.fromRGB(180, 145, 100),
	OutdoorAmbient = Color3.fromRGB(210, 175, 120),

	Atmosphere = {
		Density = 0.3,
		Offset = 0.15,
		Color = Color3.fromRGB(235, 190, 125),
		Decay = Color3.fromRGB(170, 105, 55),
		Glare = 0.5,
		Haze = 2.5,
	},

	ColorCorrection = {
		Brightness = 0.03,
		Contrast = 0.08,
		Saturation = -0.05,
		TintColor = Color3.fromRGB(255, 220, 165),
	},
}

Profiles.Volcano = {
	Brightness = 1.3,
	ClockTime = 18,
	ExposureCompensation = -0.25,

	Ambient = Color3.fromRGB(90, 55, 45),
	OutdoorAmbient = Color3.fromRGB(110, 65, 50),

	Atmosphere = {
		Density = 0.48,
		Offset = 0,
		Color = Color3.fromRGB(115, 80, 65),
		Decay = Color3.fromRGB(55, 25, 20),
		Glare = 0.3,
		Haze = 3,
	},

	ColorCorrection = {
		Brightness = -0.08,
		Contrast = 0.2,
		Saturation = -0.05,
		TintColor = Color3.fromRGB(255, 155, 120),
	},
}

return Profiles