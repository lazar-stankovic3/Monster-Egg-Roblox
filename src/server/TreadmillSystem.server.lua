local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local treadmillFolder = workspace:WaitForChild("Treadmills")

local TRAIN_INTERVAL = 0.25

-- player = treadmill
local playersTraining = {}

-- Sprečava više Touch eventova
local touchCounts = {}

local function getPlayerFromHit(hit)

	local character = hit:FindFirstAncestorOfClass("Model")

	if not character then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return nil
	end

	return Players:GetPlayerFromCharacter(character)
end

local function setupTreadmill(treadmill)

	local trainingZone = treadmill:FindFirstChild("TrainingZone")

	if not trainingZone then
		warn(treadmill.Name .. " nema TrainingZone")
		return
	end

	----------------------------------
	-- PLAYER ENTERS
	----------------------------------

	trainingZone.Touched:Connect(function(hit)

		local player = getPlayerFromHit(hit)

		if not player then
			return
		end

		touchCounts[player] = touchCounts[player] or {}
		touchCounts[player][trainingZone] =
			(touchCounts[player][trainingZone] or 0) + 1

		playersTraining[player] = treadmill
	end)

	----------------------------------
	-- PLAYER LEAVES
	----------------------------------

	trainingZone.TouchEnded:Connect(function(hit)

		local player = getPlayerFromHit(hit)

		if not player then
			return
		end

		if not touchCounts[player] then
			return
		end

		local currentCount =
			touchCounts[player][trainingZone] or 0

		currentCount -= 1

		if currentCount <= 0 then

			touchCounts[player][trainingZone] = nil

			if playersTraining[player] == treadmill then
				playersTraining[player] = nil
			end

		else

			touchCounts[player][trainingZone] = currentCount

		end
	end)
end

----------------------------------
-- SETUP
----------------------------------

for _, treadmill in ipairs(treadmillFolder:GetChildren()) do

	if treadmill:IsA("Model") then
		setupTreadmill(treadmill)
	end

end

treadmillFolder.ChildAdded:Connect(function(treadmill)

	if treadmill:IsA("Model") then
		setupTreadmill(treadmill)
	end

end)

----------------------------------
-- TRAINING LOOP
----------------------------------

task.spawn(function()

	while true do

		task.wait(TRAIN_INTERVAL)

		for player, treadmill in pairs(playersTraining) do

			if not player.Parent then
				playersTraining[player] = nil
				continue
			end

			local stats = player:FindFirstChild("Stats")

			if not stats then
				continue
			end

			local speed = stats:FindFirstChild("Speed")

			if not speed then
				continue
			end

			local gain =
				treadmill:GetAttribute("SpeedGain") or 1

			speed.Value += gain * TRAIN_INTERVAL

		end

	end

end)

----------------------------------
-- CLEANUP
----------------------------------

Players.PlayerRemoving:Connect(function(player)

	playersTraining[player] = nil
	touchCounts[player] = nil

end)