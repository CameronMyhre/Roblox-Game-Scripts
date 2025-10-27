--!strict
-- Custom Type
export type HighlightPreset = {
	FillColor: Color3,
	FillTransparency: number,
	OutlineColor: Color3,
	OutlineTransparency: number
}


-- Build a record type with each key spelled out
export type Presets = {
	Default: HighlightPreset,
}

-- Settings
local presets: Presets = {
	Default = {
		FillColor = Color3.fromRGB(205, 229, 255),
		FillTransparency = .75,
		OutlineColor = Color3.fromRGB(180, 255, 233),
		OutlineTransparency = 0.2
	}
}

return presets