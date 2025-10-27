-- Services --
local replicatedStorage = game:GetService("ReplicatedStorage")
local serverStorage = game:GetService("ServerStorage")
local players = game:GetService("Players")

-- Modules --
local framework = serverStorage:WaitForChild("Framework")
local modules = framework:WaitForChild("Modules")
local effects = require(modules:WaitForChild("Effects"))

-- Bindable Events --
local frameworkBindableEvents = framework:WaitForChild("Bindable Events")
local effectEvents = frameworkBindableEvents:WaitForChild("Effect System")
local giveEffectEvent = effectEvents:WaitForChild("GiveEffectEvent")

local bindableEvents = serverStorage:WaitForChild("Bindable Events")
local bloodlustBindableEvents = bindableEvents:WaitForChild("Bloodlust")
local startPageSpawningEvent = bloodlustBindableEvents:WaitForChild("StartPageSpawning")
local stopPageSpawningEvent = bloodlustBindableEvents:WaitForChild("EndPageSpawning")
local spawnLastPageEvent = bloodlustBindableEvents:WaitForChild("SpawnLastPageEvent")

-- Remote Events --
local remoteEvents = replicatedStorage:WaitForChild("Remote Events")
local bloodlustRemoteEvents = remoteEvents:WaitForChild("Bloodlust")
local openDaDoorEvent = bloodlustRemoteEvents:WaitForChild("OpenDaDoor")

-- Random Events --
local randomEvents = serverStorage:WaitForChild("Random Events")
local dayEvents = randomEvents:WaitForChild("Day")

local bloodlustEvent = dayEvents:WaitForChild("BLOODLUST_EVENT")
local deadlySunlightEvent = dayEvents:WaitForChild("DEADLY_SUNLIGHT_EVENT")

local nightEvents = randomEvents:WaitForChild("Night")
local powerOutageEvent = nightEvents:WaitForChild("POWER_OUTAGE_EVENT")

local anyEvents = randomEvents:WaitForChild("Any")
local droneSearchEvent = anyEvents:WaitForChild("DRONE_SEARCH_EVENT")
local naturalHazardEvent = anyEvents:WaitForChild("NATURAL_HAZARD_EVENT")

-- Objects --
local stateOfTheWorld = serverStorage:WaitForChild("State of the world")
local bloodlustActive = stateOfTheWorld:WaitForChild("bloodlust_active")

-- Settings --
local ambientLightSettings = serverStorage:WaitForChild("Ambient light settings")
local settings = ambientLightSettings:WaitForChild("Time Settings")

local transitionTime = settings:GetAttribute("transition_time_in_seconds")
local dayNightTime = settings:GetAttribute("day_night_time_in_seconds")

local eventDuration = 2 * (dayNightTime + transitionTime)

-- Flags --
local isDay = false

-- Functions --
local function giveSanguineRot()
	for _, player in ipairs(players:GetPlayers()) do
		giveEffectEvent:Fire(player, effects["Sanguine Rot"], eventDuration / 2)
	end
end

local function eventStarted()
	
	-- Set the bloodlust active event value to true.
	bloodlustActive.Value = true
	
	-- Turn off power for the duration of the event.
	powerOutageEvent:Fire(eventDuration)
	
	-- Enable deadly sunlight for the morning phase of the event.
	deadlySunlightEvent:Fire(eventDuration / 2)
	
	-- After the transition time passes (event is fully in daytime) enable light environmental hazards.
	task.wait(transitionTime)
	naturalHazardEvent:Fire(eventDuration / 2) -- Last through the sunset transition period.
	startPageSpawningEvent:Fire() -- Start spawning pages.
	
	-- After day passes, give everyone the sanguine rot effect and summon normal drones.
	task.wait(dayNightTime)
	giveSanguineRot()
	droneSearchEvent:Fire(eventDuration / 2, 3, 1)

	-- Once night time start, escalate the event even further. 
	task.wait(transitionTime)
	naturalHazardEvent:Fire(dayNightTime / 2, 5, 10, 7, 5)
	droneSearchEvent:Fire(dayNightTime, 2, 2)

	-- Halfway through the night, escalate everything further.
	task.wait(dayNightTime / 2)
	naturalHazardEvent:Fire(dayNightTime / 2, 1, 30, 5, 2)
	droneSearchEvent:Fire(dayNightTime / 2, 2, 2)
	spawnLastPageEvent:Fire() -- The players will have 90 seconds to get the last page.
	openDaDoorEvent:FireAllClients() -- Allow the door to open.
	
	-- The event is over.
	task.wait(dayNightTime / 2)
	bloodlustActive.Value = false
	stopPageSpawningEvent:Fire()
end

-- Events --
bloodlustEvent.Event:Connect(eventStarted)
