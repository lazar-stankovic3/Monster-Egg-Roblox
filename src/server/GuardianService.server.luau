--!strict
-- ServerScriptService.Server.GuardianService | Faza 8
-- Svako ukradeno jaje dobija nezavisan klon GuardianTemplate-a.

local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GuardianConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GuardianConfig"))

local activeFolder = workspace:FindFirstChild("ActiveGuardians")
if not activeFolder then
	activeFolder = Instance.new("Folder")
	activeFolder.Name = "ActiveGuardians"
	activeFolder.Parent = workspace
end

local signals = ServerScriptService:WaitForChild("GameSignals")
local forceDropEvent = signals:WaitForChild("GuardianForceDrop")
assert(forceDropEvent:IsA("BindableEvent"), "GameSignals.GuardianForceDrop must be a BindableEvent")

type Chase = { egg: Model, player: Player, guardian: Model, connection: RBXScriptConnection? }
local activeChases: { [Model]: Chase } = {}

local function isInsidePart(part: BasePart, position: Vector3, padding: number): boolean
	local point = part.CFrame:PointToObjectSpace(position)
	local half = part.Size * 0.5 + Vector3.new(padding, padding, padding)
	return math.abs(point.X) <= half.X and math.abs(point.Y) <= half.Y and math.abs(point.Z) <= half.Z
end

local function getGuardianTemplate(biomeName: unknown): Model?
	if type(biomeName) ~= "string" or biomeName == "" then return nil end
	local biomes = workspace:FindFirstChild("Biomes")
	local biome = biomes and biomes:FindFirstChild(biomeName)
	local template = biome and biome:FindFirstChild("GuardianTemplate")
	return if template and template:IsA("Model") then template else nil
end

local function getBiomeZone(biomeName: unknown): BasePart?
	if type(biomeName) ~= "string" or biomeName == "" then return nil end
	local biomes = workspace:FindFirstChild("Biomes")
	local biome = biomes and biomes:FindFirstChild(biomeName)
	local zone = biome and biome:FindFirstChild("BiomeZone")
	return if zone and zone:IsA("BasePart") then zone else nil
end

local function makePart(name: string, size: Vector3, color: Color3, offset: Vector3, root: BasePart, model: Model): BasePart
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.Neon
	part.CanCollide = false
	part.Massless = true
	part.CFrame = root.CFrame * CFrame.new(offset)
	part.Parent = model
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = part
	return part
end

local function createFallbackGuardian(zone: BasePart): Model
	local model = Instance.new("Model")
	model.Name = "GeneratedGuardian"
	local raycastParameters = RaycastParams.new()
	raycastParameters.FilterType = Enum.RaycastFilterType.Exclude
	raycastParameters.FilterDescendantsInstances = { zone }
	local rayOrigin = zone.Position + zone.CFrame.UpVector * (zone.Size.Y * 0.5 + 150)
	local groundHit = workspace:Raycast(rayOrigin, -zone.CFrame.UpVector * 300, raycastParameters)
	-- Root je 3.5 studa iznad poda da generisane noge ne počinju u zemlji.
	local spawnPosition = if groundHit then groundHit.Position + Vector3.new(0, 3.5, 0)
		else zone.Position + zone.CFrame.UpVector * (zone.Size.Y * 0.5 + 3.5)
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Transparency = 1
	root.CanCollide = true
	root.Anchored = false
	root.CFrame = CFrame.new(spawnPosition)
	root.Parent = model
	model.PrimaryPart = root

	local bodyColor = Color3.fromRGB(120, 15, 180)
	makePart("Torso", Vector3.new(2.6, 3, 1.4), bodyColor, Vector3.new(0, 0.4, 0), root, model)
	makePart("Head", Vector3.new(2, 2, 2), Color3.fromRGB(60, 255, 120), Vector3.new(0, 2.8, 0), root, model)
	makePart("LeftArm", Vector3.new(0.7, 2.6, 0.7), bodyColor, Vector3.new(-1.7, 0.35, 0), root, model)
	makePart("RightArm", Vector3.new(0.7, 2.6, 0.7), bodyColor, Vector3.new(1.7, 0.35, 0), root, model)
	makePart("LeftLeg", Vector3.new(0.8, 2.5, 0.8), bodyColor, Vector3.new(-0.65, -2.2, 0), root, model)
	makePart("RightLeg", Vector3.new(0.8, 2.5, 0.8), bodyColor, Vector3.new(0.65, -2.2, 0), root, model)

	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayName = "Guardian"
	humanoid.HipHeight = 3.5
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	humanoid.Parent = model
	return model
