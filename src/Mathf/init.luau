--!strict
-- Mathf
-- Vadym Vaist

--[=[
	@class Mathf
]=]
local Mathf = {}

local VECTOR3_ZERO = Vector3.zero
local PI = math.pi
local TAU = PI * 2

local WeightRandom = Random.new()
local RNG = Random.new()


--[=[
	Returns a random element from the provided table, with weights for each element.

	**Usage Notes:**
	- Higher weight values increase the probability of selection
	- Weight of 0 means the element will never be selected
	- Returns nil if the table is empty
	- Total weight sum is calculated automatically

	**Example:**
	```lua
	local items = {
		["Common"] = 70,
		["Rare"] = 25,
		["Legendary"] = 5
	}
	local result = Mathf.GetWeighedRandom(items)
	print("Got:", result) -- More likely to be "Common"
	```

	@param tab { [K]: number } -- Table with elements as keys and weights as values
	@return K? -- Random element from the table, or nil if empty
]=]
function Mathf.GetWeighedRandom<K>(tab: { [K]: number }): K?
    local total = 0

    for index, weight in tab do
        total += weight
    end

    local random = WeightRandom:NextNumber(0, total)

    for index, weight in tab do
        random -= weight
        if random <= 0 then
            return index
        end
    end

    return next(tab)
end


--[=[
	Calculates frame delta for smooth animation based on the provided multiplier and delta time.

	**Usage Notes:**
	- Ensures consistent animation speed regardless of frame rate
	- mult should be between 0 and 1 for typical use cases
	- Works with RunService:BindToRenderStep or Heartbeat delta
	- Formula compensates for variable frame rates

	**Example:**
	```lua
	local position = 0
	local target = 100
	RunService.Heartbeat:Connect(function(delta)
		position += (target - position) * Mathf.FrameDelta(0.1, delta)
	end)
	```

	@param mult number -- Animation speed multiplier (0-1 typical range)
	@param delta number -- Frame delta time in seconds
	@return number -- Adjusted delta value for smooth animation
]=]
function Mathf.FrameDelta(mult: number, delta: number): number
    return 1 - (1 - mult) ^ (delta * 60)
end


--[=[
	Randomly deviates a vector within specified radian spreads on X and Y axes.

	**Usage Notes:**
	- Useful for bullet spread, cone effects, or particle dispersion
	- Spreads are in radians (use math.rad() to convert from degrees)
	- Maintains the original vector's magnitude
	- Creates a cone of possible directions

	**Example:**
	```lua
	local bulletDirection = Vector3.new(0, 0, -1)
	local spread = Mathf.RandomizeVector(bulletDirection, math.rad(5), math.rad(5))
	-- Bullet will deviate up to 5 degrees in any direction
	```

	@param basisVector Vector3 -- The base direction vector
	@param radianSpreadX number -- Maximum deviation in radians on X axis
	@param radianSpreadY number -- Maximum deviation in radians on Y axis
	@return Vector3 -- Randomized vector with same magnitude as input
]=]
function Mathf.RandomizeVector(basisVector: Vector3, radianSpreadX: number, radianSpreadY: number): Vector3
    local zVector = basisVector.Unit
    local xVector = zVector:Cross(Vector3.yAxis).Unit
    local yVector = zVector:Cross(xVector).Unit
    local deviatedRot = CFrame.fromMatrix(Vector3.one, xVector, yVector, zVector)
        * CFrame.Angles(RNG:NextNumber(-radianSpreadX, radianSpreadX), RNG:NextNumber(-radianSpreadY, radianSpreadY), 0)
    return deviatedRot.ZVector * basisVector.Magnitude
end


