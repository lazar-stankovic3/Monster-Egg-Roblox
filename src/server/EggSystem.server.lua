--// EggSystem
--// ServerScriptService

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

-- RemoteEvent koji pali/gasi RunUI na klijentu
local runUIEvent = ReplicatedStorage:FindFirstChild("RunUIEvent")

if not runUIEvent then
	runUIEvent = Instance.new("RemoteEvent")
	runUIEvent.Name = "RunUIEvent"
	runUIEvent.Parent = ReplicatedStorage
end

--------------------------------------------------
-- REFERENCES
--------------------------------------------------

local eggModelsFolder = ServerStorage:WaitForChild("EggModels")
local eggTemplate = eggModelsFolder:WaitForChild("BasicEgg")

local spawnFolder = workspace:WaitForChild("EggSpawnPoints")
local lobbyZone = workspace:WaitForChild("LobbyDepositZone")

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local RESPAWN_TIME = 8

local PROMPT_HOLD_TIME = 1.2
local PROMPT_DISTANCE = 10

-- visina iznad glave
local HEAD_OFFSET = 1.2

-- Random veličine.
-- Weight = šansa da se pojavi.

local EGG_SIZES = {
	{
		Name = "Tiny",
		Scale = 0.7,
		Weight = 20,
	},

	{
		Name = "Normal",
		Scale = 1,
		Weight = 45,
	},

	{
		Name = "Large",
		Scale = 1.4,
		Weight = 22,
	},

	{
		Name = "Huge",
		Scale = 1.9,
		Weight = 10,
	},

	{
		Name = "Titanic",
		Scale = 2.6,
		Weight = 3,
	},
}

--------------------------------------------------
-- RUNTIME DATA
--------------------------------------------------

-- [player] = egg model
local carriedEggs = {}

-- [spawnPart] = spawned egg
local activeSpawnEggs = {}

--------------------------------------------------
-- RANDOM SIZE
--------------------------------------------------

local function rollEggSize()
	local totalWeight = 0

	for _, info in ipairs(EGG_SIZES) do
		totalWeight += info.Weight
	end

	local roll = math.random() * totalWeight
	local currentWeight = 0

	for _, info in ipairs(EGG_SIZES) do
		currentWeight += info.Weight

		if roll <= currentWeight then
			return info
		end
	end

	return EGG_SIZES[2]
end

--------------------------------------------------
-- INVENTORY
--------------------------------------------------

local function createInventory(player)
	local inventory = Instance.new("Folder")
	inventory.Name = "EggInventory"
	inventory.Parent = player
end

local function addEggToInventory(player, egg)
	local inventory = player:FindFirstChild("EggInventory")

	if not inventory then
		return
	end

	local item = Instance.new("Folder")

	item.Name = egg:GetAttribute("EggName") or "Egg"

	item:SetAttribute(
		"UID",
		egg:GetAttribute("UID")
	)

	item:SetAttribute(
		"EggName",
		egg:GetAttribute("EggName")
	)

	item:SetAttribute(
		"Size",
		egg:GetAttribute("Size")
	)

	item:SetAttribute(
		"Scale",
		egg:GetAttribute("Scale")
	)

	item.Parent = inventory

	print(
		player.Name,
		"deposited",
		item:GetAttribute("Size"),
		item:GetAttribute("EggName")
	)
end

--------------------------------------------------
-- MODEL SETUP
--------------------------------------------------

local function prepareEggModel(egg)
	if not egg.PrimaryPart then
		warn(
			egg.Name ..
				" nema PrimaryPart!"
		)

		return false
	end

	for _, object in ipairs(egg:GetDescendants()) do

		if object:IsA("BasePart") then

			object.Anchored = true

			object.CanCollide = true
			object.CanTouch = true
			object.CanQuery = true

		end

	end

	return true
end

--------------------------------------------------
-- CREATE PROMPT
--------------------------------------------------

