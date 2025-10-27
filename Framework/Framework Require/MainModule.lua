--[[
NOTICE: This is the script used to load the Backrooms Unlimited Framework. It is not the framework itself.

In order for this script to work, two other scripts must be present. 

Firstly, one script must exist in ServerScriptService that requires this modules. It must contain the following code:

"
local backroomsUnlimitedFramework = require(71448387701771)
backroomsUnlimitedFramework.loadFramework()
"

Secondly, one script must exist in ReplicatedFirst that allows this module to load in PlayerScripts for players who join before 
the framework can fully load. It must contain the following code:

"
-- Services --
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local localPlr = players.LocalPlayer

local starterPlayer = game:GetService("StarterPlayer")
local starterPlayerScripts = starterPlayer:WaitForChild("StarterPlayerScripts")

-- Remote Events --
local remoteFramework = replicatedStorage:WaitForChild("Framework")
local remoteEvents = remoteFramework:WaitForChild("Remote Events")
local playerEvents = remoteEvents:WaitForChild("Player")
local frameworkPlayerAddedEvent = playerEvents:WaitForChild("FrameworkPlayerAdded")

-- Functions --
local function loadPlayerScript(frameworkFolderName: string)

	-- Prefer a live template in ReplicatedStorage (works for existing players).
	local rsFramework = replicatedStorage:FindFirstChild("Framework")
	local liveTemplates = rsFramework and rsFramework:FindFirstChild("StarterPlayerTemplate")
	local liveFramework = liveTemplates and liveTemplates:FindFirstChild(frameworkFolderName)

	local frameworkFolder = liveFramework or starterPlayerScripts:FindFirstChild(frameworkFolderName)
	if not frameworkFolder then
		warn("[Framework]: No folder found with name " .. frameworkFolderName .. " in StarterPlayerScripts or ReplicatedStorage.Framework.StarterPlayerTemplate.")
		return
	end
	
	-- Remove an old copy if present to avoid duplicates, then clone.
	local existing = localPlr.PlayerScripts:FindFirstChild(frameworkFolderName)
	if existing then existing:Destroy() end

	local clonedFolder = frameworkFolder:Clone()
	clonedFolder.Parent = localPlr.PlayerScripts
end

-- Events --
frameworkPlayerAddedEvent.OnClientEvent:Connect(loadPlayerScript)
"

Once these two scripts are in place, this module will load the most recent published version of the BU framework into the game.
A model containing these two scripts can be found here: 
]]

---- Services ----
local serverScriptService = game:GetService("ServerScriptService")
local serverStorage = game:GetService("ServerStorage")
local materialService = game:GetService("MaterialService")

local replicatedStorage = game:GetService("ReplicatedStorage")

local starterGUI = game:GetService("StarterGui")
local starterPlayer = game:GetService("StarterPlayer")
local starterCharacterScripts = starterPlayer.StarterCharacterScripts
local starterPlayerScripts = starterPlayer.StarterPlayerScripts

local replicatedFirst = game:GetService("ReplicatedFirst")

local players = game:GetService("Players")

---- Objects ----
local frameworkServerScriptService = script:WaitForChild("Framework - Server Script Service")
local frameworkServerStorage = script:WaitForChild("Framework - Server Storage")
local frameworkMaterials = script:WaitForChild("Framework - Materials")

local remoteFramework = script:WaitForChild("Framework - Replicated Storage")

local frameworkStarterGUI = script:WaitForChild("Framework - StarterGUI") -- Folder of many ScreenGuis
local frameworkStarterGUIPersistAfterDeath = script:WaitForChild("Framework - Starter GUI (Persist After Death)") -- Folder of ScreenGuis

local frameworkStarterCharacter = script:WaitForChild("Framework - Starter Character")
local frameworkStarterPlayer = script:WaitForChild("Framework - StarterPlayer")

