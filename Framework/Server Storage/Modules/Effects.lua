-- Services --
local textChatService = game:GetService("TextChatService")

-- Defer channel hookup so we never block the whole script
local generalChannel
task.spawn(function()
	-- Make sure the experience is using the new TextChatService
	if textChatService.ChatVersion ~= Enum.ChatVersion.TextChatService then
		warn("[Framework Chat]: TextChatService is not enabled (using LegacyChatService). Default Roblox chat will be shown.")
		return
	end

	-- Try to get RBXGeneral without hanging forever
	local textChannels = textChatService:FindFirstChild("TextChannels") or textChatService:WaitForChild("TextChannels", 5)
	if not textChannels then
		warn("[Framework Chat]: TextChannels container not found on server.")
		return
	end

	generalChannel = textChannels:FindFirstChild("RBXGeneral") or textChannels:WaitForChild("RBXGeneral", 5)
	if not generalChannel then
		warn("[Framework Chat]: RBXGeneral channel not found/created; leaving default chat behavior.")
		return
	end

	-- Block default delivery only after we have the channel
	generalChannel.ShouldDeliverCallback = function(message, textSource)
		return false
	end
end)
local textService = game:GetService("TextService")
local serverStorage = game:GetService("ServerStorage")
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")

local badgeService = game:GetService("BadgeService")
local marketplaceService = game:GetService("MarketplaceService")

-- Modules --
local remoteFramework = replicatedStorage:WaitForChild("Framework")
local modules = remoteFramework:WaitForChild("Modules")
local configModules = modules:WaitForChild("Configs")
local titleModules = configModules:WaitForChild("Titles")

local titleRequirements = require(titleModules:WaitForChild("TitleRequirements"))
local titlePresets = require(titleModules:WaitForChild("TitlePresets"))

-- Bindable Events --
local framework = serverStorage:WaitForChild("Framework")
local bindableEvents = framework:WaitForChild("Bindable Events")
local playerEvents = bindableEvents:WaitForChild("Player")
local characterLoaded = playerEvents:WaitForChild("CharacterLoaded")
local frameworkPlayerAdded = playerEvents:WaitForChild("FrameworkPlayerAdded") -- Allows for the framework to be loaded for players already in the game.

-- Remote Events --
local remoteEvents = remoteFramework:WaitForChild("Remote Events")

local chatEvents = remoteEvents:WaitForChild("Chat")
local displayChatTextEvent = chatEvents:WaitForChild("DisplayChatTextEvent")
local loadChatHistoryEvent = chatEvents:WaitForChild("LoadChatHistoryEvent")

-- Objects --
local overheadGui = script:WaitForChild("OverheadGui")

-- Settings --
local defaultTitle = titlePresets.default
local maxTimeoutCount = 3
local maxHistoryLength = 50
local groupId = 11725215

local noTitleGUIOffset = Vector3.new(0, 2, 0)

-- Storage --
local playerTitles = {} -- array[player] = string
local messageHistory = {}

-- Functions --
--[[
Returns the lowest number in an array.
]]
local function getLowestValueInTable(array: {number})

	local lowestNumber = math.huge
	for _, number in ipairs(array) do
		if number < lowestNumber then
			lowestNumber = number
		end
	end

	return lowestNumber
end

