--!strict
-- BezierFactory
-- Vadym Vaist

--[=[
	@class BezierFactory
]=]
local BezierFactory = {}

--[=[
	Creates a cubic Bezier easing function with custom control points.
	Control points define the shape of the interpolation curve.

	**Usage Notes:**
	- Control points (P1x, P1y) and (P2x, P2y) define the curve shape
	- X values should typically be in range [0, 1] for predictable results
	- Y values can exceed [0, 1] for overshoot/undershoot effects
	- Uses Newton-Raphson iteration for accurate time calculation
	- Compatible with CSS cubic-bezier() format

	**Common Presets:**
	```lua
	-- Ease-in-out (smooth start and end)
	local ease = BezierFactory.Create(0.42, 0, 0.58, 1)

	-- Ease-out (fast start, slow end)
	local easeOut = BezierFactory.Create(0, 0, 0.58, 1)

	-- Ease-in (slow start, fast end)
	local easeIn = BezierFactory.Create(0.42, 0, 1, 1)

	-- Bounce effect (overshoot)
	local bounce = BezierFactory.Create(0.68, -0.55, 0.265, 1.55)
	```

	**Example:**
	```lua
	local customEase = BezierFactory.Create(0.25, 0.1, 0.25, 1)

	-- Animate from 0 to 100 over time 0-1
	for t = 0, 1, 0.1 do
		local value = customEase(t) * 100
		print(string.format("Time: %.1f, Value: %.1f", t, value))
	end
	```

	@param P1x number -- First control point X coordinate (typically 0-1)
	@param P1y number -- First control point Y coordinate (can be any value)
	@param P2x number -- Second control point X coordinate (typically 0-1)
	@param P2y number -- Second control point Y coordinate (can be any value)
	@return function -- Easing function that takes time [0-1] and returns interpolated value
]=]
function BezierFactory.Create(P1x: number, P1y: number, P2x: number, P2y: number): (number) -> number
	assert(P1x ~= nil, "[BezierFactory] P1x is required")
	assert(P1y ~= nil, "[BezierFactory] P1y is required")
	assert(P2x ~= nil, "[BezierFactory] P2x is required")
	assert(P2y ~= nil, "[BezierFactory] P2y is required")

	-- Coefficient calculations for cubic Bezier formula
	local function CalculateA(aA1: number, aA2: number): number
		return 1.0 - 3.0 * aA2 + 3.0 * aA1
	end

	local function CalculateB(aA1: number, aA2: number): number
		return 3.0 * aA2 - 6.0 * aA1
	end

	local function CalculateC(aA1: number): number
		return 3.0 * aA1
	end

	-- Computes the Bezier curve value at time t
	-- Returns x(t) given t, x1, x2 or y(t) given t, y1, y2
	local function EvaluateBezier(t: number, a1: number, a2: number): number
		return ((CalculateA(a1, a2) * t + CalculateB(a1, a2)) * t + CalculateC(a1)) * t
	end

	-- Computes the derivative (slope) of the Bezier curve at time t
	-- Returns dx/dt or dy/dt depending on control points provided
	local function CalculateSlope(t: number, a1: number, a2: number): number
		return 3.0 * CalculateA(a1, a2) * t * t + 2.0 * CalculateB(a1, a2) * t + CalculateC(a1)
	end

	-- Uses Newton-Raphson method to find t for a given x
	-- Iteratively refines the guess for better precision
	local function SolveTForX(targetX: number): number
		local guessT = targetX

		-- 4 iterations provides good balance of accuracy and performance
		for _ = 1, 4 do
			local currentSlope = CalculateSlope(guessT, P1x, P2x)

			-- Avoid division by zero
			if currentSlope == 0 then
				return guessT
			end

			local currentX = EvaluateBezier(guessT, P1x, P2x) - targetX
			guessT = guessT - currentX / currentSlope
		end

		return guessT
	end

	-- Return the easing function
	return function(normalizedTime: number): number
		-- Input: normalized time [0, 1]
		-- Output: interpolated value based on Bezier curve
		return EvaluateBezier(SolveTForX(normalizedTime), P1y, P2y)
	end
end