end

local function finishChase(egg: Model)
	local chase = activeChases[egg]
	if not chase then return end
	activeChases[egg] = nil
	if chase.connection then chase.connection:Disconnect() end
	if chase.guardian.Parent then chase.guardian:Destroy() end
end

local function isStillCarrying(chase: Chase): boolean
	return chase.egg.Parent ~= nil and chase.egg:GetAttribute("Carried") == true
		and chase.egg:GetAttribute("CarrierUserId") == chase.player.UserId
end

type PathState = { waypoints: { PathWaypoint }, index: number, nextRecompute: number, computing: boolean }

local function horizontalDistance(a: Vector3, b: Vector3): number
	local delta = a - b
	return Vector3.new(delta.X, 0, delta.Z).Magnitude
end

local function moveTowards(humanoid: Humanoid, root: BasePart, destination: Vector3, pathState: PathState, chase: Chase)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local excluded: { Instance } = { chase.guardian, chase.egg }
	if chase.player.Character then table.insert(excluded, chase.player.Character) end
	params.FilterDescendantsInstances = excluded
	params.RespectCanCollide = true
	local direction = destination - root.Position
	local side = if direction.Magnitude > 0.01 then direction.Unit:Cross(Vector3.yAxis) * 2 else Vector3.zero
	-- Check the width of the NPC, not just a single line through its centre.
	local clear = math.abs(direction.Y) < 3
	for _, offset in ipairs({ Vector3.zero, side, -side }) do
		if workspace:Raycast(root.Position + offset, direction, params) then clear = false; break end
	end
	-- Do not shortcut across a gap just because there is no wall in sight.
	if clear then
		for step = 1, math.max(1, math.ceil(direction.Magnitude / 4)) do
			local point = root.Position:Lerp(destination, step / math.max(1, math.ceil(direction.Magnitude / 4)))
			if not workspace:Raycast(point, Vector3.new(0, -8, 0), params) then clear = false; break end
		end
	end
	if clear then
		humanoid:MoveTo(destination)
		pathState.waypoints = {}
		return
	end

	if not pathState.computing and os.clock() >= pathState.nextRecompute then
		pathState.computing = true
		pathState.nextRecompute = os.clock() + GuardianConfig.PathRecomputeSeconds
		-- ComputeAsync yields; movement and catch/stop checks must keep running.
		task.spawn(function()
			local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 7, AgentCanJump = true, WaypointSpacing = 4 })
			local computed = pcall(function() path:ComputeAsync(root.Position, destination) end)
			pathState.computing = false
			if activeChases[chase.egg] ~= chase or not root.Parent then return end
			if computed and path.Status == Enum.PathStatus.Success then
				local points = path:GetWaypoints()
				-- The NPC may have moved while the path was being computed.
				local index = 2
				while points[index + 1] do
					local segment = points[index].Position - points[index - 1].Position
					local past = root.Position - points[index].Position
					if Vector3.new(past.X, 0, past.Z):Dot(Vector3.new(segment.X, 0, segment.Z)) < 0 then break end
					index += 1
				end
				pathState.waypoints = points
				pathState.index = index
			end
		end)
	end

	while pathState.waypoints[pathState.index]
		and horizontalDistance(root.Position, pathState.waypoints[pathState.index].Position) <= math.max(GuardianConfig.WaypointReachDistance, humanoid.WalkSpeed * GuardianConfig.ChaseTickSeconds) do
		pathState.index += 1
	end
	local waypoint = pathState.waypoints[pathState.index]
	if waypoint then
		if waypoint.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end
		humanoid:MoveTo(waypoint.Position)
	else
		humanoid:MoveTo(destination)
	end
end

