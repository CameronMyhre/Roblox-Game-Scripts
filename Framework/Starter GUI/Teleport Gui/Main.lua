-- Services --
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TweenService = game:GetService("TweenService")
local DefaultTween = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

-- Remote Events --
local Framework = ReplicatedStorage:WaitForChild("Framework")
local RemoteEvents = Framework:WaitForChild("Remote Events") 
local TeleportEvent = RemoteEvents:WaitForChild("TeleportEvent")

-- Gui --
local TeleportGui = script.Parent
local Background = TeleportGui:FindFirstChild("Background") or TeleportGui:WaitForChild("Background")
local LoadingArea = Background:FindFirstChild("Loading Area") or Background:WaitForChild("Loading Area")
local LoadingText = LoadingArea:FindFirstChild("Loading Text") or LoadingArea:WaitForChild("Loading Text")
local LoadingImage = LoadingArea:FindFirstChild("Loading Image") or LoadingArea:WaitForChild("Loading Image")

-- Settings --
local Settings = TeleportGui:WaitForChild("Settings")
local ErrorText = Settings:GetAttribute("ErrorText")
local DefaultText = Settings:GetAttribute("LoadingText")
local RotationSpeed = Settings:GetAttribute("RotationSpeed")
Background.BackgroundColor3 = Settings:GetAttribute("BackgroundColor")

-- Misc --

-- Functions --
local function Rotation()
	
	-- Make sure rotation does not excede 360 --
	if LoadingImage.Rotation + RotationSpeed <= 360 then
		LoadingImage.Rotation += RotationSpeed
	else
		LoadingImage.Rotation = 0
	end
	return
end
local function TeleportFailed()
	
	-- Reset Text --
	LoadingText.Text = ErrorText
	
	-- Play Sound Effect --
	TeleportGui:WaitForChild("SFX"):WaitForChild("TeleportFail"):Play()
	task.wait(2)
	
	-- Show UI --
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
	UserInputService.MouseIconEnabled = true
	
	-- Adjust Transparency --
	TweenService:Create(Background, DefaultTween, {BackgroundTransparency = 1}):Play()
	TweenService:Create(LoadingText, DefaultTween, {TextTransparency = 1}):Play()
	TweenService:Create(LoadingImage, DefaultTween, {ImageTransparency = 1}):Play()

	-- Adjust Position --
	TweenService:Create(LoadingArea, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = LoadingArea:GetAttribute("OffScreenPosition")}):Play()
end

local function loadSettings(NewSettings: Configuration)
	Background.BackgroundColor3 = NewSettings:GetAttribute("BackgroundColor") or Settings:GetAttribute("BackgroundColor")
	ErrorText = NewSettings:GetAttribute("ErrorText") or Settings:GetAttribute("ErrorText")
	LoadingImage.Image = NewSettings:GetAttribute("LoadingImage") or Settings:GetAttribute("LoadingImage")
	DefaultText = NewSettings:GetAttribute("LoadingText") or Settings:GetAttribute("LoadingText")
	RotationSpeed = NewSettings:GetAttribute("RotationSpeed") or Settings:GetAttribute("RotationSpeed")
end

local function ShowGui(CustomSettings: Configuration?)
	
	-- Load the settings in.
	loadSettings(CustomSettings or Settings)
	print(CustomSettings)
	
	-- Make Background Visible --
	Background.Visible = true
	
	-- Hide UI --
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	UserInputService.MouseIconEnabled = false
	
	-- Set TeleportGui --
	TeleportService:SetTeleportGui(TeleportGui)
	
	-- Reset Text --
	LoadingText.Text = DefaultText
	
	-- Adjust Transparency --
	TweenService:Create(Background, DefaultTween, {BackgroundTransparency = 0}):Play()
	TweenService:Create(LoadingText, DefaultTween, {TextTransparency = 0}):Play()
	TweenService:Create(LoadingImage, DefaultTween, {ImageTransparency = 0}):Play()
	
	-- Adjust Position --
	TweenService:Create(LoadingArea, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = LoadingArea:GetAttribute("OriginPosition")}):Play()
end

-- Events --
RunService.Heartbeat:Connect(Rotation)
TeleportEvent.OnClientEvent:Connect(ShowGui)
TeleportService.TeleportInitFailed:Connect(TeleportFailed)