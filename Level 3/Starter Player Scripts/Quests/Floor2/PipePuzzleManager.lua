-- Services --
local tweenService = game:GetService("TweenService")
local defaultTween = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

local replicatedStorage = game:GetService("ReplicatedStorage")

-- Modules --
local framework = replicatedStorage:WaitForChild("Framework")
local modules = framework:WaitForChild("Modules")

-- Configurations
local configs = modules:WaitForChild("Configs")
local presets = require(configs:WaitForChild("HighlightPreset"))

-- Enums
local enums = modules:WaitForChild("Enums")
local highlightMode = require(enums:WaitForChild("HighlightMode"))

-- Bindable Events --
local bindableEvents = framework:WaitForChild("Bindable Events")
local interactionEvents = bindableEvents:WaitForChild("Interaction")
local highlightBindableEvent = interactionEvents:WaitForChild("HighlightEvent")

-- Object --
local quests = workspace:WaitForChild("Quests")
local pipeQuest = quests:WaitForChild("PipeQuest")

local startPipe = pipeQuest:WaitForChild("Start")
local endPipe = pipeQuest:WaitForChild("End")

local pieces = {
	pipeQuest:WaitForChild("cross"),
	pipeQuest:WaitForChild("t"),
	pipeQuest:WaitForChild("corner"),
	pipeQuest:WaitForChild("straight")
}

local puzzle = pipeQuest:WaitForChild("Puzzle")
local startContainer = puzzle:WaitForChild("PuzzleStart")
local puzzleStart = startContainer:WaitForChild("PuzzleStart")

local exitQuest = quests:WaitForChild("ExitQuest")
local exitProgress = exitQuest:WaitForChild("Progress")

-- Settings --
local pieceDimensions = 2.5

local sides = {
	top = 1,
	right = 2,
	bottom = 3,
	left = 4
}

local offsets = {
	[sides.top] = {
		rowOffset = -1,
		columnOffset = 0
	},
	[sides.right] = {
		rowOffset = 0,
		columnOffset = 1
	},
	[sides.bottom] = {
		rowOffset = 1,
		columnOffset = 0
	},
	[sides.left] = {
		rowOffset = 0,
		columnOffset = -1
	}
}

local pieceSides = {
	straight = {sides.right, sides.left},
	corner = {sides.left, sides.bottom},
	t = {sides.top, sides.left, sides.bottom},
	cross = {sides.top, sides.bottom, sides.left, sides.right}
}

-- Storage --
local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890-=!@#$%^&*()_+"
local rows = 4
local columns = 5

-- Functions --
-- Utility --
local function getOppositeSide(sideNum: number)
	
	-- Don't directly change the parameter.
	local oppositeSide = sideNum
	oppositeSide -=  2-- Subtract 2.
		
	-- If the side is not in range, add / subtract until it is.
	while oppositeSide < 1 do
		oppositeSide += 4
	end

	while oppositeSide > 4 do
		oppositeSide -= 4
	end

	-- Return the opposite side.
	return oppositeSide
end

local function clampAngle(angleRadians: number)
	
	-- Don't directly change the parameter.
	local finalAngle = angleRadians
	
	-- If the angle is not in range, add / remove a full rotation until it is.
	while finalAngle > (2 * math.pi) do
		finalAngle -= (2 * math.pi)
	end
	
	while finalAngle < 0 do
		finalAngle += 2 * math.pi
	end
	
	-- Return the final angle.
	return finalAngle
end

local function numToChar(numb: number)
	return string.sub(alphabet, numb, numb) or "z"
end

local function charToNum(char: string)
	return string.find(alphabet, char)
end

local function generateGrid()
	
	local grid = {}
	
	-- Create a grid of size x by y. Uses a table of tables, with numbers for rows and letters for columns.
	for i=1, rows, 1 do
		
		-- Create a new empty row.
		grid[i] = {}
		
		-- Fill in each column element.
		for j=1, columns, 1 do
			
			local columnKey = numToChar(j)
			grid[i][columnKey] = {
				visited = false,
				solution = false,
				rotation = 0,
				piece = nil
			}
			
		end
	end
	
	-- Return the created grid.
	return grid
end

local function isValidNeighbor(grid, row, column, requireSolutionInstead: boolean?, ignoreState : boolean?)
	if not requireSolutionInstead then
		return grid[row] and grid[row][column] and (not grid[row][column].visited or ignoreState)
	else
		return grid[row] and grid[row][column] and (grid[row][column].solution or ignoreState)
	end
end

local function formatCellData(row, column)
	return {
		row = row,
		column = column
	}
end

