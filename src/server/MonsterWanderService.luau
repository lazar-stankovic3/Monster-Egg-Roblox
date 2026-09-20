local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules:WaitForChild("MonsterWanderConfig"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))

local Service = {}
local random = Random.new()
local states = {}
local started = false

local function randomRange(minimum, maximum)
	return minimum + (maximum - minimum) * random:NextNumber()
end

local function isActiveMonster(monster, plot)
	return monster:IsA("Model")
		and monster.PrimaryPart ~= nil
		and monster:GetAttribute("IsMonster") == true
		and monster:GetAttribute("OwnerUserId") == plot:GetAttribute("OwnerUserId")
		and monster.Parent == plot:FindFirstChild("PlacedEggs")
end

local function removeState(monster)
	states[monster] = nil
	if monster.Parent then monster:SetAttribute("WanderState", nil) end
end

local function createState(monster, plot)
	local boundingFrame = monster:GetBoundingBox()
	local state = {
		plot = plot,
		pivotOffset = boundingFrame:ToObjectSpace(monster:GetPivot()),
		mode = "Paused",
		nextAction = os.clock() + randomRange(Config.MinPause, Config.MaxPause),
	}
	states[monster] = state
	monster:SetAttribute("WanderState", "Paused")
	return state
end

local function destinationIsFree(monster, plot, localTarget, radius)
	local folder = plot:FindFirstChild("PlacedEggs")
	local place = plot:FindFirstChild("Place")
	if not folder or not place then return false end
	for _, other in ipairs(folder:GetChildren()) do
		if other ~= monster and other:IsA("Model") and other.PrimaryPart then
			local otherFrame, otherSize = other:GetBoundingBox()
			local otherLocal = place.CFrame:PointToObjectSpace(otherFrame.Position)
			local otherRadius = math.max(otherSize.X, otherSize.Z) / 2
			local delta = Vector2.new(localTarget.X - otherLocal.X, localTarget.Z - otherLocal.Z)
			if delta.Magnitude < radius + otherRadius + Config.NeighborGap then return false end
		end
	end
	return true
end

local function chooseWalk(monster, state, now)
	local plot = state.plot
	local place = plot:FindFirstChild("Place")
	if not place or not place:IsA("BasePart") then return false end
	local currentFrame, size = monster:GetBoundingBox()
	local currentLocal = place.CFrame:PointToObjectSpace(currentFrame.Position)
	local radius = math.max(size.X, size.Z) / 2
	local limitX = place.Size.X / 2 - radius - Config.EdgeMargin
	local limitZ = place.Size.Z / 2 - radius - Config.EdgeMargin
	if limitX <= 0 or limitZ <= 0 then return false end

	for _ = 1, Config.DestinationAttempts do
		local angle = randomRange(0, math.pi * 2)
		local distance = randomRange(Config.MinWalkDistance, Config.MaxWalkDistance)
		local targetLocal = Vector3.new(
			math.clamp(currentLocal.X + math.cos(angle) * distance, -limitX, limitX),
			place.Size.Y / 2 + size.Y / 2,
			math.clamp(currentLocal.Z + math.sin(angle) * distance, -limitZ, limitZ)
		)
		local planarDistance = Vector2.new(targetLocal.X - currentLocal.X, targetLocal.Z - currentLocal.Z).Magnitude
		if planarDistance >= Config.MinWalkDistance * 0.6 and destinationIsFree(monster, plot, targetLocal, radius) then
			local startPosition = place.CFrame:PointToWorldSpace(Vector3.new(
				currentLocal.X,
				place.Size.Y / 2 + size.Y / 2,
				currentLocal.Z
			))
			local targetPosition = place.CFrame:PointToWorldSpace(targetLocal)
			local facing = CFrame.lookAt(targetPosition, targetPosition + (targetPosition - startPosition), place.CFrame.UpVector)
			state.from = currentFrame
			state.to = facing
			state.startedAt = now
			state.duration = planarDistance / randomRange(Config.MinWalkSpeed, Config.MaxWalkSpeed)
			state.mode = "Walking"
			monster:SetAttribute("WanderState", "Walking")
			return true
		end
	end
	return false
end

local function updateMonster(monster, state, now)
	local plot = state.plot
	if not monster.Parent or not plot.Parent or not isActiveMonster(monster, plot) then
		removeState(monster)
		return
	end
	local owner = Players:GetPlayerByUserId(monster:GetAttribute("OwnerUserId"))
	if not owner or owner:GetAttribute("PlayerDataStatus") == "Loading" then return end

	if state.mode == "Walking" then
		local alpha = math.clamp((now - state.startedAt) / state.duration, 0, 1)
		local eased = alpha * alpha * (3 - 2 * alpha)
		local frame = state.from:Lerp(state.to, eased)
		monster:PivotTo(frame * state.pivotOffset)
		if alpha >= 1 then
			state.mode = "Paused"
			state.nextAction = now + randomRange(Config.MinPause, Config.MaxPause)
			monster:SetAttribute("WanderState", "Paused")
		end
	elseif now >= state.nextAction then
		if not chooseWalk(monster, state, now) then
			state.nextAction = now + randomRange(Config.MinPause, Config.MaxPause)
		end
	end
end

local function scan()
	local plots = workspace:FindFirstChild("Plots")
	if not plots then return end
	for _, plot in ipairs(plots:GetChildren()) do
		local folder = plot:FindFirstChild("PlacedEggs")
		if folder then
			for _, monster in ipairs(folder:GetChildren()) do
				if isActiveMonster(monster, plot) and not states[monster] then createState(monster, plot) end
			end
		end
	end
end

function Service.Start()
	if started then return end
	started = true
	PlotService.Start()
	local scanElapsed = Config.ScanInterval
	RunService.Heartbeat:Connect(function(deltaTime)
		scanElapsed += deltaTime
		if scanElapsed >= Config.ScanInterval then
			scanElapsed %= Config.ScanInterval
			scan()
		end
		local now = os.clock()
		for monster, state in pairs(states) do updateMonster(monster, state, now) end
	end)
end

return Service