local function startChase(egg: Model)
	if activeChases[egg] or egg:GetAttribute("Carried") ~= true then return end
	local carrierUserId = egg:GetAttribute("CarrierUserId")
	local player = if typeof(carrierUserId) == "number" then Players:GetPlayerByUserId(carrierUserId) else nil
	local template = getGuardianTemplate(egg:GetAttribute("Biome"))
	local zone = getBiomeZone(egg:GetAttribute("Biome"))
	if not player or (not template and not zone) then
		if not template and not zone then warn(string.format("[GuardianService] Biome '%s' nema GuardianTemplate ni BiomeZone; chase preskočen.", tostring(egg:GetAttribute("Biome")))) end
		return
	end

	local guardian = if template then template:Clone() else createFallbackGuardian(zone :: BasePart)
	guardian.Name = "Guardian_" .. tostring(egg:GetAttribute("UID"))
	guardian.Parent = activeFolder
	-- Template može ostati usidren u Studio-u kao bezbedan izvor za kloniranje.
	for _, descendant in ipairs(guardian:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
		end
	end
	local humanoid = guardian:FindFirstChildOfClass("Humanoid")
	local root = guardian:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or not root:IsA("BasePart") then
		warn("[GuardianService] GuardianTemplate mora imati Humanoid i HumanoidRootPart.")
		guardian:Destroy()
		return
	end

	humanoid.WalkSpeed = GuardianConfig.GetWalkSpeed(egg:GetAttribute("Biome"), egg:GetAttribute("Rarity"))
	-- Keep NPC physics on the server instead of transferring it between nearby players.
	if root:CanSetNetworkOwnership() then root:SetNetworkOwner(nil) end
	guardian:SetAttribute("TargetUserId", player.UserId)
	guardian:SetAttribute("TargetEggUID", tostring(egg:GetAttribute("UID")))
	guardian:SetAttribute("Biome", egg:GetAttribute("Biome"))
	local chase: Chase = { egg = egg, player = player, guardian = guardian, connection = nil }
	activeChases[egg] = chase
	chase.connection = egg:GetAttributeChangedSignal("Carried"):Connect(function()
		if egg:GetAttribute("Carried") ~= true then finishChase(egg) end
	end)

	task.spawn(function()
		local pathState: PathState = { waypoints = {}, index = 1, nextRecompute = 0, computing = false }
		while activeChases[egg] == chase do
			if not isStillCarrying(chase) or not root.Parent or humanoid.Health <= 0 then finishChase(egg); break end
			local character = player.Character
			local targetHumanoid = character and character:FindFirstChildOfClass("Humanoid")
			local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
			local lobbyZone = workspace:FindFirstChild("LobbyDepositZone")
			if not targetHumanoid or targetHumanoid.Health <= 0 or not targetRoot or not targetRoot:IsA("BasePart") then finishChase(egg); break end
			if lobbyZone and lobbyZone:IsA("BasePart") and isInsidePart(lobbyZone, targetRoot.Position, GuardianConfig.SafeZonePadding) then finishChase(egg); break end
			if (root.Position - targetRoot.Position).Magnitude <= GuardianConfig.CatchDistance then
				forceDropEvent:Fire(player, egg, root.Position)
				finishChase(egg)
				break
			end
			moveTowards(humanoid, root, targetRoot.Position, pathState, chase)
			task.wait(GuardianConfig.ChaseTickSeconds)
		end
	end)
end

local function watchEgg(instance: Instance)
	if not instance:IsA("Model") or instance.Name ~= "WorldEgg" then return end
	instance:GetAttributeChangedSignal("Carried"):Connect(function()
		if instance:GetAttribute("Carried") == true then startChase(instance) end
	end)
	if instance:GetAttribute("Carried") == true then startChase(instance) end
end

for _, child in ipairs(workspace:GetChildren()) do watchEgg(child) end
workspace.ChildAdded:Connect(watchEgg)
Players.PlayerRemoving:Connect(function(player)
	for egg, chase in pairs(activeChases) do if chase.player == player then finishChase(egg) end end
end)

print("[GuardianService] Phase 8 guardian service loaded.")
