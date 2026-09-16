local Players = game:GetService("Players")

local BASE_WALK_SPEED = 16

-- Pretvara Speed stat u stvarni Roblox WalkSpeed
local function calculateWalkSpeed(speedStat)
	return BASE_WALK_SPEED + 12 * math.log10((speedStat / 10) + 1)
end

local function updatePlayerSpeed(player)
	local stats = player:FindFirstChild("Stats")
	if not stats then
		return
	end

	local speed = stats:FindFirstChild("Speed")
	if not speed then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	humanoid.WalkSpeed = calculateWalkSpeed(speed.Value)
end

local function setupPlayer(player)

	-------------------------------
	-- STATS
	-------------------------------

	local stats = Instance.new("Folder")
	stats.Name = "Stats"
	stats.Parent = player

	local speed = Instance.new("NumberValue")
	speed.Name = "Speed"
	speed.Value = 0
	speed.Parent = stats

	local cash = Instance.new("NumberValue")
	cash.Name = "Cash"
	cash.Value = 0
	cash.Parent = stats

	-------------------------------
	-- LEADERSTATS
	-------------------------------

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local displaySpeed = Instance.new("NumberValue")
	displaySpeed.Name = "Speed"
	displaySpeed.Value = speed.Value
	displaySpeed.Parent = leaderstats

	local displayCash = Instance.new("NumberValue")
	displayCash.Name = "Cash"
	displayCash.Value = cash.Value
	displayCash.Parent = leaderstats

	-------------------------------
	-- SYNC
	-------------------------------

	speed.Changed:Connect(function()
		displaySpeed.Value = math.floor(speed.Value)

		updatePlayerSpeed(player)
	end)

	cash.Changed:Connect(function()
		displayCash.Value = math.floor(cash.Value)
	end)

	-------------------------------
	-- CHARACTER
	-------------------------------

	local function characterAdded(character)
		local humanoid = character:WaitForChild("Humanoid")

		task.wait()

		updatePlayerSpeed(player)
	end

	player.CharacterAdded:Connect(characterAdded)

	if player.Character then
		characterAdded(player.Character)
	end
end

Players.PlayerAdded:Connect(setupPlayer)

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end