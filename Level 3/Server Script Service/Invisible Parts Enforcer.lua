local invisibleParts = workspace["Invisible Parts"]

for _, part in ipairs(invisibleParts:GetDescendants()) do
	
	if not part:IsA("Part") then
		continue
	end
	
	part.Transparency = 1
end