-- Services --
local collectionService = game:GetService("CollectionService")
local players = game:GetService("Players")
local runService = game:GetService("RunService")
local debris = game:GetService("Debris")
local serverStorage = game:GetService("ServerStorage")

-- Modules --
local framework = serverStorage:WaitForChild("Framework")
local frameworkModules = framework:WaitForChild("Modules")
local healthManager = require(frameworkModules:WaitForChild("Health Manager"))
local effectData = require(frameworkModules:WaitForChild("Effects"))

-- Bindable Events --
local bindableEvents = framework:WaitForChild("Bindable Events")

local effectEvents = bindableEvents:WaitForChild("Effect System")
local giveEffectEvent = effectEvents:WaitForChild("GiveEffectEvent")

-- Parts --
local invisibleParts = workspace:WaitForChild("Invisible Parts")
local burningHitboxes = invisibleParts:WaitForChild("BurnParts")

local burnEffects = script:WaitForChild("PlrBurnEffects")
local fireEffect = burnEffects:WaitForChild("Fire")
local smokeEffect = burnEffects:WaitForChild("Smoke")

-- Settings --
local burnTag = "burning"
local recentlyBurnedTag = "recentlyBurned"

local baseEffectDuration = 5 -- Seconds
local contactDamage = -10 -- Per second

local damageFrequency = 2 -- Times per second

-- Storage --
local burningPlayers = {}
local damageTime = 1/damageFrequency
local currentTime = 0

-- Functions --
local function isValidInstance(possibleInstance: Instance)
	return (possibleInstance:IsA("Part") or possibleInstance:IsA("MeshPart") or possibleInstance:IsA("UnionOperation"))
end

local function adjustBurn(possiblePart: Instance, addingBurn)
	
	-- Verify that the part is a part.
	if not isValidInstance(possiblePart) then
		return
	end
	
	-- If told to do so, remove all effects. Otherwise, clone the effects over into the part.
	if not addingBurn then
		
		-- Remove the fire effect if found.
		local fire = possiblePart:FindFirstChild("Fire")
		if fire then
			fire.Enabled = false
			debris:AddItem(fire, fire.Lifetime.Max)
		end
		
		-- Remove the smoke effect if found.
		local smoke = possiblePart:FindFirstChild("Smoke")
		if smoke then
			smoke.Enabled = false
			debris:AddItem(smoke, smoke.Lifetime.Max)
		end
	else
		
		local fireClone = fireEffect:Clone()
		local smokeClone = smokeEffect:Clone()
		
		fireClone.Parent = possiblePart
		smokeClone.Parent = possiblePart
	end
end

local function partTouched(part)
	
	-- Check if the part belongs to a character.
	local possibleCharacter = part.Parent
	local plr = players:FindFirstChild(possibleCharacter.Name)
	if not plr then
		return
	end
	
	-- Return if the player was recently hit with contact damage.
	if collectionService:HasTag(plr, recentlyBurnedTag) then
		return
	end
	
	-- Find the humanoid and damage them if possible.
	local humanoid = possibleCharacter:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	
	-- Damage the player and add the recently burned tag.
	healthManager:adjustHealth(plr, contactDamage)
	collectionService:AddTag(plr, recentlyBurnedTag)
	task.delay(.5, function()
		collectionService:RemoveTag(plr, recentlyBurnedTag)
	end)

	-- Return if the player is already burning.
	if collectionService:HasTag(plr, burnTag) then
		return
	end
	
	-- Add the burn tags
	collectionService:AddTag(plr, burnTag)
	task.delay(baseEffectDuration, function()
		collectionService:RemoveTag(plr, burnTag)
		
		-- Remove all burn effects.
		for _, part in ipairs(possibleCharacter:GetChildren()) do
			adjustBurn(part, false)
		end
	end)
	
	-- Clone in burn effects and add them to the character.
	for _, part in ipairs(possibleCharacter:GetChildren()) do
		adjustBurn(part, true)
	end
	
	-- Burn the player.
	giveEffectEvent:Fire(plr, effectData.Burning, baseEffectDuration)
end

-- Setup all burning hitboxes.
for _, burningHitbox in ipairs(burningHitboxes:GetChildren()) do
	
	-- Make sure that the hitbox can be interacted with.
	if not isValidInstance(burningHitbox) then
		continue
	end
	
	-- Connect up events and hide the hitbox.
	burningHitbox.Transparency = 1
	burningHitbox.Touched:Connect(partTouched)
end