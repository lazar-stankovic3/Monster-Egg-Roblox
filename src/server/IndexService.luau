local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Modules:WaitForChild("MonsterConfig"))
local MonsterService = require(script.Parent:WaitForChild("MonsterService"))
local Service = {}
local ranks = { Tiny = 1, Normal = 2, Large = 3, Huge = 4, Titanic = 5 }
local states = {}
local started = false
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
	local state = { entries = {}, folder = folder }
	states[player] = state
	return state
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
	publish(player, state)
end

function Service.Import(player, entries)
	local state = states[player] or beginPlayer(player)
	if type(entries) == "table" then merge(state.entries, entries) end
	publish(player, state)
end

function Service.Export(player)
	local state = states[player] or beginPlayer(player)
	return table.clone(state.entries)
end

function Service.Start()
	if started then return end
	started = true
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
		task.defer(function() states[player] = nil end)
	end)
	for _, player in ipairs(Players:GetPlayers()) do beginPlayer(player) end
end

return Service
