local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules:WaitForChild("ShopConfig"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))

local Service = {}
local started = false

local function publishPassOwnership(player, definition, owns)
	player:SetAttribute(definition.Attribute, owns == true)
end

local function refreshPasses(player)
	for _, definition in pairs(Config.GamePasses) do
		publishPassOwnership(player, definition, false)
		if definition.Enabled and type(definition.Id) == "number" and definition.Id > 0 then
			task.spawn(function()
				local ok, owns = pcall(
					MarketplaceService.UserOwnsGamePassAsync,
					MarketplaceService,
					player.UserId,
					definition.Id
				)
				if player.Parent == Players then
					if ok then
						publishPassOwnership(player, definition, owns)
					else
						warn("[ShopService] Game Pass ownership check failed for " .. player.Name)
					end
				end
			end)
		end
	end
end

local function processReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player or player:GetAttribute("PlayerDataStatus") ~= "Ready" then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local _, definition = Config.GetProductById(receiptInfo.ProductId)
	if not definition then
		warn("[ShopService] Unknown Developer Product ID: " .. tostring(receiptInfo.ProductId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local ok, granted = pcall(
		PlayerDataService.ProcessProductReceipt,
		player,
		tostring(receiptInfo.PurchaseId),
		definition.Grant
	)
	if not ok then
		warn("[ShopService] Receipt processing failed: " .. tostring(granted))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	return if granted
		then Enum.ProductPurchaseDecision.PurchaseGranted
		else Enum.ProductPurchaseDecision.NotProcessedYet
end

function Service.Start()
	if started then return end
	started = true
	PlayerDataService.Start()

	Players.PlayerAdded:Connect(refreshPasses)
	for _, player in ipairs(Players:GetPlayers()) do refreshPasses(player) end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then return end
		local _, definition = Config.GetPassById(passId)
		if definition and definition.Enabled then
			publishPassOwnership(player, definition, true)
		end
	end)

	-- Roblox dozvoljava samo jedan ProcessReceipt callback u iskustvu.
	MarketplaceService.ProcessReceipt = processReceipt
	print("[ShopService] Shop controller loaded.")
end

return Service
