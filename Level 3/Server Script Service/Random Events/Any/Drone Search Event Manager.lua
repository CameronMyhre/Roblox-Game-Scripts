-- Services --
local serverStorage = game:GetService("ServerStorage")
local debris = game:GetService("Debris")

-- Bindable Events --
local randomEvents = serverStorage:WaitForChild("Random Events")
local anyEvents = randomEvents:WaitForChild("Any")
local droneSpawnEvent = anyEvents:WaitForChild("DRONE_SEARCH_EVENT")

-- Objects --
local invisibleParts = workspace:WaitForChild("Invisible Parts")
local droneSpawns = invisibleParts:WaitForChild("Drone Spawns")
local factorySpawns = droneSpawns:WaitForChild("Factory")
local stationSpawns = droneSpawns:WaitForChild("Station")

local spawnableDroneFolder = serverStorage:WaitForChild("Drone")
local l1Drones = spawnableDroneFolder:WaitForChild("L1")
local l2Drones = spawnableDroneFolder:WaitForChild("L2")

local droneFolder = workspace:WaitForChild("Drones")
local factoryDroneFolder = droneFolder:WaitForChild("Floor 1")
local stationDroneFolder = droneFolder:WaitForChild("Floor 2")

-- Settings --
local ambientLightSettings = serverStorage:WaitForChild("Ambient light settings")
local settings = ambientLightSettings:WaitForChild("Time Settings")

local transitionTime = settings:GetAttribute("transition_time_in_seconds")
local dayNightTime = settings:GetAttribute("day_night_time_in_seconds")

local eventDuration = dayNightTime + transitionTime
local defaultQuantity = 1
local defaultLevel = 1

-- Functions --
local function getRandomSpawn(isFactory: boolean)
	
	-- Determine which location the drone will be spawned in.
	local spawnFolder = factorySpawns
	if not isFactory then
		spawnFolder = stationSpawns
	end
	
	-- Get the children of the spawn folder.
	local possibleSpawns = spawnFolder:GetChildren()
	local randomIndex = math.random(1, #possibleSpawns)
	
	-- Return a random spawn.
	return possibleSpawns[randomIndex]
end

local function spawnDrone(droneModel: Model, despawnTime: number)
	
	-- Clone the drone in,
	local droneClone = droneModel:Clone()
	
	-- Determine where the drone should spawn and grab a random spawn location. Default to spawning in the factory.
	local isFactory = droneClone:GetAttribute("isFactory")
	if isFactory == nil then
		isFactory = true
	end

	local randomSpawn = getRandomSpawn(isFactory)
	droneClone:PivotTo(randomSpawn.CFrame)
	
	-- Figure out where the drone should be stored.
	local parentFolder = factoryDroneFolder
	if not isFactory then
		parentFolder = stationDroneFolder
	end
	
	-- Move the drone to the desired spawn location.
	droneClone.Parent = parentFolder
	
	-- Enable the governing script after 5 seconds to give players proper time to prepare.
	task.delay(5, function ()
		droneClone:FindFirstChild("Pathfinding").Enabled = true
	end)
	
	-- Delete the drone after the event ends. TODO: Rework to explode the drone...?
	debris:AddItem(droneClone, despawnTime)
end

local function startEvent(duration: number, droneQuantity: number?, droneLevel: number?)
	
	local duration = duration or eventDuration
	local quantity = droneQuantity or defaultQuantity
	local level = droneLevel or defaultLevel
	
	local droneFolder = l1Drones
	if level == 2 then
		droneFolder = l2Drones
	end
	
	-- Spawn all drones from the desired folder, using the quantity specified.
	local drones = droneFolder:GetChildren()
	for _, drone in ipairs(drones) do
		
		-- Spawn n drones.
		for i = 1, quantity, 1 do
			spawnDrone(drone, duration)
			task.wait()
		end
	end
end

-- Events --
droneSpawnEvent.Event:Connect(startEvent)