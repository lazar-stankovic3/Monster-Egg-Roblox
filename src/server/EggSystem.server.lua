-- ServerScriptService.Server.EggSystem
-- Faza 4
--
-- Zadržava:
-- pickup
-- carry
-- death drop
-- lobby deposit
-- Run UI
-- 8s respawn
-- PlayerRemoving cleanup
--
-- Dodaje:
-- biome egg pools
-- različite egg modele
-- stabilni EggType
-- kompletan metadata set
-- server pickup validaciju
-- legacy BasicEgg fallback

--------------------------------------------------
-- SERVICES
--------------------------------------------------

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HttpService = game:GetService("HttpService")
local GuardianHitService = require(script.Parent:WaitForChild("GuardianHitService"))
local EggInventoryService = require(script.Parent:WaitForChild("EggInventoryService"))

--------------------------------------------------
-- RUN UI EVENT
--------------------------------------------------
-- Kreiramo ga pre require-ova da RunUI ne visi
-- čak i ako neki ModuleScript ima problem.

local runUIEvent =
	ReplicatedStorage:FindFirstChild("RunUIEvent")

if not runUIEvent then
	runUIEvent = Instance.new("RemoteEvent")
	runUIEvent.Name = "RunUIEvent"
	runUIEvent.Parent = ReplicatedStorage
end

--------------------------------------------------
-- MODULES
--------------------------------------------------

local modulesFolder =
	ReplicatedStorage:FindFirstChild("Modules")

if not modulesFolder then
	error(
		"[EggSystem] ReplicatedStorage.Modules ne postoji."
	)
end

print("[EggSystem] Modules children:")

for _, child in ipairs(
	modulesFolder:GetChildren()
	) do
	print(
		" -",
		child.Name,
		child.ClassName
	)
end

local eggConfigModule =
	modulesFolder:FindFirstChild("EggConfig")

if not eggConfigModule then
	error(
		"[EggSystem] EggConfig nije pronađen u ReplicatedStorage.Modules."
	)
end

if not eggConfigModule:IsA("ModuleScript") then
	error(
		"[EggSystem] EggConfig postoji, ali nije ModuleScript."
	)
end

local eggRollerModule =
	modulesFolder:FindFirstChild("EggRoller")

if not eggRollerModule then
	error(
		"[EggSystem] EggRoller nije pronađen u ReplicatedStorage.Modules."
	)
end

if not eggRollerModule:IsA("ModuleScript") then
	error(
		"[EggSystem] EggRoller postoji, ali nije ModuleScript."
	)
end

local EggConfig =
	require(eggConfigModule :: ModuleScript)

local EggRoller =
	require(eggRollerModule :: ModuleScript)

local sizeConfigModule =
	modulesFolder:FindFirstChild("SizeConfig")

if not sizeConfigModule then
	error("[EggSystem] SizeConfig nije pronađen u ReplicatedStorage.Modules.")
end

if not sizeConfigModule:IsA("ModuleScript") then
	error("[EggSystem] SizeConfig postoji, ali nije ModuleScript.")
end

local SizeConfig =
	require(sizeConfigModule :: ModuleScript)

--------------------------------------------------
-- REFERENCES
--------------------------------------------------

local eggModelsFolder =
	ServerStorage:WaitForChild("EggModels")

-- GuardianService može samo da zatraži drop; EggSystem ostaje vlasnik carry stanja i fizike.
local signals = ServerScriptService:FindFirstChild("GameSignals")
if not signals then
	signals = Instance.new("Folder")
	signals.Name = "GameSignals"
	signals.Parent = ServerScriptService
end

local guardianForceDrop = signals:FindFirstChild("GuardianForceDrop")
if not guardianForceDrop then
	guardianForceDrop = Instance.new("BindableEvent")
	guardianForceDrop.Name = "GuardianForceDrop"
	guardianForceDrop.Parent = signals
end

if not guardianForceDrop:IsA("BindableEvent") then
	error("[EggSystem] GameSignals.GuardianForceDrop mora biti BindableEvent.")
end

local spawnFolder =
	workspace:WaitForChild("EggSpawnPoints")

local lobbyZone =
	workspace:WaitForChild("LobbyDepositZone")

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local RESPAWN_TIME = 8

local PROMPT_HOLD_TIME = 1.2
local PROMPT_DISTANCE = 10

