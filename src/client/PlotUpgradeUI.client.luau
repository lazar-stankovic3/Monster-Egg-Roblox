local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local event = ReplicatedStorage:WaitForChild("PlotUpgradeEvent", 15)
if not event then warn("[PlotUpgradeUI] PlotUpgradeEvent was not initialized"); return end

local gui = Instance.new("ScreenGui")
gui.Name = "PlotUpgradeUi"
gui.ResetOnSpawn = false
gui.DisplayOrder = 20

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(1, 0.5)
panel.Position = UDim2.new(1, -24, 0.5, 0)
panel.Size = UDim2.fromOffset(270, 132)
panel.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
panel.BackgroundTransparency = 0.08
panel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = panel
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(115, 205, 255)
stroke.Thickness = 2
stroke.Parent = panel

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(12, 8)
title.Size = UDim2.new(1, -24, 0, 28)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "PLOT CAPACITY"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 19
title.Parent = panel

local capacityLabel = Instance.new("TextLabel")
capacityLabel.Position = UDim2.fromOffset(12, 38)
capacityLabel.Size = UDim2.new(1, -24, 0, 24)
capacityLabel.BackgroundTransparency = 1
capacityLabel.Font = Enum.Font.GothamMedium
capacityLabel.TextColor3 = Color3.fromRGB(205, 220, 235)
capacityLabel.TextSize = 16
capacityLabel.Parent = panel

local button = Instance.new("TextButton")
button.Position = UDim2.fromOffset(12, 70)
button.Size = UDim2.new(1, -24, 0, 48)
button.BackgroundColor3 = Color3.fromRGB(55, 165, 225)
button.AutoButtonColor = true
button.Font = Enum.Font.GothamBold
button.TextColor3 = Color3.new(1, 1, 1)
button.TextSize = 17
button.Parent = panel
local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 10)
buttonCorner.Parent = button

local busy = false
local function refresh()
	local capacity = tonumber(player:GetAttribute("PlotCapacity")) or 6
	local nextCapacity = tonumber(player:GetAttribute("PlotUpgradeNextCapacity")) or 0
	local cost = tonumber(player:GetAttribute("PlotUpgradeCost")) or 0
	local maxed = player:GetAttribute("PlotUpgradeMaxed") == true
	local status = player:GetAttribute("PlotUpgradeStatus")
	capacityLabel.Text = string.format("Current slots: %d", capacity)
	if maxed then
		button.Text = "MAX CAPACITY (16)"
		button.BackgroundColor3 = Color3.fromRGB(80, 90, 105)
		button.Active = false
	elseif status == "NotEnoughCash" then
		button.Text = string.format("Need $%s for %d slots", tostring(cost), nextCapacity)
		button.BackgroundColor3 = Color3.fromRGB(200, 75, 70)
		button.Active = true
	elseif status == "DataNotReady" then
		button.Text = "DATA NOT READY"
		button.BackgroundColor3 = Color3.fromRGB(200, 130, 55)
		button.Active = true
	else
		button.Text = string.format("UPGRADE TO %d — $%s", nextCapacity, tostring(cost))
		button.BackgroundColor3 = Color3.fromRGB(55, 165, 225)
		button.Active = true
	end
	busy = false
end

button.Activated:Connect(function()
	if busy or player:GetAttribute("PlotUpgradeMaxed") == true then return end
	busy = true
	event:FireServer()
	task.delay(1, function() busy = false end)
end)

for _, attribute in ipairs({ "PlotCapacity", "PlotUpgradeNextCapacity", "PlotUpgradeCost",
	"PlotUpgradeMaxed", "PlotUpgradeStatus" }) do
	player:GetAttributeChangedSignal(attribute):Connect(refresh)
end

gui.Parent = player:WaitForChild("PlayerGui")
refresh()
