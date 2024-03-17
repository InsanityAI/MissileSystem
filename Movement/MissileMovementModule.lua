if Debug then Debug.beginFile "MissileSystem/Movement/MissileMovementModule" end
OnInit.module("MissileSystem/Movement/MissileMovementModule", function(require)
    ---@alias MovementHandler fun(self: MissileMovementModule, missile: Missile, delay: number, distanceToTarget?: number?, terrainAngleToTarget?: number?, heightAngleToTarget?: number?): distanceMoved: number, x: number, y:number, z:number?, orientXY: number, orientZ: number?

    ---@class MissileMovementModule abstract
    ---@field handleMissile MovementHandler
    MissileMovementModule = {}
    MissileMovementModule.__index = MissileMovementModule

    ---@param missile Missile
    function MissileMovementModule:applyToMissile(missile)
        missile.movementTime = 0
        missile.movedDistance = 0
        missile.movement = self
    end

    ---@param value number
    ---@return number normalizedValue
    function MissileMovementModule.normalize(value)
        return value * MissileSystem.PERIOD
    end
end)
if Debug then Debug.endFile() end
