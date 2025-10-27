-- Services --
local serverStorage = game:GetService("ServerStorage")
local physicsService = game:GetService("PhysicsService")

-- Bindible Events --
local framework = serverStorage:WaitForChild("Framework")
local bindableEvents = framework:WaitForChild("Bindable Events")
local playerEvents = bindableEvents:WaitForChild("Player")
local characterLoaded = playerEvents:WaitForChild("CharacterLoaded")

-- Flags --
local setupColisionGroup = false

-- Settings --
local playerColisionGroupName = "Player"

-- Main Function --
local function characterAdded(player: Player) 

	-- Get the player's charater.
	local character = player.Character
	
	-- Setup the colision groups if they are not setup yet.
	if not setupColisionGroup then
		
		-- Register the colision group.
		physicsService:RegisterCollisionGroup(playerColisionGroupName)
		physicsService:CollisionGroupSetCollidable(playerColisionGroupName, playerColisionGroupName, false)
		
		-- Toggle the flag.
		setupColisionGroup = true
	end
	
	-- Set all parts to non-collidable.
	for _, instance in ipairs(character:GetDescendants()) do
		if instance:IsA("Part") or instance:IsA("MeshPart") or instance:IsA("UnionOperation") then
			instance.CollisionGroup = playerColisionGroupName
		end
	end
end

-- Events --
characterLoaded.Event:Connect(characterAdded)