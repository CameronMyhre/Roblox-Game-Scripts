-- Services --
local replicatedStorage = game:GetService("ReplicatedStorage")
local debris = game:GetService("Debris")
local players = game:GetService("Players")
local localPlr = players.LocalPlayer

-- Remote Events --
local remoteEvents = replicatedStorage:WaitForChild("Remote Events")
local bloodlustEvents = remoteEvents:WaitForChild("Bloodlust")
local spawnPageEvent = bloodlustEvents:WaitForChild("SpawnPageEvent")
local despawnPageEvent = bloodlustEvents:WaitForChild("DespawnPageEvent")
local pageGrabbedEvent = bloodlustEvents:WaitForChild("PageGrabbedEvent")

-- Objects --
local quests = workspace:WaitForChild("Quests")
local bloodlustQuest = quests:WaitForChild("Bloodlust")
local anOldPage = bloodlustQuest:WaitForChild("An old page")

local pageObject = anOldPage:WaitForChild("Page")
local highlight = pageObject:WaitForChild("Highlight")
local billboardGUI = pageObject:WaitForChild("BillboardGui")
local proximityPrompt = pageObject:WaitForChild("ProximityPrompt")

local textGUI = pageObject:WaitForChild("TextGUI")
local pageImage = textGUI:WaitForChild("PageImage")

local smokeEffect = pageObject:WaitForChild("Smoke")
local fireEffect = pageObject:WaitForChild("Fire")

-- SFX --
local burnSound = pageObject:WaitForChild("Burned")

-- Settings --
local despawnPosition = pageObject.CFrame
local pageImageIds = {
	"rbxassetid://107858928805081",
	"rbxassetid://77091857908237",
	"rbxassetid://100917639312780",
	"rbxassetid://80111956413406",
	"rbxassetid://81221686385909",
	"rbxassetid://131835902861384",
	"rbxassetid://128032877195991",
	"rbxassetid://107565127433712",
	"rbxassetid://95177289369859"
}

-- Storage --
local collectionConnection

-- Functions --
local function spawnSoundPart()
	
	local soundPart = Instance.new("Part")
	soundPart.Anchored = true
	soundPart.CanCollide = false
	soundPart.Transparency = 1
	soundPart.CFrame = pageObject.CFrame
	soundPart.Parent = workspace
	
	local sfxClone = burnSound:Clone()
	sfxClone.Parent = soundPart
	sfxClone:Play()
	
	debris:AddItem(soundPart, sfxClone.TimeLength)
end

local function pageCollected(plr: Player)
	
	-- Ensure that the prompt is activated by the local player.
	if plr ~= localPlr then
		return
	end
	
	-- Emit the particles.
	fireEffect:Emit(25)
	smokeEffect:Emit(50)
	
	-- Spawn in a part to play sfx.
	spawnSoundPart()
	
	-- Fire the event telling the server the page was grabbed.
	pageGrabbedEvent:FireServer()
end

local function spawnPage(spawnLocation: CFrame, pageNum: number)
	
	-- Spawn in the page
	anOldPage:PivotTo(spawnLocation)
	
	-- Disconnect Existing Connections.
	if collectionConnection then
		collectionConnection:Disconnect()
	end
	
	-- Change the page image
	pageImage.Image = pageImageIds[pageNum + 1]
	if pageNum > 1 then
		pageImage.ImageRectOffset = Vector2.new(0, -1400)
	else
		pageImage.ImageRectOffset = Vector2.new(0, -1300)
	end
	
	-- Enable the highlight adn the proximity prompt.
	highlight.Enabled = true
	proximityPrompt.Enabled = true
	billboardGUI.Enabled = true
	
	-- Setup events.
	collectionConnection = proximityPrompt.Triggered:Connect(pageCollected)
end

local function despawnPage()
	
	-- Teleport the page away.
	anOldPage:PivotTo(despawnPosition)

	-- Disable the highlight and the proximity prompt.
	proximityPrompt.Enabled = false
	highlight.Enabled = false
	billboardGUI.Enabled = false
	
	-- Disconnect the collection event if it is still present.
	if collectionConnection then
		collectionConnection:Disconnect()
	end	
end

-- Events --
spawnPageEvent.OnClientEvent:Connect(spawnPage)
despawnPageEvent.OnClientEvent:Connect(despawnPage)