-- Get the player's title.
local function playerOwnsTitle(player: Player, titleData: titlePresets.titlePresetType): boolean
	
	-- Quick check --
	if titleData.requirementType == titleRequirements.none then
		return true
	end
	
	-- Keep track of how many gamepasses are owned by the player.
	-- If this is required of the title, return if the gamepass condition is met.
	local gamepassesOwned = 0
	if titleData.requiredGamepasses then
		for _, gamepassID in ipairs(titleData.requiredGamepasses) do
			if marketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassID) then
				gamepassesOwned += 1
			end
		end
		
		-- Since gamepasses are required, check if the requirment type is owning any gamepass. If this is true, return if they own at least 1 gamepass.
		if titleData.requirementType == titleRequirements.requireAnyGamepass then
			return gamepassesOwned > 0
		end
		
		-- If all gamepasses are required, return if all gamepasses are owned.
		if titleData.requirementType == titleRequirements.requireAllGamepasses then
			return gamepassesOwned == #titleData.requiredGamepasses
		end
	end
	
	-- Keep track of how many badges are owned by the player.
	-- If this is required of the title, return if the gamepass condition is met.	
	local badgesOwned = 0
	if titleData.requiredBadges then
		for _, badgeID in ipairs(titleData.requiredBadges) do
			if badgeService:UserHasBadgeAsync(player.UserId, badgeID) then
				badgesOwned += 1
			end
		end
		
		-- If owning at least 1 badge is required, return if that condition is true.
		if titleData.requirementType == titleRequirements.requireAnyBadge then
			return badgesOwned > 0
		end
		
		-- If owning all badges is required, return if that is true.
		if titleData.requirementType == titleRequirements.requireAllBadges then
			return badgesOwned == #titleData.requiredBadges
		end
	end
	
	-- Get the player's rank in the BU group, if it is required of this title.
	if titleData.requiredGroupRanks then
		
		local playerRank = player:GetRankInGroup(groupId)

		-- If the player's rank is the same as the required rank, return true.
		if titleData.requirementType == titleRequirements.requireSpecificGroupRank and table.find(titleData.requiredGroupRanks, playerRank) then
			return true
		end

		-- If a certain rank or higher is required, determine if that condition is met.
		if titleData.requirementType == titleRequirements.requireGroupRankOrHigher then
			
			local lowestRank = titleData.requiredGroupRanks[1]
			if #titleData.requiredGroupRanks > 1 then
				lowestRank = getLowestValueInTable(titleData.requiredGroupRanks)
			end
			
			return playerRank >= lowestRank
		end
	end

	-- No checks passed, player does not own the title.
	return false
end

local function getPlayerTitle(player: Player)
	
	local highestPlayerTitleName = "null"
	local highestTitlePriority = -1
	
	-- Loop through all of the available titles and see if the player owns them.
	for titleName, titleData in pairs(titlePresets) do
		
		-- If the priority is less than the current highest priority title, we don't care.
		if titleData.priority < highestTitlePriority then
			continue
		end
		
		-- See if the player owns the title.
		if playerOwnsTitle(player, titleData) then
			highestPlayerTitleName = titleName
			highestTitlePriority = titleData.priority
		end
	end
	
	-- Store a refference to the player's title. This allows us to easily get the player's title later.
	playerTitles[player] = highestPlayerTitleName
end

local function clearPlayerTitleData(player: Player)
	playerTitles[player] = nil
end

-- Overhead Gui --
local function waitForDataToLoad(player)
	
	-- Try to wait a bit for the player's data to load in.
	local plrTitleName, plrTitleData
	while task.wait(maxTimeoutCount) do

		plrTitleName = playerTitles[player]
		if plrTitleName then
			plrTitleData = titlePresets[plrTitleName]
			break
		end
		task.wait(.2)
	end
	
	-- Return what might have been found.
	return plrTitleData 
end

local function getPlayerTitleData(player: Player): titlePresets.titlePresetType
	
	-- Grab the player data if it exists, otherwise, wait for it to load.
	local plrTitleName = playerTitles[player]
	local plrTitleData: titlePresets.titlePresetType
	if plrTitleName then
		plrTitleData = titlePresets[plrTitleName]
	else
		plrTitleData = waitForDataToLoad(player)
	end
	
	-- Return the found data.
	return plrTitleData or defaultTitle
end