--[=[
	Safely interpolates between two values or colors, handling nil cases.

	**Usage Notes:**
	- Returns b if a is nil or t >= 1
	- Returns a if b is nil or t <= 0
	- Uses gamma-correct interpolation for Color3
	- Safe to use with potentially undefined values

	**Example:**
	```lua
	local color1 = Color3.new(1, 0, 0) -- Red
	local color2 = Color3.new(0, 0, 1) -- Blue
	local mixed = Mathf.SafeLerp(color1, color2, 0.5) -- Purple
	```

	@param a number | Color3 -- Start value or color
	@param b number | Color3 -- End value or color
	@param t number -- Interpolation factor (0-1)
	@return number | Color3 -- Interpolated value or color
]=]
function Mathf.SafeLerp(a: number | Color3, b: number | Color3, t: number)
    if a == nil or t >= 1 then
        return b
    elseif b == nil or t <= 0 then
        return a
    end

    if typeof(a) == "Color3" and typeof(b) == "Color3" then
        local it = 1 - t

        return Color3.new(
            (a.R ^ 2 * it + b.R ^ 2 * t) ^ 0.5,
            (a.G ^ 2 * it + b.G ^ 2 * t) ^ 0.5,
            (a.B ^ 2 * it + b.B ^ 2 * t) ^ 0.5
        )
    end

    return (a :: number) * (1 - t) + (b :: number) * t
end

-- Numbers

--[=[
	Calculates the percentage a number is between two other numbers.

	**Usage Notes:**
	- Returns 0 if num <= min
	- Returns 1 if num >= max
	- Returns 1 if min equals max (prevents division by zero)
	- Useful for progress bars and UI elements

	**Example:**
	```lua
	local health = 75
	local percent = Mathf.PercentBetween(health, 0, 100)
	print(percent) -- 0.75
	```

	@param num number -- The value to evaluate
	@param min number -- Minimum bound
	@param max number -- Maximum bound
	@return number -- Percentage between 0 and 1
]=]
function Mathf.PercentBetween(num: number, min: number, max: number): number
    return (max - min) == 0 and 1 or math.clamp((num - min) / (max - min), 0, 1)
end

--[=[
	Rounds a number to the nearest grid value with optional offset.

	**Usage Notes:**
	- Grid defines the rounding increment (e.g., 5 rounds to nearest 5)
	- Offset adjusts rounding behavior (default 0.5 for standard rounding)
	- Offset of 0 rounds down, 1 rounds up
	- Useful for snap-to-grid mechanics

	**Example:**
	```lua
	local rounded = Mathf.Round(23, 5) -- 25
	local floored = Mathf.Round(23, 5, 0) -- 20
	```

	@param num number -- Number to round
	@param grid number -- Grid size for rounding
	@param offset number? -- Rounding offset (default 0.5)
	@return number -- Rounded value
]=]
function Mathf.Round(num: number, grid: number, offset: number?): number
    return math.floor(num / grid + (offset or 0.5)) * grid
end

--[=[
	Rounds a number to the nearest integer.

	**Usage Notes:**
	- Rounds 0.5 up for positive numbers
	- Rounds -0.5 down for negative numbers
	- Equivalent to Round(x, 1, 0.5)
	- Faster than the generic Round function

	**Example:**
	```lua
	print(Mathf.RoundNumber(3.7)) -- 4
	print(Mathf.RoundNumber(-3.7)) -- -4
	```

	@param x number -- Number to round
	@return number -- Nearest integer
]=]
function Mathf.RoundNumber(x: number): number
    return if x >= 0 then math.floor(x + 0.5) else math.ceil(x - 0.5)
end

--[=[
	Linearly interpolates between two numbers.

	**Usage Notes:**
	- t = 0 returns a
	- t = 1 returns b
	- t can be outside 0-1 range for extrapolation
	- For clamped interpolation, use math.clamp on t

	**Example:**
	```lua
	local start = 0
	local finish = 100
	local halfway = Mathf.Lerp(start, finish, 0.5) -- 50
	```

	@param a number -- Start value
	@param b number -- End value
	@param t number -- Interpolation factor
	@return number -- Interpolated value
]=]
function Mathf.Lerp(a: number, b: number, t: number): number
    return a * (1 - t) + b * t
end

