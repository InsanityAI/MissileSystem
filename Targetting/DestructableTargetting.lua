if Debug then Debug.beginFile "MissileSystem/Targetting/DestructableTargetting" end
OnInit.module("MissileSystem/Targetting/DestructableTargetting", function(require)
    require "MissileSystem/Targetting/PointTargetting"
    local heightSuppliers = require "MissileSystem/HeightSuppliers" ---@type HeightSuppliers

    ---@class DestructableTargetting: PointTargetting
    ---@field target destructable
    DestructableTargetting = {}
    DestructableTargetting.__index = DestructableTargetting
    setmetatable(DestructableTargetting, PointTargetting)

    ---@type TargettingHandler
    function DestructableTargetting:handleMissile(missile, delay)
        self.x, self.y = GetDestructableX(self.target), GetDestructableY(self.target)
        self.z = heightSuppliers.getDestructableHeight(self.target, missile.collideZ)
        return PointTargetting.handleMissile(self, missile, delay)
    end

    ---@param target destructable
    ---@return DestructableTargetting
    function DestructableTargetting.create(target)
        return setmetatable({
            target = target
        }, DestructableTargetting) --[[@as DestructableTargetting]]
    end

    ---@param target destructable
    function DestructableTargetting:setTarget(target)
        self.target = target
    end

end)
if Debug then Debug.endFile() end