local function createPrompt(egg)
	local root = egg.PrimaryPart

	local prompt = Instance.new("ProximityPrompt")

	prompt.Name = "PickupPrompt"

	prompt.ActionText = "Pick Up"
	prompt.ObjectText =
		egg:GetAttribute("Size") ..
		" Egg"

	prompt.KeyboardKeyCode =
		Enum.KeyCode.E

	prompt.HoldDuration =
		PROMPT_HOLD_TIME

	prompt.MaxActivationDistance =
		PROMPT_DISTANCE

	prompt.RequiresLineOfSight = false

	prompt.Parent = root

	return prompt
end

--------------------------------------------------
-- CARRY SETUP
--------------------------------------------------

local function setEggPhysicsForCarry(egg)

	for _, object in ipairs(egg:GetDescendants()) do

		if object:IsA("BasePart") then

			object.Anchored = false
			object.CanCollide = false
			object.CanTouch = false
			object.Massless = true

		end

	end

end

local function weldEggModel(egg)

	local primary = egg.PrimaryPart

	for _, object in ipairs(egg:GetDescendants()) do

		if object:IsA("BasePart")
			and object ~= primary then

			local existing =
				object:FindFirstChild(
					"EggInternalWeld"
				)

			if not existing then

				local weld =
					Instance.new(
						"WeldConstraint"
					)

				weld.Name =
					"EggInternalWeld"

				weld.Part0 = primary
				weld.Part1 = object

				weld.Parent = object

			end
		end
	end
end

--------------------------------------------------
-- PICKUP EGG
--------------------------------------------------

local function pickupEgg(player, egg)

	-- već nosi nešto
	if carriedEggs[player] then
		return
	end

	if not egg
		or not egg.Parent
		or not egg.PrimaryPart then
		return
	end

	if egg:GetAttribute("Carried") then
		return
	end

	local character = player.Character

	if not character then
		return
	end

	local head =
		character:FindFirstChild("Head")

	local humanoid =
		character:FindFirstChildOfClass(
			"Humanoid"
		)

	if not head
		or not humanoid
		or humanoid.Health <= 0 then
		return
	end

	--------------------------------------------------
	-- LOCK OWNERSHIP
	--------------------------------------------------

	egg:SetAttribute(
		"Carried",
		true
	)

	egg:SetAttribute(
		"CarrierUserId",
		player.UserId
	)

	carriedEggs[player] = egg

	-- UPALI RUN UI
	runUIEvent:FireClient(player, true)

	--------------------------------------------------
	-- REMOVE PROMPT
	--------------------------------------------------

	local prompt =
		egg.PrimaryPart:FindFirstChild(
			"PickupPrompt"
		)

	if prompt then
		prompt:Destroy()
	end

	--------------------------------------------------
	-- PHYSICS
	--------------------------------------------------

	weldEggModel(egg)

	setEggPhysicsForCarry(egg)

	--------------------------------------------------
	-- FIND EGG HEIGHT
	--------------------------------------------------

	local _, boundingSize =
		egg:GetBoundingBox()

	local yOffset =
		HEAD_OFFSET +
		(boundingSize.Y / 2)

	--------------------------------------------------
	-- POSITION ABOVE HEAD
	--------------------------------------------------

	egg:PivotTo(
		head.CFrame *
			CFrame.new(
				0,
				yOffset,
				0
			)
	)

	--------------------------------------------------
	-- WELD TO HEAD
	--------------------------------------------------

	local weld =
		Instance.new(
			"WeldConstraint"
		)

	weld.Name = "CarryWeld"

	weld.Part0 = head
	weld.Part1 = egg.PrimaryPart

	weld.Parent = egg.PrimaryPart

	print(
		player.Name,
		"picked up",
		egg:GetAttribute("Size"),
		"egg"
	)
end

--------------------------------------------------
-- DROP EGG
--------------------------------------------------

