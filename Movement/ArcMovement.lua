if Debug then Debug.beginFile("MissileSystem/Movement/ArcMovement") end
OnInit.module("MissileSystem/Movement/ArcMovement", function(require)
    require "MissileSystem/Movement/MissileMovementModule"
    local normalizedGravityVector = MissileMovementModule.normalize(9.81)

    --- Movement which mimics Mortar fire - does not do homing
    --- Movement speed is constant and represents movement speed on XY-plane, Z movement direction is determined by distance + heightAngleToTarget
    --- Absolute movement speed varies thanks to Z movement direction and changes over time, but XY-movement speed component will always stay the same
    ---@class ArcMovement: MissileMovementModule
    ---@field movementSpeed number XY-Plane movement speed
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
    function ArcMovement:handleMissile(missile, delay, distanceToTarget, terrainAngleToTarget, heightAngleToTarget)
        ms = delay > 1 and self.movementSpeed * delay or self.movementSpeed
        gravityVector = delay > 1 and normalizedGravityVector * delay or normalizedGravityVector

        if not missile.arc_vectorZ then -- initial vectorZ
            if heightAngleToTarget then
                missile.arc_vectorZ = (gravityVector * distanceToTarget) / (2 * ms) + ms * math.tan(heightAngleToTarget)
            else
                missile.arc_vectorZ = (gravityVector * distanceToTarget) / (2 * ms)
            end
        end
        missile.arc_vectorZ = missile.arc_vectorZ - gravityVector

        vectorX, vectorY = ms * math.cos(terrainAngleToTarget), ms * math.sin(terrainAngleToTarget)
        return ms, missile.missileX + vectorX, missile.missileY + vectorY, missile.missileZ + missile.arc_vectorZ,
            terrainAngleToTarget, math.atan(missile.arc_vectorZ, ms)
    end

    ---@param movementSpeed number
    ---@return ArcMovement
    function ArcMovement.create(movementSpeed)
        return setmetatable({
            movementSpeed = movementSpeed
        }, ArcMovement) --[[@as ArcMovement]]
    end

    ---@param movementSpeed number
    function ArcMovement:updateMovementSpeed(movementSpeed)
        self.movementSpeed = self.normalize(movementSpeed)
    end

    ---@param missile Missile|MissileWithArcMovement
    function ArcMovement:applyToMissile(missile)
        MissileMovementModule.applyToMissile(self, missile)
        missile.arc_vectorZ = nil
    end
end)
if Debug then Debug.endFile() end
