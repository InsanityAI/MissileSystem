if Debug then Debug.beginFile "MissileSystem/VisionDummyRecycler" end
OnInit.module("MissileSystem/VisionDummyRecycler", function(require)
    require "UnitRecycler"
    VisionDummyRecycler = {}

    local MISSILE_ID = FourCC('dumy')

    ---@param x number
    ---@param y number
    ---@param face number
    ---@param player player
    ---@return unit missileDummy
    function VisionDummyRecycler.get(x, y, face, player)
        return UnitRecycler.getUnit(MISSILE_ID, player, x, y, face, true)
    end

    ---@param missileDummy unit
    function VisionDummyRecycler.release(missileDummy)
        if GetUnitTypeId(missileDummy) == MISSILE_ID then
            UnitRecycler.recycleUnit(missileDummy)
        end
    end
end)
if Debug then Debug.endFile() end
