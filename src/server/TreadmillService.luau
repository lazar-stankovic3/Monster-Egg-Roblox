local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Modules:WaitForChild("TreadmillConfig"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))
local Service = {}
local states = {}
local locks = {}
local blockedZones = {}
local started = false
local jumpEvent
local restoredLevels = {}

local function release(player, jumped)
	local lock = locks[player]
	if not lock then return end
	locks[player] = nil
	blockedZones[player] = lock.zone
	if lock.root.Parent then
		lock.root.Anchored = lock.anchored
		lock.root.AssemblyLinearVelocity = Vector3.zero
		lock.root.AssemblyAngularVelocity = Vector3.zero
	end
	if lock.humanoid.Parent then lock.humanoid.AutoRotate = lock.autoRotate end
	if jumped and lock.root.Parent and lock.humanoid.Health > 0 then
		local jumpSpeed = if lock.humanoid.UseJumpPower then lock.humanoid.JumpPower
			else math.sqrt(2 * workspace.Gravity * lock.humanoid.JumpHeight)
		lock.root.AssemblyLinearVelocity = Vector3.new(0, jumpSpeed, 0)
	end
	player:SetAttribute("TreadmillLocked", false)
	if jumped and player.Parent == Players then jumpEvent:FireClient(player) end
end

local function lockToZone(player, zone, root, humanoid)
	if locks[player] or root.Anchored or blockedZones[player] == zone then return false end
	locks[player] = { root = root, humanoid = humanoid, zone = zone,
		anchored = root.Anchored, autoRotate = humanoid.AutoRotate }
	root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
	root.Anchored = true
	humanoid.AutoRotate = false
	-- Zone bottom is the belt surface; retain the character's correct standing height.
	local height = humanoid.HipHeight + root.Size.Y / 2
	if humanoid.RigType == Enum.HumanoidRigType.R6 then
		local leg = player.Character:FindFirstChild("Left Leg")
		height += if leg then leg.Size.Y else 2
	end
	root.CFrame = zone.CFrame * CFrame.new(0, -zone.Size.Y / 2 + height, 0)
	player:SetAttribute("TreadmillLocked", true)
	return true
end

local function finite(n)
	return type(n) == "number" and n == n and math.abs(n) < math.huge
end

local function contains(zone, point)
	local p = zone.CFrame:PointToObjectSpace(point)
	local half = zone.Size / 2
	return math.abs(p.X) <= half.X and math.abs(p.Y) <= half.Y and math.abs(p.Z) <= half.Z
end

local function makeModel(plot, level, owner)
	local marker = plot:FindFirstChild("TreadmillPos")
	assert(marker and marker:IsA("BasePart"), "Plot needs TreadmillPos Part: " .. plot.Name)
	local definition = Config.Levels[level]
	local folder = ServerStorage:FindFirstChild("TreadmillModels")
	local template = folder and folder:FindFirstChild(definition.Name)
	local model
	if template and template:IsA("Model") then
		model = template:Clone()
		for _, item in ipairs(model:GetDescendants()) do
			if item:IsA("LuaSourceContainer") or item:IsA("Constraint") or item:IsA("JointInstance")
				or item:IsA("BodyMover") or item:IsA("ProximityPrompt") then item:Destroy() end
		end
		for _, item in ipairs(model:GetDescendants()) do
			if item:IsA("BasePart") then item.Anchored = true end
		end
		model:PivotTo(marker.CFrame)
	else
		model = Instance.new("Model")
		local function part(name, size, position, color)
			local p = Instance.new("Part")
			p.Name, p.Size, p.Color = name, size, color
			p.Anchored = true
			p.CFrame = marker.CFrame * CFrame.new(position)
			p.Parent = model
			return p
		end
		part("Deck", Vector3.new(5, 0.5, 7), Vector3.new(0, 0.25, 0), definition.Color)
		part("Belt", Vector3.new(4, 0.12, 6), Vector3.new(0, 0.56, 0), Color3.fromRGB(35, 35, 40))
		for _, x in ipairs({-2.2, 2.2}) do
			part("Support", Vector3.new(0.25, 3.5, 0.25), Vector3.new(x, 2, -2.5), definition.Color)
		end
		part("Handlebar", Vector3.new(4.6, 0.3, 0.3), Vector3.new(0, 3.7, -2.5), definition.Color)
		part("TrainingZone", Vector3.new(4, 6, 6), Vector3.new(0, 3.5, 0), definition.Color)
		model:SetAttribute("Placeholder", true)
	end
	local zone = model:FindFirstChild("TrainingZone")
	if not zone or not zone:IsA("BasePart") then model:Destroy(); error("Treadmill requires direct TrainingZone Part") end
	zone.Anchored, zone.CanCollide, zone.CanTouch, zone.CanQuery = true, false, false, false
	zone.Transparency = 1
	model.Name = "OwnedTreadmill"
	model:SetAttribute("ManagedTreadmill", true)
	model:SetAttribute("OwnerUserId", owner)
	model:SetAttribute("Level", level)
	model:SetAttribute("SpeedGain", definition.SpeedGain)
	return model
