local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local event = ReplicatedStorage:WaitForChild("BiomeUIEvent")

local gui = Instance.new("ScreenGui")
gui.Name = "BiomeUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.IgnoreGuiInset = false
gui.Parent = playerGui

-- Main panel
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.new(0.5, 0, 0, 18)
panel.Size = UDim2.new(0.9, 0, 0, 210)
panel.BackgroundColor3 = Color3.fromRGB(16, 20, 29)
panel.BackgroundTransparency = 0.05
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui

local constraint = Instance.new("UISizeConstraint")
constraint.MaxSize = Vector2.new(380, 210)
constraint.MinSize = Vector2.new(300, 210)
constraint.Parent = panel

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 18)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(78, 96, 125)
stroke.Transparency = 0.3
stroke.Thickness = 1.5
stroke.Parent = panel

-- Soft gradient
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 37, 52)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 18, 27))
})
gradient.Rotation = 90
gradient.Parent = panel

-- Inner top glow
local glow = Instance.new("Frame")
glow.Name = "Glow"
glow.Position = UDim2.new(0, 12, 0, 8)
glow.Size = UDim2.new(1, -24, 0, 2)
glow.BackgroundColor3 = Color3.fromRGB(90, 175, 255)
glow.BackgroundTransparency = 0.25
glow.BorderSizePixel = 0
glow.Parent = panel

local glowCorner = Instance.new("UICorner")
glowCorner.CornerRadius = UDim.new(1, 0)
glowCorner.Parent = glow

-- Biome pill
local biomeBadge = Instance.new("Frame")
biomeBadge.Name = "BiomeBadge"
biomeBadge.AnchorPoint = Vector2.new(0.5, 0)
biomeBadge.Position = UDim2.new(0.5, 0, 0, 16)
biomeBadge.Size = UDim2.new(0, 210, 0, 32)
biomeBadge.BackgroundColor3 = Color3.fromRGB(32, 43, 60)
biomeBadge.BackgroundTransparency = 0.08
biomeBadge.BorderSizePixel = 0
biomeBadge.Parent = panel

local badgeCorner = Instance.new("UICorner")
badgeCorner.CornerRadius = UDim.new(1, 0)
badgeCorner.Parent = biomeBadge

local badgeStroke = Instance.new("UIStroke")
badgeStroke.Color = Color3.fromRGB(85, 150, 225)
badgeStroke.Transparency = 0.5
badgeStroke.Parent = biomeBadge

local biomeName = Instance.new("TextLabel")
biomeName.Name = "BiomeName"
biomeName.Size = UDim2.new(1, -20, 1, 0)
biomeName.Position = UDim2.new(0, 10, 0, 0)
biomeName.BackgroundTransparency = 1
biomeName.Font = Enum.Font.GothamBlack
biomeName.TextSize = 17
biomeName.TextColor3 = Color3.fromRGB(238, 245, 255)
biomeName.Text = ""
biomeName.TextXAlignment = Enum.TextXAlignment.Center
biomeName.Parent = biomeBadge

-- Stat cards
local function createStatCard(name, xScale, title)
	local card = Instance.new("Frame")
	card.Name = name
	card.Position = UDim2.new(xScale, 0, 0, 62)
	card.Size = UDim2.new(0.5, -18, 0, 66)
	card.BackgroundColor3 = Color3.fromRGB(26, 32, 44)
	card.BackgroundTransparency = 0.05
	card.BorderSizePixel = 0
	card.Parent = panel

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 12)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = Color3.fromRGB(61, 72, 92)
	cardStroke.Transparency = 0.55
	cardStroke.Parent = card

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Position = UDim2.new(0, 10, 0, 7)
	titleLabel.Size = UDim2.new(1, -20, 0, 18)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamMedium
	titleLabel.TextSize = 11
	titleLabel.TextColor3 = Color3.fromRGB(145, 158, 180)
	titleLabel.Text = title
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = card

	local value = Instance.new("TextLabel")
	value.Name = "Value"
	value.Position = UDim2.new(0, 10, 0, 25)
	value.Size = UDim2.new(1, -20, 0, 32)
	value.BackgroundTransparency = 1
	value.Font = Enum.Font.GothamBlack
	value.TextSize = 24
	value.TextColor3 = Color3.fromRGB(245, 248, 255)
	value.Text = "0"
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.Parent = card

	return card, value
