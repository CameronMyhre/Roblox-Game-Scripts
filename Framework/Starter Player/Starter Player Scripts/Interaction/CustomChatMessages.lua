-- Services --
local players = game:GetService("Players")
local starterGui = game:GetService("StarterGui")
local textChatService = game:GetService("TextChatService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local chatWindowConfig = textChatService.ChatWindowConfiguration

-- Remote Events --
local framework = replicatedStorage:WaitForChild("Framework")
local remoteEvents = framework:WaitForChild("Remote Events")
local chatEvents = remoteEvents:WaitForChild("Chat")
local displayChatTextEvent = chatEvents:WaitForChild("DisplayChatTextEvent")
local loadChatHistoryEvent = chatEvents:WaitForChild("LoadChatHistoryEvent")

-- 1) force new chat
-- 3) wait for RBXGeneral
local channels = textChatService:WaitForChild("TextChannels")
local generalChannel = channels:WaitForChild("RBXGeneral")
print("Found RBXGeneral channel:", generalChannel)

-- 5) receive styled messages from server
displayChatTextEvent.OnClientEvent:Connect(function(richText)
	generalChannel:DisplaySystemMessage(richText)
end)

textChatService.OnChatWindowAdded = function(textChatMessage)
	local chatConfig = chatWindowConfig:DeriveNewMessageProperties()

	if not textChatMessage.TextSource then
		return nil
	end

	if textChatMessage.TextSource.UserId == players.LocalPlayer.UserId then
		displayChatTextEvent:FireServer(textChatMessage.Text)
		textChatMessage.Text = ""
		return chatConfig
	end

	-- else allow; server veto and system-messages will handle recolor
	return nil
end

task.wait(2)
loadChatHistoryEvent:FireServer()