local function giveGui(player)
	
	-- Get the player's character.
	local character = player.Character

	-- If the player already has overhead GUI, don't give it to them.
	local head = character:WaitForChild("Head")
	if head and head:FindFirstChild("OverheadGui") then 
		return 
	end

	-- Clone the overhead GUI to the player.
	local guiClone = overheadGui:Clone()
	guiClone.Username.Text = player.Name
	
	-- Grab the player's title data.
	local plrTitleData = getPlayerTitleData(player)
	
	-- Setup the GUI based on the found data.
	if plrTitleData.overheadGui then 
		guiClone.Container.Role.Text = plrTitleData.title
		guiClone.Container.Role.TextColor3 = plrTitleData.tagColor

		guiClone.Container.Icon.Image = plrTitleData.overheadRoleImage
		guiClone.Container.Icon.ImageColor3 = plrTitleData.tagColor
		guiClone.Container.Icon.UIGradient.Color = ColorSequence.new(plrTitleData.tagColor, plrTitleData.chatColor)
		
		-- Handle empty image IDs.
		if plrTitleData.overheadRoleImage == "" or not plrTitleData.overheadRoleImage then
			guiClone.Container.Icon.Visible = false
		end
	else
		guiClone.StudsOffset = noTitleGUIOffset
		guiClone.Container:Destroy()
	end

	guiClone.Parent = character.Head
end

-- Chat Tags Function --
local function applyGroupChatProperties(player: Player, titleData: titlePresets.titlePresetType, text)
	local borderColor = string.format("rgb(%d, %d, %d)", titleData.strokeColor.R * 255, titleData.strokeColor.G * 255, titleData.strokeColor.B * 255)
	local tagColor = string.format("rgb(%d, %d, %d)", titleData.tagColor.R * 255, titleData.tagColor.G * 255, titleData.tagColor.B * 255)
	local colorTag = string.format("rgb(%d, %d, %d)", titleData.chatColor.R * 255, titleData.chatColor.G * 255, titleData.chatColor.B * 255)
	local formattedText = string.format(
		"<stroke color=\"%s\" joins=\"miter\" thickness=\"%s\" transparency=\"0.25\"><font family=\"%s\" color= \"%s\"><b>[%s] %s</b>: </font></stroke> <font color=\"%s\">%s</font>",
		borderColor,
		titleData.strokeThickness,
		titleData.fontType,
		tagColor,
		titleData.title,
		player.Name,
		colorTag,
		text:GetNonChatStringForBroadcastAsync()
	)
	return formattedText
end

local function applyDefaultChatProperties(player, titleData, text)
	local rankColorTag = string.format("rgb(%d, %d, %d)", titleData.tagColor.R * 255, titleData.tagColor.G * 255, titleData.tagColor.B * 255)
	local colorTag = string.format("rgb(%d, %d, %d)", titleData.chatColor.R * 255, titleData.chatColor.G * 255, titleData.chatColor.B * 255)
	local formattedText = string.format(
		"<font color= \"%s\">%s: </font> <font color=\"%s\">%s</font>",
		rankColorTag,
		player.Name,
		colorTag,
		text:GetNonChatStringForBroadcastAsync()
	)
	return formattedText
end

local function appendTextToHistory(text) 
	if #messageHistory >= maxHistoryLength then
		table.remove(messageHistory, 1)
	end
	table.insert(messageHistory, text)
end

local function chatted(player, text)
	
	-- Filter the player's text.
	local filteredText = textService:FilterStringAsync(text, player.UserId)
	local playerTitleData = getPlayerTitleData(player)
	
	local chatMessage = filteredText
	if playerTitleData == defaultTitle then 
		chatMessage = applyDefaultChatProperties(player, playerTitleData, filteredText)
	else
		chatMessage = applyGroupChatProperties(player, playerTitleData, filteredText)
	end

	appendTextToHistory(chatMessage)
	displayChatTextEvent:FireAllClients(chatMessage)
end

local function loadChatHistory(player)
	for _, message in ipairs(messageHistory) do
		displayChatTextEvent:FireClient(player, message)
	end
end

-- Events --
players.PlayerAdded:Connect(getPlayerTitle)
frameworkPlayerAdded.Event:Connect(getPlayerTitle)

players.PlayerRemoving:Connect(clearPlayerTitleData)

characterLoaded.Event:Connect(giveGui)
displayChatTextEvent.OnServerEvent:Connect(chatted)
loadChatHistoryEvent.OnServerEvent:Connect(loadChatHistory)

-- Prevent any incoming chat from being delivered unstyled:
generalChannel.ShouldDeliverCallback = function(message, textSource)
	return false
end
