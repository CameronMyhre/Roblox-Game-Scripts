-- Services --
local starterGui = game:GetService("StarterGui")
local userInputService = game:GetService("UserInputService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local tweenService = game:GetService("TweenService")
local defaultTween = TweenInfo.new(.25, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
local guiFadeTween = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local backpack = localPlayer.Backpack

-- Bindable Events --
local framework = replicatedStorage:WaitForChild("Framework")
local bindableEvents = framework:WaitForChild("Bindable Events")
local guiBindableEvents = bindableEvents:WaitForChild("GUI")
local toggleGUIBindableEvent = guiBindableEvents:WaitForChild("ToggleGUI")

-- Remote Events --
local framework = replicatedStorage:WaitForChild("Framework")
local remoteEvents = framework:WaitForChild("Remote Events")
local guiRemoteEvents = remoteEvents:WaitForChild("GUI")
local toggleGUIEvent = guiRemoteEvents:WaitForChild("ToggleGUI")

-- Objects --
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoid = character:FindFirstChildOfClass("Humanoid")

-- Gui --
local gui = script.Parent
local container = gui:WaitForChild("Hotbar")
local template = container:WaitForChild("Template")

-- Settings --
local keyCodeToIndex = {
	Zero = 10,
	One = 1,
	Two = 2,
	Three = 3,
	Four = 4,
	Five = 5,
	Six = 6,
	Seven = 7,
	Eight = 8,
	Nine = 9,
	KeypadZero = 20,
	KeypadOne = 11,
	KeypadTwo = 12,
	KeypadThree = 13,
	KeypadFour = 14,
	KeypadFive = 15,
	KeypadSix = 16,
	KeypadSeven = 17,
	KeypadEight = 18,
	KeypadNine = 19,
}
local rigidHotbar = true -- When true, always render maxSlots slots.
local maxSlots = 7

local unselectedSize = UDim2.new(0.077, 0, 0.928, 0)
local selectedSize = UDim2.new(0.081, 0, 0.97, 0)

-- Storage --
local items = {}
local itemEquipConnections = {}
local equippedItemIndex = -1

local equippedTool -- : Tool?

-- Functions --
--- Utility Functions ---
local function isNewTool(instance : Instance) : boolean
	if not instance:IsA("Tool") then
		return false
	end
	if table.find(items, instance) then
		return false
	end
	return true
end

local function cloneSlotProperties(slot1, slot2)
	slot1["Tool Icon"].Image = slot2["Tool Icon"].Image
	slot1["Tool Icon"].ImageTransparency = slot2["Tool Icon"].ImageTransparency
	slot1["Tool Text"].Text = slot2["Tool Text"].Text
	slot1["Tool Text"].TextTransparency = slot2["Tool Text"].TextTransparency
end

local function clonePropertiesFromTool(slot, tool : Tool)
	if tool.TextureId ~= "" then
		slot["Tool Icon"].Image = tool.TextureId
		slot["Tool Icon"].ImageTransparency = 0
		slot["Tool Text"].TextTransparency = 1
	else
		slot["Tool Text"].Text = tool.Name
		slot["Tool Text"].TextTransparency = 0
		slot["Tool Icon"].ImageTransparency = 1
	end
end

local function selectSlot(slotIndex : number?)
	local hotbarSlot = container:FindFirstChild(slotIndex or equippedItemIndex)
	if hotbarSlot then
		tweenService:Create(hotbarSlot, defaultTween, {Size = selectedSize}):Play()
		tweenService:Create(hotbarSlot["Selection Overlay"], defaultTween, {ImageTransparency = 0}):Play()
	end
end

local function deselectSlot(slotIndex : number?)
	local hotbarSlot = container:FindFirstChild(slotIndex or equippedItemIndex)
	if hotbarSlot then
		tweenService:Create(hotbarSlot, defaultTween, {Size = unselectedSize}):Play()
		tweenService:Create(hotbarSlot["Selection Overlay"], defaultTween, {ImageTransparency = 1}):Play()
	end
end

local function refreshEquippedSelection(oldIndex : number?)
	if not equippedTool then return end
	local newIndex = table.find(items, equippedTool)
	if newIndex and newIndex ~= oldIndex then
		deselectSlot(oldIndex)
		equippedItemIndex = newIndex
		selectSlot(newIndex)
	end
end

--- Tool Action Functions ---
local function toggleToolEquipState(tool : Tool, index : number?)
	-- Deselect current slot visual first (it will be reselected if needed)
	deselectSlot(equippedItemIndex)

	if not humanoid then
		humanoid = character:FindFirstChildOfClass("Humanoid")
	end

	if tool.Parent == character then
		-- Unequip all tools
		humanoid:UnequipTools()
		-- Clear equipped tracking
		equippedItemIndex = -1
		equippedTool = nil
	else
		-- Equip the tool
		humanoid:EquipTool(tool)
		-- Track by reference and index
		equippedTool = tool
		equippedItemIndex = index
		selectSlot(index)
	end
end

--- GUI Functions ---
---- Gui Creation Functions ----
local function createHotbarSlot(tool : Tool?, index : number?) : ImageLabel
	local newHotbarSlot = template:Clone()
	newHotbarSlot.Name = index or #items
	newHotbarSlot.Visible = true
	newHotbarSlot.LayoutOrder = index or #items

	if tool then
		clonePropertiesFromTool(newHotbarSlot, tool)
		itemEquipConnections[index or #items] = newHotbarSlot.Button.MouseButton1Click:Connect(function ()
			toggleToolEquipState(tool, index)
		end)
	end

	newHotbarSlot["Tool Number"].Text = index or #items
	newHotbarSlot.Parent = container
	return newHotbarSlot
end

local function overrideHotbarSlot(tool : Tool, index : number)
	local hotbarSlot = container:FindFirstChild(index)
	if not hotbarSlot then
		createHotbarSlot(tool, index)
		return
	end

	clonePropertiesFromTool(hotbarSlot, tool)

	if itemEquipConnections[index] then
		itemEquipConnections[index]:Disconnect()
	end
	itemEquipConnections[index] = hotbarSlot.Button.MouseButton1Click:Connect(function ()
		toggleToolEquipState(tool, index)
	end)
end

local function addToolToHotbar(tool : Tool)
	table.insert(items, tool)

	if #items <= maxSlots then
		if not rigidHotbar then
			createHotbarSlot(tool)
		else
			overrideHotbarSlot(tool, #items)
		end
	end

	-- If this tool is already equipped, select its slot and track reference
	if tool.Parent == character then
		deselectSlot(equippedItemIndex)
		equippedItemIndex = #items
		equippedTool = tool -- NEW
		selectSlot(equippedItemIndex)
	end
end

---- GUI Removal / Shift Functions ----
local function removeHotbarSlot(slotIndex : number?)
	local toolEquipConnection = itemEquipConnections[slotIndex]
	if toolEquipConnection then
		toolEquipConnection:Disconnect()
		itemEquipConnections[slotIndex] = nil
	end

	local hotbarSlot = container:FindFirstChild(slotIndex)
	if hotbarSlot then
		if rigidHotbar then
			cloneSlotProperties(hotbarSlot, template)
		else
			hotbarSlot:Destroy()
		end
	end
end

local function moveTools(toolIndex : number)
	for i = toolIndex, (math.min(#items, maxSlots) + 1), 1 do
		local tool = items[i]
		if not tool then
			removeHotbarSlot(i)
			continue
		end
		if i > maxSlots then
			continue
		end
		overrideHotbarSlot(tool, i)
	end
end

local function removeToolFromHotbar(tool : Tool)
	local toolIndex = table.find(items, tool)
	if not toolIndex then return end

	-- Track old equipped index before we mutate items
	local oldEquippedIndex = equippedItemIndex
	local removedWasEquipped = (tool == equippedTool)

	table.remove(items, toolIndex)

	if removedWasEquipped then
        
		-- Deselection for removed equipped tool
		deselectSlot(toolIndex)
		equippedItemIndex = -1
		equippedTool = nil
	end

	if toolIndex > #items then
		removeHotbarSlot(toolIndex)
	else
		moveTools(toolIndex)
	end

	if not removedWasEquipped then
		refreshEquippedSelection(oldEquippedIndex)
	end
end

--- Event Functions ---
local function childAdded(child)
	if not isNewTool(child) then return end
	addToolToHotbar(child)
end

local function childRemoved(child)
	if not child:IsA("Tool") then
		return
	end

	-- If player still owns the tool, ignore (we only care about drops/deletions)
	if child.Parent == backpack or child.Parent == character then
		return
	end

	removeToolFromHotbar(child)
end

local function inputBegan(input, gameProcessed)
	if gameProcessed then return end
	local index = keyCodeToIndex[input.KeyCode.Name]
	if index and index <= maxSlots and items[index] then
		toggleToolEquipState(items[index], index)
	end
end

local function toggleGUI(toActive: boolean)
	local targetTransparency = toActive and 0 or 1
	tweenService:Create(container, guiFadeTween, {
		GroupTransparency = targetTransparency
	}):Play()
end

--- Setup Functions ---
local function setup()

	-- Disable Roblox inventory GUI
	starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	if rigidHotbar then
		for i = 1, maxSlots, 1 do
			createHotbarSlot(nil, i)
		end
	end
end

-- Events --
backpack.ChildAdded:Connect(childAdded)
character.ChildAdded:Connect(childAdded)
backpack.ChildRemoved:Connect(childRemoved)
character.ChildRemoved:Connect(childRemoved)
userInputService.InputBegan:Connect(inputBegan)

toggleGUIBindableEvent.Event:Connect(toggleGUI)
toggleGUIEvent.OnClientEvent:Connect(toggleGUI)

-- Setup the GUI when the player spawns.
setup()
for _,v in ipairs(localPlayer.Backpack:GetChildren()) do
	if v:IsA("Tool") then
		addToolToHotbar(v)
	end
end
