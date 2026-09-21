local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Config = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PolishConfig"))

local POP = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local STUDS = "rbxassetid://6927295847"

local function formatNumber(value)
	value = tonumber(value) or 0
	local absolute = math.abs(value)
	if absolute >= 1e9 then return string.format("%.2fB", value / 1e9) end
	if absolute >= 1e6 then return string.format("%.2fM", value / 1e6) end
	if absolute >= 1e3 then return string.format("%.1fK", value / 1e3) end
	if value == math.floor(value) then return tostring(math.floor(value)) end
	return string.format("%.1f", value)
end

local function playSound(id, volume, speed)
	if type(id) ~= "string" or id == "" then return nil end
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = volume or 0.35
	sound.PlaybackSpeed = speed or 1
	sound.Parent = SoundService
	sound:Play()
	Debris:AddItem(sound, 6)
	return sound
end

-- HUD: server attributes remain the source of truth.
local gui = Instance.new("ScreenGui")
gui.Name = "PolishHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 15
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global

local hud = Instance.new("Frame")
hud.Name = "RateHUD"
hud.AnchorPoint = Vector2.new(1, 0)
hud.Position = UDim2.new(1, -22, 0, 18)
hud.Size = UDim2.fromOffset(245, 72)
hud.BackgroundColor3 = Color3.fromRGB(26, 29, 42)
hud.BorderSizePixel = 0
hud.Parent = gui

local hudCorner = Instance.new("UICorner")
hudCorner.CornerRadius = UDim.new(0, 13)
hudCorner.Parent = hud
local hudStroke = Instance.new("UIStroke")
hudStroke.Color = Color3.fromRGB(15, 15, 18)
hudStroke.Thickness = 3
hudStroke.Parent = hud

local texture = Instance.new("ImageLabel")
texture.Name = "Studs"
texture.Size = UDim2.fromScale(1, 1)
texture.BackgroundTransparency = 1
texture.Image = STUDS
texture.ImageTransparency = 0.78
texture.ScaleType = Enum.ScaleType.Tile
texture.TileSize = UDim2.fromOffset(54, 54)
texture.ZIndex = 0
texture.Parent = hud
local textureCorner = Instance.new("UICorner")
textureCorner.CornerRadius = hudCorner.CornerRadius
textureCorner.Parent = texture