-- Malo tolerancije iznad prompt distance-a.
local SERVER_PICKUP_DISTANCE =
	PROMPT_DISTANCE + 2

local HEAD_OFFSET = 1.2

--------------------------------------------------
-- RANDOM
--------------------------------------------------

local randomObject = Random.new()

--------------------------------------------------
-- RUNTIME DATA
--------------------------------------------------

-- [Player] = egg Model
local carriedEggs = {}

-- [spawnPart] = egg Model
local activeSpawnEggs = {}

-- [egg Model] = original spawn Part
local eggOriginSpawn = {}

-- Deposit debounce
local depositCooldown = {}

-- Spawn point imena koja nisu jedinstvena
local duplicateSpawnNames = {}

--------------------------------------------------
-- SPAWN NAME VALIDATION
--------------------------------------------------

local function scanSpawnPointNames()
	local seen = {}

	for _, object in ipairs(
		spawnFolder:GetChildren()
		) do
		if object:IsA("BasePart") then
			if seen[object.Name] then
				duplicateSpawnNames[object.Name] =
					true
			else
				seen[object.Name] = object
			end
		end
	end

	for duplicateName in pairs(
		duplicateSpawnNames
		) do
		warn(
			string.format(
				"[EggSystem] DUPLICATE SpawnPoint name '%s'. SpawnPoint imena moraju biti jedinstvena. Spawnovi sa ovim imenom će biti preskočeni.",
				duplicateName
			)
		)
	end
end

--------------------------------------------------
-- INVENTORY
--------------------------------------------------

local function getOrCreateInventory(player)
	local existing =
		player:FindFirstChild("EggInventory")

	if existing
		and existing:IsA("Folder") then

		return existing
	end

	if existing then
		warn(
			string.format(
				"[EggSystem] %s već ima EggInventory koji nije Folder.",
				player.Name
			)
		)

		return nil
	end

	local inventory = Instance.new("Folder")
	inventory.Name = "EggInventory"
	inventory.Parent = player

	return inventory
end

local function addEggToInventory(player, egg)
	local inventory = getOrCreateInventory(player)
	if not inventory then return false end
	return EggInventoryService.Deposit(player, egg, inventory)
end

--------------------------------------------------
-- MODEL PHYSICS
--------------------------------------------------

local function prepareEggModel(egg)
	if not egg:IsA("Model") then
		warn(
			"[EggSystem] Egg template nije Model."
		)

		return false
	end

	if not egg.PrimaryPart then
		warn(
			string.format(
				"[EggSystem] Egg model '%s' nema PrimaryPart.",
				egg.Name
			)
		)

		return false
	end

	local foundPart = false

	for _, object in ipairs(
		egg:GetDescendants()
		) do
		if object:IsA("BasePart") then
			foundPart = true

			object.Anchored = true
			object.CanCollide = true
			object.CanTouch = true
			object.CanQuery = true
			object.Massless = false
		end
	end

	if not foundPart then
		warn(
			string.format(
				"[EggSystem] Egg model '%s' nema nijedan BasePart.",
				egg.Name
			)
		)

		return false
	end

	return true
end

local function setEggPhysicsForCarry(egg)
	for _, object in ipairs(
		egg:GetDescendants()
		) do
		if object:IsA("BasePart") then
			object.Anchored = false
			object.CanCollide = false
			object.CanTouch = false
			object.CanQuery = true
			object.Massless = true
		end
	end
end

local function setEggPhysicsForDrop(egg)
	for _, object in ipairs(
		egg:GetDescendants()
		) do
		if object:IsA("BasePart") then
			object.Anchored = false
			object.CanCollide = true
			object.CanTouch = true
			object.CanQuery = true
			object.Massless = false
		end
	end
end

--------------------------------------------------
-- INTERNAL WELDS
--------------------------------------------------

local function weldEggModel(egg)
	local primary = egg.PrimaryPart

	if not primary then
		return
	end

	for _, object in ipairs(
		egg:GetDescendants()
		) do
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
-- POSITION ON SPAWN
--------------------------------------------------

