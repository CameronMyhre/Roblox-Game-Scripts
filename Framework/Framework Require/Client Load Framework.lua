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

	-- Fallback to StarterPlayerScripts for new joiners (engine did this already, but safe to keep).
	local frameworkFolder = liveFramework or starterPlayerScripts:FindFirstChild(frameworkFolderName)
	if not frameworkFolder then
		warn("[Framework]: No folder found with name " .. frameworkFolderName .. " in StarterPlayerScripts or ReplicatedStorage.Framework.StarterPlayerTemplate.")
		return
	end

	-- If a copy already exists in PlayerScripts, replace it to avoid stale versions.
	local existing = localPlr.PlayerScripts:FindFirstChild(frameworkFolderName)
	if existing then existing:Destroy() end

	-- Clone the framework folder to the player.
	local clonedFolder = frameworkFolder:Clone()
	clonedFolder.Parent = localPlr.PlayerScripts
end

-- Events --
frameworkPlayerAddedEvent.OnClientEvent:Connect(loadPlayerScript)