--[=[
	Smoothly interpolates between two numbers using cosine interpolation.

	**Usage Notes:**
	- Provides ease-in-ease-out effect
	- Smoother than linear interpolation at edges
	- Returns exact values at t=0 and t=1 (within epsilon)
	- Uses cosine function for smooth curve

	**Example:**
	```lua
	-- Animation with smooth start and end
	local position = Mathf.SmoothLerp(0, 100, progress)
	```

	@param a number -- Start value
	@param b number -- End value
	@param t number -- Interpolation factor (0-1)
	@return number -- Smoothly interpolated value
]=]
function Mathf.SmoothLerp(a: number, b: number, t: number): number
    return if t < 0.001 then a elseif t > 0.999 then b else Mathf.Lerp(a, b, (1 - math.cos(t * PI)) / 2)
end

--[=[
	Linearly interpolates towards a target number with a given step size.

	**Usage Notes:**
	- Will not overshoot the goal
	- t is the maximum distance to move, not a percentage
	- Always moves closer to goal (or stays the same)
	- Useful for smooth following behavior

	**Example:**
	```lua
	local current = 10
	local target = 100
	current = Mathf.LerpTowards(current, target, 5) -- 15
	```

	@param n number -- Current value
	@param g number -- Goal value
	@param t number -- Maximum step size (positive)
	@return number -- New value closer to goal
]=]
function Mathf.LerpTowards(n: number, g: number, t: number): number
    if n < g then
        return math.clamp(n + t, n, g)
    else
        return math.clamp(n - t, g, n)
    end
end

--[=[
	Wraps a number within a range.

	**Usage Notes:**
	- Range is [min, max)
	- Works like modulo but for arbitrary ranges
	- Handles negative numbers correctly
	- Does not clamp, values wrap around

	**Example:**
	```lua
	local angle = Mathf.Wrap(370, 0, 360) -- 10
	local wrapped = Mathf.Wrap(-5, 0, 10) -- 5
	```

	@param num number -- Number to wrap
	@param min number -- Minimum bound (inclusive)
	@param max number -- Maximum bound (exclusive)
	@return number -- Wrapped value
]=]
function Mathf.Wrap(num: number, min: number, max: number): number
    return min + (num - min) % (max - min)
end

--[=[
	Wraps an index within a given length (1-based indexing).

	**Usage Notes:**
	- Designed for Lua's 1-based arrays
	- Length 5 wraps to range [1, 5]
	- Useful for circular buffers or looping arrays
	- Handles negative indices correctly

	**Example:**
	```lua
	local array = {10, 20, 30, 40, 50}
	local index = Mathf.WrapIndex(7, #array) -- 2
	print(array[index]) -- 20
	```

	@param num number -- Index to wrap
	@param length number -- Array length
	@return number -- Wrapped index (1-based)
]=]
function Mathf.WrapIndex(num: number, length: number): number
    return Mathf.Wrap(num, 1, length + 1)
end

--[=[
	Performs cubic interpolation between four vectors.

	**Usage Notes:**
	- Creates smooth curves through multiple points
	- v1 and v2 are the interpolation segment
	- v0 and v3 provide curve context
	- x should be between 0 and 1 for segment v1-v2

	**Example:**
	```lua
	-- Smooth path through waypoints
	local points = {wp0, wp1, wp2, wp3}
	local position = Mathf.Cubic_Interpolate(
		points[1], points[2], points[3], points[4], 0.5
	)
	```

	@param v0 Vector3 -- Previous control point
	@param v1 Vector3 -- Start point
	@param v2 Vector3 -- End point
	@param v3 Vector3 -- Next control point
	@param x number -- Interpolation factor (0-1)
	@return Vector3 -- Interpolated position
]=]
function Mathf.Cubic_Interpolate(v0: Vector3, v1: Vector3, v2: Vector3, v3: Vector3, x: number): Vector3
    local P = (v3 - v2) - (v0 - v1)
    local Q = (v0 - v1) - P
    local R = v2 - v0
    local S = v1

    return P * x ^ 3 + Q * x ^ 2 + R * x + S
end

