-- Match the local Humanoid/animation controller to the server's hit state.
-- The client never decides who gets hit or the launch velocity.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local function setup(character)
	local humanoid = character:WaitForChild("Humanoid")
	local connection, stepConnection
	local saved = nil
	local function restore()
		if stepConnection then stepConnection:Disconnect(); stepConnection = nil end
		if not saved then return end
		for motor, enabled in pairs(saved.motors) do
			if motor.Parent then motor.Enabled = enabled end
		end
		if saved.animate and saved.animate.Parent then saved.animate.Enabled = saved.animateEnabled end
		if humanoid.Parent then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, saved.gettingUp)
			humanoid.PlatformStand = false
			if humanoid.Health > 0 then humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end
		end
		saved = nil
	end
	local function update()
		if character:GetAttribute("GuardianRagdoll") ~= true then restore(); return end
		if saved then return end
		local animate = character:FindFirstChild("Animate")
		saved = { motors = {}, gettingUp = humanoid:GetStateEnabled(Enum.HumanoidStateType.GettingUp), animate = nil }
		if animate and animate:IsA("LocalScript") then
			saved.animate, saved.animateEnabled = animate, animate.Enabled
			animate.Enabled = false
		end
		-- Server tags only originally enabled body motors belonging to this hit.
		local function enforce()
			for _, joint in ipairs(character:GetDescendants()) do
				if (joint:IsA("Motor6D") or joint:IsA("AnimationConstraint"))
					and joint:GetAttribute("GuardianRagdollMotor") == true then
					saved.motors[joint] = true
					joint.Enabled = false
				end
			end
			local animator = humanoid:FindFirstChildOfClass("Animator")
			if animator then
				for _, track in ipairs(animator:GetPlayingAnimationTracks()) do track:Stop(0) end
			end
			humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
			humanoid.PlatformStand = true
			humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		end
		enforce()
		stepConnection = RunService.PreSimulation:Connect(enforce)
	end
	connection = character:GetAttributeChangedSignal("GuardianRagdoll"):Connect(update)
	local removing
	removing = player.CharacterRemoving:Connect(function(oldCharacter)
		if oldCharacter ~= character then return end
		connection:Disconnect()
		restore()
		removing:Disconnect()
	end)
	update()
end

player.CharacterAdded:Connect(setup)
if player.Character then task.spawn(setup, player.Character) end
