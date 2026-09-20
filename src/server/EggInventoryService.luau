-- Server-owned inventory records; Tools are replaceable views of those records.
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EggConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("EggConfig"))
local Service = {}
local states = {}
local fields = { "UID", "EggType", "EggName", "Biome", "Rarity", "Size", "Scale" }

local function validMetadata(data)
	if type(data) ~= "table" then return false end
	for _, field in ipairs(fields) do
		local value = data[field]
		if field == "Scale" then
			if type(value) ~= "number" or value ~= value or value <= 0 or value == math.huge then return false end
		elseif type(value) ~= "string" or value == "" or #value > 128 then
			return false
		end
	end
	return EggConfig.EggTypes[data.EggType] ~= nil or data.EggType == EggConfig.LegacyBasicEgg.EggType
end

local function makeTool(player, egg)
	-- Never clone the live carried assembly: its joints can reference the character
	-- and its parts can carry velocities/forces from the world simulation.
	local eggType = egg:GetAttribute("EggType")
	local definition = EggConfig.EggTypes[eggType]
	if not definition and eggType == EggConfig.LegacyBasicEgg.EggType then
		definition = EggConfig.LegacyBasicEgg
	end
	local models = ServerStorage:FindFirstChild("EggModels")
	local source = models and definition and models:FindFirstChild(definition.ModelName)
	assert(source and source:IsA("Model"), "Missing clean EggModels template for " .. tostring(eggType))
	local visual = source:Clone()
	assert(visual and visual.PrimaryPart, "Egg visual must have a PrimaryPart")
	-- Never copy world carry welds, prompts, scripts, or chase state into a Tool.
	for _, object in ipairs(visual:GetDescendants()) do
		if object:IsA("LuaSourceContainer") or object:IsA("JointInstance")
			or object:IsA("Constraint") or object:IsA("BodyMover") or object:IsA("ProximityPrompt") then
			object:Destroy()
		end
	end
	-- Strip joints before touching transforms or anchoring any cloned part.
	for _, part in ipairs(visual:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
			part.AssemblyLinearVelocity = Vector3.zero
			part.AssemblyAngularVelocity = Vector3.zero
			part.RootPriority = -127
		end
	end
	visual:ScaleTo(egg:GetAttribute("Scale"))
	for name in pairs(visual:GetAttributes()) do visual:SetAttribute(name, nil) end
	visual.Name = "EggVisual"
	-- Keep the original rolled Scale in the Tool, preview and placed model.
	-- Only normalize position/orientation for the handle; never shrink the visual.
	visual:PivotTo(CFrame.new())
	local tool = Instance.new("Tool")
	tool.Name = tostring(egg:GetAttribute("Size")) .. " " .. tostring(egg:GetAttribute("EggName"))
	tool.ToolTip = tostring(egg:GetAttribute("Rarity")) .. " | " .. tostring(egg:GetAttribute("Biome"))
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool:SetAttribute("IsEggTool", true)
	tool:SetAttribute("OwnerUserId", player.UserId)
	for _, field in ipairs(fields) do tool:SetAttribute(field, egg:GetAttribute(field)) end
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.4, 0.4, 0.4)
	handle.Transparency = 1
	handle.CFrame = CFrame.new()
	handle.CanCollide, handle.CanTouch, handle.CanQuery = false, false, false
	handle.Massless = true
	handle.RootPriority = -127
	handle.Parent = tool
	visual.Parent = tool
	for _, part in ipairs(visual:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
			part.Massless = true
			-- Explicit offsets survive cloning outside Workspace and Tool equip movement.
			local weld = Instance.new("Weld")
			weld.Name = "EggToolWeld"
			weld.C0 = handle.CFrame:ToObjectSpace(part.CFrame)
			weld.C1 = CFrame.new()
			weld.Part0, weld.Part1 = handle, part
			weld.Parent = part
		end
	end
	for _, part in ipairs(visual:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.AssemblyLinearVelocity = Vector3.zero
			part.AssemblyAngularVelocity = Vector3.zero
		end
	end
	return tool
end

local function reconcile(player, state)
	if states[player] ~= state then return end
	local backpack = player:FindFirstChildOfClass("Backpack")
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not backpack or not humanoid or humanoid.Health <= 0 then return end
	for uid, entry in pairs(state.entries) do
		if entry.record.Parent ~= state.inventory then
			if entry.live then entry.live:Destroy() end
			entry.template:Destroy()
			state.entries[uid] = nil
		else
			-- Equip moves this same instance between Backpack and Character.
			if not entry.live or (entry.live.Parent ~= backpack and entry.live.Parent ~= character) then
				if entry.live then entry.live:Destroy() end
				entry.live = entry.template:Clone()
				entry.live.Parent = backpack
			end
		end
	end
end

function Service.StartPlayer(player, inventory)
	if states[player] then return states[player] end
	local state = { inventory = inventory, entries = {}, connections = {} }
	states[player] = state
	table.insert(state.connections, player.CharacterAdded:Connect(function(character)
		task.spawn(function()
			character:WaitForChild("Humanoid", 10)
			player:WaitForChild("Backpack", 10)
			if player.Character == character then reconcile(player, state) end
		end)
	end))
	table.insert(state.connections, player.ChildAdded:Connect(function(child)
		if child:IsA("Backpack") then task.defer(reconcile, player, state) end
	end))
	table.insert(state.connections, inventory.ChildRemoved:Connect(function()
		-- A future placement service can consume a record and its Tool together.
		for uid, entry in pairs(state.entries) do
			if entry.record.Parent ~= inventory then
				if entry.live then entry.live:Destroy() end
				entry.template:Destroy()
				state.entries[uid] = nil
			end
		end
	end))
	return state
end

function Service.Deposit(player, egg, inventory)
	local backpack = player:FindFirstChildOfClass("Backpack")
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not backpack or not humanoid or humanoid.Health <= 0 then return false end
	for _, field in ipairs(fields) do
		local value = egg:GetAttribute(field)
		if field == "Scale" then
			if type(value) ~= "number" or value ~= value or value <= 0 or value == math.huge then return false end
		elseif type(value) ~= "string" or value == "" then
			return false
		end
	end
	local uid = egg:GetAttribute("UID")
	local state = Service.StartPlayer(player, inventory)
	-- No yielding between duplicate check and commit.
	for _, record in ipairs(inventory:GetChildren()) do
		if record:GetAttribute("UID") == uid then return false end
	end
	if state.entries[uid] then return false end
	local ok, template = pcall(makeTool, player, egg)
	if not ok then warn("[EggInventoryService] Tool preparation failed: " .. tostring(template)); return false end
	local record = Instance.new("Folder")
	record.Name = uid
	for _, field in ipairs(fields) do record:SetAttribute(field, egg:GetAttribute(field)) end
	record:SetAttribute("OwnerUserId", player.UserId)
	local live = template:Clone()
	state.entries[uid] = { record = record, template = template, live = live }
	record.Parent = inventory
	live.Parent = backpack
	return true
end

function Service.Restore(player, inventory, records)
	local state = Service.StartPlayer(player, inventory)
	if type(records) ~= "table" then return end
	for index, data in ipairs(records) do
		if index > 100 then break end
		if validMetadata(data) and not state.entries[data.UID] then
			local record = Instance.new("Folder")
			record.Name = data.UID
			for _, field in ipairs(fields) do record:SetAttribute(field, data[field]) end
			record:SetAttribute("OwnerUserId", player.UserId)
			local ok, template = pcall(makeTool, player, record)
			if ok then
				state.entries[data.UID] = { record = record, template = template }
				record.Parent = inventory
			else
				record:Destroy()
				warn("[EggInventoryService] Restore skipped: " .. tostring(template))
			end
		end
	end
	reconcile(player, state)
end

function Service.Snapshot(player)
	local state = states[player]
	local result = {}
	if not state then return result end
	for _, entry in pairs(state.entries) do
		if entry.record.Parent == state.inventory then
			local data = {}
			for _, field in ipairs(fields) do data[field] = entry.record:GetAttribute(field) end
			table.insert(result, data)
		end
	end
	table.sort(result, function(a, b) return a.UID < b.UID end)
	return result
end

function Service.CreatePlacedVisual(player, data)
	if not validMetadata(data) then return nil end
	local record = Instance.new("Folder")
	for _, field in ipairs(fields) do record:SetAttribute(field, data[field]) end
	record:SetAttribute("OwnerUserId", player.UserId)
	local ok, tool = pcall(makeTool, player, record)
	record:Destroy()
	if not ok then return nil end
	local source = tool:FindFirstChild("EggVisual")
	local visual = source and source:Clone()
	tool:Destroy()
	if not visual then return nil end
	for _, object in ipairs(visual:GetDescendants()) do
		if object:IsA("JointInstance") or object:IsA("Constraint") then object:Destroy()
		elseif object:IsA("BasePart") then
			object.Anchored = true
			object.CanCollide, object.CanTouch, object.CanQuery = false, false, true
		end
	end
	for _, field in ipairs(fields) do visual:SetAttribute(field, data[field]) end
	visual:SetAttribute("OwnerUserId", player.UserId)
	visual:SetAttribute("Placed", true)
	visual.Name = data.UID
	return visual
end

function Service.GetEquippedEntry(player, uid)
	local state = states[player]
	local entry = state and state.entries[uid]
	if not entry or entry.record.Parent ~= state.inventory
		or not entry.live or entry.live.Parent ~= player.Character
		or entry.record:GetAttribute("OwnerUserId") ~= player.UserId then return nil end
	return entry
end

function Service.ConsumeEquipped(player, uid)
	local entry = Service.GetEquippedEntry(player, uid)
	if not entry then return false end
	states[player].entries[uid] = nil
	entry.live:Destroy()
	entry.template:Destroy()
	entry.record:Destroy()
	return true
end

Players.PlayerRemoving:Connect(function(player)
	local state = states[player]
	if not state then return end
	-- Persistence snapshots PlayerRemoving synchronously; clean runtime objects after it finishes.
	task.defer(function()
		if states[player] ~= state then return end
		states[player] = nil
		for _, connection in ipairs(state.connections) do connection:Disconnect() end
		for _, entry in pairs(state.entries) do
			entry.template:Destroy()
			if entry.live then entry.live:Destroy() end
		end
	end)
end)

return Service
