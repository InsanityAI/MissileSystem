if Debug then Debug.beginFile "MissileSystem/Simple/SimpleMovementCache" end
OnInit.module("MissileSystem/Simple/SimpleMovementCache", function (require)
    require "MissileSystem/Movement/MissileMovementModule"
    require "MissileSystem/Movement/BasicMovement"
    require "MissileSystem/Movement/ArcMovement"
    require "Cache"

    ---@param movementType MissileMovementModule
    ---@param speed1 number
    ---@param speed2 number
    ---@return MissileMovementModule
    ---@class SimpleMovementCache: Cache
    ---@field get fun(self: SimpleMovementCache, movementType: MissileMovementModule, speed1: number, speed2: number): MissileMovementModule
    SimpleMovementCache = Cache.create(function(movementType, speed1, speed2)
        return movementType --[[@as unknown]].create(speed1, speed2)
    end, 3)

end)
if Debug then Debug.endFile() end