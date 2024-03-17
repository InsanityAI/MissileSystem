if Debug then Debug.beginFile "MissileSystem/Targetting/ItemTargetting" end
OnInit.module("MissileSystem/Targetting/ItemTargetting", function(require)
    require "MissileSystem/Targetting/PointTargetting"
    local heightSuppliers = require "MissileSystem/WidgetHeightSuppliers" ---@type WidgetHeightSuppliers

    ---@class ItemTargetting: PointTargetting
    ---@field target item
    ItemTargetting = {}
    ItemTargetting.__index = ItemTargetting
    setmetatable(ItemTargetting, PointTargetting)

    ---@type TargettingHandler
    function ItemTargetting:handleMissile(missile, delay)
        self.x, self.y = GetItemX(self.target), GetItemY(self.target)
        self.z = heightSuppliers.getItemHeight(self.target, missile.collideZ)
        return PointTargetting.handleMissile(self, missile, delay)
    end

    ---@param target item
    ---@return ItemTargetting
    function ItemTargetting.create(target)
        return setmetatable({
            target = target
        }, ItemTargetting) --[[@as ItemTargetting]]
    end

    ---@param target item
    function ItemTargetting:setTarget(target)
        self.target = target
    end

end)
if Debug then Debug.endFile() end