local function getUnvisitedNeighbors(grid, row, column)
	
	local foundNeighbors = {}
	
	if isValidNeighbor(grid, row-1, column) then
		table.insert(foundNeighbors, formatCellData(row-1, column))
	end
	
	if isValidNeighbor(grid, row+1, column) then
		table.insert(foundNeighbors, formatCellData(row+1, column))
	end
	
	if isValidNeighbor(grid, row,(numToChar(charToNum(column)-1))) then
		table.insert(foundNeighbors, formatCellData(row, (numToChar(charToNum(column)-1))))
	end
	
	if isValidNeighbor(grid, row, (numToChar(charToNum(column)+1))) then
		table.insert(foundNeighbors, formatCellData(row, (numToChar(charToNum(column)+1))))
	end
	
	return foundNeighbors
end

-- Main Logic --
local function generatePuzzleSolution(startingRow, exitRow)
	
	-- Get the playing grid.
	local grid = generateGrid()

	-- Mark the starting cell as visited.
	grid[startingRow]["A"].visited = true
	
	local pathGenerated = false
	
	-- Create a table and flag to determine when a solution is found. 
	local solutionPath = {}
	solutionPath[1] = {
		row = startingRow,
		column = "A"
	}
	
	while not pathGenerated do
		
		local currentCell = solutionPath[#solutionPath]
		local Neighbors = getUnvisitedNeighbors(grid, currentCell.row, currentCell.column)
		
		-- If there aren't any neighbors, then backtrack.
		if #Neighbors == 0 then
			if #solutionPath == 1 then
				pathGenerated = true
				break
			end
			
			-- Remove the most recent element until Neighbors can be found.
			table.remove(solutionPath, #solutionPath)
			continue
		end
		
		-- Get the next cell.
		local nextCell = Neighbors[math.random(1, #Neighbors)]
		grid[nextCell.row][nextCell.column].visited = true
		table.insert(solutionPath, nextCell)
		
		-- Check if the next cell is the ending cell.
		if nextCell.row == exitRow and nextCell.column == numToChar(columns) then
			break
		end
	end
	
	return grid, solutionPath
end


-- Check Solution --
local function findConnectionPoints(cell)
	
	if not cell.piece then
		return {}
	end
	
	local rotationalIndexShift = math.floor(cell.rotation / (math.pi/2)) % 4 -- # 90 degree rotations.
	local pieceName = cell.piece.Name
	
	-- Get the base # sides each piece has.
	local base = pieceSides[pieceName]
	
	-- Find the sides of the cell.
	local sides = {}
	for _, side in ipairs(base) do
		table.insert(sides, ((side - 1 + rotationalIndexShift) % 4) + 1)
	end
	
	-- Return the found sides.
	return sides
end

local function findConnectedPieces(grid, cell, currentRow, currentColumn, seenCells : {})
	
	local possibleNeighbors = findConnectionPoints(cell)
	local connectedNeighbors = {}
	for key, side in possibleNeighbors do

		local sideOffset = offsets[side]
		local newCellRow = currentRow + sideOffset.rowOffset
		local newCellColumn = numToChar(charToNum(currentColumn) + sideOffset.columnOffset)
		
		-- Check whether or not the Neighbor is valid.
		if isValidNeighbor(grid, newCellRow, newCellColumn, false, true) and not table.find(seenCells, newCellColumn .. tostring(newCellRow)) then
			
			-- Verify that the other cell is touching this cell.
			local possibleNeighborsNeighbors = findConnectionPoints(grid[newCellRow][newCellColumn])
			if not table.find(possibleNeighborsNeighbors, getOppositeSide(side)) then
				continue
			end
			
			table.insert(connectedNeighbors, formatCellData(newCellRow, newCellColumn))
		end
	end
	
	-- Return the connected and valid Neighbors	
	return connectedNeighbors
end

local function checkPuzzle(grid, startRow, endRow)
	
	-- Verify that the start of the puzzle is right. (Puzzle cannot connect if this is wrong)
	local startNeighbors = findConnectionPoints(grid[startRow]['A'])
	if not table.find(startNeighbors, sides.left) then
		return false
	end
	
	local solutionPath = {}
	local seenCells = {}
	
	local formattedStartCellData = formatCellData(startRow, 'A')
	table.insert(solutionPath, formattedStartCellData)
	table.insert(seenCells, "A" .. tostring(startRow))

	local isAtEnd = false
	while not isAtEnd do
		
		-- Get data for the current cell.
		local currentCellData = solutionPath[#solutionPath]
		local currentCell = grid[currentCellData.row][currentCellData.column]
		
		-- Get the Neighbors to the cell.
		local Neighbors = findConnectedPieces(grid, currentCell, currentCellData.row, currentCellData.column, seenCells)
		if #Neighbors == 0 then
			
			-- if the current path point is the start, there is no path ot the end.
			if #solutionPath == 1 then
				print(seenCells)
				return false -- Puzzle is not solved. Dead end hit.
			end
			
			-- Remove the most recently added pipe path.
			table.remove(solutionPath, #solutionPath)
			continue
		end
		
		-- Add the first Neighbor to the seen cells and add it to the path.
		local newCell = Neighbors[1]
		table.insert(seenCells, newCell.column .. tostring(newCell.row))
		table.insert(solutionPath, newCell)

		if newCell.row == endRow and newCell.column == numToChar(columns) then

			-- Verify that the end of the puzzle is right. (Puzzle cannot connect if this is wrong)
			local endNeighbors = findConnectionPoints(grid[endRow][numToChar(columns)])
			if not table.find(endNeighbors, sides.right) then
				print(endNeighbors)
				print(seenCells)
				return false
			end			

			return true
		end
	end

end


-- Build Physical Puzzle --
local function getPieceType(currentCell, solutionPath, grid, startOrEnd: boolean): Model

	-- Find all Neighbors that exist.
	local topNeighbor  = isValidNeighbor(grid, currentCell.row -1, currentCell.column, true)
	local bottomNeighbor = isValidNeighbor(grid, currentCell.row + 1, currentCell.column, true)
	local leftNeighbor = isValidNeighbor(grid, currentCell.row, (numToChar(charToNum(currentCell.column)-1)), true)
	local rightNeighbor = isValidNeighbor(grid, currentCell.row, (numToChar(charToNum(currentCell.column)+1)), true)

	-- Keep track of the # of correct cells.
	local validCells =  0
	
	if topNeighbor then
		validCells += 1
	end
	if bottomNeighbor then
		validCells += 1
	end
	if leftNeighbor then
		validCells += 1
	end
	if rightNeighbor then
		validCells += 1
	end
	if startOrEnd then
		validCells += 1
	end

	-- Determine the piece type.
	if validCells == 4 then
		return pieces[1]:Clone()
	elseif validCells == 3 then
		return pieces[2]:Clone()
	elseif (topNeighbor or bottomNeighbor) and (rightNeighbor or leftNeighbor) or (startOrEnd and (topNeighbor or bottomNeighbor)) then
		return pieces[3]:Clone()
	else
		return pieces[4]:Clone()
	end
end

local function disablePuzzle()
	
	-- The puzzle is completed.
	exitProgress:SetAttribute("PipesAligned", true)
	
	-- Prevent further interaction.
	for _, pipe in ipairs(puzzle:GetChildren()) do
		if not pipe:IsA("Model") or pipe == startContainer then
			continue
		end

		-- Delete the hitbox to disable interaction.
		local hitbox = pipe:FindFirstChild("Hitbox")
		hitbox:Destroy()
	end
end

local function buildPuzzle()
	
	-- Define the start and end rows.
	local startingRow = math.random(1, 3)
	local exitRow = math.random(1, 3)

	local grid, solution = generatePuzzleSolution(startingRow, exitRow)
	print(solution)

	-- Mark all solution paths as solutions on the main grid. This has to be done before the 
	for stepNumber, cell in ipairs(solution) do
		
		-- Mark the current cell as a solution.
		local currentCell = grid[cell.row][cell.column]
		currentCell.solution = true
	end
	
	-- Loop through all 
	for stepNumber, cell in ipairs(solution) do

		-- Check if the piece is a 
		local isEndOrStart = false
		if startingRow == cell.row and cell.column == numToChar(1) or cell.row == exitRow and cell.column == numToChar(columns) then
			isEndOrStart = true
		end
		
		-- Grab the piece type for each solution path.
		local currentCell = grid[cell.row][cell.column]
		local cellPiece = getPieceType(cell, solution, grid, isEndOrStart)
		cellPiece.Parent = puzzle
		currentCell.piece = cellPiece
		
		-- Compute a world relative CFrame for the piece.
		local relativeCFrame = CFrame.new(pieceDimensions * -(charToNum(cell.column) - 1), pieceDimensions * -(cell.row - 1), 0)
		local worldCFrame = puzzleStart.CFrame:ToWorldSpace(relativeCFrame)
		
		-- Apply a random rotation to the cell.\
		local flips = math.random(1, 4)
		local rotationCFrame = CFrame.Angles(0, 0, flips * math.pi / 2)
		worldCFrame *= rotationCFrame
		
		-- Store the current rotation.
		currentCell.rotation = flips * (math.pi / 2)
		
		-- Setup Events --
		local clickDebounce = false
		local clickDetector = cellPiece.Hitbox.ClickDetector
		clickDetector.MouseClick:Connect(function ()
			
			-- Return if the debounce is on / puzzle is currently moving.
			if clickDebounce then 
				return
			end
			
			-- Toggle debounce.
			clickDebounce = true
			
			-- Calculate the amount to rotate the piece by.
			local angleChange = math.pi / 2
			currentCell.rotation = clampAngle(currentCell.rotation + angleChange)
			local currentCFrame = cellPiece.PrimaryPart.CFrame
			currentCFrame *= CFrame.Angles(0, 0, angleChange)
			
			-- Rotate the piece gradually.
			tweenService:Create(cellPiece.PrimaryPart, defaultTween, {
				CFrame = currentCFrame
			}):Play()
			
			local isComplete = checkPuzzle(grid, startingRow, exitRow)
			if isComplete then
				highlightBindableEvent:Fire(cellPiece.Pipe, highlightMode.Hide)
				disablePuzzle()
			end			
			
			-- Toggle debouncecurrentCFrame
			task.wait(defaultTween.Time)
			clickDebounce = false
		end)
		
		clickDetector.MouseHoverEnter:Connect(function ()
			highlightBindableEvent:Fire(cellPiece.Pipe, highlightMode.Show)
		end)
		
		clickDetector.MouseHoverLeave:Connect(function ()
			highlightBindableEvent:Fire(cellPiece.Pipe, highlightMode.Hide)
		end)
		
		-- Move the model to the position.
		cellPiece:PivotTo(worldCFrame)
	end
	
	-- Populate non-solution grid spaces.
	for rowNum, row in grid do
		
		for column, cell in row do
			
			if cell.solution then
				continue
			end
			
			local randomPiece = pieces[math.random(2,4)]:Clone()
			cell.piece = randomPiece
			randomPiece.Parent = puzzle
			
			-- Compute a world relative CFrame for the piece.
			local relativeCFrame = CFrame.new(pieceDimensions * -(charToNum(column) - 1), pieceDimensions * -(rowNum - 1), 0)
			local worldCFrame = puzzleStart.CFrame:ToWorldSpace(relativeCFrame)
			
			-- Apply a random rotation to the cell.\
			local flips = math.random(1, 4)
			local rotationCFrame = CFrame.Angles(0, 0, flips * math.pi / 2)
			worldCFrame *= rotationCFrame

			-- Store the current rotation.
			cell.rotation = flips * (math.pi / 2)
			
			-- Setup Events --
			local clickDebounce = false
			local clickDetector = randomPiece.Hitbox.ClickDetector

			clickDetector.MouseClick:Connect(function ()

				-- Return if the debounce is on / puzzle is currently moving.
				if clickDebounce then 
					return
				end

				-- Toggle debounce.
				clickDebounce = true

				-- Calculate the amount to rotate the piece by.
				local angleChange = math.pi / 2
				cell.rotation = clampAngle(cell.rotation + angleChange)
				local currentCFrame = randomPiece.PrimaryPart.CFrame
				currentCFrame *= CFrame.Angles(0, 0, angleChange)

				-- Rotate the piece gradually.
				tweenService:Create(randomPiece.PrimaryPart, defaultTween, {
					CFrame = currentCFrame
				}):Play()

				local isComplete = checkPuzzle(grid, startingRow, exitRow)
				if isComplete then
					highlightBindableEvent:Fire(randomPiece.Pipe, highlightMode.Hide)
					disablePuzzle()
				end	
				
				-- Toggle debouncecurrentCFrame
				task.wait(defaultTween.Time)
				clickDebounce = false
			end)

			clickDetector.MouseHoverEnter:Connect(function ()
				highlightBindableEvent:Fire(randomPiece.Pipe, highlightMode.Show)
			end)

			clickDetector.MouseHoverLeave:Connect(function ()
				highlightBindableEvent:Fire(randomPiece.Pipe, highlightMode.Hide)
			end)
			
			-- Move the model to the position.
			randomPiece:PivotTo(worldCFrame)
		end
	end
	
	-- Setup the start and end row pipes.
	local startPipeClone = startPipe:Clone()
	startPipeClone.Parent = pipeQuest
	
	local relativeStartCFrame = CFrame.new(pieceDimensions, -(startingRow-1) * pieceDimensions, 0)
	local worldCStartFrame = puzzleStart.CFrame:ToWorldSpace(relativeStartCFrame)
	startPipeClone:PivotTo(worldCStartFrame)
	
	local endPipeClone = endPipe:Clone()
	endPipeClone.Parent = pipeQuest

	local relativeEndCFrame = CFrame.new(-columns * pieceDimensions, -(exitRow-1) * pieceDimensions, 0)
	local worldEndCFrame = puzzleStart.CFrame:ToWorldSpace(relativeEndCFrame)
	endPipeClone:PivotTo(worldEndCFrame)
end

-- Create the actual puzzle.
task.wait(10)
buildPuzzle()