local function rateLabel(name, position, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = position
	label.Size = UDim2.new(1, -24, 0, 27)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = color
	label.TextSize = 19
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 2
	label.Parent = hud
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Thickness = 2
	stroke.Parent = label
	return label
end

local cashRate = rateLabel("CashPerSecond", UDim2.fromOffset(13, 8), Color3.fromRGB(92, 255, 116))
local speedRate = rateLabel("SpeedPerSecond", UDim2.fromOffset(13, 37), Color3.fromRGB(85, 190, 255))

local banner = Instance.new("TextLabel")
banner.Name = "EventBanner"
banner.AnchorPoint = Vector2.new(0.5, 0.5)
banner.Position = UDim2.fromScale(0.5, 0.25)
banner.Size = UDim2.fromOffset(430, 64)
banner.BackgroundTransparency = 1
banner.Font = Enum.Font.FredokaOne
banner.TextColor3 = Color3.new(1, 1, 1)
banner.TextStrokeColor3 = Color3.new(0, 0, 0)
banner.TextStrokeTransparency = 0
banner.TextScaled = true
banner.TextTransparency = 1
banner.ZIndex = 100
banner.Parent = gui
local bannerScale = Instance.new("UIScale")
bannerScale.Scale = 0.75
bannerScale.Parent = banner

gui.Parent = playerGui

local function refreshRates()
	cashRate.Text = "$" .. formatNumber(player:GetAttribute("CashPerSecond")) .. " / sec"
	local training = tonumber(player:GetAttribute("TrainingSpeedPerSecond")) or 0
	speedRate.Text = if training > 0 then "+" .. formatNumber(training) .. " Speed / sec" else "Speed training: idle"
	speedRate.TextColor3 = if training > 0 then Color3.fromRGB(85, 190, 255) else Color3.fromRGB(170, 178, 195)
end

player:GetAttributeChangedSignal("CashPerSecond"):Connect(refreshRates)
player:GetAttributeChangedSignal("TrainingSpeedPerSecond"):Connect(refreshRates)
refreshRates()

local bannerGeneration = 0
local function showBanner(text, color)
	bannerGeneration += 1
	local generation = bannerGeneration
	banner.Text = text
	banner.TextColor3 = color
	banner.TextTransparency = 1
	bannerScale.Scale = 0.72
	TweenService:Create(banner, TweenInfo.new(0.2), { TextTransparency = 0 }):Play()
	TweenService:Create(bannerScale, POP, { Scale = 1 }):Play()
	task.delay(1.25, function()
		if generation ~= bannerGeneration then return end
		TweenService:Create(banner, TweenInfo.new(0.28), { TextTransparency = 1 }):Play()
		TweenService:Create(bannerScale, TweenInfo.new(0.28), { Scale = 1.12 }):Play()
	end)
end

local function floatingText(text, color, position)
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = position
	label.Size = UDim2.fromOffset(230, 42)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.Text = text
	label.TextColor3 = color
	label.TextSize = 25
	label.TextStrokeTransparency = 0
	label.ZIndex = 90
	label.Parent = gui
	local scale = Instance.new("UIScale")
	scale.Scale = 0.72
	scale.Parent = label
	TweenService:Create(scale, POP, { Scale = 1 }):Play()
	TweenService:Create(label, TweenInfo.new(0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = position - UDim2.fromOffset(0, 65),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
	Debris:AddItem(label, 0.9)
end

-- Floating Cash and Speed are derived from replicated stat deltas, never awarded here.
task.spawn(function()
	local stats = player:WaitForChild("Stats", 20)
	if not stats then return end
	local cash = stats:WaitForChild("Cash", 10)
	local speed = stats:WaitForChild("Speed", 10)
	local oldCash = cash and cash.Value or 0
	local oldSpeed = speed and speed.Value or 0
	if cash then
		cash.Changed:Connect(function(value)
			local delta = value - oldCash
			oldCash = value
			if delta > 0 and (tonumber(player:GetAttribute("CashPerSecond")) or 0) > 0 then
				floatingText("+$" .. formatNumber(delta), Color3.fromRGB(92, 255, 116), UDim2.new(1, -145, 0, 112))
			end
		end)
	end
	if speed then
		speed.Changed:Connect(function(value)
			local delta = value - oldSpeed
			oldSpeed = value
			if delta > 0 and (tonumber(player:GetAttribute("TrainingSpeedPerSecond")) or 0) > 0 then
				floatingText("+" .. formatNumber(delta) .. " SPEED", Color3.fromRGB(85, 190, 255), UDim2.fromScale(0.5, 0.72))
			end
		end)
	end
end)

local function animateOpen(screenGui)
	if screenGui == gui or not screenGui.Enabled then return end
	local root = screenGui:FindFirstChildWhichIsA("GuiObject")
	if not root then return end
	local scale = root:FindFirstChild("PolishOpenScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Name = "PolishOpenScale"
		scale.Parent = root
	end
	scale.Scale = 0.9
	TweenService:Create(scale, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

local function registerGui(child)
	if not child:IsA("ScreenGui") or child == gui then return end
	child:GetPropertyChangedSignal("Enabled"):Connect(function()
		if child.Enabled then animateOpen(child) end
	end)
end

for _, child in ipairs(playerGui:GetChildren()) do registerGui(child) end
playerGui.ChildAdded:Connect(registerGui)

local function rarityColor(rarity)
	return Config.RarityColors[rarity] or Color3.new(1, 1, 1)
end

local function hatchBurst(monster, rarity, isOwner)
	if not monster or not monster:IsA("Model") or not monster.Parent then return end
	local primary = monster.PrimaryPart or monster:FindFirstChildWhichIsA("BasePart", true)
	if not primary then return end
	local color = rarityColor(rarity)
	local highlight = Instance.new("Highlight")
	highlight.Name = "HatchHighlight"
	highlight.FillColor = color
	highlight.OutlineColor = Color3.new(1, 1, 1)
	highlight.FillTransparency = 0.15
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = monster
	TweenService:Create(highlight, TweenInfo.new(0.9), { FillTransparency = 1, OutlineTransparency = 1 }):Play()
	Debris:AddItem(highlight, 1)

	local attachment = Instance.new("Attachment")
	attachment.Name = "HatchBurst"
	attachment.Parent = primary
	local particles = Instance.new("ParticleEmitter")
	particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	particles.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	particles.LightEmission = 0.7
	particles.Lifetime = NumberRange.new(0.55, 1.1)
	particles.Speed = NumberRange.new(6, 12)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Drag = 3
	particles.Rate = 0
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.55),
		NumberSequenceKeypoint.new(1, 0),
	})
	particles.Parent = attachment
	particles:Emit(Config.RarityBurstCount[rarity] or 20)
	Debris:AddItem(attachment, 1.5)
	if isOwner then
		showBanner(string.upper(tostring(rarity)) .. " HATCH!", color)
		playSound(Config.Sounds.Hatch, 0.5, 0.9 + math.random() * 0.2)
	end
end

local polishEvent = ReplicatedStorage:WaitForChild("PolishEvent", 20)
if polishEvent and polishEvent:IsA("RemoteEvent") then
	polishEvent.OnClientEvent:Connect(function(action, monster, rarity, ownerUserId)
		if action == "Hatch" then
			hatchBurst(monster, rarity, ownerUserId == player.UserId)
		end
	end)
end

local chaseSound
local runEvent = ReplicatedStorage:WaitForChild("RunUIEvent", 20)
if runEvent and runEvent:IsA("RemoteEvent") then
	runEvent.OnClientEvent:Connect(function(running, reason)
		local camera = workspace.CurrentCamera
		if running then
			showBanner("RUN!", Color3.fromRGB(255, 67, 67))
			playSound(Config.Sounds.Pickup, 0.45, 1)
			if camera then TweenService:Create(camera, TweenInfo.new(0.25), { FieldOfView = 76 }):Play() end
			if Config.Sounds.ChaseMusicId ~= "" and not chaseSound then
				chaseSound = Instance.new("Sound")
				chaseSound.Name = "ChaseMusic"
				chaseSound.SoundId = Config.Sounds.ChaseMusicId
				chaseSound.Volume = 0.45
				chaseSound.Looped = true
				chaseSound.Parent = SoundService
				chaseSound:Play()
			end
		else
			if camera then TweenService:Create(camera, TweenInfo.new(0.35), { FieldOfView = 70 }):Play() end
			if chaseSound then chaseSound:Destroy(); chaseSound = nil end
			if reason == "Deposited" then
				showBanner("EGG SECURED!", Color3.fromRGB(92, 255, 116))
				playSound(Config.Sounds.Deposit, 0.45, 1)
			end
		end
	end)
end

-- Floating income above owned monsters. Visual only; IncomeService performs payment.
task.spawn(function()
	while gui.Parent do
		task.wait(3)
		local shown = 0
		for _, monster in ipairs(workspace:GetDescendants()) do
			if shown >= 16 then break end
			if monster:IsA("Model") and monster:GetAttribute("IsMonster") == true
				and monster:GetAttribute("OwnerUserId") == player.UserId then
				local income = tonumber(monster:GetAttribute("FinalIncome")) or 0
				local primary = monster.PrimaryPart
				if primary and income > 0 then
					shown += 1
					local bill = Instance.new("BillboardGui")
					bill.Name = "IncomeFloat"
					bill.Adornee = primary
					bill.Size = UDim2.fromOffset(150, 40)
					bill.StudsOffsetWorldSpace = Vector3.new(math.random(-10, 10) / 10, 3, 0)
					bill.AlwaysOnTop = true
					bill.MaxDistance = 90
					bill.Parent = primary
					local text = Instance.new("TextLabel")
					text.Size = UDim2.fromScale(1, 1)
					text.BackgroundTransparency = 1
					text.Font = Enum.Font.FredokaOne
					text.Text = "+$" .. formatNumber(income)
					text.TextColor3 = Color3.fromRGB(92, 255, 116)
					text.TextSize = 22
					text.TextStrokeTransparency = 0
					text.Parent = bill
					TweenService:Create(bill, TweenInfo.new(1), { StudsOffsetWorldSpace = bill.StudsOffsetWorldSpace + Vector3.new(0, 2, 0) }):Play()
					TweenService:Create(text, TweenInfo.new(1), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
					Debris:AddItem(bill, 1.05)
				end
			end
		end
	end
end)