local function positionEggOnSpawn(
	egg,
	spawnPart
)
	local baseCFrame =
		CFrame.new(
			spawnPart.Position
		)
		* CFrame.Angles(
			0,
			math.rad(
				spawnPart.Orientation.Y
			),
			0
		)

	egg:PivotTo(baseCFrame)

	local boxCFrame, boxSize =
		egg:GetBoundingBox()

	local eggBottomY =
		boxCFrame.Position.Y
	- (boxSize.Y / 2)

	local spawnTopY =
		spawnPart.Position.Y
		+ (spawnPart.Size.Y / 2)

	local yCorrection =
		spawnTopY - eggBottomY

	egg:PivotTo(
		egg:GetPivot()
			+ Vector3.new(
				0,
				yCorrection,
				0
			)
	)
end

--------------------------------------------------
-- POSITION ABOVE HEAD
--------------------------------------------------

local function positionEggAboveHead(
	egg,
	head
)
	egg:PivotTo(
		CFrame.new(head.Position)
			* head.CFrame.Rotation
	)

	local boxCFrame, boxSize =
		egg:GetBoundingBox()

	local eggBottomY =
		boxCFrame.Position.Y
	- (boxSize.Y / 2)

	local desiredBottomY =
		head.Position.Y
		+ (head.Size.Y / 2)
		+ HEAD_OFFSET

	local yCorrection =
		desiredBottomY - eggBottomY

	egg:PivotTo(
		egg:GetPivot()
			+ Vector3.new(
				0,
				yCorrection,
				0
			)
	)
end

--------------------------------------------------
-- PROMPT
--------------------------------------------------

local pickupEgg

local function createPrompt(egg)
	local root = egg.PrimaryPart

	if not root then
		return nil
	end

	local existing =
		root:FindFirstChild("PickupPrompt")

	if existing then
		existing:Destroy()
	end

	local prompt =
		Instance.new("ProximityPrompt")

	prompt.Name = "PickupPrompt"
	prompt.ActionText = "Pick Up"

	local sizeName =
		egg:GetAttribute("Size")
		or "Unknown"

	local eggName =
		egg:GetAttribute("EggName")
		or "Egg"

	prompt.ObjectText =
		string.format(
			"%s %s",
			tostring(sizeName),
			tostring(eggName)
		)

	prompt.KeyboardKeyCode =
		Enum.KeyCode.E

	prompt.HoldDuration =
		PROMPT_HOLD_TIME

	prompt.MaxActivationDistance =
		PROMPT_DISTANCE

	prompt.RequiresLineOfSight = false

	prompt.Parent = root

	prompt.Triggered:Connect(
		function(player)
			pickupEgg(
				player,
				egg
			)
		end
	)

	return prompt
end

--------------------------------------------------
-- PICKUP VALIDATION
--------------------------------------------------

local function validatePickup(
	player,
	egg
)
	if not player
		or not player:IsA("Player") then

		return false
	end

	if carriedEggs[player] then
		return false
	end

	if not egg
		or not egg.Parent
		or not egg.PrimaryPart then

		return false
	end

	if egg:GetAttribute("Carried") == true then
		return false
	end

	local character =
		player.Character

	if not character or character:GetAttribute("GuardianRagdoll") == true then
		return false
	end

	local humanoid =
		character:
		FindFirstChildOfClass(
			"Humanoid"
		)

	local root =
		character:
		FindFirstChild(
			"HumanoidRootPart"
		)

	local head =
		character:
		FindFirstChild(
			"Head"
		)

	if not humanoid
		or humanoid.Health <= 0
		or not root
		or not head then

		return false
	end

	local distance =
		(
			root.Position
			- egg.PrimaryPart.Position
		).Magnitude

	if distance > SERVER_PICKUP_DISTANCE then
		warn(
			string.format(
				"[EggSystem] Pickup odbijen za %s: distance %.2f > %.2f",
				player.Name,
				distance,
				SERVER_PICKUP_DISTANCE
			)
		)

		return false
	end

	return true,
		character,
		humanoid,
		root,
		head
end

local function getCarryMovementPenalty(egg)
	local penalty = SizeConfig.GetCarryMovementPenalty(egg:GetAttribute("Size"))

	if type(penalty) ~= "number" then
		warn(string.format(
			"[EggSystem] Egg UID=%s ima nevalidan Size '%s'; carry penalty nije primenjen.",
			tostring(egg:GetAttribute("UID")),
			tostring(egg:GetAttribute("Size"))
		))
		return nil
	end

	return penalty
