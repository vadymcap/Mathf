--!strict
-- ExperienceCalculator
-- Vadym Vaist

-- Calculate experience on an exponential curve and perform relevant calculations
-- Uses formulas from stackoverflow.com/questions/6954874/php-game-formula-to-calculate-a-level-based-on-exp

--[=[
	@class ExperienceCalculator
]=]
local ExperienceCalculator = {}
ExperienceCalculator._experienceFactor = 200

--[=[
	Sets the experience scaling factor that affects level progression curve.
	Higher values make leveling slower, lower values make it faster.

	**Usage Notes:**
	- Default factor is 200
	- Must be positive number
	- Affects all level calculations globally
	- Change this before performing any calculations for consistency

	**Example:**
	```lua
	ExperienceCalculator.SetExperienceFactor(150) -- Faster progression
	ExperienceCalculator.SetExperienceFactor(300) -- Slower progression
	```

	@param factor number -- The scaling factor for experience calculations
]=]
function ExperienceCalculator.SetExperienceFactor(factor: number)
	assert(factor > 0, "[Maid.AddTask] - Experience factor must be positive\n\n" .. debug.traceback())
	ExperienceCalculator._experienceFactor = factor
end

--[=[
	Gets the current experience scaling factor.

	**Usage Notes:**
	- Useful for saving/loading game settings
	- Returns the current factor being used for calculations

	**Example:**
	```lua
	local currentFactor = ExperienceCalculator.GetExperienceFactor()
	print("Current XP factor:", currentFactor) -- 200
	```

	@return number -- The current experience factor
]=]
function ExperienceCalculator.GetExperienceFactor(): number
	return ExperienceCalculator._experienceFactor
end

--[=[
	Calculates the player's level based on their total accumulated experience.

	**Usage Notes:**
	- Returns floor value (always rounds down)
	- Works with any positive experience value
	- Level 1 starts at 0 experience
	- Safe to call with math.huge (returns maximum level)

	**Example:**
	```lua
	local level = ExperienceCalculator.GetLevel(1000)
	print("Player is level:", level) -- e.g., 5
	```

	@param experience number -- Total accumulated experience points
	@return number -- The current level (rounded down)
]=]
function ExperienceCalculator.GetLevel(experience: number): number
	local factor = ExperienceCalculator._experienceFactor
	return math.floor((factor + math.sqrt(factor * factor - 4 * factor * -experience)) / (2 * factor))
end

--[=[
	Returns the total experience required to reach the next level from current level.

	**Usage Notes:**
	- Input is the CURRENT level, not experience
	- Result is the TOTAL experience needed for next level (not remaining)
	- Use GetExperienceForNextLevel() to get remaining XP needed

	**Example:**
	```lua
	local xpForLevel6 = ExperienceCalculator.GetExperienceRequiredForNextLevel(5)
	print("Total XP needed for level 6:", xpForLevel6)
	```

	@param currentLevel number -- The player's current level
	@return number -- Total experience required to reach the next level
]=]
function ExperienceCalculator.GetExperienceRequiredForNextLevel(currentLevel: number): number
	return ExperienceCalculator._experienceFactor * (currentLevel * (1 + currentLevel))
end

--[=[
	Gets the total experience required to reach a specific level.

	**Usage Notes:**
	- Input is the TARGET level you want to calculate for
	- Returns cumulative XP needed from level 0
	- Useful for displaying level requirements in UI

	**Example:**
	```lua
	local xpForLevel10 = ExperienceCalculator.GetExperienceRequiredForLevel(10)
	print("Total XP to reach level 10:", xpForLevel10)
	```

	@param level number -- The target level
	@return number -- Total experience required to reach that level
]=]
function ExperienceCalculator.GetExperienceRequiredForLevel(level: number): number
	return ExperienceCalculator.GetExperienceRequiredForNextLevel(level - 1)
end

--[=[
	Calculates how much more experience is needed to reach the next level.

	**Usage Notes:**
	- Input is CURRENT experience, not level
	- Returns remaining XP needed (not total required)
	- Returns 0 if experience is infinite (math.huge)
	- Useful for progress bars and "XP to next level" displays

	**Example:**
	```lua
	local remaining = ExperienceCalculator.GetExperienceForNextLevel(1250)
	print("XP needed for next level:", remaining)
	```

	@param currentExperience number -- Player's current total experience
	@return number -- Experience points remaining to reach next level
]=]
function ExperienceCalculator.GetExperienceForNextLevel(currentExperience: number): number
	if currentExperience - 1 == currentExperience then -- math.huge check
		return 0
	end

	local currentLevel = ExperienceCalculator.GetLevel(currentExperience)
	local experienceRequired = ExperienceCalculator.GetExperienceRequiredForNextLevel(currentLevel)

	return experienceRequired - currentExperience
end