--[=[
	Maps a number from one range to another.

	**Usage Notes:**
	- Throws error if input range is zero (min0 == max0)
	- Linear transformation between ranges
	- Can extrapolate beyond target range if num outside input range
	- Useful for converting between different value systems

	**Example:**
	```lua
	-- Convert 0-100 health to 0-1 UI scale
	local healthPercent = Mathf.Map(75, 0, 100, 0, 1) -- 0.75
	-- Convert temperature F to C
	local celsius = Mathf.Map(32, 32, 212, 0, 100) -- 0
	```

	@param num number -- Input value
	@param min0 number -- Input range minimum
	@param max0 number -- Input range maximum
	@param min1 number -- Output range minimum
	@param max1 number -- Output range maximum
	@return number -- Mapped value in output range
]=]
function Mathf.Map(num: number, min0: number, max0: number, min1: number, max1: number): number
	if max0 == min0 then
		error("Range of zero")
	end

	return (((num - min0) * (max1 - min1)) / (max0 - min0)) + min1
end

--[=[
	Solves for angle across from side c using law of cosines.

	**Usage Notes:**
	- Returns nil if triangle is impossible (invalid side lengths)
	- Returns angle in radians
	- All sides must be positive
	- Useful for inverse kinematics and triangle solving

	**Example:**
	```lua
	local angle = Mathf.LawOfCosines(3, 4, 5)
	if angle then
		print(math.deg(angle)) -- ~90 degrees for right triangle
	end
	```

	@param a number -- Side length a
	@param b number -- Side length b
	@param c number -- Side length c (opposite to returned angle)
	@return number? -- Angle in radians, or nil if impossible
]=]
function Mathf.LawOfCosines(a: number, b: number, c: number): number?
	local l = (a * a + b * b - c * c) / (2 * a * b)
	local angle = math.acos(l)
	if angle ~= angle then -- NaN check
		return nil
	end
	return angle
end

--[=[
	Rounds up to the nearest multiple of precision.

	**Usage Notes:**
	- Always rounds towards positive infinity
	- precision must be positive
	- Useful for allocating memory or grid alignment
	- Complements RoundDown

	**Example:**
	```lua
	local rounded = Mathf.RoundUp(23, 5) -- 25
	local rounded = Mathf.RoundUp(20, 5) -- 20
	```

	@param number number -- Number to round
	@param precision number -- Rounding precision
	@return number -- Rounded up value
]=]
function Mathf.RoundUp(number: number, precision: number): number
	return math.ceil(number / precision) * precision
end

--[=[
	Rounds down to the nearest multiple of precision.

	**Usage Notes:**
	- Always rounds towards negative infinity
	- precision must be positive
	- Useful for truncating to grid or quantizing values
	- Complements RoundUp

	**Example:**
	```lua
	local rounded = Mathf.RoundDown(23, 5) -- 20
	local rounded = Mathf.RoundDown(20, 5) -- 20
	```

	@param number number -- Number to round
	@param precision number -- Rounding precision
	@return number -- Rounded down value
]=]
function Mathf.RoundDown(number: number, precision: number): number
	return math.floor(number / precision) * precision
end

-- Vectors

--[=[
	Spherically interpolates between two vectors.

	**Usage Notes:**
	- Maintains constant length during interpolation
	- Creates arc motion between vectors
	- More natural than linear interpolation for rotations
	- Result has same length as interpolated CFrame's LookVector

	**Example:**
	```lua
	local lookDir = Vector3.new(1, 0, 0)
	local targetDir = Vector3.new(0, 1, 0)
	local smoothDir = Mathf.SlerpVector(lookDir, targetDir, 0.5)
	-- Result follows curved path, not straight line
	```

	@param a Vector3 -- Start vector
	@param b Vector3 -- End vector
	@param t number -- Interpolation factor (0-1)
	@return Vector3 -- Spherically interpolated vector
]=]
function Mathf.SlerpVector(a: Vector3, b: Vector3, t: number): Vector3
    return (CFrame.lookAt(VECTOR3_ZERO, a):Lerp(CFrame.lookAt(VECTOR3_ZERO, b), t)).LookVector
end

-- Color3

