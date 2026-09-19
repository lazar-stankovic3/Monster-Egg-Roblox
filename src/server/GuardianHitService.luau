-- Server-only temporary ragdoll. Original joints and movement settings are restored.
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("GuardianConfig"))
local HitService = {}
local active = {}
local RunService = game:GetService("RunService")

function HitService.Hit(player, origin, droppedEgg)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or active[character] then return end
	active[character] = true
	local oldRotate, oldStand, oldNeck = humanoid.AutoRotate, humanoid.PlatformStand, humanoid.RequiresNeck
	local oldGettingUp = humanoid:GetStateEnabled(Enum.HumanoidStateType.GettingUp)
	local motors, parts, temporary, colliders = {}, {}, {}, {}
	local function keep(instance)
		table.insert(temporary, instance)
		return instance
	end
	-- Disable the neck death check before releasing any joints (R6 and R15).
	humanoid.RequiresNeck = false
	humanoid.AutoRotate = false
	humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
	humanoid.PlatformStand = true
	for _, part in ipairs(character:GetChildren()) do
		if part:IsA("BasePart") then
			parts[part] = part.CanCollide
			part.CanCollide = false
			if part ~= root then
				-- Humanoid may overwrite limb collisions. Separate welded colliders
				-- keep the relaxed body resting on the floor in Physics state.
				local collider = keep(Instance.new("Part"))
				collider.Name = "GuardianRagdollCollider"
				collider.Size = part.Size * 0.75
				collider.Transparency = 1
				collider.Massless = true
				collider.CanCollide = true
				collider.CanTouch = false
				collider.CanQuery = false
				collider.CFrame = part.CFrame
				collider.Parent = character
				local weld = Instance.new("WeldConstraint")
				weld.Part0, weld.Part1 = part, collider
				weld.Parent = collider
				table.insert(colliders, collider)
			end
		end
	end
	for _, motor in ipairs(character:GetDescendants()) do
		-- AvatarJointUpgrade uses AnimationConstraint instead of Motor6D.
		-- Part0/Part1/C1 are read-only compatibility aliases on that class.
		-- Temporarily replace either joint with our socket, leaving the rig's
		-- original attachments and animation settings untouched.
		if (motor:IsA("Motor6D") or motor:IsA("AnimationConstraint"))
			and motor.Enabled and motor.Part0 and motor.Part1
			and parts[motor.Part0] ~= nil and parts[motor.Part1] ~= nil
			and motor.Part0 ~= root and motor.Part1 ~= root then
			local a = keep(Instance.new("Attachment"))
			-- Both attachment pivots must coincide in the current animated pose.
			a.CFrame = motor.Part0.CFrame:ToObjectSpace(motor.Part1.CFrame * motor.C1)
			a.Parent = motor.Part0
			local b = keep(Instance.new("Attachment"))
			b.CFrame = motor.C1
			b.Parent = motor.Part1
			local socket = keep(Instance.new("BallSocketConstraint"))
			socket.Attachment0, socket.Attachment1 = a, b
			socket.LimitsEnabled = true
			socket.UpperAngle = if motor.Name == "Neck" then 40 else 80
			socket.TwistLimitsEnabled = true
			socket.TwistLowerAngle, socket.TwistUpperAngle = -55, 55
			socket.Parent = motor.Part0
			table.insert(motors, motor)
			motor:SetAttribute("GuardianRagdollMotor", true)
			motor.Enabled = false
		end
	end
	-- Body parts hit the ground but cannot fling one another through self-collisions.
	local body = {}
	for part in pairs(parts) do table.insert(body, part) end
	for _, collider in ipairs(colliders) do table.insert(body, collider) end
	for i = 1, #body do
		for j = i + 1, #body do
			local constraint = keep(Instance.new("NoCollisionConstraint"))
			constraint.Part0, constraint.Part1 = body[i], body[j]
			constraint.Parent = root
		end
	end
	-- Drop enables egg collisions before the launch. Ignore only this egg vs
	-- this character (including accessories and the new ragdoll colliders).
	-- All constraints are installed before the first physics wait and cleaned
	-- with the ragdoll; the egg still collides with terrain and other players.
	if droppedEgg and droppedEgg.Parent then
		local characterParts = {}
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then table.insert(characterParts, part) end
		end
		for _, eggPart in ipairs(droppedEgg:GetDescendants()) do
			if eggPart:IsA("BasePart") then
				for _, characterPart in ipairs(characterParts) do
					local constraint = keep(Instance.new("NoCollisionConstraint"))
					constraint.Name = "GuardianDroppedEggNoCollision"
					constraint.Part0, constraint.Part1 = eggPart, characterPart
					constraint.Parent = root
				end
			end
		end
	end
	local away = root.Position - origin
	away = Vector3.new(away.X, 0, away.Z)
	if away.Magnitude < 0.01 then away = Vector3.new(0, 0, -1) end
	local velocity = away.Unit * Config.KnockbackSpeed + Vector3.new(0, Config.KnockbackUpSpeed, 0)
	character:SetAttribute("GuardianRagdollJointCount", #motors)
	if #motors == 0 then
		warn("[GuardianHitService] No enabled body Motor6D/AnimationConstraint joints: " .. character.Name)
	end
	character:SetAttribute("GuardianRagdoll", true)

	task.spawn(function()
		-- Let physics split the disabled motors into separate assemblies first.
		RunService.Heartbeat:Wait()
		if character.Parent and player.Character == character and humanoid.Health > 0 and root.Parent then
			local assemblies = {}
			for part in pairs(parts) do
				if part.Parent then
					local assembly = part.AssemblyRootPart or part
					if not assemblies[assembly] then
						assemblies[assembly] = true
						if assembly:CanSetNetworkOwnership() then assembly:SetNetworkOwner(nil) end
						assembly:ApplyImpulse((velocity - assembly.AssemblyLinearVelocity) * assembly.AssemblyMass)
					end
				end
			end
			humanoid:ChangeState(Enum.HumanoidStateType.Physics)
			root.AssemblyAngularVelocity = Vector3.yAxis:Cross(away.Unit) * 7
		end
		local began, grounded = os.clock(), 0
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local ignored = { character }
		if droppedEgg and droppedEgg.Parent then table.insert(ignored, droppedEgg) end
		params.FilterDescendantsInstances = ignored
		params.RespectCanCollide = true
		while character.Parent and player.Character == character and humanoid.Health > 0
			and os.clock() - began < Config.RagdollMaxSeconds do
			local dt = task.wait(0.1)
			if not root.Parent then break end
			local landed = false
			if os.clock() - began >= Config.RagdollMinSeconds and root.AssemblyLinearVelocity.Magnitude < 12 then
				for part in pairs(parts) do
					if part.Parent and part ~= root and workspace:Raycast(part.Position,
						Vector3.new(0, -(part.Size.Magnitude * 0.5 + 0.35), 0), params) then
						landed = true
						break
					end
				end
			end
			grounded = if landed then grounded + dt else 0
			if grounded >= Config.RagdollGroundedSeconds then break end
		end
		-- Restore this character only; a delayed recovery must never alter a respawn.
		for _, motor in ipairs(motors) do
			if motor.Parent then
				motor.Enabled = true
				motor:SetAttribute("GuardianRagdollMotor", nil)
			end
		end
		for _, instance in ipairs(temporary) do instance:Destroy() end
		for part, collide in pairs(parts) do
			if part.Parent then
				part.CanCollide = collide
				part.AssemblyAngularVelocity = Vector3.zero
				if humanoid.Health > 0 then part.AssemblyLinearVelocity = Vector3.zero end
			end
		end
		if humanoid.Parent then
			humanoid.RequiresNeck = oldNeck
			humanoid.AutoRotate = oldRotate
			humanoid.PlatformStand = oldStand
			humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, oldGettingUp)
			if player.Character == character and humanoid.Health > 0 and not oldStand then
				humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
		end
		for part in pairs(parts) do
			if part.Parent and part:CanSetNetworkOwnership() then part:SetNetworkOwnershipAuto() end
		end
		character:SetAttribute("GuardianRagdoll", nil)
		character:SetAttribute("GuardianRagdollJointCount", nil)
		active[character] = nil
	end)
end

return HitService
