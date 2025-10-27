-- Services --
local players = game:GetService("Players")
local datastoreService = game:GetService("DataStoreService")

local serverStorage = game:GetService("ServerStorage")
local replicatedStorage = game:GetService("ReplicatedStorage")

-- Bindable Events --
local framework = serverStorage:WaitForChild("Framework")
local bindableEvents = framework:WaitForChild("Bindable Events")
local datastoreEvents = bindableEvents:WaitForChild("Datastore")
local dataLoadedEvent = datastoreEvents:WaitForChild("DataLoaded")

local playerEvents = bindableEvents:WaitForChild("Player")
local frameworkPlayerAdded = playerEvents:WaitForChild("FrameworkPlayerAdded") -- Allows for the framework to be loaded for players already in the game.

-- Remote Events --
local remoteFramework = replicatedStorage:WaitForChild("Framework")
local remoteEvents = remoteFramework:WaitForChild("Remote Events")
local remoteDatastoreEvents = remoteEvents:WaitForChild("Datastore")
local remoteDataLoadedEvent = remoteDatastoreEvents:WaitForChild("DataLoaded")

-- Settings --
local plrDataFolderName = "plrData"

local equippedFlashlightValueName = "EquippedFlashlight"
local flashlightSaveKey = "-equippedFlashlight"
local defaultFlashlightName = "regular"

local doNotSaveFolderName = "DoNotSave"

-- Storage --
local setupPlayers = {}

-- Datastores --
local cosmeticItemDatastore = datastoreService:GetDataStore("cosmetics")

-- Functions --
local function saveData(plr: Player)
	
	-- If the player's data is corrupted, then do not save.
	if plr:FindFirstChild(doNotSaveFolderName) then
		return
	end
	
	-- Attempt to find the player's data.
	local plrDataFolder = plr:FindFirstChild(plrDataFolderName)
	if not plrDataFolder then
		return
	end
	
	-- Save the player's data.
	local success, err = pcall(function ()
		
		-- Attempt to find the value for the equipped flashlight so it can be saved.
		local flashlightValue = plrDataFolder:FindFirstChild(equippedFlashlightValueName)
		if not flashlightValue then
			return
		end
		
		local flashlightSaveValue = flashlightValue.Value or defaultFlashlightName
		cosmeticItemDatastore:SetAsync(tostring(plr.UserId) .. flashlightSaveKey, flashlightSaveValue)
	end)
	
	-- Output the status of the operation.
	if success then
		print(plr.Name .. "'s data has been saved successfully!")
	else
		warn("Something went wrong saving " .. plr.Name .. "'s data.")
	end
	
	-- Remove the player form the list of setup data.
	local playerIndex = table.find(setupPlayers, plr)
	if playerIndex then
		table.remove(setupPlayers, playerIndex)
	end
end

-- Event Functions --
local function loadData(plr: Player)
	
	-- If the player already has data, then do not load it again.
	if table.find(setupPlayers, plr) then
		return
	end
	
	-- Try and get the player's data from datastore
	local equippedFlashlight
	local success, err = pcall(function()
		equippedFlashlight = cosmeticItemDatastore:GetAsync(tostring(plr.UserId) .. flashlightSaveKey)
	end)
	
	-- Check whether or not the above function was successful --
	if not success then
		local doNotSave = Instance.new("Folder")
		doNotSave.Name = doNotSaveFolderName
		doNotSave.Parent = plr
		warn(err)
	else
		print("Data loaded for " .. plr.Name .. "!")
	end
	
	-- Create a folder to store all of the player's data.
	local plrDataFolder = Instance.new("Folder")
	plrDataFolder.Name = plrDataFolderName
	plrDataFolder.Parent = plr
	
	-- Convert all player data into tangible values. This makes it easy for other scripts to interact with data.
	local equippedFlashlightValue = Instance.new("StringValue")
	equippedFlashlightValue.Name = equippedFlashlightValueName
	equippedFlashlightValue.Value = equippedFlashlight or defaultFlashlightName
	equippedFlashlightValue.Parent = plrDataFolder
	
	-- The player's data is setup.
	table.insert(setupPlayers, plr)
	
	-- Fire events to inform other scripts that the player's data has been loaded.
	dataLoadedEvent:Fire(plr)
	remoteDataLoadedEvent:FireClient(plr)
end

-- Events --
players.PlayerAdded:Connect(loadData)
frameworkPlayerAdded.Event:Connect(loadData)

players.PlayerRemoving:Connect(saveData)

-- Save player's data when the server closes to prevent data loss --
game:BindToClose(function ()
	for _,plr in ipairs(players:GetChildren()) do
		saveData(plr)
	end
end)