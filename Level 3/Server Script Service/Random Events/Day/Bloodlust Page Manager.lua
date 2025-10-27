-- Services --
local serverStorage = game:GetService("ServerStorage")
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local runService = game:GetService("RunService")

local soundService = game:GetService("SoundService")
local teleportService = game:GetService("TeleportService")

-- Bindable Events --
local bindableEvents = serverStorage:WaitForChild("Bindable Events")
local bloodlustBindableEvents = bindableEvents:WaitForChild("Bloodlust")
local startPageSpawningEvent = bloodlustBindableEvents:WaitForChild("StartPageSpawning")
local stopPageSpawningEvent = bloodlustBindableEvents:WaitForChild("EndPageSpawning")
local spawnLastPageEvent = bloodlustBindableEvents:WaitForChild("SpawnLastPageEvent")

-- Bindable Events --
local framework = serverStorage:WaitForChild("Framework")
local frameworkBindableEvents = framework:WaitForChild("Bindable Events")
local playerEvents = frameworkBindableEvents:WaitForChild("Player")
local deathEvent = playerEvents:WaitForChild("PlayerDied")

-- Remote Events --
local remoteEvents = replicatedStorage:WaitForChild("Remote Events")
local bloodlustEvents = remoteEvents:WaitForChild("Bloodlust")
local spawnPageEvent = bloodlustEvents:WaitForChild("SpawnPageEvent")
local despawnPageEvent = bloodlustEvents:WaitForChild("DespawnPageEvent")
local pageGrabbedEvent = bloodlustEvents:WaitForChild("PageGrabbedEvent")
local toggleTeleportVFXEvent = bloodlustEvents:WaitForChild("ToggleTeleportVFX")

-- Remote Events --
local remoteFramework = replicatedStorage:WaitForChild("Framework")
local frameworkRemoteEvents = remoteFramework:WaitForChild("Remote Events")
local dialogEvents = frameworkRemoteEvents:WaitForChild("DialogEvents")
local dialogEvent = dialogEvents:WaitForChild("DialogEvent")

-- Objects --
local quests = workspace:WaitForChild("Quests")
local bloodlustQuest = quests:WaitForChild("Bloodlust")
local anOldPage = bloodlustQuest:WaitForChild("An old page")
local pageObject = anOldPage:WaitForChild("Page")
local proximityPrompt = pageObject:WaitForChild("ProximityPrompt")

local nullSpawnPageLocation = bloodlustQuest:WaitForChild("NullSpawnPoint")

local invisibleParts = workspace:WaitForChild("Invisible Parts")
local pageSpawnLocations = invisibleParts:WaitForChild("Page Spawns")
local stationSpawnLocations = pageSpawnLocations:WaitForChild("Station Spawns")

local defaultSpawn = workspace:WaitForChild("SpawnLocation")

-- SFX --
local sparkleSound = soundService:WaitForChild("Sparkle Sound")

-- Settings --
local dialogTemplate = "~!~SlowFade~ %s/%s Pages~"
local secondToLastDialog = "~!~SmallWave,Fade~ Eight of nine, yet the final page has yet to manifest~"
local lastPageSpawnedText = "~!~SmallWave,Fade~ The final page has materialized~"
local requiredAmountOfPages = 9

local overlapParams = OverlapParams.new()
overlapParams.FilterDescendantsInstances = {pageSpawnLocations}
overlapParams.FilterType = Enum.RaycastFilterType.Include

local despawnRange = 1001
local despawnTimeCheck = 3 -- Seconds

local pageMaxActivationDistance = 10

local maxSpawnRange = 750
local minSpawnRange = 100

local stationCompletionPlaceId = 77456619525834
local regularCompletionPlaceId = 72022060623705

-- Flags --
local isSpawning = false
local canSpawnFinalPage = false

-- Storage --
local playerProgress = {}
local accumulatedTime = 0

local heartbeatConnection, grabConnection

-- Functions --
local function newPlayerData()
	return { 
		numPages = 0, 
		numStationPages = 0,
		spawnLocation = nil
	}
end

