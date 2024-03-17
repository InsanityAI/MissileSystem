if Debug then Debug.beginFile "MissileSystem/Effect/MissileEffect" end
OnInit.module("MissileSystem/Effect/MissileEffect", function(require)

    ---@class MissileEffectSet: Set
    ---@field create fun(...: MissileEffect): MissileEffectSet
    ---@field union fun(...: MissileEffect): MissileEffectSet
    ---@field intersection fun(...: MissileEffect): MissileEffectSet
    ---@field except fun(...: MissileEffect): MissileEffectSet
    ---@field fromTable fun(data: MissileEffect[]): MissileEffectSet
    ---@field add fun(self: MissileEffectSet, ...: MissileEffect): MissileEffectSet
    ---@field remove fun(self: MissileEffectSet, ...: MissileEffect): MissileEffectSet
    ---@field addAll fun(self: MissileEffectSet, container: MissileEffectSet|MissileEffect[]): MissileEffectSet
    ---@field addAllKeys fun(self: MissileEffectSet, container: table<MissileEffectSet, unknown>): MissileEffectSet
    ---@field removeAll fun(self: MissileEffectSet, container: MissileEffectSet|MissileEffect[]): MissileEffectSet
    ---@field retainAll fun(self: MissileEffectSet, container: MissileEffectSet|MissileEffect[]): MissileEffectSet
    ---@field clear fun(self: MissileEffectSet): MissileEffectSet
    ---@field elements fun(self: MissileEffectSet): fun(): MissileEffect
    ---@field contains fun(self: MissileEffectSet, effect: MissileEffect): boolean
    ---@field size fun(self: MissileEffectSet): integer
    ---@field isEmpty fun(self: MissileEffectSet): boolean
    ---@field toString fun(self: MissileEffectSet): string
    ---@field print fun(self: MissileEffectSet)
    ---@field random fun(self: MissileEffectSet): MissileEffect
    ---@field toArray fun(self: MissileEffectSet): MissileEffect[]
    ---@field intersects fun(self: MissileEffectSet, otherSet: MissileEffectSet): boolean
    ---@field copy fun(self: MissileEffectSet): MissileEffectSet

    ---@class MissileEffect
    ---@field missile Missile? readonly
    ---@field x number readonly
    ---@field y number readonly
    ---@field z number readonly
    ---@field dx number readonly
    ---@field dy number readonly
    ---@field dz number readonly
    ---@field model string readonly
    ---@field size integer readonly
    ---@field yaw integer readonly
    ---@field pitch integer readonly
    ---@field roll integer readonly
    ---@field alpha integer readonly
    ---@field colorRed integer readonly
    ---@field colorGreen integer readonly
    ---@field colorBlue integer readonly
    ---@field playerColor player readonly
    ---@field animation animtype readonly
    ---@field timescale number readonly
    ---@field effect effect readonly
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

    ---@param scale number
    function MissileEffect:setScale(scale)
        self.size = scale
        BlzSetSpecialEffectScale(self.effect, scale)
    end

    ---@param yaw number?
    ---@param pitch number?
    ---@param roll number?
    function MissileEffect:orient(yaw, pitch, roll)
        self.yaw, self.pitch, self.roll = yaw and yaw or self.yaw, pitch and pitch or self.pitch, roll and roll or self.roll
        BlzSetSpecialEffectOrientation(self.effect, self.yaw, self.pitch, self.roll)
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

    ---@param missile Missile? nil to remove effect from missile - effect still needs to be destroyed afterwards
    function MissileEffect:attachToMissile(missile)
        if self.missile then
            self.missile.effects:removeSingle(self)
        end
        self.missile = missile
        if self.missile then
            self.missile.effects:addSingle(self)
        end
    end

    function MissileEffect:destroy()
        if self.missile then
            self.missile.effects:removeSingle(self)
        end
        DestroyEffect(self.effect)
        self.effect = nil
    end
end)
if Debug then Debug.endFile() end
