local Players = game:GetService("Players")

local player = Players.LocalPlayer

local RUN_ANIMATION_ID = "rbxassetid://110696808533851"
local WALK_ANIMATION_ID = "rbxassetid://507777826"

local function setupCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")
	local animate = character:WaitForChild("Animate")

	local run = animate:FindFirstChild("run")

	if not run then
		warn("Run animation nije pronađena")
		return
	end

	local runAnim = run:FindFirstChild("RunAnim")

	if not runAnim then
		warn("RunAnim nije pronađen")
		return
	end

	runAnim.AnimationId = player:GetAttribute("SlowMode") and WALK_ANIMATION_ID or RUN_ANIMATION_ID
end

if player.Character then
	setupCharacter(player.Character)
end

player.CharacterAdded:Connect(setupCharacter)

player:GetAttributeChangedSignal("SlowMode"):Connect(function()
	if player.Character then
		setupCharacter(player.Character)
	end
end)
