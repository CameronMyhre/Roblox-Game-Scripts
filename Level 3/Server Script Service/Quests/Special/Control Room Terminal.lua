-- Services --
local serverStorage = game:GetService("ServerStorage")
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local collectionService = game:GetService("CollectionService")
local badgerService = game:GetService("BadgeService")

-- Remote Events --
local remoteEvents = replicatedStorage:WaitForChild("Remote Events")
local controlRoomEvents = remoteEvents:WaitForChild("ControlRoom")
local activateEventEvent = controlRoomEvents:WaitForChild("ActivateEvent")
local eventDataUpdated = controlRoomEvents:WaitForChild("EventDataUpdated")

-- Remote Functions --
local remoteFunctions = replicatedStorage:WaitForChild("Remote Functions")
local getEventDataFunction = remoteFunctions:WaitForChild("GetAllEventData")

-- Bindable Events --
local randomEvents = serverStorage:WaitForChild("Random Events")
local anyEventsFolder = randomEvents:WaitForChild("Any")
local dayEventsFolder = randomEvents:WaitForChild("Day")
local nightEventsFolder = randomEvents:WaitForChild("Night")

local bindableEvents = serverStorage:WaitForChild("Bindable Events")
local queueRandomEventEvent = bindableEvents:WaitForChild("QueueRandomEvent")

-- Objects --
local quests = workspace:WaitForChild("Quests")
local controlRoomQuest = quests:WaitForChild("Control Room Quest")
local controlRoomTerminalQuest = controlRoomQuest:WaitForChild("Screen")

-- Settings --
local eventCooldown = 300 -- 5 minute delay between events
local eventSettings = {
	bloodlust = {
		event = dayEventsFolder:WaitForChild("BLOODLUST_EVENT"),
		lastUsed = nil,
		cooldown = 1800,
		type = "day"
	},
	deadlySunlight = {
		event = dayEventsFolder:WaitForChild("DEADLY_SUNLIGHT_EVENT"),
		lastUsed = nil,
		cooldown = 900,
		type = "day"
	},
	fog = {
		event = dayEventsFolder:WaitForChild("FOG_EVENT"),
		lastUsed = nil,
		cooldown = 600,
		type = "day"
	},
	rain = {
		event = dayEventsFolder:WaitForChild("RAIN_EVENT"),
		lastUsed = nil,
		cooldown = 600,
		type = "day"
	},

	fullMoon = {
		event = nightEventsFolder:WaitForChild("FULL_MOON_EVENT"),
		lastUsed = nil,
		cooldown = 600,
		type = "night"
	},
	newMoon = {
		event = nightEventsFolder:WaitForChild("NEW_MOON_EVENT"),
		lastUsed = nil,
		cooldown = 600,
		type = "night"
	},
	powerOutage = {
		event = nightEventsFolder:WaitForChild("POWER_OUTAGE_EVENT"),
		lastUsed = nil,
		cooldown = 900,
		type = "night"
	},

	drones = {
		event = anyEventsFolder:WaitForChild("DRONE_SEARCH_EVENT"),
		lastUsed = nil,
		cooldown = 900,
		type = "any"
	},
	environmentalHazards = {
		event = anyEventsFolder:WaitForChild("NATURAL_HAZARD_EVENT"),
		lastUsed = nil,
		cooldown = 900,
		type = "any"
	}
}

local administrationTag = "ControlRoomUnlocked"
local voidstoneCompletedTag = "fuelQuestFinished"

local badgeID = 2147738892

local maxDistanceFromScreen = 45 -- Studs

-- Storage --
local obtainedData = {}
local lastEventActivated

--- Functions ---
-- Event Activation --
local function activateEvent(plr: Player, eventName: string)

	-- Get the event settings.
	local eventSettings = eventSettings[eventName]
	if not eventSettings then
		return "invalidEvent"
	end

	-- Make sure the player is in the control room.
	local character = plr.Character
	if not character then
		return
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") 	-- Ensure that the player has a humanoid root part.
	if not humanoidRootPart then
		return
	end

	local distanceToScreen = (humanoidRootPart.CFrame.Position - controlRoomTerminalQuest.CFrame.Position).Magnitude
	if distanceToScreen > maxDistanceFromScreen then
		return "Exploiting :3"
	end

	-- Verify that the player has all of the quest completion tags.
	if not collectionService:HasTag(plr, voidstoneCompletedTag) or not collectionService:HasTag(character, administrationTag) then
		return "Exploiting :3"
	end
	
	-- Give the player the badge if they haven't already been given it.
	if not badgerService:UserHasBadgeAsync(plr.UserId, badgeID) then
		badgerService:AwardBadge(plr.UserId, badgeID)
	end
	
	if eventSettings.lastUsed and os.time() - eventSettings.lastUsed < eventSettings.cooldown then
		return "eventCooldown"
	end

	-- Verify that the overall cooldown isn't active.
	if lastEventActivated and lastEventActivated > os.time() - eventCooldown then
		return "serverCooldown"
	end

	-- Activate the event.
	local eventFormattedData = {
		eventType = eventSettings.type,
		bindableEvent = eventSettings.event
	}
	
	queueRandomEventEvent:Fire(eventFormattedData)

	-- Update the last used time.
	eventSettings.lastUsed = os.time()
	lastEventActivated = os.time()

	-- Format the event data and send it to the clients.
	local formattedData = {
		eventName = eventName,
		currentCooldown = eventSettings.cooldown,
		eventType = eventSettings.type
	}

	-- Tell all the clients that the data has been updated.
	eventDataUpdated:FireAllClients(formattedData)
end

-- Retrieving Data --
local function getEventData(plr: Player)

	-- Prevent the server from making costly function calls.
	if table.find(obtainedData, plr) then
		return
	end

	local data = {}
	for name, settings in pairs(eventSettings) do

		local cooldownTime = 0
		if settings.lastUsed then
			cooldownTime = settings.cooldown - (os.time() - settings.lastUsed)
		end

		-- Format the data to be easy to read.
		local formattedData = {
			eventName = name,
			currentCooldown = cooldownTime,
			eventType = settings.type
		}

		-- Add the formatted data to the data table.
		table.insert(data, formattedData)
	end

	-- Calculate the remaining server cooldown.
	local remainingCooldown = 0
	if eventSettings.lastUsed then
		remainingCooldown = eventCooldown - os.time() - eventSettings.lastUsed
		remainingCooldown = math.max(0, remainingCooldown)
	end

	-- Return the formatted data.
	return data, eventCooldown, remainingCooldown
end

local function playerRemoving(plr: Player)

	-- Remove the player from the list of players who obtained data when they leave.
	local plrIndex = table.find(obtainedData, plr)
	if plrIndex then
		table.remove(obtainedData, plrIndex)
	end
end

-- Events --
getEventDataFunction.OnServerInvoke = getEventData
activateEventEvent.OnServerEvent:Connect(activateEvent)
players.PlayerRemoving:Connect(playerRemoving)