end

local function publish(player, state)
	local definition = Config.Levels[state.level]
	player:SetAttribute("TreadmillLevel", state.level)
	player:SetAttribute("OwnedTreadmill", definition.Name)
	state.plot:SetAttribute("TreadmillLevel", state.level)
	state.prompt.ObjectText = definition.Name .. " | +" .. definition.SpeedGain .. " Speed/sec"
	local nextLevel = Config.Levels[state.level + 1]
	state.prompt.ActionText = if nextLevel then "Upgrade: " .. nextLevel.Name .. " ($" .. nextLevel.Cost .. ")" else "MAX LEVEL"
	state.prompt.Enabled = nextLevel ~= nil
end

function Service.TryUpgrade(player)
	if player:GetAttribute("PlayerDataStatus") == "Loading" then return false end
	local state = states[player]
	if not state or not state.model or not state.prompt or not PlotService.IsOwner(player, state.plot) then return false end
	local now = os.clock()
	if now - (state.lastPurchase or -math.huge) < 0.75 then return false end
	state.lastPurchase = now
	local nextLevel = state.level + 1 -- No client-supplied level or price, ever.
	local definition = Config.Levels[nextLevel]
	if not definition then return false end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0
		or (root.Position - state.prompt.Parent.Position).Magnitude > 12 then return false end
	local stats = player:FindFirstChild("Stats")
	local cash = stats and stats:FindFirstChild("Cash")
	if not cash or not cash:IsA("NumberValue") or not finite(cash.Value) or cash.Value < definition.Cost then
		player:SetAttribute("TreadmillPurchaseStatus", "NotEnoughCash")
		return false
	end
	-- Prepare before charging; no yielding between validation and commit.
	local ok, model = pcall(makeModel, state.plot, nextLevel, player.UserId)
	if not ok then warn("[TreadmillService] " .. tostring(model)); return false end
	cash.Value -= definition.Cost
	release(player, false)
	state.model:Destroy()
	state.model, state.level = model, nextLevel
	model.Parent = state.plot
	publish(player, state)
	player:SetAttribute("TreadmillPurchaseStatus", "Purchased")
	return true
end

local function cleanup(state)
	if state.connection then state.connection:Disconnect() end
	if state.prompt then state.prompt:Destroy() end
	if state.model then state.model:Destroy() end
end

local function ensurePlot(player)
	local plot = PlotService.GetPlot(player)
	local state = states[player]
	if state and state.plot == plot then return state end
	local level = if state then state.level else (restoredLevels[player] or 1)
	if state then cleanup(state) end
	states[player] = nil
	if not plot then return nil end
	state = { plot = plot, level = level }
	states[player] = state
	local marker = plot:FindFirstChild("TreadmillUpgradePart")
	if not marker or not marker:IsA("BasePart") then
		warn("[TreadmillService] " .. plot.Name .. " needs TreadmillUpgradePart (Part). Restart Play after setup.")
		return state
	end
	local ok, model = pcall(makeModel, plot, level, player.UserId)
	if not ok then warn("[TreadmillService] " .. tostring(model)); return state end
	state.model = model
	model.Parent = plot
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TreadmillUpgradePrompt"
	prompt.MaxActivationDistance = 10
	prompt.HoldDuration = 0.5
	prompt.RequiresLineOfSight = false
	prompt.Parent = marker
	state.prompt = prompt
	state.connection = prompt.Triggered:Connect(function(who)
		if who == player then Service.TryUpgrade(player) end
	end)
	publish(player, state)
	return state
