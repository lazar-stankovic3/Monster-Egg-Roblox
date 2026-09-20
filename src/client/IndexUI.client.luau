local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MonsterConfig"))
local unlocks = player:WaitForChild("IndexUnlocks")
local previews = ReplicatedStorage:WaitForChild("IndexPreviews")
local playerGui = player:WaitForChild("PlayerGui")
local biomeNames = { "Hatchling Fields", "Bio Marsh", "Spore Lab", "Volcano", "Cryo Sector", "Fossil Lab", "Mutation Core", "Cosmic Incubator" }
local sectionBiomes = { "HatchlingFields", "BioMarsh", "SporeLab", "Volcano", "CryoSector", "FossilLab", "MutationCore", "CosmicIncubator" }
local rarityOrder = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Mythic = 6 }
local catalog = {}
for id, definition in pairs(Config.Definitions) do table.insert(catalog, { id = id, definition = definition }) end
table.sort(catalog, function(a, b)
	local ra, rb = rarityOrder[a.definition.Rarity], rarityOrder[b.definition.Rarity]
	if ra ~= rb then return ra < rb end
	return a.definition.IndexId < b.definition.IndexId
end)
local currentGui, refresh
local connections = {}

local function connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(connections, connection)
end

local function viewport(holder, id, unlocked)
	local old = holder:FindFirstChild("IndexViewport")
	if old then old:Destroy() end
	local question = holder:FindFirstChild("QuestionMark")
	if question then question.Visible = not unlocked end
	local image = holder:FindFirstChild("MonsterImage")
	if image then image.Visible = false end
	if not unlocked then return end
	local source = previews:FindFirstChild(id)
	if not source then return end
	local view = Instance.new("ViewportFrame")
	view.Name = "IndexViewport"
	view.Size = UDim2.fromScale(1, 1)
	view.BackgroundTransparency = 1
	view.ZIndex = holder.ZIndex + 1
	view.Ambient = Color3.fromRGB(200, 200, 200)
	view.LightColor = Color3.new(1, 1, 1)
	local world = Instance.new("WorldModel")
	world.Parent = view
	local model = source:Clone()
	model.Parent = world
	local frame, size = model:GetBoundingBox()
	local camera = Instance.new("Camera")
	camera.FieldOfView = 35
	local distance = size.Magnitude / (2 * math.tan(math.rad(camera.FieldOfView / 2))) * 1.15
	camera.CFrame = CFrame.lookAt(frame.Position + Vector3.new(0.25, 0.15, -1).Unit * distance, frame.Position)
	camera.Parent = view
	view.CurrentCamera = camera
	view.Parent = holder
end

