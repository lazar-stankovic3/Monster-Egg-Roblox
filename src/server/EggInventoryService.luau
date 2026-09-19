-- Server-owned inventory records; Tools are replaceable views of those records.
local Players = game:GetService("Players")
local Service = {}
local states = {}
local fields = { "UID", "EggType", "EggName", "Biome", "Rarity", "Size", "Scale" }

local function makeTool(player, egg)
	local visual = egg:Clone()
	assert(visual and visual.PrimaryPart, "Egg visual must have a PrimaryPart")
	-- Never copy world carry welds, prompts, scripts, or chase state into a Tool.
	for _, object in ipairs(visual:GetDescendants()) do
		if object:IsA("LuaSourceContainer") or object:IsA("JointInstance")
			or object:IsA("Constraint") or object:IsA("ProximityPrompt") then
			object:Destroy()
		end
	end
	for name in pairs(visual:GetAttributes()) do visual:SetAttribute(name, nil) end
	visual.Name = "EggVisual"
	local extent = visual:GetExtentsSize()
	local longest = math.max(extent.X, extent.Y, extent.Z)
	if longest > 4 then visual:ScaleTo(visual:GetScale() * 4 / longest) end
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
	handle.Parent = tool
	visual.Parent = tool
	for _, part in ipairs(visual:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
			part.Massless = true
			local weld = Instance.new("WeldConstraint")
			weld.Part0, weld.Part1 = handle, part
			weld.Parent = part
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
		elseif type(value) ~= "string" or value == "" then return false end
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

Players.PlayerRemoving:Connect(function(player)
	local state = states[player]
	if not state then return end
	states[player] = nil
	for _, connection in ipairs(state.connections) do connection:Disconnect() end
	for _, entry in pairs(state.entries) do
		entry.template:Destroy()
		if entry.live then entry.live:Destroy() end
	end
end)

return Service
