-- Services --
local serverStorage = game:GetService("ServerStorage")
local runService = game:GetService("RunService")

-- Bindable Events --
local randomEvents = serverStorage:WaitForChild("Random Events")
local anyEvents = randomEvents:WaitForChild("Any")
local environmentalHazardsEvent = anyEvents:WaitForChild("NATURAL_HAZARD_EVENT")

local bindableEvents = serverStorage:WaitForChild("Bindable Events")
local spawnNaturalHazardEvent = bindableEvents:WaitForChild("SpawnNaturalHazardEvent")

-- Settings --
local ambientLightSettings = serverStorage:WaitForChild("Ambient light settings")
local lightSettings = ambientLightSettings:WaitForChild("Time Settings")
local transitionTime = lightSettings:GetAttribute("transition_time_in_seconds")
local dayNightTime = lightSettings:GetAttribute("day_night_time_in_seconds")

local defaultTime = transitionTime + dayNightTime

local frequency = 10 -- Seconds 
local count = 3
local radius = 10
local cooldown = 15

-- Strage --
local remainingActiveTime = 0
local accumulatedTime = 0

local usedFrequency = frequency
local usedCount = count
local usedRadius = radius
local useCooldown = cooldown

-- Functions --
local function periodic(deltaTime: number)
	
	-- If the event is not active, return.
	if remainingActiveTime < 0 then
		return
	end	
	
	-- Increment accumulated time and the active time.
	accumulatedTime += deltaTime
	remainingActiveTime -= deltaTime
	
	-- Spawn in the hazards if enough time has passed.
	if accumulatedTime > usedFrequency then
		
		--Reset the accumulated time.
		accumulatedTime = 0
		
		-- Spawn the environmental hazards.
		spawnNaturalHazardEvent:Fire(usedRadius, usedCount, useCooldown)
	end

end

local function startEvent(time: number?, newFrequency: number?, newCount: number?, mewRadius: number?, newCooldown: number?)
	
	-- Update values.
	remainingActiveTime = time or defaultTime
	accumulatedTime = 0
	
	usedFrequency = newFrequency or frequency
	usedCount = newCount or count
	usedRadius = mewRadius or radius
	useCooldown = newCooldown or cooldown
end

-- Events --
environmentalHazardsEvent.Event:Connect(startEvent)
runService.Heartbeat:Connect(periodic)