local function bind(gui)
	if currentGui == gui then return end
	for _, connection in ipairs(connections) do connection:Disconnect() end
	connections = {}
	currentGui, refresh = gui, nil
	local frame = gui:WaitForChild("Frame", 10)
	local bottom = frame and frame:WaitForChild("BottomFrame", 10)
	local details = bottom and bottom:FindFirstChild("MonsterDetails")
	local scroller = bottom and bottom:FindFirstChild("BiomeScroller")
	if not details or not scroller then warn("[IndexUI] Missing MonsterDetails/BiomeScroller"); return end
	-- Reuse the user's styles and reserve separate rows for the two new fields.
	for _, name in ipairs({"BaseIncome", "BestSizeFound"}) do
		if not details:FindFirstChild(name) then
			local label = details.Biome:Clone()
			label.Name = name
			label.Parent = details
		end
	end
	local rows = { MonsterName = 0.44, Rarity = 0.54, Biome = 0.62, BaseIncome = 0.70, BestSizeFound = 0.78, Status = 0.88 }
	details.ImageHolder.Position = UDim2.fromScale(0.1, 0.03)
	details.ImageHolder.Size = UDim2.fromScale(0.8, 0.39)
	details.ImageHolder.AnchorPoint = Vector2.zero
	for name, y in pairs(rows) do
		local label = details:FindFirstChild(name)
		if label then
			label.AnchorPoint = Vector2.zero
			label.Position = UDim2.fromScale(0.05, y)
			label.Size = UDim2.fromScale(0.9, if name == "MonsterName" then 0.09 else 0.07)
			label.TextScaled = true
			label.TextWrapped = true
		end
	end
	local selected
	local bindings = {}
	local sections = {}
	for index, biome in ipairs(sectionBiomes) do
		local section = scroller:FindFirstChild("BiomeSection_" .. index)
		if not section then continue end
		local entries = {}
		for _, entry in ipairs(catalog) do if entry.definition.Biome == biome then table.insert(entries, entry) end end
		section.BiomePreview.BiomeName.Text = biomeNames[index]
		section.Visible = #entries > 0
		table.insert(sections, { section = section, entries = entries })
		local area = section.CreatureArea
		local template = area:FindFirstChild("CreatureSlot_1")
		for _, slot in ipairs(area:GetChildren()) do
			if slot:IsA("GuiObject") and slot.Name:match("^CreatureSlot_") then slot.Visible = false end
		end
		for slotIndex, entry in ipairs(entries) do
			local slot = area:FindFirstChild("CreatureSlot_" .. slotIndex)
			if not slot and template then slot = template:Clone(); slot.Name = "CreatureSlot_" .. slotIndex; slot.Parent = area end
			if not slot then continue end
			slot.Visible, slot.LayoutOrder = true, slotIndex
			local button = slot:FindFirstChild("IndexSelect") or Instance.new("TextButton")
			button.Name = "IndexSelect"
			button.Size = UDim2.fromScale(1, 1)
			button.BackgroundTransparency = 1
			button.Text = ""
			button.ZIndex = slot.ImageArea.ZIndex + 5
			button.Parent = slot
			connect(button.Activated, function() selected = entry; if refresh then refresh() end end)
			table.insert(bindings, { slot = slot, entry = entry })
		end
	end
	scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroller.CanvasSize = UDim2.fromOffset(0, 0)
	refresh = function()
		if currentGui ~= gui or not gui.Parent then return end
		local count = 0
		for _, entry in ipairs(catalog) do if unlocks:FindFirstChild(entry.definition.IndexId) then count += 1 end end
		bottom.UnlockedBar.UnlockedText.Text = string.format("Unlocked: %d/%d", count, #catalog)
		local status = player:GetAttribute("IndexDataStatus")
		if status == "LoadFailed" then bottom.UnlockedBar.UnlockedText.Text ..= " (session only)"
		elseif status == "SaveFailed" then bottom.UnlockedBar.UnlockedText.Text ..= " (save pending)" end
		for _, info in ipairs(sections) do
			local found = 0
			for _, entry in ipairs(info.entries) do if unlocks:FindFirstChild(entry.definition.IndexId) then found += 1 end end
			info.section.BiomePreview.Progress.Text = string.format("%d/%d", found, #info.entries)
		end
		for _, info in ipairs(bindings) do
			local def = info.entry.definition
			local unlocked = unlocks:FindFirstChild(def.IndexId) ~= nil
			info.slot.CreatureName.Text = if unlocked then def.MonsterName else "???"
			viewport(info.slot.ImageArea, def.IndexId, unlocked)
		end
		local def = selected and selected.definition
		local record = def and unlocks:FindFirstChild(def.IndexId)
		details.MonsterName.Text = if record then def.MonsterName elseif def then "???" else "Select a Creature"
		details.Rarity.Text = if record then def.Rarity else "???"
		details.Biome.Text = "Biome: " .. (if record then (if def.Biome == "HatchlingFields" then "Hatchling Fields" else def.Biome) else "???")
		details.BaseIncome.Text = if record then string.format("Base Income: $%g/sec", def.BaseIncome) else "Base Income: ???"
		details.BestSizeFound.Text = "Best Size Found: " .. (if record then record:GetAttribute("BestSizeFound") or "???" else "???")
		details.Status.Text = if record then "UNLOCKED" elseif def then "LOCKED" else "SELECT A CREATURE"
		viewport(details.ImageHolder, if def then def.IndexId else "", record ~= nil)
	end
	connect(frame.TopFrame.ExitButton.Activated, function() frame.Visible = false end)
	refresh()
end

local function changed() if refresh then refresh() end end
player:GetAttributeChangedSignal("IndexDataStatus"):Connect(changed)
local recordConnections = {}
local function watch(record)
	recordConnections[record] = record:GetAttributeChangedSignal("BestSizeFound"):Connect(changed)
	changed()
end
unlocks.ChildAdded:Connect(watch)
unlocks.ChildRemoved:Connect(function(record)
	if recordConnections[record] then recordConnections[record]:Disconnect(); recordConnections[record] = nil end
	changed()
end)
for _, record in ipairs(unlocks:GetChildren()) do watch(record) end
playerGui.ChildAdded:Connect(function(gui) if gui.Name == "IndexUi" then task.spawn(bind, gui) end end)
playerGui.ChildRemoved:Connect(function(gui)
	if gui == currentGui then
		for _, connection in ipairs(connections) do connection:Disconnect() end
		connections, currentGui, refresh = {}, nil, nil
	end
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or input.KeyCode ~= Enum.KeyCode.I then return end
	local gui = currentGui
	local frame = gui and gui:FindFirstChild("Frame")
	if frame then gui.Enabled = true; frame.Visible = not frame.Visible end
end)
local existing = playerGui:FindFirstChild("IndexUi")
if existing then task.spawn(bind, existing) end