--[=[
	Linearly interpolates between two colors using gamma-correct interpolation.

	**Usage Notes:**
	- Uses perceptually correct interpolation (gamma space)
	- Prevents colors from appearing too dark in middle
	- More accurate than component-wise linear interpolation
	- Same algorithm as SafeLerp for Color3

	**Example:**
	```lua
	local red = Color3.new(1, 0, 0)
	local blue = Color3.new(0, 0, 1)
	local purple = Mathf.LerpColor3(red, blue, 0.5)
	```

	@param a Color3 -- Start color
	@param b Color3 -- End color
	@param t number -- Interpolation factor (0-1)
	@return Color3 -- Interpolated color
]=]
function Mathf.LerpColor3(a: Color3, b: Color3, t: number): Color3
    local it = 1 - t

    return Color3.new(
        (a.R ^ 2 * it + b.R ^ 2 * t) ^ 0.5,
        (a.G ^ 2 * it + b.G ^ 2 * t) ^ 0.5,
        (a.B ^ 2 * it + b.B ^ 2 * t) ^ 0.5
    )
end

-- Other

--[=[
	Checks if a position is within the bounding box of a part.

	**Usage Notes:**
	- Works with rotated parts (uses CFrame space)
	- sizemult scales the bounding box (1 = exact size)
	- Does not account for part shape (treats all as boxes)
	- Useful for trigger zones and collision detection

	**Example:**
	```lua
	local isInside = Mathf.InPart(workspace.Zone, player.Position)
	-- Check with 10% margin
	local isNear = Mathf.InPart(workspace.Zone, player.Position, 1.1)
	```

	@param part BasePart -- Part to check against
	@param pos Vector3 -- Position to test
	@param sizemult number? -- Size multiplier (default 1)
	@return boolean -- True if position is inside the part
]=]
function Mathf.InPart(part: BasePart, pos: Vector3, sizemult: number?): boolean
    local rel = part.CFrame:PointToObjectSpace(pos)
    local size = part.Size * (sizemult or 1)
    size /= 2

    return math.abs(rel.X) <= size.X and math.abs(rel.Y) <= size.Y and math.abs(rel.Z) <= size.Z
end

--[=[
	Reflects a vector off a surface with the given normal.

	**Usage Notes:**
	- Normal does not need to be unit length
	- Returns vector with same magnitude as input
	- Follows physics reflection formula
	- Useful for bouncing projectiles or mirror effects

	**Example:**
	```lua
	local velocity = Vector3.new(10, -10, 0) -- Moving down-right
	local ground = Vector3.new(0, 1, 0) -- Up normal
	local bounced = Mathf.ReflectVector(velocity, ground)
	-- Result: Vector3.new(10, 10, 0) - bounced up-right
	```

	@param vector Vector3 -- Incident vector
	@param normal Vector3 -- Surface normal
	@return Vector3 -- Reflected vector
]=]
function Mathf.ReflectVector(vector: Vector3, normal: Vector3): Vector3
    local projection = (vector:Dot(normal) / normal.Magnitude ^ 2) * normal
    local reflection = vector - 2 * projection
    return reflection
end

--[=[
	Solves inverse kinematics for a two-bone chain.

	**Usage Notes:**
	- Returns base orientation and two joint angles
	- Handles unreachable targets (fully extended)
	- Handles targets too close (folded back)
	- Angles are in radians
	- Used for arm/leg IK systems

	**Example:**
	```lua
	local shoulder = Vector3.new(0, 5, 0)
	local hand = Vector3.new(3, 2, 0)
	local upperArm = 2
	local forearm = 2
	local cf, angle1, angle2 = Mathf.IK(shoulder, hand, upperArm, forearm)
	-- Apply angles to joints
	```

	@param a Vector3 -- Joint pivot position
	@param b Vector3 -- End point target position
	@param l1 number -- Length of first bone
	@param l2 number -- Length of second bone
	@return CFrame -- Base orientation from a to b
	@return number -- First joint angle in radians
	@return number -- Second joint angle in radians
]=]
function Mathf.IK(a: Vector3, b: Vector3, l1: number, l2: number): (CFrame, number, number)
    local aToB = CFrame.lookAt(a, b)
    local aDistB = (a - b).Magnitude
    if aDistB >= l1 + l2 then
        return aToB, 0, 0
    end

    if aDistB < (math.max(l1, l2) - math.min(l1, l2)) then
        return aToB, 0, PI
    end

    b = aToB:PointToObjectSpace(b)

    local bZ = b.Z
    local x = (bZ ^ 2 - l2 ^ 2 + l1 ^ 2) / (2 * bZ)
    local y = math.sqrt(1 - (x / l1) ^ 2) * l1
    local a1 = -math.asin(y / ((x ^ 2 + y ^ 2) ^ 0.5))
    local a2 = if x < bZ
        then -PI + math.asin(-y / (((bZ - x) ^ 2 + y ^ 2) ^ 0.5))
        else -math.asin(-y / (((bZ - x) ^ 2 + y ^ 2) ^ 0.5))

    return aToB, a1, a2 - a1
