if Debug then Debug.beginFile("MissileSystem/Movement/ArcMovement") end
OnInit.module("MissileSystem/Movement/ArcMovement", function(require)
    require "MissileSystem/Movement/MissileMovementModule"
    --- Movement which mimics Mortar fire - does not do homing
    --- Movement speed is constant and represents movement speed on XY-plane, Z movement direction is determined by distance + heightAngleToTarget
    --- Absolute movement speed varies thanks to Z movement direction and changes over time, but XY-movement speed component will always stay the same
    ---@class ArcMovement: MissileMovementModule
    ---@field movementSpeed number XY-Plane movement speed
    ---@field gravity number missile's downward speed per second
    ArcMovement = {}
    ArcMovement.__index = ArcMovement
    setmetatable(ArcMovement, BasicMovement)

    --- temp variables
    local gravityVector ---@type number
    local ms ---@type number
    local vectorX ---@type number
    local vectorY ---@type number
    ---

    ---@class MissileWithArcMovement: Missile
    ---@field arc_vectorZ number

    ---@type MovementHandler
    ---@param missile MissileWithArcMovement
    ---@return number vector, number vectorX, number vectorY, number? vectorZ, number orientXY, number? orientZ
    function ArcMovement:handleMissile(missile, delay, distanceToTarget, terrainAngleToTarget, heightAngleToTarget)
        ms = delay > 1 and self.movementSpeed * delay or self.movementSpeed
        gravityVector = delay > 1 and self.gravity * delay or self.gravity

        if not missile.arc_vectorZ then -- initial vectorZ
            if heightAngleToTarget then
                missile.arc_vectorZ = (gravityVector * distanceToTarget) / (2 * ms) + ms * math.tan(heightAngleToTarget)
            else
                missile.arc_vectorZ = (gravityVector * distanceToTarget) / (2 * ms)
            end
        else
            missile.arc_vectorZ = missile.arc_vectorZ - gravityVector
        end

        vectorX, vectorY = ms * math.cos(terrainAngleToTarget), ms * math.sin(terrainAngleToTarget)
        return ms, vectorX, vectorY, missile.arc_vectorZ, terrainAngleToTarget, math.atan(missile.arc_vectorZ, ms)
    end

    ---@param movementSpeed number
    ---@param gravity number
    ---@return ArcMovement
    function ArcMovement.create(movementSpeed, gravity)
        return setmetatable({
            movementSpeed = ArcMovement.normalize(movementSpeed),
            gravity = ArcMovement.normalize(gravity)
        }, ArcMovement) --[[@as ArcMovement]]
    end

    ---@param movementSpeed number
    function ArcMovement:updateMovementSpeed(movementSpeed)
        self.movementSpeed = self.normalize(movementSpeed)
    end

    ---@param gravity number
    function ArcMovement:updateGravity(gravity)
        self.gravity = self.normalize(gravity)
    end

    ---@param missile Missile|MissileWithArcMovement
    function ArcMovement:applyToMissile(missile)
        MissileMovementModule.applyToMissile(self, missile)
        missile.arc_vectorZ = nil
    end
end)
if Debug then Debug.endFile() end