---- Settings ----
local frameworkFolderName = "Framework"
local persistentGUIFrameworkName = "Framework - Persist on Death"

local noPermissionText = "This game does not have permission to use this asset."

local startupText = "Backrooms Unlimited Framework version [%s]"
local loadingText = "Loading framework version [%s]..."
local loadingFinishedText = "Loading finished!"
local enablingScriptText = "Enabling all framework scripts..."
local enabledAllFrameworkScriptsText = "All framework scripts enabled."
local searchingForExistingPlayersText = "Searching for existing players..."
local noExistingPlayersFoundText = "No existing players found."
local loadingFrameworkForPlayerText = "Loading framework for %s"
local loadedFrameworkForPlayerText = "Framework loaded for %s"
local frameworkFinishedLoadingText = "Framework successfully loaded!"

local versionNumber = "1.8.0" -- Semantic versioning.

local whitelistedGameIDs = { -- Prevent the framework from loading if it is not included here. This exists to prevent the framework from loading in games that do not have the rights to use it.
	2666624767, 	-- Backrooms Unlimited
 	5481008344, 	-- Framework testing place
	15850480970,	-- Level 3 retake.
	4535680462, 		-- Testing Place
	8547669610,
	9041508693 -- Demo Place
}

---- Framework Instance ----
local frameworkModule = {}

---- Internal (module) state ----
local playerChildAddedConns = {} -- [Player] = {desc=RBXScriptConnection, child=RBXScriptConnection}
local descendantEnableConns = {} -- [ScreenGui] = RBXScriptConnection (short-lived watcher)
local pendingCleanup = {}        -- [Player] = boolean (throttle container cleanup)

---- Utility Functions ----
local function hasPermission(): boolean
	return table.find(whitelistedGameIDs, game.GameId) ~= nil
end

-- Tag helper for ScreenGuis
local function tagScreenGui(g: Instance, isFromStarter: boolean, isPersist: boolean?)
	if g and g:IsA("ScreenGui") then
		g:SetAttribute("BUVersion", versionNumber)
		g:SetAttribute("BUFromStarter", isFromStarter and true or false)
		g:SetAttribute("BUFramework", true)
		if isPersist then
			g.ResetOnSpawn = false
		end
	end
end

-- Tag helper for top-level framework containers (Folders)
local function tagContainer(container: Instance, isFromStarter: boolean)
	if container and container:IsA("Folder") then
		container:SetAttribute("BUContainer", true)
		container:SetAttribute("BUFromStarter", isFromStarter and true or false)
	end
end

-- Toggle state on any container's descendant Scripts/LocalScripts
local function toggleStateOnAllChildScripts(container: Instance, shouldBeEnabled: boolean)
	for _, d in ipairs(container:GetDescendants()) do
		if d:IsA("Script") or d:IsA("LocalScript") then
			d.Enabled = shouldBeEnabled
		end
	end
end

-- Iterate all ScreenGuis under a container
local function eachScreenGui(container: Instance, fn)
	for _, d in ipairs(container:GetDescendants()) do
		if d:IsA("ScreenGui") then
			fn(d)
		end
	end
end

-- Count ScreenGuis (for container comparison)
local function countScreenGuis(container: Instance): number
	local n = 0
	for _, d in ipairs(container:GetDescendants()) do
		if d:IsA("ScreenGui") then
			n += 1
		end
	end
	return n
end

---- Overarching Framework Spawning Functions ----
local function cloneFrameworkFolder(folder: Folder, parent, name: string?)

	-- If a folder already exists here, remove it.
	local existingFolder = parent:FindFirstChild(name or frameworkFolderName)
	if existingFolder then
		existingFolder:Destroy()
	end

	-- Clone the folder instance and rename it so that other assets can find it.
	local clonedFolder = folder:Clone()
	clonedFolder.Name = name or frameworkFolderName
	-- Important: keep template disabled until activation in PlayerGui or we explicitly re-enable.
	toggleStateOnAllChildScripts(clonedFolder, false)
	clonedFolder.Parent = parent

	-- Return the cloned instance.
	return clonedFolder