end


--[=[
	Converts a world position to screen coordinates relative to a UI reference frame.

	**Usage Notes:**
	- Returns pixel coordinates adjusted for camera roll
	- Points behind camera return (20000, 20000) - off-screen
	- Accounts for FOV and aspect ratio
	- Subtracts 36 from Y for UI offset
	- Reference frame provides screen dimensions

	**Example:**
	```lua
	local camera = workspace.CurrentCamera
	local screenGui = player.PlayerGui.ScreenGui
	local x, y = Mathf.Vector3ToPixel(
		workspace.Target.Position,
		camera,
		screenGui.Frame
	)
	-- Position UI element at world position
	```

	@param position Vector3 -- World position to convert
	@param camera Camera -- Camera instance
	@param reference Frame -- UI frame for screen dimensions
	@return number -- Screen X coordinate in pixels
	@return number -- Screen Y coordinate in pixels
]=]
function Mathf.Vector3ToPixel(position: Vector3, camera: Camera, reference: Frame): (number, number)
    local screen_width = reference.AbsoluteSize.X
    local screen_height = reference.AbsoluteSize.Y
    local point = (camera.CFrame * CFrame.Angles(0, 0, -camera:GetRoll())):Inverse() * position
    local fovMult = 1 / math.tan(math.rad(camera.FieldOfView) / 2)
    local x = screen_width / 2 * (1 + point.X / -point.Z * fovMult * screen_height / screen_width)
    local y = screen_height / 2 * (1 + point.Y / -point.Z * fovMult)
    if point.Z > 0 then
        x = 20000
        y = 20000
    end

    return x, screen_height - y - 36
end


--[=[
	Linearly interpolates between two angles in degrees.

	**Usage Notes:**
	- Takes shortest path around circle
	- Handles wrap-around at 360 degrees
	- Returns angle in range [-180, 180]
	- Works with any angle values (not limited to 0-360)

	**Example:**
	```lua
	local from = 350 -- degrees
	local to = 10 -- degrees
	local mid = Mathf.LerpAngle(from, to, 0.5) -- 0 (not 180!)
	```

	@param a number -- Start angle in degrees
	@param b number -- End angle in degrees
	@param t number -- Interpolation factor (0-1)
	@return number -- Interpolated angle in degrees [-180, 180]
]=]
function Mathf.LerpAngle(
    a: number,
    b: number,
    t: number
): number
    local ret

    if a - b < 180 then
        ret = a + (b - a) * t
    else
        ret = a + (360 + b - a) * t
    end

    return (ret - 180) % 360 - 180
end


--[=[
	Linearly interpolates between two angles in radians.

	**Usage Notes:**
	- Takes shortest path around circle
	- Handles wrap-around at 2π
	- Returns angle in range [0, 2π]
	- Converts to degrees internally for calculation

	**Example:**
	```lua
	local from = math.rad(350)
	local to = math.rad(10)
	local mid = Mathf.LerpRadAngle(from, to, 0.5) -- ~0 radians
	```

	@param a1 number -- Start angle in radians
	@param a2 number -- End angle in radians
	@param percent number -- Interpolation factor (0-1)
	@return number -- Interpolated angle in radians [0, 2π]
]=]
function Mathf.LerpRadAngle(a1: number, a2: number, percent: number): number
    a1 = math.deg(a1)
    a2 = math.deg(a2)
    local difference = math.abs(a2 - a1)
    if difference > 180 then
        if a2 > a1 then
            a1 += 360
        else
            a2 += 360
        end
    end
    a1 = math.rad(a1)
    a2 = math.rad(a2)
    return Mathf.Wrap(Mathf.Lerp(a1, a2, percent), 0, TAU)
