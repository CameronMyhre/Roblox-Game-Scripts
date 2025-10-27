-- Services --
local serverStorage = game:GetService("ServerStorage")
local runService = game:GetService("RunService")
local debris = game:GetService("Debris")

local tweenService = game:GetService("TweenService")
local despawnTween = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

-- Modules --
local framework = serverStorage:WaitForChild("Framework")
local modules = framework:WaitForChild("Modules")
local itemChances = require(modules:WaitForChild("ItemSpawnChances"))

-- Objects --
local objects = framework:WaitForChild("Objects")
local spawnableItems = objects:WaitForChild("SpawnableItems")
local spawnedItemsFolder
local itemSpawnLocations

-- Settings --
local spawnLocationFolderName = "ItemSpawnLocations"
local spawnItemFolderName = "SpawnedItems"

local despawnTime = 120
local itemSpawnTime = 10
local itemSpawnMaxVariance = 5 -- Makes item spawns less predictable.

-- Storage --
local items = {}
local spawnerTime = 0
local spawnedItems

-- Functions --
local function pickRandomItem()
	
	local randomNumber = math.random(1, 10000000)
	randomNumber /= 100000
	
	-- Find the random item.
	local chanceSum = 0
	for itemName, itemOdds in itemChances do
		
		-- Add the current item's odds to the chance sum
		chanceSum += itemOdds
		if randomNumber < chanceSum then
			return itemName
		end
	end
	
	return "VialOfAbstraction"
end

local function spawnItem()
	
	local randomItemName = pickRandomItem()
	local randomItem = spawnableItems[randomItemName]
	
	-- If the names were messed up, default to almond water.
	if not randomItem then
		randomItem = spawnableItems["AlmondWater"]
	end
	
	-- Random Spawn Location --
	local randomSpawnLocation = itemSpawnLocations[math.random(1, #itemSpawnLocations)]
	local randomItemClone = randomItem:Clone()
	randomItemClone.Parent = spawnedItems
	randomItemClone.Handle.CFrame = randomSpawnLocation.CFrame
	
	-- Item Details 
	local itemDetails = {
		time = tick(),
		item = randomItemClone
	}
	table.insert(items, itemDetails)
	
	-- Remove the item from the despawn queue once equipped.
	randomItemClone.Equipped:Once(function ()
		table.remove(items, table.find(items, itemDetails))
	end)
end

local function despawnItem(item: Instance)
	
	local model = Instance.new("Model")
	model.Parent = workspace
	
	for _, instance in ipairs(item:GetDescendants()) do
		
		-- Skip over the part if it isn't a part, mesh or union.
		if not (instance:IsA("Part") or instance:IsA("MeshPart") or instance:IsA("UnionOperation")) then
			continue
		end
		
		-- Reparent the object to prevent it from being grabbed/
		instance.Parent = model
		
		-- Fade the instance out.
		tweenService:Create(instance, despawnTween, {
			Transparency = 1
		}):Play()
	end
	
	-- Despawn the item and model.
	debris:AddItem(item, despawnTween.Time)
	debris:AddItem(model, despawnTween.Time)
end

local function periodic(deltaTime)
	
	local currentTime = tick()
	
	-- Remove all dead items.
	for index, item in items do
		
		-- Remove the item if it is time for it to despawn.
		if currentTime - item.time > despawnTime then
			despawnItem(item.item)
			table.remove(items, index)
		end
	end
	
	-- Increment spawner time.
	spawnerTime += deltaTime
	
	-- Attempt to spawn an item.
	if spawnerTime > itemSpawnTime then
		spawnerTime = 0 - math.random(0, itemSpawnMaxVariance)
		spawnItem()
	end
end

-- Setup item spawning.
local function setup()
	
	-- Verify that there are spawn locations in workspace. If not, destory this script as it has no purpose.
	local spawnLocationFolder = workspace:FindFirstChild(spawnLocationFolderName)
	if not spawnLocationFolder then
		script:Destroy()
		return
	end
	
	itemSpawnLocations = spawnLocationFolder:GetChildren()
	if #itemSpawnLocations == 0 then
		script:Destroy()
		return
	end
	
	-- Create a folder for spawned item to reside in, since they can be spawned.
	spawnedItems = Instance.new("Folder")
	spawnedItems.Name = "SpawnedItems"
	spawnedItems.Parent = workspace
	
	-- Allow items to start spawning.
	runService.Heartbeat:Connect(periodic)
end

-- Setup item spawning.
setup()