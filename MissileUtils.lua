if Debug then Debug.beginFile "MissileUtils" end
OnInit.module("MissileUtils", function()
    --[[
    -- ------------------------------------- Missile Utils v2.8 ------------------------------------- --
    -- This is a simple Utils library for the Relativistic Missiles system.
    -- ---------------------------------------- By Chopinski ---------------------------------------- --
    ]]

    Require.strict "Missile"
    Require.strict "SetUtils"

    ---@param set Set
    ---@param type unknown
    ---@return Set
    function GroupEnumMissilesOfType(set, type)
        if set then
            if set:size() > 0 then
                set:clear()
            end

            for missile, _ in pairs(Missile.collection) do
                if missile.type == type then
                    set:add(missile)
                end
            end
        end

        return set
    end

    ---@param set Set
    ---@param type unknown
    ---@param amount integer
    ---@return Set
    function SetEnumMissilesOfTypeCounted(set, type, amount)
        local j = amount

        if set then
            if set:size() > 0 then
                set:clear()
            end

            for missile, _ in pairs(Missile.collection) do
                if missile.type == type then
                    set:add(missile)
                    j = j - 1
                end

                if j <= 0 then
                    break
                end
            end
        end

        return set
    end

    ---@param set Set
    ---@param player player
    ---@return Set
    function SetEnumMissilesOfPlayer(set, player)
        if set then
            if set:size() > 0 then
                set:clear()
            end

            for missile, _ in pairs(Missile.collection) do
                if missile.owner == player then
                    set:add(missile)
                end
            end
        end

        return set
    end

    ---@param set Set
    ---@param player player
    ---@param amount integer
    ---@return Set
    function SetEnumMissilesOfPlayerCounted(set, player, amount)
        local j = amount

        if set then
            if set:size() > 0 then
                set:clear()
            end

            for missile, _ in pairs(Missile.collection) do
                if missile.owner == player then
                    set:add(missile)
                    j = j - 1
                end

                if j <= 0 then
                    break
                end
            end
        end

        return set
    end

    ---@param set Set
    ---@param rect rect
    ---@return Set
    function GroupEnumMissilesInRect(set, rect)
        if set and rect then
            if set:size() > 0 then
                set:clear()
            end

            for missile, _ in pairs(Missile.collection) do
                if GetRectMinX(rect) <= missile.x and missile.x <= GetRectMaxX(rect) and GetRectMinY(rect) <= missile.y and missile.y <= GetRectMaxY(rect) then
                    set:add(missile)
                end
            end
        end

        return set
    end

    ---@param set Set
    ---@param rect rect
    ---@param amount integer
    ---@return Set
    function SetEnumMissilesInRectCounted(set, rect, amount)
        local j = amount

        if set and rect then
            if set:size() > 0 then
                set:clear()
            end

            for missile, _ in pairs(Missile.collection) do
                if GetRectMinX(rect) <= missile.x and missile.x <= GetRectMaxX(rect) and GetRectMinY(rect) <= missile.y and missile.y <= GetRectMaxY(rect) then
                    set:add(missile)
                    j = j - 1
                end

                if j <= 0 then
                    break
                end
            end
        end

        return set
    end

    ---@param set Set
    ---@param location location
    ---@param radius number
    ---@return Set
    function SetEnumMissilesInRangeOfLoc(set, location, radius)
        return SetEnumMissilesInRange(set, GetLocationX(location), GetLocationY(location), radius)
    end

    ---@param set Set
    ---@param location location
    ---@param radius number
    ---@param amount integer
    ---@return Set
    function SetEnumMissilesInRangeOfLocCounted(set, location, radius, amount)
        return SetEnumMissilesInRangeCounted(set, GetLocationX(location), GetLocationY(location), radius, amount)
    end

    ---@param set Set
    ---@param x number
    ---@param y number
    ---@param radius number
    ---@return Set
    function SetEnumMissilesInRange(set, x, y, radius)
        if set and radius > 0 then
            radius = radius * radius

            if set:size() > 0 then
                set:clear()
            end

            for missile, _ in pairs(Missile.collection) do
                local dx = missile.x - x
                local dy = missile.y - y

                if dx * dx + dy * dy <= radius then
                    set:add(missile)
                end
            end
        end

        return set
    end

    ---@param set Set
    ---@param x number
    ---@param y number
    ---@param radius number
    ---@param amount integer
    ---@return Set
    function SetEnumMissilesInRangeCounted(set, x, y, radius, amount)
        local j = amount

        if set and radius > 0 then
            radius = radius * radius

            if set:size() > 0 then
                set:clear()
            end

            for missile, _ in pairs(Missile.collection) do
                local dx = missile.x - x
                local dy = missile.y - y

                if dx * dx + dy * dy <= radius then
                    set:add(missile)
                    j = j - 1
                end

                if j <= 0 then
                    break
                end
            end
        end

        return set
    end
end)
if Debug then Debug.endFile() end