--[=[
	Calculates progress within the current level (for progress bars).
	Returns how much XP you've earned in current level and how much is needed total.

	**Usage Notes:**
	- Perfect for progress bars: achieved/total gives you 0.0-1.0 percentage
	- Returns (1, 1) if experience is infinite
	- Both return values are always positive
	- achieved will never exceed total

	**Example:**
	```lua
	local achieved, total = ExperienceCalculator.GetSubExperience(1250)
	local percentage = achieved / total
	print(string.format("Level progress: %.1f%%", percentage * 100))
	```

	@param currentExperience number -- Player's current total experience
	@return number -- Experience achieved within current level
	@return number -- Total experience required for current level
]=]
function ExperienceCalculator.GetSubExperience(currentExperience: number): (number, number)
	if currentExperience - 1 == currentExperience then -- math.huge check
		return 1, 1
	end

	local currentLevel = ExperienceCalculator.GetLevel(currentExperience)
	local lastLevel = currentLevel - 1

	local xpForCurrentLevel = ExperienceCalculator._experienceFactor * (lastLevel * (1 + lastLevel))
	local experienceRequired = ExperienceCalculator._experienceFactor * (currentLevel * (1 + currentLevel))

	local achievedOfNext = currentExperience - xpForCurrentLevel
	local subTotalRequired = experienceRequired - xpForCurrentLevel

	return achievedOfNext, subTotalRequired
end

--[=[
	Calculates the experience difference between two levels.
	Useful for determining XP rewards or level gaps.

	**Usage Notes:**
	- Can calculate forwards (level 5 to 10) or backwards (level 10 to 5)
	- Returns absolute difference
	- Useful for milestone rewards and catch-up mechanics

	**Example:**
	```lua
	local xpGap = ExperienceCalculator.GetExperienceBetweenLevels(5, 10)
	print("XP needed to go from level 5 to 10:", xpGap)
	```

	@param fromLevel number -- Starting level
	@param toLevel number -- Target level
	@return number -- Experience difference between the two levels
]=]
function ExperienceCalculator.GetExperienceBetweenLevels(fromLevel: number, toLevel: number): number
	local fromXP = ExperienceCalculator.GetExperienceRequiredForLevel(fromLevel)
	local toXP = ExperienceCalculator.GetExperienceRequiredForLevel(toLevel)
	return math.abs(toXP - fromXP)
end

--[=[
	Calculates what level a player would reach after gaining specified experience.

	**Usage Notes:**
	- Does not modify current experience, only projects the result
	- Useful for "what if" calculations and reward previews
	- Handles overflow safely

	**Example:**
	```lua
	local futureLevel = ExperienceCalculator.ProjectLevel(1000, 500)
	print("After gaining 500 XP, you'll be level:", futureLevel)
	```

	@param currentExperience number -- Current total experience
	@param experienceGain number -- Experience to be added
	@return number -- Projected level after gaining experience
]=]
function ExperienceCalculator.ProjectLevel(currentExperience: number, experienceGain: number): number
	return ExperienceCalculator.GetLevel(currentExperience + experienceGain)
end

--[=[
	Calculates completion percentage of current level (0-100).
	Convenience function that combines GetSubExperience with percentage calculation.

	**Usage Notes:**
	- Returns value between 0 and 100
	- Useful for UI displays without manual calculation
	- Returns 100 if experience is infinite

	**Example:**
	```lua
	local percent = ExperienceCalculator.GetLevelProgressPercentage(1250)
	print(string.format("Level progress: %.1f%%", percent))
	```

	@param currentExperience number -- Player's current total experience
	@return number -- Completion percentage (0-100)
]=]
function ExperienceCalculator.GetLevelProgressPercentage(currentExperience: number): number
	local achieved, total = ExperienceCalculator.GetSubExperience(currentExperience)
	return (achieved / total) * 100
end

--[=[
	Validates if an experience value would cause a level up.

	**Usage Notes:**
	- Useful for triggering level-up events and animations
	- Check this before and after adding experience
	- Returns false if either value is infinite

	**Example:**
	```lua
	local oldXP = 1000
	local newXP = 1500
	if ExperienceCalculator.WillLevelUp(oldXP, newXP) then
		print("Level up!")
	end
	```

	@param currentExperience number -- Experience before gain
	@param newExperience number -- Experience after gain
	@return boolean -- True if the experience gain causes a level up
]=]
function ExperienceCalculator.WillLevelUp(currentExperience: number, newExperience: number): boolean
	if currentExperience - 1 == currentExperience or newExperience - 1 == newExperience then
		return false
	end

	return ExperienceCalculator.GetLevel(currentExperience) < ExperienceCalculator.GetLevel(newExperience)
end

--[=[
	Generates a lookup table of experience requirements for a range of levels.
	Useful for caching and displaying level progression tables.

	**Usage Notes:**
	- Computationally efficient for displaying multiple level requirements
	- Returns a dictionary with level as key, XP as value
	- Useful for leaderboards and progression UI

	**Example:**
	```lua
	local table = ExperienceCalculator.GenerateLevelTable(1, 20)
	for level, xp in pairs(table) do
		print(string.format("Level %d: %d XP", level, xp))
	end
	```

	@param startLevel number -- First level in the table
	@param endLevel number -- Last level in the table
	@return table -- Dictionary mapping levels to experience requirements
]=]
function ExperienceCalculator.GenerateLevelTable(startLevel: number, endLevel: number): { [number]: number }
	local levelTable = {}
	for level = startLevel, endLevel do
		levelTable[level] = ExperienceCalculator.GetExperienceRequiredForLevel(level)
	end
	return levelTable
end

return ExperienceCalculator
