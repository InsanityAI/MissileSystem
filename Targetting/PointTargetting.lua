if Debug then Debug.beginFile "MissileSystem/Targetting/PointTargetting" end
OnInit.module("MissileSystem/Targetting/PointTargetting", function(require)
    require "MissileSystem/Targetting/MissileTargettingModule"

    ---@class PointTargetting: MissileTargettingModule
    ---@field x number
    ---@field y number
    ---@field z number?
    PointTargetting = {}
    PointTargetting.__index = PointTargetting
    setmetatable(PointTargetting, MissileTargettingModule)

    --- temp variables section
    local dx, dy, dz ---@type number, number, number?
    local terrainAngleToTarget ---@type number
    local heightAngleToTarget ---@type number?
    local distance ---@type number
    --- end of temp variables section

    ---@type TargettingHandler
    function PointTargetting:handleMissile(missile, delay)
        dx, dy, dz = self.x - missile.missileX, self.y - missile.missileY, nil
        terrainAngleToTarget = math.atan(dy, dx)
        heightAngleToTarget = nil
        distance = (dx ^ 2 + dy ^ 2) ^ 0.5
        if self.z ~= nil then -- no need to check for Z safety mode because no async getters are being used in this case
            -- unless the z was supplied by an async getter, at which point there's nothing missile system can do to mitigate the desync problem
            dz = self.z - missile.missileZ
            heightAngleToTarget = math.atan(dz, distance)
        end
        return distance, terrainAngleToTarget, heightAngleToTarget
    end

    ---@param x number
    ---@param y number
    ---@param z number?
    ---@return PointTargetting
    function PointTargetting.create(x, y, z)
        return setmetatable({
            target = { x = x, y = y, z = z }
        }, PointTargetting) --[[@as PointTargetting]]
    end

    ---@param x number
    ---@param y number
    ---@param z number?
    function PointTargetting:setPosition(x,y,z)
        self.x = x
        self.y = y
        self.z = z
    end

end)
if Debug then Debug.endFile() end
