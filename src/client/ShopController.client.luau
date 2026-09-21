local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Config = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ShopConfig"))

local currentShop
local connections = {}

local function disconnectAll()
	for _, connection in ipairs(connections) do connection:Disconnect() end
	table.clear(connections)
end

local function setButtonText(button, text)
	if button:IsA("TextButton") then
		button.Text = text
		return
	end
	for _, descendant in ipairs(button:GetDescendants()) do
		if descendant:IsA("TextLabel") and string.find(string.lower(descendant.Name), "price") then
			descendant.Text = text
			return
		end
	end
end

local function setUnavailable(button, text)
	button.Active = false
	button.AutoButtonColor = false
	setButtonText(button, text)
end

local function loadPrice(button, id, infoType)
	task.spawn(function()
		local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, id, infoType)
		if currentShop and button:IsDescendantOf(currentShop) then
			if ok and info and info.IsForSale ~= false then
				setButtonText(button, "R$ " .. tostring(info.PriceInRobux or "?"))
			else
				setUnavailable(button, "UNAVAILABLE")
			end
		end
	end)
end

local function bindProduct(section, cardName, definition)
	local card = section:FindFirstChild(cardName)
	local button = card and card:FindFirstChild("BuyButton")
	if not button or not button:IsA("GuiButton") then
		warn("[ShopController] Missing BuyButton for " .. cardName)
		return
	end
	local productName = card:FindFirstChild("ProductName")
	if productName and productName:IsA("TextLabel") and definition.DisplayName then
		productName.Text = definition.DisplayName
	end
	if type(definition.Id) ~= "number" or definition.Id <= 0 then
		setUnavailable(button, "SET PRODUCT ID")
		return
	end
	loadPrice(button, definition.Id, Enum.InfoType.Product)
	table.insert(connections, button.Activated:Connect(function()
		MarketplaceService:PromptProductPurchase(player, definition.Id)
	end))
end

local function bindPass(section, cardName, definition)
	local card = section:FindFirstChild(cardName)
	local button = card and card:FindFirstChild("BuyButton")
	if not button or not button:IsA("GuiButton") then
		warn("[ShopController] Missing BuyButton for " .. cardName)
		return
	end
	if not definition.Enabled then
		setUnavailable(button, "COMING SOON")
		return
	end
	if type(definition.Id) ~= "number" or definition.Id <= 0 then
		setUnavailable(button, "SET PASS ID")
		return
	end
	loadPrice(button, definition.Id, Enum.InfoType.GamePass)
	table.insert(connections, button.Activated:Connect(function()
		if player:GetAttribute(definition.Attribute) == true then return end
		MarketplaceService:PromptGamePassPurchase(player, definition.Id)
	end))
	local function refreshOwned()
		if player:GetAttribute(definition.Attribute) == true then
			setUnavailable(button, "OWNED")
		end
	end
	table.insert(connections, player:GetAttributeChangedSignal(definition.Attribute):Connect(refreshOwned))
	refreshOwned()
end

local function bind(shop)
	if currentShop == shop then return end
	disconnectAll()
	currentShop = shop

	local frame = shop:WaitForChild("Frame", 10)
	local bottom = frame and frame:WaitForChild("BottomFrame", 10)
	local scrolling = bottom and bottom:WaitForChild("ScrollingFrame", 10)
	local passes = scrolling and scrolling:FindFirstChild("PassesSection")
	local speed = scrolling and scrolling:FindFirstChild("SpeedSection")
	local coins = scrolling and scrolling:FindFirstChild("CoinsSection")
	if not passes or not speed or not coins then
		warn("[ShopController] Shop hierarchy is missing PassesSection, SpeedSection or CoinsSection")
		return
	end

	for cardName, definition in pairs(Config.GamePasses) do
		bindPass(passes, cardName, definition)
	end
	for cardName, definition in pairs(Config.DeveloperProducts) do
		local section = if string.find(cardName, "COINS") then coins else speed
		bindProduct(section, cardName, definition)
	end

	print("[ShopController] Existing Shop UI connected.")
end

local existing = playerGui:FindFirstChild("Shop")
if existing and existing:IsA("ScreenGui") then task.spawn(bind, existing) end
playerGui.ChildAdded:Connect(function(child)
	if child.Name == "Shop" and child:IsA("ScreenGui") then task.spawn(bind, child) end
end)