end

-- Build a live client template under ReplicatedStorage so existing players can clone PlayerScripts.
local function publishStarterPlayerLiveTemplate()
	local rsFramework = replicatedStorage:FindFirstChild("Framework")
	if not rsFramework then return end

	-- Reset live template container
	local liveContainer = rsFramework:FindFirstChild("StarterPlayerTemplate")
	if liveContainer then liveContainer:Destroy() end
	liveContainer = Instance.new("Folder")
	liveContainer.Name = "StarterPlayerTemplate"
	tagContainer(liveContainer, false)
	liveContainer.Parent = rsFramework

	-- Clone the StarterPlayer template into the live container, enable scripts inside so they run after client clones.
	local clientTemplate = frameworkStarterPlayer:Clone()
	clientTemplate.Name = frameworkFolderName
	toggleStateOnAllChildScripts(clientTemplate, true)
	clientTemplate.Parent = liveContainer
end

local function markStarterTemplates()
	-- Tag containers
	local starterFolderMain = starterGUI:FindFirstChild(frameworkFolderName)
	if starterFolderMain then
		tagContainer(starterFolderMain, true)
		-- Mark & disable every ScreenGui inside this template folder.
		eachScreenGui(starterFolderMain, function(g)
			tagScreenGui(g, true, false)
			toggleStateOnAllChildScripts(g, false)
		end)
	end
	local starterFolderPersist = starterGUI:FindFirstChild(persistentGUIFrameworkName)
	if starterFolderPersist then
		tagContainer(starterFolderPersist, true)
		-- Mark & disable every ScreenGui inside this template folder.
		eachScreenGui(starterFolderPersist, function(g)
			tagScreenGui(g, true, true)
			toggleStateOnAllChildScripts(g, false)
		end)
	end
end

local function cloneFrameworkFolders()

	-- Clone the client folders in.
	cloneFrameworkFolder(remoteFramework, replicatedStorage)

	-- Clone framework GUI folders into StarterGui (kept disabled/tagged; individual ScreenGuis will mirror to PlayerGui)
	cloneFrameworkFolder(frameworkStarterGUI, starterGUI, frameworkFolderName)
	cloneFrameworkFolder(frameworkStarterGUIPersistAfterDeath, starterGUI, persistentGUIFrameworkName)

	-- Tag/prepare all templates under StarterGui
	markStarterTemplates()

	-- Clone character/player scripts (template lives in StarterPlayerScripts, disabled for now; we will enable below)
	cloneFrameworkFolder(frameworkStarterCharacter, starterCharacterScripts)
	cloneFrameworkFolder(frameworkStarterPlayer, starterPlayerScripts)

	-- Clone the server assets in.
	cloneFrameworkFolder(frameworkServerScriptService, serverScriptService)
	cloneFrameworkFolder(frameworkServerStorage, serverStorage)
	cloneFrameworkFolder(frameworkMaterials, materialService)

	-- Publish a live PlayerScripts template for existing players (clients read it from ReplicatedStorage).
	publishStarterPlayerLiveTemplate()
end

---- Framework Initialization ----
-- After all cloning is done inside loadFramework(), flip scripts back on (but not in StarterGui)
local function enableClonedScripts()
	for _, target in ipairs({
		serverScriptService:FindFirstChild("Framework"),
		serverStorage:FindFirstChild("Framework"),
		replicatedStorage:FindFirstChild("Framework"),
		-- Do NOT enable inside StarterGui templates
		starterPlayer.StarterCharacterScripts:FindFirstChild("Framework"),
		starterPlayer.StarterPlayerScripts:FindFirstChild("Framework"),
		}) do
		if target then
			toggleStateOnAllChildScripts(target, true)
		end
	end
end

