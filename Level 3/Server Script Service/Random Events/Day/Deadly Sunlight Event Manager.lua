-- Services --
local serverStorage = game:GetService("ServerStorage")
local runService = game:GetService("RunService")
local collectionService = game:WaitForChild("CollectionService")
local players = game:GetService("Players")
local debris = game:GetService("Debris")

-- Modules --
local framework = serverStorage:WaitForChild("Framework")
local frameworkModules = framework:WaitForChild("Modules")
local effects = require(frameworkModules:WaitForChild("Effects"))

-- Bindable Events --
local frameworkBindableEvents = framework:WaitForChild("Bindable Events")
local effectEvents = frameworkBindableEvents:WaitForChild("Effect System")
local giveEffectEvent = effectEvents:WaitForChild("GiveEffectEvent")

local bindableEvents = serverStorage:WaitForChild("Bindable Events")
local deadlySunlightPulseEvent = bindableEvents:WaitForChild("DeadlySunlightPulseEvent")

local randomEvents = serverStorage:FindFirstChild("Random Events")
local dayEvents = randomEvents:FindFirstChild("Day")
local DEADLY_SUNLIGHT_EVENT = dayEvents:WaitForChild("DEADLY_SUNLIGHT_EVENT")

-- Objects --
local invisibleParts = workspace:WaitForChild("Invisible Parts")

local deadlySunlightZone = serverStorage:WaitForChild("Deadly Sunlight Zones")
local fireEffect = script:WaitForChild("Fire")

-- Settings --
local ambientLightSettings = serverStorage:WaitForChild("Ambient light settings")
local settings = ambientLightSettings:WaitForChild("Time Settings")

local transitionTime = settings:GetAttribute("transition_time_in_seconds")
local dayNightTime = settings:GetAttribute("day_night_time_in_seconds")

local deadlySunlightDelay = 4 -- Seconds
local deadlySunlightDuration = 3 -- Seconds
local deadlySunlightTimer = 12 -- Seconds

local defaultOverlapParams = OverlapParams.new()
defaultOverlapParams.MaxParts = 100

local burnTag = "burnTag"
local tagRemovalTime = 8 -- Seconds
local fireRemovalTime = 2

local hitDamage = -2.5

-- Flags --
local deadlySunlightEnabled = false

-- Storage --
local runServiceConnection
local accumulatedTime = 0

-- Functions --
local function getPlayersInSunlight() : {Player}
	
	local playersInSunlight = {}
	for _, player in ipairs(players:GetChildren())  do
		
		-- Skip over non-player elements.
		if not player:IsA("Player") then
			continue
		end
		
		-- If the player does not have a character, skip them.
		local character = player.Character
		if not character then
			continue
		end
		
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then
			continue
		end
		
		-- Adjust the default overlap params.
		local overlapParams = OverlapParams.new()
		overlapParams.MaxParts = defaultOverlapParams.MaxParts
		overlapParams.FilterDescendantsInstances = {character}
		
		-- Loop through all of the overlapping player parts and see if any of them are the sunlight hitboxes.
		local partsBoundInPlayer = workspace:GetPartBoundsInBox(humanoidRootPart.CFrame, humanoidRootPart.Size, defaultOverlapParams)
		for _,part in ipairs(partsBoundInPlayer) do
			if part.Parent == deadlySunlightZone then
				table.insert(playersInSunlight, player)
				continue
			end
		end
	end
	
	return playersInSunlight
end

local function burnPlayer(plr : Player)
		
	-- Return if the player has the burn tag.
	if collectionService:HasTag(plr, burnTag) then
		return
	end

	-- Give the player the burn tag.
	collectionService:AddTag(plr, burnTag)
	task.delay(tagRemovalTime, function()
		collectionService:RemoveTag(plr, burnTag)
	end)
	
	-- Get and kill the humanoid.
	local character = plr.Character
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	giveEffectEvent:Fire(plr, effects.Burning, 2)
	
	-- Apply burn effects/
	local fireClones = {}
	for _, part in ipairs(character:GetChildren()) do
		if part:IsA("Part") or part:IsA("MeshPart") or part:IsA("Union") then
			
			local fireClone = fireEffect:Clone()
			fireClone.Parent = part
			
			-- If the player isn't dead, remove the fire after the invincibility time expires.
			if humanoid.Health > 0 then
				debris:AddItem(fireClone, 2 + fireClone.Lifetime.Max)
			end
			
			table.insert(fireClones, fireClone)
		end
	end
	
	collectionService:AddTag(plr, burnTag)
	task.delay(tagRemovalTime, function()
		
		-- Allow the player to be damaged again.
		collectionService:RemoveTag(plr, burnTag)
	end)
	
	task.delay(fireRemovalTime, function ()
		
		-- Remove particles in a smoother manner.
		for _, fireClone in ipairs(fireClones) do
			fireClone.Enabled = false
		end
	end)
end

local function burnPlayersInSunlight()
	
	local playersInSunlight = getPlayersInSunlight()
	
	for _,player in ipairs(playersInSunlight) do
		burnPlayer(player)
	end
end

-- Event Functions --
local function periodic(deltaTime)
	
	-- Add the change in time to the accumulator.
	accumulatedTime += deltaTime
	
	-- Disable deadly sunlight if the effect duration is over.
	if deadlySunlightEnabled and accumulatedTime > (deadlySunlightDelay + deadlySunlightDuration) then
		deadlySunlightEnabled = false
	end
	
	if deadlySunlightEnabled and accumulatedTime > deadlySunlightDelay then
		
		-- Logic to kill players.
		burnPlayersInSunlight()
	end
	
	-- Check if the accumulated time is greater than or equal to the delay time.
	if accumulatedTime >= deadlySunlightTimer then
		
		-- Reset the accumulated time.
		accumulatedTime = 0
		
		-- Deadly sunlight is now enabled.
		deadlySunlightEnabled = true
		
		-- Toggle effects
		deadlySunlightPulseEvent:Fire()
	end
end


local function deadlySunlightStarted(duration: number?)
	
	-- Wait for the base effects to load in.
	task.wait(5)
	
	-- Reset necessary values.
	accumulatedTime = 0

	-- Connect the RunService event.
	runServiceConnection = runService.Heartbeat:Connect(periodic)
	task.wait(duration or (dayNightTime + transitionTime))
	runServiceConnection:Disconnect()
end

-- Events --
DEADLY_SUNLIGHT_EVENT.Event:Connect(deadlySunlightStarted)

-- On start reparent the deadly sunlight zones to workspace!
deadlySunlightZone.Parent = invisibleParts