end


--[=[
	Linearly interpolates towards a target angle with a given step size.

	**Usage Notes:**
	- Takes shortest path around circle
	- Will not overshoot target
	- t is maximum degrees to move, not percentage
	- Handles angle wrap-around automatically

	**Example:**
	```lua
	local current = 350
	local target = 10
	current = Mathf.LerpTowardsAngle(current, target, 5) -- 355
	-- Next frame: 0, then 5, then 10 (stops at target)
	```

	@param a1 number -- Current angle in degrees
	@param a2 number -- Target angle in degrees
	@param t number -- Maximum step size in degrees
	@return number -- New angle closer to target
]=]
function Mathf.LerpTowardsAngle(a1: number, a2: number, t: number): number
    local dist = math.abs(a2 - a1)
    if dist > 180 then
        if a1 > a2 then
            a1 += 360
        else
            a2 += 360
        end
    end
    return Mathf.LerpTowards(a1, a2, t)
end

--[=[
	Linearly interpolates between two angles in degrees with adjusted range [-180, 180].

	**Usage Notes:**
	- Similar to LerpAngle but uses different normalization
	- Takes shortest path around circle
	- Returns angle in range [-180, 180]
	- Adds 180 offset during calculation

	**Example:**
	```lua
	local from = 170
	local to = -170
	local mid = Mathf.LerpAngle2(from, to, 0.5) -- 180 or -180
	```

	@param a1 number -- Start angle in degrees
	@param a2 number -- End angle in degrees
	@param percent number -- Interpolation factor (0-1)
	@return number -- Interpolated angle in degrees [-180, 180]
]=]
function Mathf.LerpAngle2(a1: number, a2: number, percent: number): number
    a1 += 180
    a2 += 180
    local difference = math.abs(a2 - a1)
    if difference > 180 then
        if a2 > a1 then
            a2 -= 360
        else
            a1 -= 360
        end
    end
    a1 = (a1 - 180)
    a2 = (a2 - 180)
    return Mathf.Wrap(Mathf.Lerp(a1, a2, percent), -180, 180)
end


--[=[
	Calculates the shortest angular distance between two angles in degrees.

	**Usage Notes:**
	- Returns signed distance (positive or negative)
	- Takes shortest path around circle
	- Result in radians despite input in degrees
	- Useful for determining rotation direction

	**Example:**
	```lua
	local current = 10
	local target = 350
	local distance = Mathf.AngleDistance(
		math.rad(current),
		math.rad(target)
	)
	-- Negative value means rotate counter-clockwise
	```

	@param a1 number -- First angle in radians
	@param a2 number -- Second angle in radians
	@return number -- Angular distance in radians
]=]
function Mathf.AngleDistance(a1: number, a2: number): number
    a1 = math.deg(a1)
    a2 = math.deg(a2)
    local difference = math.abs(a2 - a1)
    if difference > 180 then
        if a1 > a2 then
            a2 += 360
        else
            a1 += 360
        end
    end
    return math.rad(a1 - a2)
end


--[=[
	Interpolates between two CFrames.

	**Usage Notes:**
	- Returns exact values at t=0 and t=1 (within epsilon)
	- Interpolates both position and rotation
	- Uses CFrame:Lerp internally
	- Optimized to skip calculation at extremes

	**Example:**
	```lua
	local start = CFrame.new(0, 0, 0)
	local finish = CFrame.new(10, 0, 0) * CFrame.Angles(0, math.pi, 0)
	local middle = Mathf.InterpolateCFrame(start, finish, 0.5)
	part.CFrame = middle
	```

	@param CF1 CFrame -- Start CFrame
	@param CF2 CFrame -- End CFrame
	@param percent number -- Interpolation factor (0-1)
	@return CFrame -- Interpolated CFrame
]=]
function Mathf.InterpolateCFrame(CF1: CFrame, CF2: CFrame, percent: number): CFrame
    return if percent < 0.001 then CF1 elseif percent > 0.999 then CF2 else CF1:Lerp(CF2, percent)
end

export type Mathf = typeof(Mathf)
return Mathf