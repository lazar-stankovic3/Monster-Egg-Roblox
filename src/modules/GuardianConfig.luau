--!strict

-- ReplicatedStorage.Modules.GuardianConfig
-- Faza 8. Guardian koristi Humanoid.WalkSpeed, nikada Player.Stats.Speed.

local GuardianConfig = {}

GuardianConfig.DefaultBiomeSpeed = 25
GuardianConfig.CatchDistance = 5
GuardianConfig.SafeZonePadding = 4
GuardianConfig.PathRecomputeSeconds = 0.35
GuardianConfig.ChaseTickSeconds = 0.05
GuardianConfig.WaypointReachDistance = 2
GuardianConfig.KnockbackSpeed = 95
GuardianConfig.KnockbackUpSpeed = 42
GuardianConfig.RagdollMinSeconds = 1
GuardianConfig.RagdollMaxSeconds = 5
GuardianConfig.RagdollGroundedSeconds = 0.4

local biomeBaseSpeed: { [string]: number } = {
	HatchlingFields = 25,
	Volcano = 45,
	Void = 70,
}
GuardianConfig.BiomeBaseSpeed = biomeBaseSpeed

-- Procentualni dodatak na biome baznu brzinu.
local raritySpeedBonus: { [string]: number } = {
	Common = 0,
	Uncommon = 0.025,
	Rare = 0.05,
	Epic = 0.10,
	Legendary = 0.20,
	Mythic = 0.30,
}
GuardianConfig.RaritySpeedBonus = raritySpeedBonus

function GuardianConfig.GetWalkSpeed(biomeName: unknown, rarityName: unknown): number
	local baseSpeed = if type(biomeName) == "string" then GuardianConfig.BiomeBaseSpeed[biomeName] else nil
	baseSpeed = if type(baseSpeed) == "number" then baseSpeed else GuardianConfig.DefaultBiomeSpeed
	local bonus = if type(rarityName) == "string" then GuardianConfig.RaritySpeedBonus[rarityName] else nil
	bonus = if type(bonus) == "number" then bonus else 0
	return baseSpeed * (1 + bonus)
end

return GuardianConfig