local function dropEgg(player)
	local egg =
		carriedEggs[player]

	if not egg
		or not egg.Parent then

		carriedEggs[player] = nil

		-- UGASI RUN UI
		runUIEvent:FireClient(player, false)

		return
	end

	local character =
		player.Character

	local root =
		character and
		character:FindFirstChild(
			"HumanoidRootPart"
		)

	local carryWeld =
		egg.PrimaryPart:
		FindFirstChild(
			"CarryWeld"
		)

	if carryWeld then
		carryWeld:Destroy()
	end

	--------------------------------------------------
	-- RESET
	--------------------------------------------------

	egg:SetAttribute(
		"Carried",
		false
	)

	egg:SetAttribute(
		"CarrierUserId",
		nil
	)

	carriedEggs[player] = nil

	-- UGASI RUN UI
	runUIEvent:FireClient(player, false)

	--------------------------------------------------
	-- WORLD PHYSICS
	--------------------------------------------------

	for _, object in ipairs(
		egg:GetDescendants()
		) do

		if object:IsA("BasePart") then

			object.Anchored = false
			object.CanCollide = true
			object.CanTouch = true
			object.Massless = false

		end
	end

	if root then

		egg:PivotTo(
			root.CFrame *
				CFrame.new(
					0,
					2,
					-4
				)
		)

	end

	--------------------------------------------------
	-- PICKUP AGAIN
	--------------------------------------------------

	local prompt =
		createPrompt(egg)

	prompt.Triggered:Connect(
		function(newPlayer)

			pickupEgg(
				newPlayer,
				egg
			)

		end
	)
end

--------------------------------------------------
-- SPAWN EGG
--------------------------------------------------

local function spawnEgg(spawnPart)

	if activeSpawnEggs[spawnPart]
		and activeSpawnEggs[spawnPart].Parent then
		return
	end

	local egg = eggTemplate:Clone()
	egg.Name = "WorldEgg"

	--------------------------------------------------
	-- UNIQUE ID
	--------------------------------------------------

	egg:SetAttribute(
		"UID",
		HttpService:GenerateGUID(false)
	)

	egg:SetAttribute(
		"EggName",
		"BasicEgg"
	)

	--------------------------------------------------
	-- RANDOM SIZE
	--------------------------------------------------

	local sizeInfo = rollEggSize()

	egg:SetAttribute(
		"Size",
		sizeInfo.Name
	)

	egg:SetAttribute(
		"Scale",
		sizeInfo.Scale
	)

	egg:SetAttribute(
		"SpawnPoint",
		spawnPart.Name
	)

	egg:SetAttribute(
		"Carried",
		false
	)

	--------------------------------------------------
	-- SCALE
	--------------------------------------------------

	egg:ScaleTo(sizeInfo.Scale)

	--------------------------------------------------
	-- PARENT
	--------------------------------------------------

	egg.Parent = workspace

	--------------------------------------------------
	-- PREPARE MODEL
	--------------------------------------------------

	if not prepareEggModel(egg) then
		egg:Destroy()
		return
	end

	--------------------------------------------------
	-- POSITION
	-- PrimaryPart is at the bottom of the egg
	--------------------------------------------------

	local root = egg.PrimaryPart

	if not root then
		warn("Egg nema PrimaryPart!")
		egg:Destroy()
		return
	end

	-- top surface of spawn part
	local spawnTopY =
		spawnPart.Position.Y
		+ (spawnPart.Size.Y / 2)

	-- Since PrimaryPart is on the bottom,
	-- place it directly on top of spawn point.
	local targetCFrame = CFrame.new(
		spawnPart.Position.X,
		spawnTopY,
		spawnPart.Position.Z
	)

	-- Preserve spawn point rotation if you want
	targetCFrame =
		CFrame.new(
			spawnPart.Position.X,
			spawnTopY,
			spawnPart.Position.Z
		)
		* CFrame.Angles(
			0,
			math.rad(spawnPart.Orientation.Y),
			0
		)

	egg:SetPrimaryPartCFrame(targetCFrame)

	--------------------------------------------------
	-- REGISTER ACTIVE EGG
	--------------------------------------------------

	activeSpawnEggs[spawnPart] = egg

	--------------------------------------------------
	-- PROMPT
	--------------------------------------------------

	local prompt = createPrompt(egg)

	prompt.Triggered:Connect(function(player)
		pickupEgg(player, egg)
	end)

	print(
		"🥚 Spawned",
		sizeInfo.Name,
		"egg at",
		spawnPart.Name
	)
