local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local event = ReplicatedStorage:WaitForChild("BiomeUIEvent")

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local AUTO_HIDE_TIME = 2.5
local SHOW_TIME = 0.22
local HIDE_TIME = 0.18

--------------------------------------------------
-- GUI
--------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "BiomeUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.IgnoreGuiInset = false
gui.Parent = playerGui

--------------------------------------------------
-- MAIN PANEL
--------------------------------------------------

local panel = Instance.new("Frame")
panel.Name = "Panel"

panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.new(0.5, 0, 0, 18)

panel.Size = UDim2.new(0, 230, 0, 72)

panel.BackgroundColor3 = Color3.fromRGB(10, 13, 18)
panel.BackgroundTransparency = 0.28

panel.BorderSizePixel = 0
panel.Visible = false

panel.Parent = gui

--------------------------------------------------
-- CORNER
--------------------------------------------------

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = panel

--------------------------------------------------
-- STROKE
--------------------------------------------------

local stroke = Instance.new("UIStroke")

stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Transparency = 0.88
stroke.Thickness = 1

stroke.Parent = panel

--------------------------------------------------
-- GRADIENT
--------------------------------------------------

local gradient = Instance.new("UIGradient")

gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(
		0,
		Color3.fromRGB(28, 33, 44)
	),

	ColorSequenceKeypoint.new(
		1,
		Color3.fromRGB(11, 14, 20)
	)
})

gradient.Rotation = 90

gradient.Parent = panel

--------------------------------------------------
-- BIOME NAME
--------------------------------------------------

local biomeName = Instance.new("TextLabel")

biomeName.Name = "BiomeName"

biomeName.Position = UDim2.new(0, 14, 0, 10)
biomeName.Size = UDim2.new(1, -28, 0, 25)

biomeName.BackgroundTransparency = 1

biomeName.Font = Enum.Font.GothamBold
biomeName.TextSize = 17

biomeName.TextColor3 = Color3.fromRGB(245, 248, 255)

biomeName.Text = ""

biomeName.TextXAlignment = Enum.TextXAlignment.Center

biomeName.Parent = panel

--------------------------------------------------
-- RECOMMENDED SPEED
--------------------------------------------------

local recommended = Instance.new("TextLabel")

recommended.Name = "Recommended"

recommended.Position = UDim2.new(0, 14, 0, 37)
recommended.Size = UDim2.new(1, -28, 0, 22)

recommended.BackgroundTransparency = 1

recommended.Font = Enum.Font.GothamMedium
recommended.TextSize = 13

recommended.TextColor3 = Color3.fromRGB(170, 180, 198)

recommended.Text = "Recommended Speed  •  0"

recommended.TextXAlignment = Enum.TextXAlignment.Center

recommended.Parent = panel

--------------------------------------------------
-- FORMAT SPEED
--------------------------------------------------

local function formatSpeed(value)

	if value == math.floor(value) then
		return string.format("%.0f", value)
	end

	return string.format("%.1f", value)

end

--------------------------------------------------
-- STATE
--------------------------------------------------

local hideTask = nil
local showing = false

--------------------------------------------------
-- SHOW PANEL
--------------------------------------------------

local function showPanel()

	showing = true

	panel.Position = UDim2.new(0.5, 0, 0, 5)

	panel.BackgroundTransparency = 1

	biomeName.TextTransparency = 1
	recommended.TextTransparency = 1

	panel.Visible = true

	--------------------------------------------------
	-- PANEL ANIMATION
	--------------------------------------------------

	TweenService:Create(
		panel,

		TweenInfo.new(
			SHOW_TIME,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		),

		{
			Position = UDim2.new(0.5, 0, 0, 18),
			BackgroundTransparency = 0.28
		}

	):Play()

	--------------------------------------------------
	-- TEXT ANIMATION
	--------------------------------------------------

	TweenService:Create(
		biomeName,

		TweenInfo.new(
			SHOW_TIME,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		),

		{
			TextTransparency = 0
		}

	):Play()

	TweenService:Create(
		recommended,

		TweenInfo.new(
			SHOW_TIME + 0.03,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		),

		{
			TextTransparency = 0
		}

	):Play()

end

--------------------------------------------------
-- HIDE PANEL
--------------------------------------------------

local function hidePanel()

	if not panel.Visible then
		return
	end

	showing = false

	--------------------------------------------------
	-- TEXT FADE
	--------------------------------------------------

	TweenService:Create(
		biomeName,

		TweenInfo.new(
			HIDE_TIME,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.In
		),

		{
			TextTransparency = 1
		}

	):Play()

	TweenService:Create(
		recommended,

		TweenInfo.new(
			HIDE_TIME,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.In
		),

		{
			TextTransparency = 1
		}

	):Play()

	--------------------------------------------------
	-- PANEL HIDE
	--------------------------------------------------

	local tween = TweenService:Create(
		panel,

		TweenInfo.new(
			HIDE_TIME,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.In
		),

		{
			Position = UDim2.new(0.5, 0, 0, 5),
			BackgroundTransparency = 1
		}

	)

	tween:Play()

	tween.Completed:Wait()

	if not showing then
		panel.Visible = false
	end

end

--------------------------------------------------
-- EVENT
--------------------------------------------------

event.OnClientEvent:Connect(function(data)

	--------------------------------------------------
	-- SERVER TRAŽI DA SE UI SAKRIJE
	--------------------------------------------------

	if not data.Visible then

		if hideTask then
			task.cancel(hideTask)
			hideTask = nil
		end

		hidePanel()

		return

	end

	--------------------------------------------------
	-- UPDATE BIOME NAME
	--------------------------------------------------

	biomeName.Text = string.upper(
		data.BiomeName or "UNKNOWN BIOME"
	)

	--------------------------------------------------
	-- UPDATE RECOMMENDED SPEED
	--------------------------------------------------

	local speed = data.RecommendedSpeed or 0

	recommended.Text =
		"Recommended Speed  •  "
		.. formatSpeed(speed)

	--------------------------------------------------
	-- CANCEL OLD AUTO HIDE
	--------------------------------------------------

	if hideTask then
		task.cancel(hideTask)
		hideTask = nil
	end

	--------------------------------------------------
	-- SHOW UI
	--------------------------------------------------

	if not panel.Visible then
		showPanel()
	else
		showing = true

		panel.Position = UDim2.new(0.5, 0, 0, 18)
		panel.BackgroundTransparency = 0.28

		biomeName.TextTransparency = 0
		recommended.TextTransparency = 0
	end

	--------------------------------------------------
	-- AUTO HIDE
	--------------------------------------------------

	hideTask = task.delay(AUTO_HIDE_TIME, function()

		hideTask = nil

		if panel.Visible then
			hidePanel()
		end

	end)

end)

--------------------------------------------------
-- READY
--------------------------------------------------

event:FireServer("Ready")