end

local function clearCarryMovementPenalty(player)
	player:SetAttribute("CarryMovementPenalty", 0)
end

--------------------------------------------------
-- PICKUP
--------------------------------------------------

pickupEgg = function(player, egg)
	local valid,
		_character,
		_humanoid,
		_root,
		head =
		validatePickup(
			player,
			egg
		)

	if not valid then
		return
	end

	local carryPenalty = getCarryMovementPenalty(egg)

	if carryPenalty == nil then
		return
	end

	--------------------------------------------------
	-- LOCK
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
	player:SetAttribute("CarryMovementPenalty", carryPenalty)

	--------------------------------------------------
	-- REMOVE PROMPT
	--------------------------------------------------

	local prompt =
		egg.PrimaryPart:
		FindFirstChild(
			"PickupPrompt"
		)

	if prompt then
		prompt:Destroy()
	end

	--------------------------------------------------
	-- CARRY
	--------------------------------------------------

	weldEggModel(egg)
	setEggPhysicsForCarry(egg)

	positionEggAboveHead(
		egg,
		head
	)

	local carryWeld =
		Instance.new("WeldConstraint")

	carryWeld.Name = "CarryWeld"
	carryWeld.Part0 = head
	carryWeld.Part1 = egg.PrimaryPart
	carryWeld.Parent = egg.PrimaryPart

	runUIEvent:FireClient(
		player,
		true
	)

	print(
		string.format(
			"[EggSystem] %s picked up %s %s | UID=%s",
			player.Name,
			tostring(
				egg:GetAttribute("Size")
			),
			tostring(
				egg:GetAttribute("EggName")
			),
			tostring(
				egg:GetAttribute("UID")
			)
		)
	)
end

--------------------------------------------------
-- DROP
--------------------------------------------------

local function dropEgg(player)
	local egg =
		carriedEggs[player]

	if not egg
		or not egg.Parent then

		carriedEggs[player] = nil
		clearCarryMovementPenalty(player)

		runUIEvent:FireClient(
			player,
			false
		)

		return
	end

	local primary =
		egg.PrimaryPart

	if not primary then
		carriedEggs[player] = nil
		clearCarryMovementPenalty(player)

		runUIEvent:FireClient(
			player,
			false
		)

		return
	end

	local character =
		player.Character

	local characterRoot =
		character
		and character:
		FindFirstChild(
			"HumanoidRootPart"
		)

	local carryWeld =
		primary:
		FindFirstChild(
			"CarryWeld"
		)

	if carryWeld then
		carryWeld:Destroy()
	end

	egg:SetAttribute(
		"Carried",
		false
	)

	egg:SetAttribute(
		"CarrierUserId",
		0
	)

	carriedEggs[player] = nil
	clearCarryMovementPenalty(player)

	runUIEvent:FireClient(
		player,
		false
	)

	setEggPhysicsForDrop(egg)

	if characterRoot then
		egg:PivotTo(
			characterRoot.CFrame
				* CFrame.new(
					0,
					2,
					-4
				)
		)
	end

	createPrompt(egg)

	print(
		string.format(
			"[EggSystem] %s dropped %s | UID=%s",
			player.Name,
			tostring(
				egg:GetAttribute("EggName")
			),
			tostring(
				egg:GetAttribute("UID")
			)
		)
	)
end

guardianForceDrop.Event:Connect(function(player, expectedEgg, guardianPosition)
	if typeof(player) == "Instance" and player:IsA("Player")
		and expectedEgg ~= nil and carriedEggs[player] == expectedEgg then
		dropEgg(player)
		if typeof(guardianPosition) == "Vector3" then
			GuardianHitService.Hit(player, guardianPosition, expectedEgg)
		end
	end
end)

--------------------------------------------------
-- RESOLVE EGG DEFINITION
--------------------------------------------------

local function getEggDefinitionForSpawn(
	spawnPart
)
	local biomeAttribute =
		spawnPart:GetAttribute("Biome")

	--------------------------------------------------
	-- LEGACY
	--------------------------------------------------

	if biomeAttribute == nil then
		return
			EggConfig.LegacyBasicEgg,
			EggConfig.LegacyBasicEgg.Biome,
			nil
	end

	--------------------------------------------------
	-- ATTRIBUTE EXISTS BUT INVALID
	--------------------------------------------------

	if type(biomeAttribute) ~= "string"
		or biomeAttribute == "" then

		return nil,
			nil,
			string.format(
				"SpawnPoint '%s' ima Biome Attribute, ali nije validan non-empty String.",
				spawnPart.Name
			)
	end

	local biomeKey = tostring(biomeAttribute)