end

function Service.SetLevel(player, level)
	if type(level) ~= "number" or level % 1 ~= 0 or not Config.Levels[level] then return false end
	restoredLevels[player] = level
	local state = states[player]
	if state and state.level ~= level then
		cleanup(state)
		states[player] = nil
		ensurePlot(player)
	end
	return true
end

function Service.GetLevel(player)
	local state = states[player]
	return state and state.level or restoredLevels[player] or 1
end

function Service.Start()
	if started then return end
	started = true
	PlotService.Start()
	jumpEvent = ReplicatedStorage:FindFirstChild("TreadmillJumpEvent")
	if not jumpEvent then
		jumpEvent = Instance.new("RemoteEvent")
		jumpEvent.Name = "TreadmillJumpEvent"
		jumpEvent.Parent = ReplicatedStorage
	end
	assert(jumpEvent:IsA("RemoteEvent"), "TreadmillJumpEvent must be a RemoteEvent")
	jumpEvent.OnServerEvent:Connect(function(player) release(player, true) end)
	Players.PlayerRemoving:Connect(function(player)
		release(player, false)
		blockedZones[player] = nil
		task.defer(function()
			if states[player] then cleanup(states[player]); states[player] = nil end
			restoredLevels[player] = nil
		end)
	end)
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.25 then return end
		elapsed %= 0.25
		for _, player in ipairs(Players:GetPlayers()) do
			local state = ensurePlot(player)
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local stats = player:FindFirstChild("Stats")
			local speed = stats and stats:FindFirstChild("Speed")
			local gain = 0
			local lock = locks[player]
			if lock and (lock.root ~= root or not humanoid or humanoid.Health <= 0
				or not lock.zone:IsDescendantOf(workspace)) then release(player, false) end
			local blocked = blockedZones[player]
			if blocked and (not root or not blocked:IsDescendantOf(workspace) or not contains(blocked, root.Position)) then
				blockedZones[player] = nil
			end
			local trainingZone
			if player:GetAttribute("PlayerDataStatus") ~= "Loading"
				and root and humanoid and humanoid.Health > 0 and speed and speed:IsA("NumberValue") then
				if state and state.model and state.model.Parent == state.plot and PlotService.IsOwner(player, state.plot)
					and contains(state.model.TrainingZone, root.Position) then
					gain = Config.Levels[state.level].SpeedGain
					trainingZone = state.model.TrainingZone
				else
					-- Existing public treadmills remain usable; overlapping zones never stack.
					local folder = workspace:FindFirstChild("Treadmills")
					for _, model in ipairs(if folder then folder:GetChildren() else {}) do
						local zone = model:FindFirstChild("TrainingZone")
						local rate = model:GetAttribute("SpeedGain") or 1
						local owner = model:GetAttribute("OwnerUserId")
						if model:IsA("Model") and zone and zone:IsA("BasePart") and finite(rate) and rate > 0
							and (owner == nil or owner == 0 or owner == player.UserId) and contains(zone, root.Position) then
							if rate > gain then gain, trainingZone = rate, zone end
						end
					end
				end
				if locks[player] and locks[player].zone ~= trainingZone then release(player, false) end
				if trainingZone and not locks[player] then lockToZone(player, trainingZone, root, humanoid) end
				if not locks[player] then gain = 0 end
				if finite(speed.Value) and finite(speed.Value + gain * 0.25) then speed.Value += gain * 0.25 end
			end
			player:SetAttribute("TrainingSpeedPerSecond", gain)
		end
	end)
end

return Service
