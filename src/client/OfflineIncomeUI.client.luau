local Players = game:GetService("Players")
local player = Players.LocalPlayer

local shown = false

local function formatDuration(seconds)
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	if hours > 0 then return string.format("%dh %02dm", hours, minutes) end
	return string.format("%dm", math.max(1, minutes))
end

local function showOfflineIncome()
	if shown or player:GetAttribute("PlayerDataStatus") ~= "Ready" then return end
	local amount = tonumber(player:GetAttribute("OfflineIncomeAmount")) or 0
	local seconds = tonumber(player:GetAttribute("OfflineIncomeSeconds")) or 0
	if amount <= 0 or seconds <= 0 then return end
	shown = true

	local gui = Instance.new("ScreenGui")
	gui.Name = "OfflineIncomeUi"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 50
	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = UDim2.fromScale(0.5, 0.08)
	frame.Size = UDim2.fromOffset(390, 92)
	frame.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
	frame.BackgroundTransparency = 0.08
	frame.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 205, 70)
	stroke.Thickness = 2
	stroke.Parent = frame
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = 22
	label.TextWrapped = true
	label.Text = string.format("Welcome back!\nYou earned $%s in %s", string.format("%.1f", amount), formatDuration(seconds))
	label.Parent = frame
	gui.Parent = player:WaitForChild("PlayerGui")
	task.delay(8, function() if gui.Parent then gui:Destroy() end end)
end

player:GetAttributeChangedSignal("PlayerDataStatus"):Connect(showOfflineIncome)
player:GetAttributeChangedSignal("OfflineIncomeAmount"):Connect(showOfflineIncome)
player:GetAttributeChangedSignal("OfflineIncomeSeconds"):Connect(showOfflineIncome)
task.defer(showOfflineIncome)