end

local recommendedCard, recommendedValue =
	createStatCard("RecommendedCard", 0, "RECOMMENDED SPEED")

recommendedCard.Position = UDim2.new(0, 12, 0, 62)

local currentCard, currentValue =
	createStatCard("CurrentCard", 0.5, "YOUR SPEED")

currentCard.Position = UDim2.new(0.5, 6, 0, 62)

-- Progress background
local progressBackground = Instance.new("Frame")
progressBackground.Name = "ProgressBackground"
progressBackground.Position = UDim2.new(0, 12, 0, 140)
progressBackground.Size = UDim2.new(1, -24, 0, 10)
progressBackground.BackgroundColor3 = Color3.fromRGB(37, 44, 58)
progressBackground.BorderSizePixel = 0
progressBackground.Parent = panel

local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(1, 0)
progressCorner.Parent = progressBackground

local progressFill = Instance.new("Frame")
progressFill.Name = "ProgressFill"
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = Color3.fromRGB(82, 184, 255)
progressFill.BorderSizePixel = 0
progressFill.Parent = progressBackground

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = progressFill

local fillGradient = Instance.new("UIGradient")
fillGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(67, 143, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(94, 225, 255))
})
fillGradient.Parent = progressFill

-- Status
local statusContainer = Instance.new("Frame")
statusContainer.Name = "StatusContainer"
statusContainer.AnchorPoint = Vector2.new(0.5, 0)
statusContainer.Position = UDim2.new(0.5, 0, 0, 163)
statusContainer.Size = UDim2.new(1, -24, 0, 34)
statusContainer.BackgroundColor3 = Color3.fromRGB(33, 39, 51)
statusContainer.BorderSizePixel = 0
statusContainer.Parent = panel

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 10)
statusCorner.Parent = statusContainer

local status = Instance.new("TextLabel")
status.Name = "Status"
status.Size = UDim2.new(1, 0, 1, 0)
status.BackgroundTransparency = 1
status.Font = Enum.Font.GothamBlack
status.TextSize = 18
status.Text = ""
status.TextColor3 = Color3.fromRGB(255, 255, 255)
status.Parent = statusContainer

local function formatSpeed(value)
	if value == math.floor(value) then
		return string.format("%.0f", value)
	end

	return string.format("%.2f", value)
end

local function updateProgress(playerSpeed, recommendedSpeed)
	local ratio = 0

	if recommendedSpeed > 0 then
		ratio = math.clamp(playerSpeed / recommendedSpeed, 0, 1)
	end

	TweenService:Create(
		progressFill,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Size = UDim2.new(ratio, 0, 1, 0)
		}
	):Play()
end

local function showPanel()
	panel.Position = UDim2.new(0.5, 0, 0, 4)
	panel.BackgroundTransparency = 1
	panel.Visible = true

	TweenService:Create(
		panel,
		TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{
			Position = UDim2.new(0.5, 0, 0, 18),
			BackgroundTransparency = 0.05
		}
	):Play()
end

event.OnClientEvent:Connect(function(data)
	if not data.Visible then
		panel.Visible = false
		return
	end

	biomeName.Text = string.upper(data.BiomeName)

	recommendedValue.Text =
		formatSpeed(data.RecommendedSpeed)

	currentValue.Text =
		formatSpeed(data.PlayerSpeed)

	status.Text = data.Status

	updateProgress(
		data.PlayerSpeed,
		data.RecommendedSpeed
	)

	if data.Status == "READY" then
		status.TextColor3 = Color3.fromRGB(110, 255, 165)
		statusContainer.BackgroundColor3 =
			Color3.fromRGB(24, 66, 49)

		currentValue.TextColor3 =
			Color3.fromRGB(110, 255, 165)
	else
		status.TextColor3 = Color3.fromRGB(255, 116, 116)
		statusContainer.BackgroundColor3 =
			Color3.fromRGB(72, 34, 39)

		currentValue.TextColor3 =
			Color3.fromRGB(255, 140, 140)
	end

	if not panel.Visible then
		showPanel()
	end
end)

event:FireServer("Ready")