---- PlayerGui container management ----
local function isFrameworkContainer(inst: Instance): boolean
	return inst:IsA("Folder")
		and (inst.Name == frameworkFolderName or inst.Name == persistentGUIFrameworkName or inst:GetAttribute("BUContainer") == true)
end

-- Merge duplicate containers of the same name, prefer Starter-sourced / or with more ScreenGuis
local function unifyContainers(pg: PlayerGui, containerName: string)
	local containers = {}
	for _, child in ipairs(pg:GetChildren()) do
		if isFrameworkContainer(child) and child.Name == containerName then
			table.insert(containers, child)
		end
	end
	if #containers <= 1 then
		return
	end

	-- Pick a keeper: prefer BUFromStarter=true, then more ScreenGuis, then first.
	local keep = containers[1]
	for i = 2, #containers do
		local c = containers[i]
		local keepStarter = keep:GetAttribute("BUFromStarter") == true and 1 or 0
		local cStarter = c:GetAttribute("BUFromStarter") == true and 1 or 0
		if cStarter > keepStarter then
			keep = c
		elseif cStarter == keepStarter then
			if countScreenGuis(c) > countScreenGuis(keep) then
				keep = c
			end
		end
	end

	-- Move ScreenGuis from others into keep, then destroy others.
	for _, c in ipairs(containers) do
		if c ~= keep then
			for _, d in ipairs(c:GetChildren()) do
				if d:IsA("ScreenGui") then
					d.Parent = keep
				end
			end
			c:Destroy()
		end
	end
end

-- Remove empty leftover framework containers (throttled)
local function scheduleContainerCleanup(player: Player, pg: PlayerGui)
	-- Defensive: if we don't know the player, skip cleanup to avoid nil indexing
	if not player then
		return
	end
	if pendingCleanup[player] then
		return
	end
	pendingCleanup[player] = true
	task.delay(0.25, function()
		pendingCleanup[player] = nil

		-- Unify first to ensure we don't delete the intended keeper.
		unifyContainers(pg, frameworkFolderName)
		unifyContainers(pg, persistentGUIFrameworkName)

		for _, child in ipairs(pg:GetChildren()) do
			if isFrameworkContainer(child) then
				if countScreenGuis(child) == 0 then
					child:Destroy()
				end
			end
		end
	end)
end

---- De-dupe & activation for ScreenGuis ----
-- De-dupe by ScreenGui name among BU-tagged guis; prefer BUFromStarter=true
local function dedupeByName(pg: PlayerGui, guiName: string): ScreenGui?
	local keep: ScreenGui? = nil
	local others = {}

	-- Consider all ScreenGuis with this name (across any container)
	for _, d in ipairs(pg:GetDescendants()) do
		if d:IsA("ScreenGui") and d.Name == guiName and d:GetAttribute("BUFramework") == true then
			if not keep then
				keep = d
			else
				-- prefer Starter-sourced one
				local starterScore = (d:GetAttribute("BUFromStarter") == true) and 1 or 0
				local keepScore = (keep:GetAttribute("BUFromStarter") == true) and 1 or 0
				if starterScore > keepScore then
					table.insert(others, keep)
					keep = d
				else
					table.insert(others, d)
				end
			end
		end
	end

	for _, o in ipairs(others) do
		o:Destroy()
	end

	return keep
end

-- Arm a single ScreenGui (enable scripts now and for late arrivals)
local function armGui(g: ScreenGui)
	if not g then return end

	-- Helper to (re)enable present descendants.
	local function armNow()
		toggleStateOnAllChildScripts(g, true)
		-- In case a parent container exists but is disabled (defensive), re-enable there too.
		local parent = g.Parent
		if parent then
			toggleStateOnAllChildScripts(parent, true)
		end
	end

	-- Enable immediately + next ticks to catch late streams; also a short-lived DescendantAdded watcher
	armNow()
	task.defer(armNow)
	task.delay(0.5, armNow)

	if not descendantEnableConns[g] then
		descendantEnableConns[g] = g.DescendantAdded:Connect(function(d)
			if d:IsA("Script") or d:IsA("LocalScript") then
				d.Enabled = true
			end
		end)
		task.delay(5, function()
			local conn = descendantEnableConns[g]
			if conn then
				conn:Disconnect()
				descendantEnableConns[g] = nil
			end
		end)
	end
