if Debug then Debug.beginFile "MissileSystem/WidgetHeightSuppliers" end
OnInit.module("MissileSystem/WidgetHeightSuppliers", function(require)
    ---@class WidgetHeightSuppliers
    local WidgetHeightSuppliers = {}

    ---@param safeZGetter fun(widget: widget): height: number
    ---@param unsafeZGetter fun(widget: widget): height: number
    ---@return fun(widget: widget, collideZMode: CollideZMode): height: number?
    local function widgetHeightSupplierFactory(safeZGetter, unsafeZGetter)
        return function(widget, collideZMode)
            if collideZMode == CollideZMode.NONE then
                return nil
            elseif collideZMode == CollideZMode.SAFE then
                return safeZGetter(widget)
            elseif collideZMode == CollideZMode.UNSAFE then
                return unsafeZGetter(widget)
            else
                error("Unknown collideZMode " .. collideZMode)
            end
        end
    end

    WidgetHeightSuppliers.getUnitHeight = widgetHeightSupplierFactory(GetUnitFlyHeight, BlzGetLocalUnitZ)

    WidgetHeightSuppliers.getDestructableHeight = widgetHeightSupplierFactory(GetDestructableOccluderHeight,
        ---@param it destructable
        function(it) return GetPointZ(GetDestructableX(it), GetDestructableY(it)) + GetDestructableOccluderHeight(it) end
    )

    WidgetHeightSuppliers.getItemHeight = widgetHeightSupplierFactory(function() return 0 end,
        ---@param it item
        function(it) return GetPointZ(GetItemX(it), GetItemY(it)) end
    )

    return WidgetHeightSuppliers
end)
if Debug then Debug.endFile() end
