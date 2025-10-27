-- Services --
local replicatedStorage = game:GetService("ReplicatedStorage")
local textService       = game:GetService("TextService")
local userInputService  = game:GetService("UserInputService")
local runService        = game:GetService("RunService")
local tweenService      = game:GetService("TweenService")

-- Tweens --
local defaultTween = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local longTween    = TweenInfo.new(2,   Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

-- Remote Events --
local framework           = replicatedStorage:WaitForChild("Framework")
local remoteEvents        = framework:WaitForChild("Remote Events")
local dialogEvents        = remoteEvents:WaitForChild("DialogEvents")
local dialogEvent         = dialogEvents:WaitForChild("DialogEvent")
local dialogFinishedEvent = dialogEvents:WaitForChild("DialogFinishedEvent")

-- Bindable Events --
local bindableEvents               = framework:WaitForChild("Bindable Events")
local dialogBindableEvents         = bindableEvents:WaitForChild("DialogEvents")
local dialogBindableEvnet          = dialogBindableEvents:WaitForChild("DialogEvent")          -- (kept original var name)
local dialogFinishedBindableEvnent = dialogBindableEvents:WaitForChild("DialogFinishedEvent")  -- (kept original var name)

-- GUI --
local gui       = script.Parent
local container = gui:WaitForChild("Container")
local character = container:WaitForChild("Character")
local wordGui   = container:WaitForChild("Word")
local baseline  = container:WaitForChild("Baseline")

-- State --
local isActive = false
local effects  = {}

-- Effect Implementations --
local function charAlive(obj)
	return obj and obj.Parent and obj:FindFirstChild("Text") and obj.Text and obj.Text.Parent
end

effects["BigWave"] = function(characterObj)
	if not charAlive(characterObj) then return end

	characterObj.Text.Position = UDim2.new(.5, 0, .5, 20)
	characterObj.Text.TextTransparency = 1

	tweenService:Create(characterObj.Text, defaultTween, {
		Position = UDim2.new(0.5, 0, .5, -20),
		TextTransparency = 0
	}):Play()

	task.delay(defaultTween.Time, function()
		if not charAlive(characterObj) then return end
		tweenService:Create(characterObj.Text, defaultTween, {
			Position = UDim2.new(0.5, 0, .5, 0)
		}):Play()
	end)

	task.wait(0.1)
end

effects["SmallWave"] = function(characterObj)
	if not charAlive(characterObj) then return end

	characterObj.Text.Position = UDim2.new(.5, 0, .5, 10)
	characterObj.Text.TextTransparency = 1

	tweenService:Create(characterObj.Text, defaultTween, {
		Position = UDim2.new(0.5, 0, .5, -10),
		TextTransparency = 0
	}):Play()

	task.delay(defaultTween.Time, function()
		if not charAlive(characterObj) then return end
		tweenService:Create(characterObj.Text, defaultTween, {
			Position = UDim2.new(0.5, 0, .5, 0)
		}):Play()
	end)

	task.wait(0.1)
end

effects["Distortion"] = function(characterObj)
	task.spawn(function()
		for _ = 0, 100 do
			if not charAlive(characterObj) then break end
			characterObj.Text.Position = UDim2.new(.5, math.random(-5, 5), .5, math.random(-5, 5))
			characterObj.Text.Rotation = math.random(-30, 30)
			task.wait(0.05)
		end
		if charAlive(characterObj) then
			characterObj.Text.Position = UDim2.new(.5, 0, .5, 0)
			characterObj.Text.Rotation = 0
		end
	end)
	task.wait(0.05)
end

effects["SmallJitter"] = function(characterObj)
	task.spawn(function()
		for _ = 0, 25 do
			if not charAlive(characterObj) then break end
			characterObj.Text.Position = UDim2.new(.5, math.random(-5, 5), .5, math.random(-5, 5))
			characterObj.Text.Rotation = math.random(-10, 10)
			task.wait(0.05)
		end
		if charAlive(characterObj) then
			characterObj.Text.Position = UDim2.new(.5, 0, .5, 0)
			characterObj.Text.Rotation = 0
		end
	end)
	task.wait(0.05)
end

effects["Shake"] = function(characterObj)
	task.spawn(function()
		while charAlive(characterObj) do
			characterObj.Text.Position = UDim2.new(.5, math.random(-1, 1), .5, math.random(-1, 1))
			task.wait(0.02)
		end
	end)
	task.wait(0.05)
end

effects["Slam"] = function(characterObj)
	if not charAlive(characterObj) then return end
	local originalColor = characterObj.Text.TextColor3
	local originalSize  = characterObj.Text.TextSize
	characterObj.Text.TextColor3 = Color3.fromRGB(255, 255, 255)
	characterObj.Text.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
	characterObj.Text.TextSize = originalSize * 2

	tweenService:Create(characterObj.Text, defaultTween, {
		TextColor3 = originalColor,
		TextSize   = originalSize,
		TextStrokeColor3 = originalColor
	}):Play()

	task.wait(0.05)
end

effects["Shatter"] = function(characterObj)
	if not charAlive(characterObj) then return end
	characterObj.Text.Position = UDim2.new(0.5, math.random(-50, 50), 0.5, math.random(-50, 50))
	tweenService:Create(characterObj.Text, longTween, {
		Position = UDim2.new(.5, 0, .5, 0),
	}):Play()
end

effects["Fade"] = function(characterObj)
	if not charAlive(characterObj) then return end
	characterObj.Text.TextTransparency = 1
	tweenService:Create(characterObj.Text, defaultTween, { TextTransparency = 0 }):Play()
end

effects["SlowFade"] = function(characterObj)
	if not charAlive(characterObj) then return end
	characterObj.Text.TextTransparency = 1
	tweenService:Create(characterObj.Text, longTween, { TextTransparency = 0 }):Play()
end

effects["Delay"] = function(_characterObj)
	task.wait(0.05)
end

-- Helpers --
local BIG_BOUND = Vector2.new(1000, 1000)

local function applyInlineEffectTags(textLabel, tagName)
	-- Ensure RichText is on for inline formatting
	if textLabel then textLabel.RichText = true end
	if tagName == "Italic" or tagName == "Bold" then
		return true
	end
	return false
end

local function formatCharacter(parent: GuiObject, char: string, appliedEffects: {string}, textSize: number, font: Enum.Font)
	-- Compute character width
	local charBounds = textService:GetTextSize(char, textSize, font, BIG_BOUND)

	-- Clone character template
	local charClone = character:Clone()
	charClone.Text.Text     = char
	charClone.Text.TextSize = textSize
	charClone.Text.Font     = font
    
	-- make sure inline tags work
	charClone.Text.RichText = true
	charClone.Visible       = true
	charClone.Size          = UDim2.new(0, charBounds.X + 1, 1, 0)
	charClone.Parent        = parent

	-- Expand parent to fit this character
	parent.Size = UDim2.new(0, parent.Size.X.Offset + charBounds.X + 1, 0, parent.Size.Y.Offset)

	-- Apply effects in order
	for _, effectName in ipairs(appliedEffects) do
		
		-- Handle text being colored.
		if effectName:sub(1,5) == "Color" then
			local hex =
				effectName:match("^Color%s*=%s*#(%x%x%x%x%x%x)$") or
				effectName:match("^Color#(%x%x%x%x%x%x)$")

			if not hex then
				local short =
					effectName:match("^Color%s*=%s*#(%x%x%x)$") or
					effectName:match("^Color#(%x%x%x)$")
				if short then
					-- Expand #RGB -> #RRGGBB
					hex = short:sub(1,1)..short:sub(1,1)
						.. short:sub(2,2)..short:sub(2,2)
						.. short:sub(3,3)..short:sub(3,3)
				end
			end
			
			-- If there is a valid hex code, apply it.
			if hex then
				
				-- Prefer fromHex if available; fallback to manual parse
				local ok, col = pcall(function() return Color3.fromHex("#"..hex) end)
				if ok and col then
					charClone.Text.TextColor3 = col
				else
					local r = tonumber(hex:sub(1,2), 16)
					local g = tonumber(hex:sub(3,4), 16)
					local b = tonumber(hex:sub(5,6), 16)
					if r and g and b then
						charClone.Text.TextColor3 = Color3.fromRGB(r, g, b)
					else
						warn("Invalid Color value: " .. tostring(effectName))
					end
				end
			else
				warn("Invalid Color format, expected Color=#RRGGBB (or #RGB): " .. tostring(effectName))
			end
			continue
		end

		-- Inline formatting
		if effectName == "Italic" then
			charClone.Size = UDim2.new(0, charClone.Size.X.Offset + 1, 1, 0)
			charClone.Text.Text = string.format("<i>%s</i>", charClone.Text.Text)
			applyInlineEffectTags(charClone.Text, "Italic")
			continue
		elseif effectName == "Bold" then
			charClone.Size = UDim2.new(0, charClone.Size.X.Offset + 1, 1, 0)
			charClone.Text.Text = string.format("<b>%s</b>", charClone.Text.Text)
			applyInlineEffectTags(charClone.Text, "Bold")
			continue
		end

		-- Motion/appearance effects
		local fx = effects[effectName]
		if fx then
			fx(charClone)
		end
	end
end

-- Tokenize text into exact runs (spaces kept)
local function tokenizePreserveSpaces(s: string)
	local tokens = {}
	local i, n = 1, #s
	while i <= n do
		local c = s:sub(i,i)
		if c == " " then
			local j = i
			while j <= n and s:sub(j,j) == " " do j += 1 end
			table.insert(tokens, s:sub(i, j-1)) -- one or more spaces
			i = j
		else
			local j = i
			while j <= n and s:sub(j,j) ~= " " do j += 1 end
			table.insert(tokens, s:sub(i, j-1)) -- non-space run
			i = j
		end
	end
	return tokens
end

-- Split into plain chunks and tagged chunks; never throws on malformed text
local function splitTaggedChunks(str: string)
	local chunks = {}
	local pos = 1
	while true do
		local s, e = str:find("~!~", pos, true)
		if not s then break end

		if s > pos then
			table.insert(chunks, str:sub(pos, s-1)) -- leading plain text
		end

		local effEnd = str:find("~", e+1, true)
		if not effEnd then
			-- No closing for effects list; treat remainder as plain text
			table.insert(chunks, str:sub(s))
			pos = #str + 1
			break
		end

		local contentEnd = str:find("~", effEnd+1, true)
		if not contentEnd then
			-- No closing for content; treat remainder as plain text
			table.insert(chunks, str:sub(s))
			pos = #str + 1
			break
		end

		-- Well-formed tagged chunk
		local chunk = str:sub(s, contentEnd)
		table.insert(chunks, chunk)
		pos = contentEnd + 1
	end

	-- Trailing plain text
	if pos <= #str then
		table.insert(chunks, str:sub(pos))
	end

	return chunks
end

-- Parse a single tagged chunk into {effectsList}, content string
local function parseChunk(chunk: string)
	
	-- Expect "~!~(effects)~(content)~", but be forgiving.
	local ef, ct = chunk:match("^~!~(.-)~(.-)~$")
	if not ef or not ct then
		
		-- Fallback: not actually a tagged chunk, treat as plain
		return {}, chunk
	end

	local list = {}
	for eff in ef:gmatch("([^,]+)") do
		eff = eff:match("^%s*(.-)%s*$") -- trim
		if eff ~= "" then
			table.insert(list, eff)
		end
	end
	return list, ct
end

local function clearText()
	
	-- Fade group out
	tweenService:Create(container, defaultTween, { GroupTransparency = 1 }):Play()
	task.wait(defaultTween.Time + 0.5)

	-- Remove all spawned word/char frames (keep templates)
	for _, child in ipairs(container:GetChildren()) do
		if not child:IsA("Frame") or child == wordGui or child == character or child == baseline then
			continue
		end
		child:Destroy()
	end

	-- Reset group transparency
	container.GroupTransparency = 0
end

local function getEffectiveHeight(font: Enum.Font)
	baseline.Visible   = true
	baseline.Text.Font = font
	runService.RenderStepped:Wait()
	local textHeight   = baseline.Text.TextBounds.Y
	baseline.Visible   = false
	return textHeight
end

-- Writer --
local function writeText(text: string, font: Enum.Font, textDuration: number, isRemote: boolean, fontSizeMultiplier: number?, yield: boolean?, dialogId: string?)
	if isActive then
		if not yield then return end
		repeat task.wait(math.random(0.01, 0.1)) until not isActive
	end
	isActive = true

	local textSize = getEffectiveHeight(font)
	if typeof(fontSizeMultiplier) == "number" then
		textSize *= fontSizeMultiplier
	end

	local segments = splitTaggedChunks(text)
	for _, segment in ipairs(segments) do
		local innerText = segment
		local applied = {}

		-- If it's a tag, extract effects + content
		if segment:sub(1,3) == "~!~" then
			applied, innerText = parseChunk(segment)
		end

		-- Tokenize preserving exact spaces (no auto-inserting or trimming)
		local tokens = tokenizePreserveSpaces(innerText)

		for _, token in ipairs(tokens) do
			if token == "" then
				continue
			end

			-- Create a "word" frame for this token (word or spaces)
			local bounds = textService:GetTextSize(token, textSize, font, BIG_BOUND)

			local wordClone = wordGui:Clone()
			wordClone.Visible = true
			wordClone.Size    = UDim2.new(0, 0, 0, bounds.Y)
			wordClone.Parent  = container

			-- Let first char render reliably
			runService.Heartbeat:Wait()

			-- Emit characters exactly as written
			for i = 1, #token do
				local ch = token:sub(i,i)
				formatCharacter(wordClone, ch, applied, textSize, font)
			end
		end
	end

	-- Hold on screen, then clear
	task.wait(textDuration)
	clearText()

	-- Completion callback
	if dialogId then
		if isRemote then
			dialogFinishedEvent:FireServer(dialogId)
		else
			dialogFinishedBindableEvnent:Fire(dialogId)
		end
	end

	isActive = false
end

local function writeTextRemote(text: string, font: Enum.Font, textDuration: number, fontSizeMultiplier: number?, yield: boolean?, dialogId: string?)
	writeText(text, font, textDuration, true, fontSizeMultiplier, yield, dialogId)
end

local function writeTextBindable(text: string, font: Enum.Font, textDuration: number, fontSizeMultiplier: number?, yield: boolean?, dialogId: string?)
	writeText(text, font, textDuration, false, fontSizeMultiplier, yield, dialogId)
end

-- Events --
dialogEvent.OnClientEvent:Connect(writeTextRemote)
dialogBindableEvnet.Event:Connect(writeTextBindable)

-- Example:
-- writeText("~!~Shake~You feel the ground beneath you start to fade, like dust amidst a starstruck world.~", Enum.Font.Gotham, 2)
