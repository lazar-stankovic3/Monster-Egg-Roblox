local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Config = require(ReplicatedStorage.Modules:WaitForChild("MonsterConfig"))
local MonsterService = require(script.Parent:WaitForChild("MonsterService"))
local Service = {}
local ranks = { Tiny = 1, Normal = 2, Large = 3, Huge = 4, Titanic = 5 }
local states = {}
local started = false
local store
local validIds = {}
for _, definition in pairs(Config.Definitions) do validIds[definition.IndexId] = true end

local function merge(target, source)
	for id, size in pairs(source) do
		if validIds[id] and ranks[size] and (not target[id] or ranks[size] > ranks[target[id]]) then target[id] = size end
	end
end

local function publish(player, state)
	for id, size in pairs(state.entries) do
		local record = state.folder:FindFirstChild(id)
		if not record then
			record = Instance.new("Folder")
			record.Name = id
			record:SetAttribute("BestSizeFound", size)
			record.Parent = state.folder
		else record:SetAttribute("BestSizeFound", size) end
	end
end

local function beginPlayer(player)
	if states[player] then return states[player] end
	local folder = Instance.new("Folder")
	folder.Name = "IndexUnlocks"
	folder.Parent = player
	local state = { entries = {}, folder = folder, loaded = false, loading = true, revision = 0, savedRevision = 0 }
	states[player] = state
	player:SetAttribute("IndexDataStatus", "Loading")
	task.spawn(function()
		local ok, data
		for attempt = 1, 3 do
			ok, data = pcall(function() return store:GetAsync("u_" .. player.UserId) end)
			if ok then break end
			if attempt < 3 then task.wait(attempt * 2) end
		end
		if states[player] ~= state then return end
		state.loading = false
		if not ok or (data ~= nil and (type(data) ~= "table" or data.Version ~= 1 or type(data.Unlocks) ~= "table")) then
			player:SetAttribute("IndexDataStatus", "LoadFailed")
			warn("[IndexService] Load failed; saving disabled for " .. player.Name .. ": " .. tostring(data))
			return
		end
		if data then merge(state.entries, data.Unlocks) end
		state.loaded = true
		publish(player, state)
		player:SetAttribute("IndexDataStatus", "Ready")
	end)
	return state
end

local function save(player, state)
	if not state.loaded or state.saving or state.revision == state.savedRevision then return end
	state.saving = true
	local revision = state.revision
	local snapshot = table.clone(state.entries)
	local ok, result
	for attempt = 1, 3 do
		ok, result = pcall(function()
			return store:UpdateAsync("u_" .. player.UserId, function(old)
				if old ~= nil and (type(old) ~= "table" or old.Version ~= 1 or type(old.Unlocks) ~= "table") then
					error("Unsupported Index data; refusing overwrite")
				end
				local entries = if old then table.clone(old.Unlocks) else {}
				-- Unlocks only grow; concurrent sessions cannot downgrade Best Size.
				for id, size in pairs(snapshot) do
					if not ranks[entries[id]] or ranks[size] > ranks[entries[id]] then entries[id] = size end
				end
				return { Version = 1, Unlocks = entries }
			end)
		end)
		if ok then break end
		if attempt < 3 then task.wait(attempt * 2) end
	end
	state.saving = false
	if ok then
		state.savedRevision = revision
		if states[player] == state then
			merge(state.entries, result.Unlocks)
			publish(player, state)
			player:SetAttribute("IndexDataStatus", "Ready")
		end
	else
		if player.Parent == Players then player:SetAttribute("IndexDataStatus", "SaveFailed") end
		warn("[IndexService] Save failed for " .. player.Name .. ": " .. tostring(result))
	end
end

function Service.RecordHatch(player, monster)
	if player.Parent ~= Players or monster:GetAttribute("OwnerUserId") ~= player.UserId
		or monster:GetAttribute("IsMonster") ~= true or not monster:GetAttribute("HatchedAt") then return end
	local definition = Config.Definitions[monster:GetAttribute("MonsterId")]
	local size = monster:GetAttribute("Size")
	if not definition or not ranks[size] then return end
	local state = states[player] or beginPlayer(player)
	local id = definition.IndexId
	if state.entries[id] and ranks[state.entries[id]] >= ranks[size] then return end
	state.entries[id] = size
	state.revision += 1
	publish(player, state)
end

local function flush(player, state)
	local deadline = os.clock() + 24
	while (state.saving or state.loading) and os.clock() < deadline do task.wait(0.1) end
	save(player, state)
end

function Service.Start()
	if started then return end
	started = true
	-- Failure to access DataStore does not prevent session-only unlocks.
	local ok, result = pcall(function() return DataStoreService:GetDataStore("MonsterEggIndex_v1") end)
	if ok then store = result end
	local previews = Instance.new("Folder")
	previews.Name = "IndexPreviews"
	for id, definition in pairs(Config.Definitions) do
		local egg = Instance.new("Folder")
		for name, value in pairs({ Scale = 1, Size = "Normal", Rarity = definition.Rarity, Biome = definition.Biome,
			OwnerUserId = 0, UID = "preview", EggType = "preview", EggName = "preview" }) do egg:SetAttribute(name, value) end
		local success, model = pcall(MonsterService.Create, egg, id)
		egg:Destroy()
		if success then model.Name = definition.IndexId; model.Parent = previews
		else warn("[IndexService] Preview failed: " .. tostring(model)) end
	end
	previews.Parent = ReplicatedStorage
	Players.PlayerAdded:Connect(beginPlayer)
	Players.PlayerRemoving:Connect(function(player)
		local state = states[player]
		if not state then return end
		flush(player, state)
		states[player] = nil
	end)
	for _, player in ipairs(Players:GetPlayers()) do beginPlayer(player) end
	task.spawn(function()
		while true do
			task.wait(60)
			for player, state in pairs(states) do task.spawn(save, player, state) end
		end
	end)
	game:BindToClose(function()
		local pending = 0
		for player, state in pairs(states) do
			pending += 1
			task.spawn(function() flush(player, state); pending -= 1 end)
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do task.wait(0.1) end
	end)
end

return Service
