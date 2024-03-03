if Debug then Debug.beginFile "MissileEffect" end
OnInit.module("MissileEffect", function()
    --[[
    -- ------------------------------------- Missile Effect v2.8 ------------------------------------ --
    -- Credits to Forsakn for the first translation of Missile Effect to LUA
    -- ---------------------------------------- By Chopinski ---------------------------------------- --
]]

    ---@class MissileEffect
    ---@field x number
    ---@field y number
    ---@field z number
    ---@field dx number
    ---@field dy number
    ---@field dz number
    ---@field model string
    ---@field size integer
    ---@field yaw integer
    ---@field pitch integer
    ---@field roll integer
    ---@field alpha integer
    ---@field colorRed integer
    ---@field colorGreen integer
    ---@field colorBlue integer
    ---@field playerColor player
    ---@field animation animtype
    ---@field timescale number
    ---@field effect effect
    MissileEffect = {}
    MissileEffect.__index = MissileEffect

    ---@param missileEffect MissileEffect
    local function applyEffectProperties(missileEffect)
        BlzSetSpecialEffectScale(missileEffect.effect, missileEffect.size)
        BlzSetSpecialEffectOrientation(missileEffect.effect, missileEffect.yaw, missileEffect.pitch, missileEffect.roll)
        BlzSetSpecialEffectTimeScale(missileEffect.effect, missileEffect.timescale)
        if MissileEffect.animation then BlzPlaySpecialEffect(missileEffect.effect, missileEffect.animation) end
        if missileEffect.playerColor ~= nil then
            BlzSetSpecialEffectColorByPlayer(missileEffect.effect, missileEffect.playerColor)
        else
            BlzSetSpecialEffectColor(missileEffect.effect, missileEffect.colorRed, missileEffect.colorGreen,
                missileEffect.colorBlue)
        end
        BlzSetSpecialEffectAlpha(missileEffect.effect, missileEffect.alpha)
        BlzSetSpecialEffectPosition(missileEffect.effect, missileEffect.x - missileEffect.dx,
            missileEffect.y - missileEffect.dy, missileEffect.z - missileEffect.dz)
    end

    function MissileEffect:destroy()
        DestroyEffect(self.effect)
        self.effect = nil
    end

    MissileEffect.detach = MissileEffect.destroy

    ---@param scale number
    function MissileEffect:setScale(scale)
        self.size = scale
        BlzSetSpecialEffectScale(self.effect, scale)
    end

    ---@param yaw number
    ---@param pitch number
    ---@param roll number
    function MissileEffect:orient(yaw, pitch, roll)
        self.yaw, self.pitch, self.roll = yaw, pitch, roll
        BlzSetSpecialEffectOrientation(self.effect, yaw, pitch, roll)
    end

    ---@param x number
    ---@param y number
    ---@param z number
    function MissileEffect:move(x, y, z)
        if not (x > WorldBounds.maxX or x < WorldBounds.minX or y > WorldBounds.maxY or y < WorldBounds.minY) then
            BlzSetSpecialEffectPosition(self.effect, x - self.dx, y - self.dy, z - self.dz)
            return true
        end
        return false
    end

    ---@param model string
    function MissileEffect:setModel(model)
        if self.effect ~= nil then
            self:destroy()
        end
        self.model = model
        self.effect = AddSpecialEffect(model, self.x, self.y)
        BlzSetSpecialEffectZ(self.effect, self.z)
        applyEffectProperties(self)
    end

    ---@param red integer
    ---@param green integer
    ---@param blue integer
    function MissileEffect:setColor(red, green, blue)
        self.red, self.green, self.blue = red, green, blue
        BlzSetSpecialEffectColor(self.effect, red, green, blue)
    end

    ---@param real number time scale
    function MissileEffect:setTimeScale(real)
        self.timescale = real
        BlzSetSpecialEffectTimeScale(self.effect, real)
    end

    ---@param integer integer alpha
    function MissileEffect:setAlpha(integer)
        self.alpha = integer
        BlzSetSpecialEffectAlpha(self.effect, integer)
    end

    ---@param integer integer player number
    function MissileEffect:setPlayerColor(integer)
        self.playerColor = Player(integer)
        BlzSetSpecialEffectColorByPlayer(self.effect, self.playerColor)
    end

    ---@param integer integer animation type
    function MissileEffect:setAnimation(integer)
        self.animation = ConvertAnimType(integer)
        BlzPlaySpecialEffect(self.effect, self.animation)
    end

    ---@param dx number
    ---@param dy number
    ---@param dz number
    function MissileEffect:setOffset(dx, dy, dz)
        self.dx, self.dy, self.dz = dx, dy, dz;
        BlzSetSpecialEffectPosition(self.effect, self.x - self.dx, self.y - self.dy, self.z - self.dz)
    end

    ---@param x number?
    ---@param y number?
    ---@param z number?
    ---@return MissileEffect
    function MissileEffect.create(x, y, z)
        return setmetatable({
            x = x or 0,
            y = y or 0,
            z = z or 0,
            dx = 0,
            dy = 0,
            dz = 0,
            model = nil,
            size = 1,
            yaw = 0,
            pitch = 0,
            roll = 0,
            alpha = 255,
            colorRed = 255,
            colorGreen = 255,
            colorBlue = 255,
            playerColor = nil,
            animation = nil,
            timescale = 1,
            effect = nil
        }, MissileEffect)
    end
end)
if Debug then Debug.endFile() end
