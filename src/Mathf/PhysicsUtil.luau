--!strict
-- PhysicsUtil
-- Vadym Vaist

--[=[
	@class PhysicsUtil
]=]
local Workspace = game:GetService("Workspace")

local PhysicsUtil = {}

--[=[
	Standard water density constant used for buoyancy calculations.

	**Usage Notes:**
	- Default value: 1 (mass/volume)
	- Can be modified for different liquid densities
	- Used in EstimateBuoyancyContribution calculations
	- Real water density is ~1000 kg/m³, this is simplified for Roblox

	**Example:**
	```lua
	PhysicsUtil.WATER_DENSITY = 1.5 -- Denser liquid
	```
]=]
PhysicsUtil.WATER_DENSITY = 1 -- (mass/volume)

--[=[
	Retrieves all connected parts of a part, including the part itself.

	**Usage Notes:**
	- Uses recursive connection detection
	- Includes the original part in returned array
	- Works with welded, hinged, and constraint-connected parts
	- Useful for calculating properties of entire assemblies

	**Example:**
	```lua
	local car = workspace.Vehicle.Chassis
	local allParts = PhysicsUtil.GetConnectedParts(car)
	print("Vehicle has", #allParts, "parts")
	```

	@param part BasePart -- The part to get connections from
	@return {BasePart} -- Array containing all connected parts plus the original part
]=]
function PhysicsUtil.GetConnectedParts(part: BasePart): { BasePart }
	local parts = part:GetConnectedParts(true)
	parts[#parts + 1] = part
	return parts
end

--[=[
	Estimates the total buoyancy force contributed by a collection of parts.

	**Usage Notes:**
	- Only CanCollide parts contribute to buoyancy displacement
	- Returns negative values if object would sink
	- Positive values indicate floating capability
	- Uses workspace gravity for calculations
	- Assumes parts are fully submerged

	**Example:**
	```lua
	local boat = workspace.Boat
	local parts = PhysicsUtil.GetConnectedParts(boat.Hull)
	local buoyancy, mass, volume = PhysicsUtil.EstimateBuoyancyContribution(parts)

	if buoyancy > 0 then
		print("Boat will float!")
	else
		print("Boat will sink!")
	end
	```

	@param parts {BasePart} -- Array of parts to calculate buoyancy for
	@return number -- Total buoyancy force (positive = float, negative = sink)
	@return number -- Total mass of all parts
	@return number -- Total volume of collidable parts
]=]
function PhysicsUtil.EstimateBuoyancyContribution(parts: { BasePart }): (number, number, number)
	local mass = 0
	local totalVolumeApplicable = 0
	local totalFloat = 0

	for _, part in pairs(parts) do
		local partMass = part:GetMass()
		mass = mass + partMass
		totalFloat = totalFloat - partMass * Workspace.Gravity

		if part.CanCollide then
			local volume = part.Size.X * part.Size.Y * part.Size.Z
			totalFloat = totalFloat + volume * PhysicsUtil.WATER_DENSITY * Workspace.Gravity
			totalVolumeApplicable = totalVolumeApplicable + volume
		end
	end

	return totalFloat, mass, totalVolumeApplicable
end

--[=[
	Calculates the world-space center of mass for a collection of parts.

	**Usage Notes:**
	- Returns weighted average position based on part masses
	- Essential for realistic physics simulation
	- Used as pivot point for rotational physics
	- More accurate than using geometric center
	- Works with any collection of parts

	**Example:**
	```lua
	local vehicle = workspace.Car
	local parts = PhysicsUtil.GetConnectedParts(vehicle.Chassis)
	local centerOfMass, totalMass = PhysicsUtil.GetCenterOfMass(parts)

	-- Visualize center of mass
	local sphere = Instance.new("Part")
	sphere.Shape = Enum.PartType.Ball
	sphere.Size = Vector3.new(1, 1, 1)
	sphere.Position = centerOfMass
	sphere.Anchored = true
	sphere.Parent = workspace
	```

	@param parts {BasePart} -- Array of parts to calculate center of mass for
	@return Vector3 -- World position of center of mass
	@return number -- Total mass of all parts
]=]
function PhysicsUtil.GetCenterOfMass(parts: { BasePart }): (Vector3, number)
	local mass = 0
	local weightedSum = Vector3.new(0, 0, 0)

	for _, part in pairs(parts) do
		mass = mass + part:GetMass()
		weightedSum = weightedSum + part:GetMass() * part.Position
	end

	return weightedSum / mass, mass
end

--[=[
	Calculates the moment of inertia of a cuboid part around a given axis.

	**Usage Notes:**
	- Moment of inertia represents resistance to rotational acceleration
	- Higher values mean harder to rotate
	- Takes into account both part shape and position relative to axis
	- Uses parallel axis theorem for offset calculation
	- Essential for realistic torque simulation

	**Example:**
	```lua
	local part = workspace.Wheel
	local axis = Vector3.new(0, 1, 0) -- Rotation around Y axis
	local origin = part.Position
	local inertia = PhysicsUtil.MomentOfInertia(part, axis, origin)
	print("Rotational inertia:", inertia)
	```

	@param part BasePart -- The part to calculate inertia for
	@param axis Vector3 -- Axis of rotation (does not need to be unit vector)
	@param origin Vector3 -- Origin point of the rotation axis
	@return number -- Moment of inertia around the specified axis
]=]
function PhysicsUtil.MomentOfInertia(part: BasePart, axis: Vector3, origin: Vector3): number
	local PartSize = part.Size
	local mass = part:GetMass()
	local Radius = (part.Position - origin):Cross(axis)
	local r2 = Radius:Dot(Radius)
	local ip = mass * r2 -- Inertia based on Position
	local s2 = PartSize * PartSize
	local sa = (part.CFrame - part.Position):Inverse() * axis
	local id = (Vector3.new(s2.Y + s2.Z, s2.Z + s2.X, s2.X + s2.Y)):Dot(sa * sa) * mass / 12 -- Inertia based on Direction
	return ip + id
end

--[=[
	Calculates the total moment of inertia for a connected body of parts.

	**Usage Notes:**
	- Sums individual part inertias for entire assembly
	- Axis should be the torque vector or (offset × force)
	- Origin should be the center of mass of the assembly
	- Used for calculating angular acceleration from torque
	- Essential for multi-part physics simulation

	**Example:**
	```lua
	local robot = workspace.Robot
	local parts = PhysicsUtil.GetConnectedParts(robot.Torso)
	local com, mass = PhysicsUtil.GetCenterOfMass(parts)
	local torque = Vector3.new(0, 100, 0) -- Spin torque
	local inertia = PhysicsUtil.BodyMomentOfInertia(parts, torque, com)
	local angularAccel = torque / inertia
	```

	@param parts {BasePart} -- Array of connected parts
	@param axis Vector3 -- Rotation axis (typically torque vector)
	@param origin Vector3 -- Origin of rotation (typically center of mass)
	@return number -- Total moment of inertia for the entire body
]=]
function PhysicsUtil.BodyMomentOfInertia(parts: { BasePart }, axis: Vector3, origin: Vector3): number
	local TotalBodyInertia = 0

	for _, part in pairs(parts) do
		TotalBodyInertia = TotalBodyInertia + PhysicsUtil.MomentOfInertia(part, axis, origin)
	end

	return TotalBodyInertia
end

--[=[
	Applies a force to a Roblox physics body at a specific position.

	**Usage Notes:**
	- Automatically calculates both linear and angular acceleration
	- Uses Newton's laws and rotational dynamics
	- Works on entire connected assembly, not just one part
	- Force position determines torque magnitude and direction
	- Modifies both Velocity and RotVelocity properties
	- Setting velocity on one part affects entire connected body in Roblox

	**Physics Details:**
	- Linear acceleration = Force / Mass
	- Torque = Offset × Force
	- Angular acceleration = Torque / Moment of Inertia

	**Example:**
	```lua
	-- Apply explosion force to a part
	local part = workspace.Crate
	local explosionPos = Vector3.new(0, 5, 0)
	local force = (part.Position - explosionPos).Unit * 1000
	PhysicsUtil.ApplyForce(part, force, part.Position)

	-- Apply force at edge of part for spin effect
	local spinForce = Vector3.new(100, 0, 0)
	local edgePos = part.Position + Vector3.new(0, part.Size.Y/2, 0)
	PhysicsUtil.ApplyForce(part, spinForce, edgePos)
	```

	@param part BasePart -- The part to apply force to (can be any part in assembly)
	@param force Vector3 -- Force vector to apply (in studs * mass / second²)
	@param forcePosition Vector3? -- World position where force is applied (defaults to part.Position)
]=]
function PhysicsUtil.ApplyForce(part: BasePart, force: Vector3, forcePosition: Vector3?)
	local parts = PhysicsUtil.GetConnectedParts(part)

	forcePosition = forcePosition or part.Position

	local CenterOfMass, mass = PhysicsUtil.GetCenterOfMass(parts)
	local Offset = (CenterOfMass - forcePosition)
	local Torque = Offset:Cross(force)

	local MomentOfInertia = PhysicsUtil.BodyMomentOfInertia(parts, Torque, CenterOfMass)
	local RotAcceleration = MomentOfInertia ~= 0 and Torque / MomentOfInertia or Vector3.new(0, 0, 0) -- Prevent division by zero
	local acceleration = force / mass

	part.RotVelocity = part.RotVelocity + RotAcceleration
	part.Velocity = part.Velocity + acceleration
end

--[=[
	Accelerates a part using Newton's third law (action-reaction).

	**Usage Notes:**
	- Applies equal and opposite forces to both parts
	- Useful for projectile systems and explosions
	- EmittingPart receives recoil force
	- Conserves momentum in the system
	- Force magnitude calculated from part mass and desired acceleration
	
	**Physics:**
	- Force = Mass × Acceleration
	- Action force on part, reaction force on emittingPart
	- Both parts affected by their respective connected assemblies
	
	**Example:**
	```lua
	-- Cannon firing system
	local cannon = workspace.Cannon.Barrel
	local cannonball = workspace.Cannonball
	local acceleration = Vector3.new(0, 0, -500) -- Fire forward
	
	PhysicsUtil.AcceleratePart(cannonball, cannon, acceleration)
	-- Cannonball flies forward, cannon recoils backward
	
	-- Rocket propulsion
	local rocket = workspace.Rocket
	local exhaustPart = workspace.ExhaustParticle
	local thrust = Vector3.new(0, 1000, 0) -- Upward thrust
	PhysicsUtil.AcceleratePart(exhaustPart, rocket, -thrust)
	```
	
	@param part BasePart -- The part to accelerate
	@param emittingPart BasePart -- The part that emits/launches the other part (receives recoil)
	@param acceleration Vector3 -- Desired acceleration vector for the part
]=]
function PhysicsUtil.AcceleratePart(part: BasePart, emittingPart: BasePart, acceleration: Vector3)
	local force = acceleration * part:GetMass()
	local Position = part.Position

	PhysicsUtil.ApplyForce(part, force, Position)
	PhysicsUtil.ApplyForce(emittingPart, -force, Position)
end

export type PhysicsUtil = typeof(PhysicsUtil)
return PhysicsUtil