local function spawnPage(plr: Player, previousSpawn: Part?)
	
	-- Figure out where the player is.
	local playerPosition
	
	-- Attempt to get the player's character.
	local character = plr.Character
	if character then
		playerPosition = character:FindFirstChild("HumanoidRootPart")
	end
	
	-- If no root part could be found, use the spawn location.
	if not playerPosition then
		playerPosition = plr.RespawnLocation or defaultSpawn
	end
	
	-- Get nearby spawn locations.
	local nearbySpawnLocations = workspace:GetPartBoundsInRadius(
		playerPosition.CFrame.Position,
		maxSpawnRange,
		overlapParams
	)
	
	-- Filter out the previous spawn.
	if previousSpawn then
		table.remove(nearbySpawnLocations, table.find(nearbySpawnLocations, previousSpawn))
	end
	
	-- Sort out close and far spawns. We prioritize far spawns to make things more challenging.
	local closeSpawns = {}
	local farSpawns = {}
	for _, spawnLocation in ipairs(nearbySpawnLocations) do
		if (spawnLocation.Position - playerPosition.CFrame.Position).Magnitude > minSpawnRange then
			table.insert(farSpawns, spawnLocation)
		else
			table.insert(closeSpawns, spawnLocation)
		end
	end
	
	-- Determine where the page will spawn.
	local spawnLocation
	if #farSpawns > 0 then
		spawnLocation = farSpawns[math.random(#farSpawns)]
	elseif #closeSpawns > 0 then
		spawnLocation = closeSpawns[math.random(#closeSpawns)]
	else
		warn("Error: No valid spawns found.")
		spawnLocation = nullSpawnPageLocation
	end
	
	-- Store the data for the player.
	local plrData = playerProgress[plr]
	if not plrData then
		plrData = newPlayerData()
		playerProgress[plr] = plrData
	end
	plrData.spawnLocation = spawnLocation
	
	-- Spawn the page for the player.
	spawnPageEvent:FireClient(plr, spawnLocation.CFrame, plrData.numPages)
end

local function pageGrabbed(plr: Player)
	
	-- Verify that the player is near the page.
	local character = plr.Character
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end
	
	local plrData = playerProgress[plr]
	local spawnLocation = plrData.spawnLocation
	local distanceToPage = (spawnLocation.CFrame.Position - humanoidRootPart.CFrame.Position).Magnitude
	if distanceToPage > pageMaxActivationDistance then
		return
	end
	
	-- Prevent overgrabbing pages.
	if plrData.numPages >= requiredAmountOfPages then 
		return 
	end

	if spawnLocation.Parent == stationSpawnLocations then
		plrData.numStationPages += 1
	end
	
	-- Increment the number of pages for the player.
	plrData.numPages += 1
	
	-- Spawn another page in (if the player doesn't have all of them and it's not the last page).
	if plrData.numPages < (requiredAmountOfPages - 1) or (canSpawnFinalPage and plrData.numPages < requiredAmountOfPages) then
		spawnPage(plr, spawnLocation)
		dialogEvent:FireClient(plr, string.format(dialogTemplate, plrData.numPages, requiredAmountOfPages), Enum.Font.Gotham, 3)
	elseif plrData.numPages == (requiredAmountOfPages - 1) and not canSpawnFinalPage then
		dialogEvent:FireClient(plr, secondToLastDialog, Enum.Font.Gotham, 3)
		despawnPageEvent:FireClient(plr)
	end
	
	-- Handle completing the event.
	if plrData.numPages == requiredAmountOfPages then
		
		-- Despawn the page and toggle the teleport effects.
		despawnPageEvent:FireClient(plr)
		toggleTeleportVFXEvent:FireClient(plr)
		
		-- Figure out which place the player should be teleported to.
		local teleportId = regularCompletionPlaceId
		if plrData.numStationPages == requiredAmountOfPages then
			teleportId = stationCompletionPlaceId
		end
		
		-- Wait a bit, then teleport the player.
		task.wait(7)
		teleportService:Teleport(teleportId, plr)
	end
end

-- Roblox Events --
local function periodic(deltaTime)
	
	-- Return if the event is over.
	if not isSpawning then
		return
	end
	
	-- Increment accumulated time.
	accumulatedTime += deltaTime
	
	-- Return if the accumulated time is not enough to check if pages should be despawned.
	if accumulatedTime < despawnTimeCheck then
		return
	end
	
	for player, data in pairs(playerProgress) do
		
		-- If there is no spawn location, there cannot be a page to despawn.
		if not data.spawnLocation then
			continue
		end
		
		-- Find the player's character.
		local character = player.Character
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then
			despawnPageEvent:FireClient(player) -- Despawn the page if the player does not have a humanoid root part.
			continue
		end
		
		-- Compute the distance from the player to the page.
		local distanceToPage = (data.spawnLocation.CFrame.Position - humanoidRootPart.CFrame.Position).Magnitude
		
		-- Despawn the page if the player is too far away.
		if distanceToPage > despawnRange and 
			(data.numPages ~= (requiredAmountOfPages - 1) or canSpawnFinalPage) and
			data.numPages ~= requiredAmountOfPages then -- Player doesn't have the max # of pages.
			despawnPageEvent:FireClient(player) -- Despawn the page if the player is too far away.
			spawnPage(player, data.spawnLocation)
		end
	end
	
	-- Reset the accumulated time.
	accumulatedTime = 0
end

local function playerAdded(plr: Player)
	
	-- If there is existing data for the player, do nothing.
	if playerProgress[plr] or not isSpawning then
		return
	end
	
	-- Setup the player's data.
	playerProgress[plr] = newPlayerData()
	spawnPage(plr)
end

local function playerRemoving(plr: Player)
	
	-- If the player has no data, do nothing.
	if not playerProgress[plr] or not isSpawning then
		return
	end
	
	-- Clear the player's data. (Doesn't reset on rejoin)
	playerProgress[plr] = newPlayerData()
end

local function playerDied(plr: Player)
	
	-- If the player has no data, do nothing.
	if not playerProgress[plr] or not isSpawning then
		return
	end
	
	-- Clear the player's data. (Doesn't reset on rejoin)
	playerProgress[plr] = newPlayerData()
	
	-- Despawn the current spawn page.
	despawnPageEvent:FireClient(plr)
end

-- Event Setup --
local function setupPlayerData(plr: Player)

	-- Format data for the player's progress.
	playerProgress[plr] = newPlayerData()
	
	-- Spawn in a page for the player.
	spawnPage(plr)
end

local function startPageSpawns()
	
	-- Toggle the flag for spawning.
	isSpawning = true
	canSpawnFinalPage = false

	-- Reset all relevant values.
	accumulatedTime = 0
	table.clear(playerProgress)
	
	-- Play a sound to indicate a change in the event.
	sparkleSound:Play()
	
	-- Setup the event for all the players.
	for _, plr in players:GetPlayers() do
		setupPlayerData(plr)
	end
	
	-- Connect up necessary events.
	heartbeatConnection = runService.Heartbeat:Connect(periodic)
	grabConnection = pageGrabbedEvent.OnServerEvent:Connect(pageGrabbed)
end

local function endPageSpawn()
	
	-- Toggle the flag for spawning.
	isSpawning = false
	canSpawnFinalPage = false

	-- Reset all relevant values.
	accumulatedTime = 0
	table.clear(playerProgress)
	
	-- Despawn all pages.
	despawnPageEvent:FireAllClients()
	
	-- Disconnect all events.
	heartbeatConnection:Disconnect()
	grabConnection:Disconnect()
end

local function spawnLastPage()
	
	-- Allow the last page to spawn in.
	canSpawnFinalPage = true
	
	-- Spawn the last page for all players who have the maximum number of pages.
	for player, data in pairs(playerProgress) do
		
		-- Spawn in a page if the player has 1 less than the maximum number of pages.
		if data.numPages == (requiredAmountOfPages - 1) then
			spawnPage(player, data.spawnLocation)
			dialogEvent:FireClient(player, lastPageSpawnedText, Enum.Font.Gotham, 4)
		end
	end
end

-- Events --
startPageSpawningEvent.Event:Connect(startPageSpawns)
stopPageSpawningEvent.Event:Connect(endPageSpawn)	
spawnLastPageEvent.Event:Connect(spawnLastPage)

players.PlayerAdded:Connect(playerAdded)
players.PlayerRemoving:Connect(playerRemoving)
deathEvent.Event:Connect(playerDied)