local definition, rollError =
	EggRoller.RollEggForBiome(
		biomeKey,
		randomObject
	)

if not definition then
	local errorMessage =
		tostring(
			rollError
				or "nije moguće izabrati egg"
		)

	return nil,
		nil,
		string.format(
			"SpawnPoint '%s' Biome='%s': %s",
			tostring(spawnPart.Name),
			biomeKey,
			errorMessage
		)
end

return definition,
	biomeKey,
	nil
end
--------------------------------------------------
-- APPLY WORLD ATTRIBUTES
--------------------------------------------------

local function applyWorldAttributes(
	egg,
	definition,
	biomeName,
	sizeInfo,
	spawnPart
)
	egg:SetAttribute(
		"UID",
		HttpService:GenerateGUID(false)
	)

	egg:SetAttribute(
		"EggName",
		definition.EggName
	)

	egg:SetAttribute(
		"EggType",
		definition.EggType
	)

	egg:SetAttribute(
		"Biome",
		biomeName
	)

	egg:SetAttribute(
		"Rarity",
		definition.Rarity
	)

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

	egg:SetAttribute(
		"CarrierUserId",
		0
	)
end

--------------------------------------------------
-- SPAWN EGG
--------------------------------------------------

local function spawnEgg(spawnPart)
	if not spawnPart
		or not spawnPart.Parent
		or not spawnPart:IsA("BasePart") then

		return
	end

	if duplicateSpawnNames[
		spawnPart.Name
		] then

		warn(
			string.format(
				"[EggSystem] Preskačem SpawnPoint '%s' jer ime nije jedinstveno.",
				spawnPart.Name
			)
		)

		return
	end

	local active =
		activeSpawnEggs[spawnPart]

	if active
		and active.Parent then

		return
	end

	--------------------------------------------------
	-- CHOOSE EGG
	--------------------------------------------------

	local definition,
		biomeName,
		definitionError =
		getEggDefinitionForSpawn(
			spawnPart
		)

	if not definition then
		warn(
			"[EggSystem] "
				.. (
					definitionError
					or "Egg definition nije pronađen."
				)
				.. " Spawn preskočen."
		)

		return
	end

	--------------------------------------------------
	-- MODEL
	--------------------------------------------------

	local template =
		eggModelsFolder:
		FindFirstChild(
			definition.ModelName
		)

	if not template
		or not template:IsA("Model") then

		warn(
			string.format(
				"[EggSystem] SpawnPoint '%s': model '%s' za EggType '%s' ne postoji kao Model u ServerStorage.EggModels. Spawn preskočen.",
				spawnPart.Name,
				tostring(
					definition.ModelName
				),
				tostring(
					definition.EggType
				)
			)
		)

		return
	end

	--------------------------------------------------
	-- SIZE
	--------------------------------------------------

	local sizeInfo, sizeError =
		EggRoller.RollSize(
			randomObject
		)

	if not sizeInfo then
		warn(
			string.format(
				"[EggSystem] SpawnPoint '%s': size roll failed: %s. Spawn preskočen.",
				spawnPart.Name,
				tostring(sizeError)
			)
		)

		return
	end

	--------------------------------------------------
	-- CLONE
	--------------------------------------------------

	local egg =
		template:Clone()

	egg.Name = "WorldEgg"

	applyWorldAttributes(
		egg,
		definition,
		biomeName,
		sizeInfo,
		spawnPart
	)

	egg:ScaleTo(
		sizeInfo.Scale
	)

	egg.Parent = workspace

	if not prepareEggModel(egg) then
		egg:Destroy()
		return
	end

	positionEggOnSpawn(
		egg,
		spawnPart
	)

	activeSpawnEggs[spawnPart] = egg
	eggOriginSpawn[egg] = spawnPart

	createPrompt(egg)

	print(
		string.format(
			"[EggSystem] Spawned %s %s | EggType=%s | Biome=%s | Rarity=%s | SpawnPoint=%s | UID=%s",
			sizeInfo.Name,
			definition.EggName,
			definition.EggType,
			biomeName,
			definition.Rarity,
			spawnPart.Name,
			tostring(
				egg:GetAttribute("UID")
			)
		)
	)
