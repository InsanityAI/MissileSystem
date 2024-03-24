if Debug then Debug.beginFile "MissileSystem/Simple/SimpleTargettingCache" end
OnInit.module("MissileSystem/Simple/SimpleTargettingCache", function (require)
    require "Cache"
    require "MissileSystem/Targetting/PointTargetting"
    require "MissileSystem/Targetting/UnitTargetting"
    require "MissileSystem/Targetting/DestructableTargetting"
    require "MissileSystem/Targetting/ItemTargetting"
    require "MissileSystem/Targetting/MissileTargetting"
    require "typeof"

    -- shadow 'type' function to fool EmmyLuaLS
    local type = typeof

    ---@overload fun(targetUnit: unit): UnitTargetting
    ---@overload fun(targetDestructable: destructable): DestructableTargetting
    ---@overload fun(targetItem: item): ItemTargetting
    ---@overload fun(targetMissile: Missile): MissileTargetting
    ---@overload fun(targetX: number, targetY: number, targetZ: number): PointTargetting
    ---@class SimpleTargettingCache: Cache
    ---@field get fun(self: SimpleTargettingCache, target: number|widget|Missile, targetY: number?, targetZ: number?): MissileTargettingModule
    SimpleTargettingCache = Cache.create(function(target, targetY, targetZ)
        local targetType = type(target)
        if targetType == 'number' then
            return PointTargetting.create(target, targetY, targetZ)
        elseif targetType == 'unit' then
            return UnitTargetting.create(target)
        elseif targetType == 'item' then
            return ItemTargetting.create(target)
        elseif targetType == 'destructable' then
            return DestructableTargetting.create(target)
        elseif targetType == 'table' then -- missile
            return MissileTargetting.create(target)
        else
            error("Unknown target type '" .. targetType .. "'!")
        end
    end, 3)

end)
if Debug then Debug.endFile() end