--[=[
	Creates a linear easing function (no acceleration/deceleration).

	**Usage Notes:**
	- Equivalent to BezierFactory.Create(0, 0, 1, 1)
	- Constant speed throughout animation
	- Useful as baseline for comparing other easing functions

	**Example:**
	```lua
	local linear = BezierFactory.Linear()
	print(linear(0.5)) -- 0.5 (exactly halfway)
	```

	@return function -- Linear easing function
]=]
function BezierFactory.Linear(): (number) -> number
	return function(t: number): number
		return t
	end
end

--[=[
	Creates an ease-in-out easing function (smooth acceleration and deceleration).
	Common default for smooth animations.

	**Usage Notes:**
	- Equivalent to CSS ease-in-out and BezierFactory.Create(0.42, 0, 0.58, 1)
	- Starts slow, speeds up in middle, slows down at end
	- Most natural feeling for UI animations

	**Example:**
	```lua
	local ease = BezierFactory.EaseInOut()
	-- Use for smooth button animations
	```

	@return function -- Ease-in-out easing function
]=]
function BezierFactory.EaseInOut(): (number) -> number
	return BezierFactory.Create(0.42, 0, 0.58, 1)
end

--[=[
	Creates an ease-out easing function (fast start, slow end).
	Great for objects coming to rest naturally.

	**Usage Notes:**
	- Equivalent to CSS ease-out and BezierFactory.Create(0, 0, 0.58, 1)
	- Rapid initial movement that gradually slows
	- Perfect for dropdown menus and sliding panels

	**Example:**
	```lua
	local easeOut = BezierFactory.EaseOut()
	-- Use for menu slide-ins
	```

	@return function -- Ease-out easing function
]=]
function BezierFactory.EaseOut(): (number) -> number
	return BezierFactory.Create(0, 0, 0.58, 1)
end

--[=[
	Creates an ease-in easing function (slow start, fast end).
	Useful for objects accelerating away.

	**Usage Notes:**
	- Equivalent to CSS ease-in and BezierFactory.Create(0.42, 0, 1, 1)
	- Gradual start that rapidly accelerates
	- Good for objects being launched or thrown

	**Example:**
	```lua
	local easeIn = BezierFactory.EaseIn()
	-- Use for projectile launches
	```

	@return function -- Ease-in easing function
]=]
function BezierFactory.EaseIn(): (number) -> number
	return BezierFactory.Create(0.42, 0, 1, 1)
end

--[=[
	Validates if control points will produce a valid monotonic curve.
	Monotonic curves don't reverse direction (always increasing or constant).

	**Usage Notes:**
	- X coordinates should be in range [0, 1] for monotonic curves
	- Non-monotonic curves can cause unexpected animation behavior
	- This function helps catch problematic control point values

	**Example:**
	```lua
	if BezierFactory.ValidateControlPoints(0.5, 0.5, 0.3, 0.8) then
		print("Valid control points")
	else
		warn("Control points may cause issues")
	end
	```

	@param P1x number -- First control point X
	@param P1y number -- First control point Y
	@param P2x number -- Second control point X
	@param P2y number -- Second control point Y
	@return boolean -- True if control points will produce a valid curve
]=]
function BezierFactory.ValidateControlPoints(P1x: number, P1y: number, P2x: number, P2y: number): boolean
	-- X coordinates should be in valid range for monotonic curve
	return P1x >= 0 and P1x <= 1 and P2x >= 0 and P2x <= 1
end

--[=[
	Samples a Bezier curve at regular intervals for visualization or debugging.

	**Usage Notes:**
	- Returns table of {time, value} pairs
	- Useful for plotting curves or debugging easing functions
	- Higher sample counts provide smoother visualization but more computation

	**Example:**
	```lua
	local ease = BezierFactory.Create(0.25, 0.1, 0.25, 1)
	local samples = BezierFactory.SampleCurve(ease, 20)

	for _, point in ipairs(samples) do
		print(string.format("t: %.2f, v: %.2f", point.time, point.value))
	end
	```

	@param easingFunction function -- The easing function to sample
	@param sampleCount number -- Number of samples to take (default: 10)
	@return table -- Array of {time: number, value: number} tables
]=]
function BezierFactory.SampleCurve(
	easingFunction: (number) -> number,
	sampleCount: number?
): { { time: number, value: number } }
	local samples = {}
	local count = sampleCount or 10

	for i = 0, count do
		local t = i / count
		table.insert(samples, {
			time = t,
			value = easingFunction(t),
		})
	end

	return samples
end

export type BezierFactory = typeof(BezierFactory)
return BezierFactory
