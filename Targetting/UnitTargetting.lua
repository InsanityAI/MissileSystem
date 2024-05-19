if Debug then Debug.beginFile "MissileSystem/Targetting/UnitTargetting" end
OnInit.module("MissileSystem/Targetting/UnitTargetting", function (require)
    require "MissileSystem/Targetting/PointTargetting"
    local heightSuppliers = require "MissileSystem/HeightSuppliers" ---@type HeightSuppliers

    ---@class UnitTargetting: PointTargetting
    ---@field target unit
    UnitTargetting = {}
    UnitTargetting.__index = UnitTargetting
    setmetatable(UnitTargetting, PointTargetting)

    ---@type TargettingHandler
    function UnitTargetting:handleMissile(missile, delay)
        self.x, self.y = GetUnitX(self.target), GetUnitY(self.target)
        self.z = heightSuppliers.getUnitHeight(self.target, missile.collideZ)
        return PointTargetting.handleMissile(self, missile, delay)
    end

    ---@param target unit
    ---@return UnitTargetting
    function UnitTargetting.create(target)
        return setmetatable({
            target = target
        }, UnitTargetting) --[[@as UnitTargetting]]
    end

    ---@param target unit
    function UnitTargetting:setTarget(target)
        self.target = target
    end

end)
if Debug then Debug.endFile() end