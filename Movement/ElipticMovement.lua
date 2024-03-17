-- if Debug then Debug.beginFile "MissileSystem/Movement/ElipticMovement" end
-- OnInit.module("MissileSystem/Movement/ElipticMovement", function (require)
--     require "MissileSystem/Movement/MissileMovementModule"

--     ---@class ElipticMovement: MissileMovementModule
--     ---@field movementSpeed number XY Plane movement speed
--     ---@field elipsisCoefficient number less than 1 is narrow (towards target), 1 is circle, more than 1 is wide (away from target)
--     ElipticMovement = {}
--     ElipticMovement.__index = ElipticMovement
--     setmetatable(ElipticMovement, MissileMovementModule)

--     ---@type MovementHandler
--     function ElipticMovement:handleMissile(missile, delay, distanceToTarget, terrainAngleToTarget, heightAngleToTarget)
--         ms = delay > 1 and self.movementSpeed * delay or self.movementSpeed
--         gravityVector = delay > 1 and normalizedGravityVector * delay or normalizedGravityVector

--         if not missile.arc_vectorZ then -- initial vectorZ
--             if heightAngleToTarget then
--                 missile.arc_vectorZ = (gravityVector * distanceToTarget) / (2 * ms) + ms * math.tan(heightAngleToTarget)
--             else
--                 missile.arc_vectorZ = (gravityVector * distanceToTarget) / (2 * ms)
--             end
--         end
--         missile.arc_vectorZ = missile.arc_vectorZ - gravityVector

--         vectorX, vectorY = ms * math.cos(terrainAngleToTarget), ms * math.sin(terrainAngleToTarget)
--         return ms, missile.missileX + vectorX, missile.missileY + vectorY, missile.missileZ + missile.arc_vectorZ,
--             terrainAngleToTarget, math.atan(missile.arc_vectorZ, ms)
--     end

--      ---@param movementSpeed number
--     ---@return ElipticMovement
--     function ElipticMovement.create(movementSpeed)
--         return setmetatable({
--             movementSpeed = movementSpeed
--         }, ElipticMovement) --[[@as ElipticMovement]]
--     end

--     ---@param movementSpeed number
--     function ElipticMovement:updateMovementSpeed(movementSpeed)
--         self.movementSpeed = self.normalize(movementSpeed)
--     end

--     ---@param coefficient number
--     function ElipticMovement:updateCoefficient(coefficient)
--         self.elipsisCoefficient = coefficient
--     end

--     -- ---@param missile Missile
--     -- function ElipticMovement:applyToMissile(missile)
--     --     MissileMovementModule.applyToMissile(self, missile)
--     --     missile --[[@as MissileWithArcMovement]].arc_vectorZ = nil
--     -- end
-- end)
-- if Debug then Debug.endFile() end