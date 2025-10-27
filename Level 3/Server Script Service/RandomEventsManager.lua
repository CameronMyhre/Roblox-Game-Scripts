-- Services --
local serverStorage = game:GetService("ServerStorage")
local runService = game:GetService("RunService")

-- Bindable Events --
local bindableEvents = serverStorage:FindFirstChild("Bindable Events")
local spawnRandomEventEvent = bindableEvents:WaitForChild("SpawnRandomEvent")

local randomEvents = serverStorage:FindFirstChild("Random Events")
local dayEventsFolder = randomEvents:FindFirstChild("Day")
local nightEventsFolder = randomEvents:FindFirstChild("Night")
local anyEventsFolder = randomEvents:FindFirstChild("Any")

local dayEvents = dayEventsFolder:GetChildren()
local nightEvents = nightEventsFolder:GetChildren()
local anyEvents = anyEventsFolder:GetChildren()

-- Bindable  Events --
local bindableEvents = serverStorage:WaitForChild("Bindable Events")
local queueRandomEventEvent = bindableEvents:WaitForChild("QueueRandomEvent")

-- Settings --
local generalSettings = randomEvents:WaitForChild("General Event Settings")
local eventWeights =   generalSettings:WaitForChild("Event Weights")

local min_event_chance = generalSettings:GetAttribute("min_event_chance")
local max_event_chance = generalSettings:GetAttribute("max_event_chance")
local daily_event_chance_change = generalSettings:GetAttribute("daily_event_chance_change") -- The amount the % event change will increase by each day/night cycle

local day_weight = eventWeights:GetAttribute("day_weight")
local night_weight = eventWeights:GetAttribute("night_weight")
local any_weight = eventWeights:GetAttribute("any_weight")

local stateOfTheWorld = serverStorage:WaitForChild("State of the world")

-- Storage --
local event_chance = min_event_chance

--[[
Event Queue Format: 
	{
		eventName = "event name",
		isNight: boolean,
		isAny boolean,
		event = event,
	}
--]]
local eventQueue = {}


-- Functions --

--[[
	Returns the chance an event will occur (the sum of the event type's weight times each event's weight) 
	Additionally, returns an array with events in it that account for each event's weight.
]]--
local function getChanceAndWeightedEvents(events, eventWeight)
	
	-- Initialize return values
	local eventChance = 0
	local eventPool = {}
	
	-- Loop through all of the events 
	for _,event in ipairs(events) do

		-- Ensure that each child is actually an event
		if not event:IsA("BindableEvent") then
			continue
		end
		
		-- Get the weight attribute from the event. 
		local weight = event:GetAttribute("weight")
		
		-- If the event doesn't have a weight then send a warning to the dev console and set weight to 1.
		if weight == nil then
			warn(event.Name .. " does not have a weight attached to it.")
			weight = 1
		end
		
		-- Add the event to the eventPool weight times.
		for i = 0, weight, 1 do
			table.insert(eventPool, event)
		end
		
		-- Add the event's weight times the event types weight to the total event chance
		eventChance += (weight * eventWeight)
	end
	
	-- Return the event chance
	return eventChance, eventPool
end

--[[
	Selects a random event to be run.
]]--
local function selectRandomEvent(isNight)

	-- Determine which events can occur based on the time of day
	local timeEvents
	local timeEventWeight
	if isNight then
		timeEvents = nightEvents
		timeEventWeight = night_weight
	else
		timeEvents = dayEvents
		timeEventWeight = day_weight
	end
	
	-- Get the chance for each type of event to occur.
	local timeEventChance, timeEventsPool = getChanceAndWeightedEvents(timeEvents, timeEventWeight)
	local anyEventChance, anyEventsPool = getChanceAndWeightedEvents(anyEvents, any_weight)
	
	-- Calculate the sum of both weights (the total pool of outcomes)
	local chanceSum = timeEventChance + anyEventChance
	
	-- Determine which kind of event will occur. This is done by generating a random number that doesn't
	-- exceed the maximum number of outcomes. 
	local randomNumber = math.random(0, chanceSum)
	
	-- Set the poll of events can occur based on the random number generated.
	local eventsPool
	if randomNumber <= timeEventChance then
		eventsPool = timeEventsPool
	else
		eventsPool = anyEventsPool
	end
	
	-- Get a random event from the pool of random events
	local randomEvent = eventsPool[math.random(1, #eventsPool)]
	
	-- Fire the random event
	randomEvent:Fire()
end

local function selectQueuedEvent(isNight: boolean)
	
	local eventFound = false
	local foundIndex
	for index, eventData in ipairs(eventQueue) do
		
		-- Check if the event can occur based on the time of day.
		if not eventData.isNight and isNight and not eventData.isAny then
			continue
		end
		
		-- A valid event was found.
		eventFound = true
		foundIndex = index
		
		-- Fire the event.
		eventData.bindableEvent:Fire()
		break
	end
	
	-- Remove the event for the list of events.
	if foundIndex then
		table.remove(eventQueue, foundIndex)
	end
	
	-- Return whether or not an event was found.
	return eventFound
end

--[[
	Add half the daily event change to the event chance (Each time this function is run 1/2 a day passes). 
	Then, if the new values exceeds the maximum  event chance, set it to the max value. After that, return.
]]--
local function increaseEventChance() 
	event_chance += daily_event_chance_change / 2
	if event_chance > max_event_chance then
		event_chance = max_event_chance
	end
end

--[[
	Decide whether or not an event will occur. If not, then increase the chance that an event will occur next time
	if adding onto the current chance an event will occur will not exceed the maximum event chance.
]]--
local function determineIfAnEventWIllOccur(isNight) 

	-- Generate a random number
	local randomNumber = math.random(0, 100)

	-- Check if the number we generated is greater than our event chance. If it is, then an event will not occur and
	-- we will add to the chance that an event will occur next time (if possible). Otherwise, spawn an event.
	if randomNumber > event_chance then
		increaseEventChance()
		return
	end

	-- Start an event --
	selectRandomEvent(isNight)
end

local function attemptToSelectEvent(isNight: boolean)

	-- First attempt to spawn a queued event.
	local spawnedQueuedEvent = selectQueuedEvent(isNight)

	-- If an event was not spawned, then spawn a random event.
	if not spawnedQueuedEvent then
		determineIfAnEventWIllOccur(isNight)
	end
end


local function addEventToQueue(eventData)
	
	-- Add the event to the event queue.
	local formattedData = {}
	
	-- Determine if the event is a time event or an any event.
	if eventData.eventType == "day" then
		formattedData.isNight = false
		formattedData.isAny = false
	elseif eventData.eventType == "night" then
		formattedData.isNight = true
		formattedData.isAny = false
	else
		formattedData.isNight = false
		formattedData.isAny = true
	end
	
	-- Store the bindable event.
	formattedData.bindableEvent = eventData.bindableEvent
	
	-- Add the event data to the queue.
	table.insert(eventQueue, formattedData)
end

--- Events ----
spawnRandomEventEvent.Event:Connect(attemptToSelectEvent)
queueRandomEventEvent.Event:Connect(addEventToQueue)