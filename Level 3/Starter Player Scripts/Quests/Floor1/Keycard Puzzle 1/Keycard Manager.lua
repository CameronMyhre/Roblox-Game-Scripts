--- Services ---
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

--- Variables ---
local QuestsFolder = game.Workspace:WaitForChild("Quests")
local KeyCardQuest = QuestsFolder:WaitForChild("KeycardQuest1")
local KeyCardModel = KeyCardQuest:WaitForChild("Keycard")
local KeyScannerModel = KeyCardQuest:WaitForChild("Keycard_Scanner")

local KeyCard = KeyCardModel:WaitForChild("Card")
local KeyCardLight = KeyCard:WaitForChild("Attachment"):WaitForChild("PointLight")
local KeyScanner = KeyScannerModel:WaitForChild("Scanner")
local KeyScannerLight = KeyScannerModel:WaitForChild("Light"):WaitForChild("Attachment"):WaitForChild("PointLight")
local SwipeSFX = KeyScanner:WaitForChild("SwipeSFX")
local KeyCardVFX = KeyCard:WaitForChild("ParticleEmitter")

local Door = KeyCardQuest:WaitForChild("KeycardDoor")
local ClickDetector = Door:WaitForChild("DoorModel"):WaitForChild("Hitbox"):WaitForChild("ClickDetector")

--- Prompts ---
local KeyPrompt = KeyCard:WaitForChild("ProximityPrompt")
local ScannerPrompt = KeyScanner:WaitForChild("ScannerPrompt")
local KeyScannerLight = KeyScannerModel:WaitForChild("Light")
local ScannerPointLight = KeyScannerLight:WaitForChild("Attachment"):WaitForChild("PointLight")

--- Tweens ---
local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local SwiperTweenInfo = TweenInfo.new(0.25,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut)

--- Functions ---

--- Handles Custom Tweens ---
local function PlayCustomTween(Object, tweenInfo, Data)
	TweenService:Create(Object, tweenInfo, Data):Play()
end

--- Handles KeyCard Collection ---
local function OnKeyCollect()
	
	--- Enables Scanner and Fades the Keycard ---
	KeyPrompt.Enabled = false
	ScannerPrompt.Enabled = true

	--- Plays Tweens to smoothly get rid of it ---
	PlayCustomTween(KeyCard, tweenInfo, { Transparency = 1 })
	PlayCustomTween(KeyCardLight, tweenInfo, { Range = 0 })

	--- Smoothly Gets rid of the particles ---
	KeyCardVFX.Rate = 0

	--- Waits for a bit and destroys the keycard ---
	task.wait(1)
	KeyCard:Destroy()
end

--- Handles Scanner Swipe ---
local function OnScannerSwipe()
	
	--- Disables Scanner ---
	ScannerPrompt.Enabled = false

	--- Lights up the scanner and plays swipe SFX ---
	SwipeSFX:Play()
	task.wait(1.2)
	
	--- Plays Custom Tweens Regarding Light ---
	PlayCustomTween(KeyScannerLight, tweenInfo, {Color = Color3.fromRGB(133, 255, 111)})
	PlayCustomTween(ScannerPointLight, tweenInfo, {Color = Color3.fromRGB(133, 255, 111), Brightness = 0, Range = 0 })
	
	--- Sets Range to ClickDetector ---
	ClickDetector.MaxActivationDistance = 7
end

--- Connects ---
KeyPrompt.Triggered:Connect(OnKeyCollect)
ScannerPrompt.Triggered:Connect(OnScannerSwipe)