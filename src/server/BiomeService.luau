local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BiomeService = {}
local CHECK_INTERVAL = 0.15
local started = false
local states = {}

local function isFiniteNumber(value)
	return typeof(value) == "number" and value == value and math.abs(value) < math.huge
end

local function getOrCreate(parent, className, name)
	local instance = parent:FindFirstChild(name)
	if instance then
		assert(instance:IsA(className), instance:GetFullName() .. " must be a " .. className)
		return instance
	end
	instance = Instance.new(className)
	instance.Name = name
	instance.Parent = parent
	return instance
end

local function contains(zone, position)
	-- Local coordinates also support rotated zones; body parts/accessories are irrelevant.
	local point = zone.CFrame:PointToObjectSpace(position)
	local half = zone.Size * 0.5
	return math.abs(point.X) <= half.X
		and math.abs(point.Y) <= half.Y
		and math.abs(point.Z) <= half.Z
end

local function collectBiomes(folder)
	local biomes = {}
	for _, model in ipairs(folder:GetChildren()) do
		if not model:IsA("Model") then
			continue
		end
		local zone = model:FindFirstChild("BiomeZone")
		local recommended = model:GetAttribute("RecommendedSpeed")
		if not zone or not zone:IsA("BasePart") or not isFiniteNumber(recommended) or recommended < 0 then
			continue
		end
		local displayName = model:GetAttribute("DisplayName")
		table.insert(biomes, {
			Model = model,
			Zone = zone,
			RecommendedSpeed = recommended,
			Name = if typeof(displayName) == "string" and displayName ~= "" then displayName else model.Name,
		})
	end
	-- Overlapping zones choose the higher recommendation, then model name.
	table.sort(biomes, function(a, b)
		if a.RecommendedSpeed == b.RecommendedSpeed then
			return a.Model.Name < b.Model.Name
		end
		return a.RecommendedSpeed > b.RecommendedSpeed
	end)
	return biomes
end

local function getSnapshot(player, biomes)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local stats = player:FindFirstChild("Stats")
	local speed = stats and stats:FindFirstChild("Speed")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart")
		or not speed or not (speed:IsA("NumberValue") or speed:IsA("IntValue"))
		or not isFiniteNumber(speed.Value) then
		return nil
	end
	for _, biome in ipairs(biomes) do
		if contains(biome.Zone, root.Position) then
			return {
				Model = biome.Model,
				BiomeName = biome.Name,
				RecommendedSpeed = biome.RecommendedSpeed,
				PlayerSpeed = speed.Value,
			}
		end
	end
	return nil
end

local function sameSnapshot(a, b)
	if a == nil or b == nil then
		return a == b
	end
	return a.Model == b.Model and a.BiomeName == b.BiomeName
		and a.RecommendedSpeed == b.RecommendedSpeed and a.PlayerSpeed == b.PlayerSpeed
end

function BiomeService.Start()
	if started then
		return
	end
	started = true
	local folder = getOrCreate(workspace, "Folder", "Biomes")
	-- Phase 3's explicit path; keep a single event, not two competing copies.
	local event = getOrCreate(ReplicatedStorage, "RemoteEvent", "BiomeUIEvent")

	local function updatePlayer(player, state, biomes, force)
		local snapshot = getSnapshot(player, biomes)
		if not force and sameSnapshot(state.Snapshot, snapshot) then
			return
		end
		state.Snapshot = snapshot
		if snapshot then
			event:FireClient(player, {
				Visible = true,
				BiomeName = snapshot.BiomeName,
				RecommendedSpeed = snapshot.RecommendedSpeed,
				PlayerSpeed = snapshot.PlayerSpeed,
				Status = if snapshot.PlayerSpeed >= snapshot.RecommendedSpeed then "READY" else "DANGEROUS",
			})
		else
			event:FireClient(player, { Visible = false })
		end
	end

	-- Client readiness only. No client-supplied biome, stat, or gameplay decision is accepted.
	-- This avoids losing the first snapshot if a player spawns inside a biome before UI loads.
	event.OnServerEvent:Connect(function(player, action)
		if action ~= "Ready" then
			return
		end
		local state = states[player]
		local now = os.clock()
		if state and now - state.LastReady < 2 then
			return
		end
		state = state or {}
		state.LastReady = now
		states[player] = state
		updatePlayer(player, state, collectBiomes(folder), true)
	end)

	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)

	local elapsed = 0
	RunService.Heartbeat:Connect(function(deltaTime)
		elapsed += deltaTime
		if elapsed < CHECK_INTERVAL then
			return
		end
		elapsed %= CHECK_INTERVAL
		local biomes = collectBiomes(folder)
		for player, state in pairs(states) do
			updatePlayer(player, state, biomes, false)
		end
	end)
end

return BiomeService
