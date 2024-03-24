if Debug then Debug.beginFile "typeof" end
OnInit.module("typeof", function(require)
    -- taken from DebugUtils
    ---@param input any
    ---@return string typeName
    function typeof(input)
        local typeString = type(input)
        if typeString == 'userdata' then
            typeString = tostring(input)                                         --tostring returns the warcraft type plus a colon and some hashstuff.
            return typeString:sub(1, (typeString:find(":", nil, true) or 0) - 1) --string.find returns nil, if the argument is not found, which would break string.sub. So we need to replace by 0.
        else
            return typeString
        end
    end
end)
if Debug then Debug.endFile() end
