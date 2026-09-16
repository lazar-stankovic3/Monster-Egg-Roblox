local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local event = ReplicatedStorage:WaitForChild("BiomeUIEvent")

local gui = Instance.new("ScreenGui")
gui.Name = "BiomeUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.new(0.5, 0, 0, 12)
panel.Size = UDim2.new(0.9, 0, 0, 182)
panel.BackgroundColor3 = Color3.fromRGB(22, 27, 36)
panel.BackgroundTransparency = 0.1
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui

local constraint = Instance.new("UISizeConstraint")
constraint.MaxSize = Vector2.new(340, 182)
constraint.Parent = panel
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = panel
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(90, 105, 125)
stroke.Transparency = 0.3
stroke.Parent = panel

local function label(name, y, height, textSize)
	local result = Instance.new("TextLabel")
	result.Name = name
	result.Position = UDim2.new(0, 12, 0, y)
	result.Size = UDim2.new(1, -24, 0, height)
	result.BackgroundTransparency = 1
	result.Font = Enum.Font.GothamBold
	result.TextSize = textSize
	result.TextColor3 = Color3.fromRGB(240, 243, 248)
	result.Text = ""
	result.TextWrapped = true
	result.Parent = panel
	return result
end

local biomeName = label("BiomeName", 10, 32, 20)
local recommended = label("RecommendedSpeed", 48, 38, 16)
local current = label("YourSpeed", 91, 38, 16)
local status = label("Status", 140, 28, 20)

local function formatSpeed(value)
	-- Preserve fractional training progress without showing long floating-point tails.
	if value == math.floor(value) then
		return string.format("%.0f", value)
	end
	return string.format("%.2f", value)
end

event.OnClientEvent:Connect(function(data)
	if not data.Visible then
		panel.Visible = false
		return
	end
	biomeName.Text = string.upper(data.BiomeName)
	recommended.Text = "Recommended Speed\n" .. formatSpeed(data.RecommendedSpeed)
	current.Text = "Your Speed\n" .. formatSpeed(data.PlayerSpeed)
	status.Text = data.Status
	status.TextColor3 = if data.Status == "READY"
		then Color3.fromRGB(102, 235, 153) else Color3.fromRGB(255, 109, 109)
	panel.Visible = true
end)

-- Connect the listener before requesting the authoritative initial snapshot.
event:FireServer("Ready")
