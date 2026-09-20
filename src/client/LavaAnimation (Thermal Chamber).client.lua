local RunService = game:GetService("RunService")

local lavaFloor = workspace:WaitForChild("LavaFloor")
local texture = lavaFloor:WaitForChild("Texture")
local light = lavaFloor:WaitForChild("SurfaceLight")

-- =========================
-- POMERANJE LAVE
-- =========================

local MOVE_SPEED_U = 0.6
local MOVE_SPEED_V = 0.18

-- =========================
-- PULSIRANJE SVETLA
-- =========================

local BASE_BRIGHTNESS = 0.8
local BRIGHTNESS_PULSE = 0.35

-- =========================
-- PULSIRANJE TEKSTURE
-- =========================

local BASE_TRANSPARENCY = 0.02
local TRANSPARENCY_PULSE = 0.08

-- Brzina pulsiranja
local PULSE_SPEED_1 = 1.3
local PULSE_SPEED_2 = 2.1

-- =========================
-- START VREDNOSTI
-- =========================

local timePassed = 0
local offsetU = texture.OffsetStudsU
local offsetV = texture.OffsetStudsV

-- =========================
-- ANIMACIJA
-- =========================

RunService.RenderStepped:Connect(function(dt)
	timePassed += dt

	-- Pomeranje lava teksture
	offsetU += MOVE_SPEED_U * dt
	offsetV += MOVE_SPEED_V * dt

	texture.OffsetStudsU = offsetU
	texture.OffsetStudsV = offsetV

	-- Nepravilan heat pulse
	local wave1 = math.sin(timePassed * PULSE_SPEED_1)
	local wave2 = math.sin(timePassed * PULSE_SPEED_2)

	local pulse = wave1 * 0.7 + wave2 * 0.3

	-- Pretvaramo otprilike u 0 - 1e
	pulse = (pulse + 1) / 2

	-- Pulsiranje SurfaceLight-a
	light.Brightness =
		BASE_BRIGHTNESS + pulse * BRIGHTNESS_PULSE

	-- Pulsiranje same teksture
	-- Kad je pulse jači, lava je manje providna
	texture.Transparency =
		BASE_TRANSPARENCY + (1 - pulse) * TRANSPARENCY_PULSE
end)