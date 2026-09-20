local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local event = ReplicatedStorage:WaitForChild("TreadmillJumpEvent", 15)
if not event then warn("[Treadmill] Server did not initialize TreadmillJumpEvent"); return end
local lastJump = 0
UserInputService.JumpRequest:Connect(function()
	if not player:GetAttribute("TreadmillLocked") then return end
	local now = os.clock()
	if now - lastJump < 0.2 then return end
	lastJump = now
	event:FireServer()
end)
event.OnClientEvent:Connect(function()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		humanoid.Jump = true
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)
