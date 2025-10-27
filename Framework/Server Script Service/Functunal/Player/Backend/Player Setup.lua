-- Services --
local serverStorage = game:GetService("ServerStorage")
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")

-- Modules --
local framework = serverStorage:WaitForChild("Framework")
local modules = framework:WaitForChild("Modules")
local healthManager = require(modules:WaitForChild("Health Manager")) -- Require the health manager so that its periodic heal starts running.

-- Bindible Events --
local bindableEvnets = framework:WaitForChild("Bindable Events")
local playerEvents = bindableEvnets:WaitForChild("Player") -- Bindible events folder 
local characterLoadedEvent = playerEvents:WaitForChild("CharacterLoaded")
local characterSetupEvent = playerEvents:WaitForChild("CharacterSetup")

-- Remote Events --
local remoteFramework = replicatedStorage:WaitForChild("Framework")
local remoteEvents = remoteFramework:WaitForChild("Remote Events")
local remotePlayerEvents = remoteEvents:WaitForChild("Player")
local characterSetupRemoteEvent = remotePlayerEvents:WaitForChild("CharacterSetup")

-- Objects --
local health = script:WaitForChild("Health Stats")
local sprintSystemModifiers = script:WaitForChild("Sprinting Stats")

local function characterLoaded(plr: Player)
	
	-- Get the player's character.
	local character = plr.Character
	
	-- Clone the necessary objects into the player's character.
	health:Clone().Parent = character
	sprintSystemModifiers:Clone().Parent = character
	
	-- Tell other scripts that the character has been setup.
	characterSetupEvent:Fire(plr)
	characterSetupRemoteEvent:FireClient(plr)
end

-- Events --
characterLoadedEvent.Event:Connect(characterLoaded)