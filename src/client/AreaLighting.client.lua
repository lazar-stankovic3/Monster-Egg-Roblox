local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local Profiles = require(
	ReplicatedStorage
		:WaitForChild("Modules")
		:WaitForChild("LightingProfiles")
)

local Areas = workspace:WaitForChild("Areas")

local TRANSITION_TIME = 1.5
local CHECK_INTERVAL = 0.15

local currentArea = nil
local elapsed = 0

-- Kreiramo efekte ako već ne postoje

local atmosphere = Lighting:FindFirstChild("AreaAtmosphere")

if not atmosphere then
	atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "AreaAtmosphere"
	atmosphere.Parent = Lighting
end

local colorCorrection = Lighting:FindFirstChild("AreaColorCorrection")

if not colorCorrection then
	colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Name = "AreaColorCorrection"
	colorCorrection.Parent = Lighting
end

local bloom = Lighting:FindFirstChild("AreaBloom")

if not bloom then
	bloom = Instance.new("BloomEffect")
	bloom.Name = "AreaBloom"
	bloom.Parent = Lighting
end

local tweenInfo = TweenInfo.new(
	TRANSITION_TIME,
	Enum.EasingStyle.Quad,
	Enum.EasingDirection.Out
)

-- Preserve the starting lighting before any area profile is applied.
local defaultProperties = {}
local activeTweens = {}

local function rememberDefaults(object, propertyNames)
	local properties = {}
	for _, name in ipairs(propertyNames) do
		properties[name] = object[name]
	end
	defaultProperties[object] = properties
end

rememberDefaults(Lighting, {
	"Brightness", "ClockTime", "ExposureCompensation", "Ambient", "OutdoorAmbient",
})
rememberDefaults(atmosphere, { "Density", "Offset", "Color", "Decay", "Glare", "Haze" })
rememberDefaults(colorCorrection, { "Brightness", "Contrast", "Saturation", "TintColor" })
rememberDefaults(bloom, { "Intensity", "Size", "Threshold" })

local function resetLighting()
	for object, tween in pairs(activeTweens) do
		tween:Cancel()
		activeTweens[object] = nil
	end
	for object, properties in pairs(defaultProperties) do
		for name, value in pairs(properties) do
			object[name] = value
		end
	end
	currentArea = nil
	elapsed = 0
end

local function tweenObject(object, properties)
	if activeTweens[object] then
		activeTweens[object]:Cancel()
	end
	local tween = TweenService:Create(
		object,
		tweenInfo,
		properties
	)

	activeTweens[object] = tween
	tween:Play()

	return tween
end

local function applyProfile(areaName)
	local profile = Profiles[areaName]

	if not profile then
		warn("Nema Lighting profila za area:", areaName)
		return
	end

	print("Lighting area:", areaName)

	-- Glavni Lighting

	local lightingProperties = {}

	if profile.Brightness ~= nil then
		lightingProperties.Brightness = profile.Brightness
	end

	if profile.ClockTime ~= nil then
		lightingProperties.ClockTime = profile.ClockTime
	end

	if profile.ExposureCompensation ~= nil then
		lightingProperties.ExposureCompensation =
			profile.ExposureCompensation
	end

	if profile.Ambient ~= nil then
		lightingProperties.Ambient = profile.Ambient
	end

	if profile.OutdoorAmbient ~= nil then
		lightingProperties.OutdoorAmbient =
			profile.OutdoorAmbient
	end

	tweenObject(
		Lighting,
		lightingProperties
	)

	-- Atmosphere

	if profile.Atmosphere then
		local data = profile.Atmosphere

		tweenObject(atmosphere, {
			Density = data.Density or atmosphere.Density,
			Offset = data.Offset or atmosphere.Offset,
			Color = data.Color or atmosphere.Color,
			Decay = data.Decay or atmosphere.Decay,
			Glare = data.Glare or atmosphere.Glare,
			Haze = data.Haze or atmosphere.Haze,
		})
	end

	-- Color Correction

	if profile.ColorCorrection then
		local data = profile.ColorCorrection

		tweenObject(colorCorrection, {
			Brightness = data.Brightness
				or colorCorrection.Brightness,

			Contrast = data.Contrast
				or colorCorrection.Contrast,

			Saturation = data.Saturation
				or colorCorrection.Saturation,

			TintColor = data.TintColor
				or colorCorrection.TintColor,
		})
	end

	-- Bloom

	if profile.Bloom then
		local data = profile.Bloom

		tweenObject(bloom, {
			Intensity = data.Intensity
				or bloom.Intensity,

			Size = data.Size
				or bloom.Size,

			Threshold = data.Threshold
				or bloom.Threshold,
		})
	end
end

local function isPointInsidePart(point, part)
	local relativePoint =
		part.CFrame:PointToObjectSpace(point)

	local halfSize = part.Size / 2

	return
		math.abs(relativePoint.X) <= halfSize.X
		and math.abs(relativePoint.Y) <= halfSize.Y
		and math.abs(relativePoint.Z) <= halfSize.Z
end

local function getCurrentArea(position)
	for _, area in ipairs(Areas:GetChildren()) do

		local zone =
			area:FindFirstChild("LightingZone")

		if zone
			and zone:IsA("BasePart")
			and isPointInsidePart(position, zone)
		then
			return area.Name
		end
	end

	return nil
end

local function updateArea()
	local character = player.Character

	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local rootPart =
		character:FindFirstChild("HumanoidRootPart")

	if not rootPart then
		return
	end

	local areaName =
		getCurrentArea(rootPart.Position)

	if areaName
		and areaName ~= currentArea
	then

		currentArea = areaName

		applyProfile(areaName)
	end
end

local deathConnection = nil

local function onCharacterAdded(character)
	if deathConnection then
		deathConnection:Disconnect()
		deathConnection = nil
	end
	resetLighting()

	local humanoid = character:WaitForChild("Humanoid")
	if player.Character ~= character then
		return
	end
	deathConnection = humanoid.Died:Connect(resetLighting)
	if humanoid.Health <= 0 then
		resetLighting()
	end
end

player.CharacterAdded:Connect(onCharacterAdded)
player.CharacterRemoving:Connect(function()
	if deathConnection then
		deathConnection:Disconnect()
		deathConnection = nil
	end
	resetLighting()
end)

if player.Character then
	task.spawn(onCharacterAdded, player.Character)
end

RunService.Heartbeat:Connect(function(deltaTime)

	elapsed += deltaTime

	if elapsed < CHECK_INTERVAL then
		return
	end

	elapsed = 0

	updateArea()
end)
