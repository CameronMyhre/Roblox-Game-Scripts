-- Services --
local serverStorage = game:GetService("ServerStorage")
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")

-- Bindible Events --
local framework = serverStorage:WaitForChild("Framework")
local bindableEvents = framework:WaitForChild("Bindable Events")
local playerEvents = bindableEvents:WaitForChild("Player")
local playerJoin = playerEvents:WaitForChild("PlayerJoin")
local characterLoaded = playerEvents:WaitForChild("CharacterLoaded")
local deathEvent = playerEvents:WaitForChild("PlayerDied")
local frameworkPlayerAdded = playerEvents:WaitForChild("FrameworkPlayerAdded") -- Allows for the framework to be loaded for players already in the game.
	
-- Remote Evnets --
local remtoeFramework = replicatedStorage:WaitForChild("Framework")
local remoteEvents = remtoeFramework:WaitForChild("Remote Events")
local remotePlayerEvents = remoteEvents:WaitForChild("Player")
local remoteDeathEvent = remotePlayerEvents:WaitForChild("DeathEvent")

-- Main Function --
local function playerAdded(player) 
	
	-- Character Added Function --
	local function CharacterAdded(character)

		-- Fire Character Loaded Event --
		characterLoaded:Fire(player)

		-- Death Function --
		local function onDeath()
			deathEvent:Fire(player)
			remoteDeathEvent:FireClient(player)
		end

		-- Events --
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Died:Once(onDeath)
		else
			warn("No humanodi found!")
		end
	end

	-- If the character already exists, setup character events.
	if player.Character then
		CharacterAdded(player.Character)
	end
	
	-- Events --
	player.CharacterAdded:Connect(CharacterAdded)
end

-- Events --
players.PlayerAdded:Connect(playerAdded)
frameworkPlayerAdded.Event:Connect(playerAdded)