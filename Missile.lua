if Debug then Debug.beginFile "MissileSystem/Missile" end
OnInit.module("MissileSystem/Missile", function(require)
    local heightSuppliers = require "MissileSystem/HeightSuppliers" ---@type HeightSuppliers
    -- Note: properties marked as readonly should NOT be set to some other value explicitly.
    --      Otherwise, the system will do weird stuff. You have been warned!

    ---@enum CollideZMode
    CollideZMode = {
        NONE = 1,  -- does not check height for collisions, nor be aware of height deformities in terrain
        SAFE = 2,  -- uses safe but often imprecise methods to figure out height collision (sometimes not possible or lacking, like with Destructables)
        UNSAFE = 3 -- uses GetLocationZ and other async methods (Caution: may cause desyncs!)
    }
    local DEFAULT_Z_MODE = CollideZMode.SAFE

    ---@class Missile
    ---@field owner player readonly
    ---@field visionUnit unit readonly
    ---@field visionRange number readonly - use setVision method to change
    ---@field destroyed boolean readonly
    ---@field paused boolean readonly
    ---@field processorTask TaskObservable readonly
    ---@field timedLifeTask TimerQueueTask readonly
    ---@field effects MissileEffectSet readonly - use MissileEffect:attachToMissile to add or remove effects
    ---
    --- Position
    ---
    ---@field missileX number readonly - calculated by targetting and movement handlers
    ---@field missileY number readonly - calculated by targetting and movement handlers
    ---@field missileZ number readonly - calculated by targetting and movement handlers
    ---@field groundAngle number readonly - calculated by targetting and movement handlers
    ---@field heightAngle number readonly - calculated by targetting and movement handlers
    ---@field nextMissileX number readonly - calculated by targetting and movement handlers
    ---@field nextMissileY number readonly - calculated by targetting and movement handlers
    ---@field nextMissileZ number? readonly - calculated by targetting and movement handlers
    ---@field nextGroundAngle number readonly - calculated by targetting and movement handlers
    ---@field nextHeightAngle number? readonly - calculated by targetting and movement handlers
    ---
    --- Movement & Targetting
    ---
    ---@field targetting MissileTargettingModule? readonly - use MissileTargettingModule:applyToMissile
    ---@field movement MissileMovementModule? readonly - use MissileMovementModule:applyToMissile
    ---@field movementTime number should probably be only readonly
    ---@field movedDistance number should probably be only readonly
    ---
    --- Collision
    ---
    ---@field collisionSize number - writable
    ---@field collideZ CollideZMode - writable
    ---@field collidedUnits Set - writable
    ---@field collidedMissiles Set - writable
    ---@field collidedDestructables Set - writable
    ---@field collidedItems Set - writable
    ---
    --- Handlers
    ---     Only 1 handler of each type can be attached to the missile
    ---@field onUnit? fun(missile: Missile, unit: unit, delay: number)
    ---@field onMissile? fun(missile: Missile, collidedMissile: Missile, delay: number)
    ---@field onDestructable? fun(missile: Missile, destructable: destructable, delay: number)
    ---@field onItem? fun(missile:Missile, item: item, delay: number)
    ---@field onCliff? fun(missile: Missile, cliffDelta: number, delay: number)
    ---@field onTerrain? fun(missile: Missile, delay: number)
    ---@field onProcess? fun(missile: Missile, delay: number)
    ---@field onBoundaries? fun(missile: Missile, delay: number)
    ---@field onPause? fun(missile: Missile)
    ---@field onResume? fun(missile: Missile)
    ---@field onDestroy? fun(missile: Missile)
    Missile = {}
    Missile.__index = Missile

    ---@param owner player
    ---@param originX number
    ---@param originY number
    ---@param originZ number? default is terrain's height
    ---@param groundAngle number? default is bj_UNIT_FACING
    ---@param heightAngle number? default is 0
    ---@param collideZ CollideZMode? if undefined uses default
    ---@return Missile
    function Missile.create(owner, originX, originY, originZ, groundAngle, heightAngle, collideZ)
        collideZ = collideZ or DEFAULT_Z_MODE
        if not originZ then
            originZ = heightSuppliers.getTerrainHeight(originX, originY, collideZ)
        end

        return setmetatable({
            owner = owner,
            destroyed = false,
            paused = false,
            effects = Set.create(),
            missileX = originX,
            missileY = originY,
            missileZ = originZ,
            groundAngle = groundAngle or bj_UNIT_FACING,
            heightAngle = heightAngle or 0,
            visionRange = 0,
            collisionSize = 0,
            collideZ = collideZ,
            collidedUnits = Set.create(),
            collidedMissiles = Set.create(),
            collidedDestructables = Set.create(),
            collidedItems = Set.create(),
            movementTime = 0,
            movedDistance = 0
        }, Missile)
    end

    ---@param owner player
    ---@param originX number
    ---@param originY number
    ---@param relativeOriginZ number
    ---@param groundAngle number? default is bj_UNIT_FACING
    ---@param heightAngle number? default is 0
    ---@param collideZ CollideZMode? if undefined uses default
    ---@return Missile
    function Missile.createRelativeZ(owner, originX, originY, relativeOriginZ, groundAngle, heightAngle, collideZ)
        collideZ = collideZ or DEFAULT_Z_MODE
        relativeOriginZ = heightSuppliers.getTerrainHeight(originX, originY, collideZ) + relativeOriginZ
        return Missile.create(owner, originX, originY, relativeOriginZ, groundAngle, heightAngle, collideZ)
    end

    ---@param range number
    function Missile:setVision(range)
        if self.destroyed then
            return
        end
        if range ~= nil and range > 0 then
            self.visionRange = range
            if not self.visionUnit then
                self.visionUnit = VisionDummyRecycler.get(self.missileX, self.missileY, bj_UNIT_FACING, self.owner)
            else
                SetUnitOwner(self.visionUnit, self.owner, false)
            end
            BlzSetUnitRealField(self.visionUnit, UNIT_RF_SIGHT_RADIUS, range)
        else
            self.visionRange = 0
            if self.visionUnit then
                VisionDummyRecycler.release(self.visionUnit)
                self.visionUnit = nil
            end
        end
    end

    function Missile:pause()
        if not self.paused and not self.destroyed then
            if self.onPause then self.onPause(self) end
            self.paused = true
            if self.processorTask == nil then self:launch() end
        end
    end

    function Missile:resume()
        if self.paused then
            if self.onResume then self.onResume(self) end
            self.paused = false
        end
    end

    ---@param seconds number?
    function Missile:timedLife(seconds)
        if seconds then
            self.timedLifeTask = TimerQueue:callDelayed(seconds, Missile.destroy, self)
        elseif self.timedLifeTask then
            TimerQueue:cancel(self.timedLifeTask)
        end
    end

    local dx, dy ---@type number, number
    local distance ---@type number
    local heightAngle ---@type number?

    ---@overload fun(self: Missile, target: widget, z: number?)
    ---@param x number
    ---@param y number
    ---@param z number?
    function Missile:orientTowards(x, y, z)
        if type(x) ~= 'number' then
            if y then
                z = y
            end
            y = GetWidgetY(x)
            x = GetWidgetX(x)
        end

        dx, dy = x - self.missileX, y - self.missileY
        distance = (dx ^ 2 + dy ^ 2) ^ 0.5
        if z then
            heightAngle = math.atan(z - self.missileZ, distance)
        else
            heightAngle = nil
        end
        self:move(nil, nil, nil, math.atan(dy, dx), heightAngle)
    end

    ---@overload fun(self: Missile, target: widget, z: number?)
    ---@param x number
    ---@param y number
    ---@param z number
    function Missile:relativeZOrientTowards(x, y, z)
        if type(x) ~= 'number' then
            if y then
                z = y
            end
            y = GetWidgetY(x)
            x = GetWidgetX(x)
            z = heightSuppliers.getWidgetHeight(x --[[@as widget]], self.collideZ) + z
        else
            z = heightSuppliers.getTerrainHeight(x, y, self.collideZ) + z
        end
        self:orientTowards(x, y, z)
    end
end)
if Debug then Debug.endFile() end
