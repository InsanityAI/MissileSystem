if Debug then Debug.beginFile "MissileSystem/Targetting/MissileTargetting" end
OnInit.module("MissileSystem/Targetting/MissileTargetting", function (require)
    require "MissileSystem/Targetting/PointTargetting"

    ---@class MissileTargetting: PointTargetting
    ---@field target Missile
    MissileTargetting = {}
    MissileTargetting.__index = MissileTargetting
    setmetatable(MissileTargetting, PointTargetting)

    ---@type TargettingHandler
    function MissileTargetting:handleMissile(missile, delay)
        self.x = self.target.missileX
        self.y = self.target.missileY
        self.z = self.target.missileZ
        return PointTargetting.handleMissile(self, missile, delay)
    end

    ---@param target Missile
    ---@return MissileTargetting
    function MissileTargetting.create(target)
        return setmetatable({
            target = target
        }, MissileTargetting) --[[@as MissileTargetting]]
    end

    ---@param target Missile
    function MissileTargetting:setTarget(target)
        self.target = target
    end

end)
if Debug then Debug.endFile() end