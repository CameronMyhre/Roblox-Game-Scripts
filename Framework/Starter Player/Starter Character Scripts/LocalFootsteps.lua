-- Variables --
local plr = game:GetService("Players").LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local hrp = char:WaitForChild("HumanoidRootPart")

local materials = script:WaitForChild("FootstepSounds")
hrp:WaitForChild("Running").Volume = 0

-- Functions --
local walking = nil
hum.Running:connect(function(speed)
	if speed > hum.WalkSpeed / 2 then
		walking = true
	else
		walking = false
	end
end)

function getMaterial()
	local floormat = hum.FloorMaterial
	if not floormat then floormat = "Air" end
	local matstring = string.split(tostring(floormat),'Enum.Material.')[2]
	local material = matstring
	return material
end

local lastmat = nil
function renderFrame()
	if walking then
		local material = getMaterial()
		if material ~= lastmat and lastmat ~= nil then
			materials[lastmat].Playing = false
		end
		local materialSound = materials[material]
		materialSound.PlaybackSpeed = hum.WalkSpeed / 12
		materialSound.Playing = true
		lastmat = material
	else
		for _, sound in pairs(materials:GetChildren()) do
			sound.Playing = false
		end
	end
end

game:GetService('RunService').Heartbeat:Connect(renderFrame)