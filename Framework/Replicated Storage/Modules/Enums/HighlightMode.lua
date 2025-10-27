-- Create a custom type.
export type HighlightMode = number

export type Modes = {
	Show: HighlightMode,
	Hide: HighlightMode
}

-- Create the enum values themselves.
local HighlightMode: Modes = {
	Show = 0,
	Hide = 1,
}

-- Return the object.
return HighlightMode