end

---- Players (per-player GUI management) ----
-- Whenever any BU-tagged ScreenGui arrives in PlayerGui, de-dupe and arm it
local function connectChildAddedWatcher(player: Player, pg: PlayerGui)
	if playerChildAddedConns[player] then
		return
	end

	-- Watch for any ScreenGui desc added (covers initial mirror and respawns)
	local descConn = pg.DescendantAdded:Connect(function(d)
		if d:IsA("ScreenGui") and d:GetAttribute("BUFramework") == true then
			task.defer(function()
				local keep = dedupeByName(pg, d.Name)
				if keep then armGui(keep) end
				-- Clean up empty leftover containers afterward (throttled)
				scheduleContainerCleanup(player, pg)
			end)
		end
	end)

	-- Watch for container Folders being added; unify and cleanup
	local childConn = pg.ChildAdded:Connect(function(ch)
		if isFrameworkContainer(ch) then
			task.defer(function()
				unifyContainers(pg, ch.Name)
				scheduleContainerCleanup(player, pg)
			end)
		end
	end)

	playerChildAddedConns[player] = {desc = descConn, child = childConn}
end

-- Seed a whole folder (the same structure as Starter) into PlayerGui for existing players.
local function seedFolderToPlayerGui(player: Player, pg: PlayerGui, templateFolder: Instance, isPersist: boolean?)
	local clone = templateFolder:Clone()
	clone.Name = templateFolder.Name
	tagContainer(clone, false)

	-- Tag all ScreenGuis as BU (non-starter) and keep scripts disabled until watcher arms them.
	eachScreenGui(clone, function(g)
		tagScreenGui(g, false, isPersist)
		toggleStateOnAllChildScripts(g, false)
	end)
	clone.Parent = pg

	-- After seeding, normalize & clean containers
	task.defer(function()
		unifyContainers(pg, clone.Name)
		scheduleContainerCleanup(player, pg)
	end)
end

-- Helper: reliably notify an already-in-game client to clone PlayerScripts from live template.
local function notifyClientToLoadPlayerScripts(player: Player)

	-- Locate the RemoteEvent
	local remoteFrameworkInstance = replicatedStorage:WaitForChild("Framework")
	local remoteEvents = remoteFrameworkInstance:WaitForChild("Remote Events")
	local remotePlayerEvents = remoteEvents:WaitForChild("Player")
	local frameworkPlayerAddedRemoteEvent = remotePlayerEvents:WaitForChild("FrameworkPlayerAdded")

	-- Fire a few times with small delays to beat any listener race in ReplicatedFirst
	frameworkPlayerAddedRemoteEvent:FireClient(player, frameworkFolderName)
	task.delay(0.25, function()
		if player and player.Parent then
			frameworkPlayerAddedRemoteEvent:FireClient(player, frameworkFolderName)
		end
	end)
	task.delay(0.75, function()
		if player and player.Parent then
			frameworkPlayerAddedRemoteEvent:FireClient(player, frameworkFolderName)
		end
	end)
end

local function ensureGuiFor(player: Player)
	-- Wait for PlayerGui to exist
	local pg = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 10)
	if not pg then return end

	-- Live watcher for any BU ScreenGui or container that shows up (initial mirror or respawn)
	connectChildAddedWatcher(player, pg)

	-- Add now so current players don't have to respawn; de-dupe will handle duplicates.
	local starterFolderMain = starterGUI:FindFirstChild(frameworkFolderName)
	if starterFolderMain then
		seedFolderToPlayerGui(player, pg, starterFolderMain, false)
	end
	local starterFolderPersist = starterGUI:FindFirstChild(persistentGUIFrameworkName)
	if starterFolderPersist then
		seedFolderToPlayerGui(player, pg, starterFolderPersist, true)
	end
