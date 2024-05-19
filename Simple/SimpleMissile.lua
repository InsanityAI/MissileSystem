if Debug then Debug.beginFile "MissileSystem/Simple/SimpleMissile" end
OnInit.module("MissileSystem/Simple/SimpleMissile", function(require)
    require "MissileSystem/Missile"
    require "MissileSystem/Simple/SimpleMovementCache"

    ---@class SimpleMissile: Missile
    ---@field range number?
    SimpleMissile = {}
    SimpleMissile.__index = SimpleMissile
    setmetatable(SimpleMissile, Missile)

    ---@param missile SimpleMissile
    ---@param delay number
    local function missileDeath(missile, delay)
        missile:destroy()
    end

    ---@param missile SimpleMissile
    ---@param cliffDelta integer
    ---@param delay number
    local function missileCliffDeath(missile, cliffDelta, delay)
        if cliffDelta > 0 then
            missile:destroy()
        end
    end

    ---@param missile SimpleMissile
    ---@param delay number
    local function missileProcessDeath(missile, delay)
        if missile.range and missile.movedDistance > missile.range then
            missile:destroy()
        end
    end

    ---@param owner player
    ---@param model string
    ---@param fromX number
    ---@param fromY number
    ---@param fromZ number? relative
    ---@param toX number
    ---@param toY number
    ---@param toZ number? relative
    ---@return SimpleMissile
    function SimpleMissile.create(owner, model, fromX, fromY, fromZ, toX, toY, toZ)
        fromZ = fromZ or 0
        toZ = toZ or 0
        local missile = setmetatable(Missile.createRelativeZ(owner, fromX, fromY, fromZ), SimpleMissile) --[[@as SimpleMissile]]
        missile:relativeZOrientTowards(toX, toY, toZ)
        local effect = MissileEffect.create()
        effect:attachToMissile(missile)
        effect:setModel(model)
        missile.onTerrain = missileDeath
        missile.onBoundaries = missileDeath
        --missile.onCliff = missileCliffDeath
        missile.onProcess = missileProcessDeath
        return missile
    end

    ---@param movementType MissileMovementModule
    ---@param movementSpeed number
    ---@param speed2 number
    function SimpleMissile:setMovementType(movementType, movementSpeed, speed2)
        SimpleMovementCache:get(movementType, movementSpeed, speed2):applyToMissile(self)
    end

    ---@overload fun(self: SimpleMissile, targetUnit: unit)
    ---@overload fun(self: SimpleMissile, targetDestructable: destructable)
    ---@overload fun(self: SimpleMissile, targetItem: item)
    ---@overload fun(self: SimpleMissile, targetMissile: Missile)
    ---@overload fun(self: SimpleMissile, targetX: number, targetY: number, targetZ: number?, deathOnArrival: true?)
    function SimpleMissile:setTarget(target, targetY, targetZ, deathOnArrival)
        SimpleTargettingCache:get(target, targetY, targetZ):applyToMissile(self)
        if deathOnArrival and target and targetY then
            self.range = math.sqrt((target - self.missileX) ^ 2 + (targetY - self.missileY) ^ 2)
        end
    end

    ---@param model string
    function SimpleMissile:setEffect(model)
        (self.effects.data[0] --[[@as MissileEffect]]):setModel(model)
    end

    function SimpleMissile:setModelSize(size)
        (self.effects.data[0] --[[@as MissileEffect]]):setScale(size)
    end

    ---@param yaw number?
    ---@param pitch number?
    ---@param roll number?
    function SimpleMissile:setOrientation(yaw, pitch, roll)
        (self.effects.data[0] --[[@as MissileEffect]]):orient(yaw, pitch, roll)
    end

    ---@param alpha integer
    ---@param red integer
    ---@param green integer
    ---@param blue integer
    function SimpleMissile:setColor(alpha, red, green, blue)
        local effect = (self.effects.data[0] --[[@as MissileEffect]])
        if alpha then effect:setAlpha(alpha) end
        effect:setColor(red, green, blue)
    end

    ---@param playercolor integer
    function SimpleMissile:setPlayerColor(playercolor)
        (self.effects.data[0] --[[@as MissileEffect]]):setPlayerColor(playercolor)
    end

    ---@param animation integer
    function SimpleMissile:setAnimation(animation)
        (self.effects.data[0] --[[@as MissileEffect]]):setAnimation(animation)
    end

    ---@param timescale number
    function SimpleMissile:setTimescale(timescale)
        (self.effects.data[0] --[[@as MissileEffect]]):setTimeScale(timescale)
    end
end)
if Debug then Debug.endFile() end