end

--------------------------------------------------
-- RESPAWN
--------------------------------------------------

local function scheduleRespawn(
	spawnPointName
)

	local spawnPart =
		spawnFolder:
		FindFirstChild(
			spawnPointName
		)

	if not spawnPart then
		return
	end

	activeSpawnEggs[spawnPart] =
		nil

	task.delay(
		RESPAWN_TIME,
		function()

			spawnEgg(
				spawnPart
			)

		end
	)
end

--------------------------------------------------
-- DEPOSIT INTO INVENTORY
--------------------------------------------------

local depositCooldown = {}

local function depositEgg(player)

	if depositCooldown[player] then
		return
	end

	local egg =
		carriedEggs[player]

	if not egg
		or not egg.Parent then
		return
	end

	depositCooldown[player] = true

	--------------------------------------------------
	-- VALIDATE
	--------------------------------------------------

	if egg:GetAttribute(
		"CarrierUserId"
		) ~= player.UserId then

		depositCooldown[player] = nil
		return

	end

	local spawnPointName =
		egg:GetAttribute(
			"SpawnPoint"
		)

	--------------------------------------------------
	-- INVENTORY
	--------------------------------------------------

	addEggToInventory(
		player,
		egg
	)

	carriedEggs[player] =
		nil

	-- UGASI RUN UI
	runUIEvent:FireClient(player, false)

	--------------------------------------------------
	-- DESTROY WORLD EGG
	--------------------------------------------------

	egg:Destroy()

	--------------------------------------------------
	-- NEW EGG LATER
	--------------------------------------------------

	if spawnPointName then

		scheduleRespawn(
			spawnPointName
		)

	end

	task.delay(
		0.5,
		function()

			depositCooldown[player] =
				nil

		end
	)
end

--------------------------------------------------
-- LOBBY ZONE
--------------------------------------------------

lobbyZone.Touched:Connect(
	function(hit)

		local character =
			hit:FindFirstAncestorOfClass(
				"Model"
			)

		if not character then
			return
		end

		local humanoid =
			character:
			FindFirstChildOfClass(
				"Humanoid"
			)

		if not humanoid then
			return
		end

		local player =
			Players:
			GetPlayerFromCharacter(
				character
			)

		if not player then
			return
		end

		if carriedEggs[player] then

			depositEgg(
				player
			)

		end
	end
)

--------------------------------------------------
-- PLAYER
--------------------------------------------------

local function setupCharacter(
	player,
	character
)

	local humanoid =
		character:
		WaitForChild(
			"Humanoid"
		)

	humanoid.Died:Connect(
		function()

			if carriedEggs[player] then

				dropEgg(
					player
				)

			end
		end
	)
end

local function setupPlayer(player)

	createInventory(player)

	if player.Character then

		setupCharacter(
			player,
			player.Character
		)

	end

	player.CharacterAdded:Connect(
		function(character)

			setupCharacter(
				player,
				character
			)

		end
	)
end

Players.PlayerAdded:Connect(
	setupPlayer
)

for _, player in ipairs(
	Players:GetPlayers()
	) do

	setupPlayer(player)

end

--------------------------------------------------
-- PLAYER LEAVES
--------------------------------------------------

Players.PlayerRemoving:Connect(
	function(player)

		if carriedEggs[player] then

			local egg =
				carriedEggs[player]

			local spawnName =
				egg:GetAttribute(
					"SpawnPoint"
				)

			egg:Destroy()

			carriedEggs[player] =
				nil

			if spawnName then

				scheduleRespawn(
					spawnName
				)

			end
		end

		depositCooldown[player] =
			nil
	end
)

--------------------------------------------------
-- INITIAL SPAWNS
--------------------------------------------------

for _, spawnPart in ipairs(
	spawnFolder:GetChildren()
	) do

	if spawnPart:IsA("BasePart") then

		spawnEgg(
			spawnPart
		)

	end
end

print("🥚 Egg system loaded")