end

local function manuallyAddPlayers()

	-- Get the players who need to have framework data manually added to them.
	local existingPlayers = players:GetPlayers()
	if #existingPlayers == 0 then
		print(noExistingPlayersFoundText)
		return
	end

	-- Locate necessary framework bindable events.
	local serverFramework = serverStorage:WaitForChild("Framework")
	local bindableEvents = serverFramework:WaitForChild("Bindable Events")
	local playerEvents = bindableEvents:WaitForChild("Player")
	local frameworkPlayerAddedEvent = playerEvents:WaitForChild("FrameworkPlayerAdded")

	-- Go through each player and clone the framework GUI to them.
	for _, player in ipairs(existingPlayers) do

		-- Print that the framework is being loaded for this player.
		print(string.format(loadingFrameworkForPlayerText, player.Name))

		-- Ensure the player GUI is set up (idempotent, de-dupe protected, activation gated).
		ensureGuiFor(player)

		-- If the player has a character already, clone the character specific scripts over.
		if player.Character then
			local characterScripts = cloneFrameworkFolder(frameworkStarterCharacter, player.Character)
			toggleStateOnAllChildScripts(characterScripts, true)
		end

		-- Manually load server scripts for this player.
		frameworkPlayerAddedEvent:Fire(player)

		-- IMPORTANT: These players joined before StarterPlayerScripts had the Framework.
		-- Ask their client (ReplicatedFirst listener) to clone PlayerScripts now (from live template).
		notifyClientToLoadPlayerScripts(player)

		-- Print that the framework has been loaded for this player.
		print(string.format(loadedFrameworkForPlayerText, player.Name))
	end
end

---- Framework Functions ----
frameworkModule.loadFramework = function ()

	-- Verify that the game requiring this framework has permission to use it.
	if not hasPermission() then
		warn(noPermissionText)
		script:Destroy() -- Prevent the framework from even being seen.
		return
	end

	-- Visual Loading --
	print(string.format(startupText, versionNumber))
	print(string.format(loadingText, versionNumber))

	-- Load the framework in.
	cloneFrameworkFolders()
	print(loadingFinishedText)

	print(enablingScriptText)
	enableClonedScripts() -- NOTE: does NOT enable scripts in StarterGui templates
	print(enabledAllFrameworkScriptsText)
	task.wait()

	-- Hook up future players before processing existing players to avoid race conditions.
	players.PlayerAdded:Connect(function(player)

		-- Per-player UI management (StarterGui will handle ResetOnSpawn mirroring)
		ensureGuiFor(player)

		-- Character-specific scripts on spawn
		player.CharacterAdded:Connect(function(char)
			local characterScripts = cloneFrameworkFolder(frameworkStarterCharacter, char)
			toggleStateOnAllChildScripts(characterScripts, true)
		end)

		-- NOTE: Do NOT FireClient here for PlayerScripts — new players will have
		-- StarterPlayerScripts auto-cloned by the engine. The remote is reserved for existing players only.
	end)

	-- Clean up connections/table state on player removing (preferment)
	players.PlayerRemoving:Connect(function(player)
		local conns = playerChildAddedConns[player]
		if conns then
			if conns.desc then conns.desc:Disconnect() end
			if conns.child then conns.child:Disconnect() end
			playerChildAddedConns[player] = nil
		end
		pendingCleanup[player] = nil
	end)

	-- Clone necessary framework components to players who already exists when the framework loads.
	print(searchingForExistingPlayersText)
	manuallyAddPlayers()

	-- Print out that the framework has loaded.
	print(frameworkFinishedLoadingText)
end

return frameworkModule