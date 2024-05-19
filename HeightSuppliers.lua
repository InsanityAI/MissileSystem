if Debug then Debug.beginFile "MissileSystem/HeightSuppliers" end
OnInit.module("MissileSystem/HeightSuppliers", function(require)
    ---@class HeightSuppliers
    local HeightSuppliers = {}

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

    ---@param x number
    ---@param y number
    ---@return number z
    local function GetCliffReliableHeight(x, y)
        return (GetTerrainCliffLevel(x, y) - 2) * bj_CLIFFHEIGHT
    end

    ---@param x number
    ---@param y number
    ---@param collideZMode CollideZMode
    ---@return number? relativeZ from cliff Height
    HeightSuppliers.getTerrainHeight = function(x, y, collideZMode)
        if collideZMode == CollideZMode.NONE then
            return nil
        elseif collideZMode == CollideZMode.SAFE then
            return GetCliffReliableHeight(x, y)
        elseif collideZMode == CollideZMode.UNSAFE then
            return GetPointZ(x, y)
        else
            error("Unknown collideZMode " .. collideZMode)
        end
    end

    HeightSuppliers.getUnitHeight = widgetHeightSupplierFactory(
    ---@param it unit
        function(it) return GetCliffReliableHeight(GetUnitX(it), GetUnitY(it)) + GetUnitFlyHeight(it) end,
        BlzGetLocalUnitZ)

    HeightSuppliers.getDestructableHeight = widgetHeightSupplierFactory(
    ---@param it destructable
        function(it)
            return GetCliffReliableHeight(GetDestructableX(it), GetDestructableY(it))
        end,
        ---@param it destructable
        function(it)
            return GetPointZ(GetDestructableX(it), GetDestructableY(it))
        end
    )

    HeightSuppliers.getItemHeight = widgetHeightSupplierFactory(
    ---@param it item
        function(it) return GetCliffReliableHeight(GetItemX(it), GetItemY(it)) end,
        ---@param it item
        function(it) return GetPointZ(GetItemX(it), GetItemY(it)) end
    )

    local widgetType ---@type string
    ---@param widget widget
    ---@param collideZMode CollideZMode
    HeightSuppliers.getWidgetHeight = function(widget, collideZMode)
        widgetType = typeof(widget)
        if widgetType == 'unit' then
            return HeightSuppliers.getUnitHeight(widget, collideZMode)
        elseif widgetType == 'destructable' then
            return HeightSuppliers.getDestructableHeight(widget, collideZMode)
        elseif widgetType == 'item' then
            return HeightSuppliers.getItemHeight(widget, collideZMode)
        else
            error('Unknown widget type ' .. widgetType .. '!')
        end
    end

    return HeightSuppliers
end)
if Debug then Debug.endFile() end