end

--------------------------------------------------
-- RESPAWN
--------------------------------------------------

local function scheduleRespawn(spawnPart)
	if not spawnPart
		or not spawnPart.Parent then

		return
	end

	activeSpawnEggs[spawnPart] = nil

	task.delay(
		RESPAWN_TIME,
		function()
			if not spawnPart.Parent then
				return
			end

			spawnEgg(spawnPart)
		end
	)
end

--------------------------------------------------
-- ORIGIN SPAWN
--------------------------------------------------

local function getOriginSpawn(egg)
	local runtimeSpawn =
		eggOriginSpawn[egg]

	if runtimeSpawn
		and runtimeSpawn.Parent then

		return runtimeSpawn
	end

	local spawnPointName =
		egg:GetAttribute("SpawnPoint")

	if type(spawnPointName) ~= "string"
		or spawnPointName == "" then

		return nil
	end

	if duplicateSpawnNames[
		spawnPointName
		] then

		return nil
	end

	local spawnPart =
		spawnFolder:
		FindFirstChild(
			spawnPointName
		)

	if spawnPart
		and spawnPart:IsA("BasePart") then

		return spawnPart
	end

	return nil
end

--------------------------------------------------
-- DEPOSIT
--------------------------------------------------

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

	if egg:GetAttribute(
		"CarrierUserId"
		) ~= player.UserId then

		depositCooldown[player] = nil
		return
	end

	if egg:GetAttribute(
		"Carried"
		) ~= true then

		depositCooldown[player] = nil
		return
	end

	local spawnPart =
		getOriginSpawn(egg)

	local added =
		addEggToInventory(
			player,
			egg
		)

	if not added then
		depositCooldown[player] = nil

		warn(
			string.format(
				"[EggSystem] Deposit za %s nije uspeo; world egg nije uništen.",
				player.Name
			)
		)

		return
	end

	carriedEggs[player] = nil
	clearCarryMovementPenalty(player)

	runUIEvent:FireClient(
		player,
		false
	)

	eggOriginSpawn[egg] = nil

	egg:Destroy()

	if spawnPart then
		scheduleRespawn(
			spawnPart
		)
	else
		warn(
			string.format(
				"[EggSystem] Deposit od %s uspeo, ali original SpawnPoint nije pronađen. Respawn nije zakazan.",
				player.Name
			)
		)
	end

	task.delay(
		0.5,
		function()
			depositCooldown[player] = nil
		end
	)
end

--------------------------------------------------
-- LOBBY ZONE
--------------------------------------------------

lobbyZone.Touched:Connect(
	function(hit)
		local character =
			hit:
			FindFirstAncestorOfClass(
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

		if not humanoid
			or humanoid.Health <= 0 then

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
			depositEgg(player)
		end
	end
)

--------------------------------------------------
-- CHARACTER
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
				dropEgg(player)
			else
				clearCarryMovementPenalty(player)
			end
		end
	)
end

--------------------------------------------------
-- PLAYER
--------------------------------------------------

local function setupPlayer(player)
	getOrCreateInventory(player)

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
		local egg =
			carriedEggs[player]

		if egg
			and egg.Parent then

			local spawnPart =
				getOriginSpawn(egg)

			eggOriginSpawn[egg] = nil

			egg:Destroy()

			carriedEggs[player] = nil

			if spawnPart then
				scheduleRespawn(
					spawnPart
				)
			else
				warn(
					string.format(
						"[EggSystem] %s je izašao noseći egg, ali original SpawnPoint nije pronađen.",
						player.Name
					)
				)
			end
		end

		carriedEggs[player] = nil
		clearCarryMovementPenalty(player)
		depositCooldown[player] = nil
	end
)

--------------------------------------------------
-- INITIAL SPAWNS
--------------------------------------------------

scanSpawnPointNames()

for _, spawnPart in ipairs(
	spawnFolder:GetChildren()
	) do
	if spawnPart:IsA("BasePart") then
		spawnEgg(spawnPart)
	end
end

print(
	"[EggSystem] Phase 4 egg system loaded."
)
