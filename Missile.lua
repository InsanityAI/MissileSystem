if Debug then Debug.beginFile "Missiles" end
OnInit.module("Missile", function(require)
    --[[ requires MissileEffect, optional MissilesUtils
    -- ---------------------------------------- Missile v2.8 --------------------------------------- --
    -- Thanks and Credits to BPower, Dirac and Vexorian for the Missile Library's at which i based
    -- this Missiles library. Credits and thanks to AGD and for the effect orientation ideas.
    -- This version of Missiles requires patch 1.31+. Thanks to Forsakn for the first translation
    -- of the vJASS version of Missiles into LUA.
    --
    -- How to Import:
    --     1 - Copy this, MissileEffect and optionaly the MissileUtils libraries into your map
    -- ---------------------------------------- By Chopinski ---------------------------------------- --
]]
    require "MissileEffect"
    -- ---------------------------------------------------------------------------------------------- --
    --                                          Configuration                                         --
    -- ---------------------------------------------------------------------------------------------- --
    -- The update period of the system
    local PERIOD              = 1. / 40.

    local STARTING_DUMMY_SIZE = 600
    -- the avarage collision size compensation when detecting collisions
    local COLLISION_SIZE      = 128.
    -- item size used in z collision
    local ITEM_SIZE           = 16.
    -- Raw code of the dummy unit used for vision
    local DUMMY               = FourCC('dumi')
    local group               = CreateGroup()
    local rect                = Rect(0., 0., 0., 0.)
    local MISSILE_OP_COUNT    = 50

    ---@return integer
    local function GetMapCliffLevel()
        return GetTerrainCliffLevel(WorldBounds.maxX, WorldBounds.maxY)
    end

    do
        Pool = {}
        Pool.__index = Pool

        local player = Player(PLAYER_NEUTRAL_PASSIVE)
        local group = Set.create()
        local dummyAbility = FourCC('Amrf')

        ---Returns dummy unit back into the dummy pool
        ---@param unit unit
        function Pool.recycle(unit)
            if GetUnitTypeId(unit) == DUMMY then
                group:addSingle(unit)
                SetUnitX(unit, WorldBounds.maxX)
                SetUnitY(unit, WorldBounds.maxY)
                SetUnitOwner(unit, player, false)
                PauseUnit(unit, true)
            end
        end

        --- Fetches a dummy unit from the pool, if the pool is empty will create a new dummy unit.
        ---@param x number
        ---@param y number
        ---@param z number
        ---@param face number
        function Pool.retrieve(x, y, z, face)
            local dummy
            if group:size() > 0 then
                dummy = group:random()
                PauseUnit(dummy, false)
                group:removeSingle(dummy)
                SetUnitX(dummy, x)
                SetUnitY(dummy, y)
                SetUnitFlyHeight(dummy, z, 9000)
                BlzSetUnitFacingEx(dummy, face)
            else
                dummy = CreateUnit(player, DUMMY, x, y, face)
                SetUnitFlyHeight(dummy, z, 9000)
                UnitRemoveAbility(dummy, dummyAbility)
            end

            return dummy
        end

        --- Recycles a dummy unit after a defined delay seconds
        ---@param unit unit
        ---@param delay number
        function Pool.recycleTimed(unit, delay)
            if GetUnitTypeId(unit) == DUMMY then
                TimerQueue:callDelayed(delay, Pool.recycle, unit)
            end
        end

        if OnInit then
            OnInit.map("RelativisticMissiles", function()
                TimerQueue:callDelayed(0, function()
                    for _ = 0, STARTING_DUMMY_SIZE do
                        local unit = CreateUnit(player, DUMMY, WorldBounds.maxX, WorldBounds.maxY, 0)
                        PauseUnit(unit, false)
                        group:addSingle(unit)
                        UnitRemoveAbility(unit, dummyAbility)
                    end
                end)
            end)
        end
    end

    do
        ---@class Coordinates
        ---@field x number
        ---@field y number
        ---@field z number
        ---@field ref Coordinates
        Coordinates = {}
        Coordinates.__index = Coordinates

        function Coordinates:destroy()
            self = nil
        end

        ---@param a Coordinates
        function Coordinates:math(a)
            local dx
            local dy

            while true do
                dx = a.x - self.x
                dy = a.y - self.y
                dx = dx * dx + dy * dy
                dy = SquareRoot(dx)
                if dx ~= 0. and dy ~= 0. then
                    break
                end
                a.x = a.x + .01
                a.z = a.z - GetPointZ(a.x - .01, a.y) + GetPointZ(a.x, a.y)
            end

            self.square = dx
            self.distance = dy
            self.angle = Atan2(a.y - self.y, a.x - self.x)
            self.slope = (a.z - self.z) / dy
            self.alpha = Atan(self.slope)
            -- Set b.
            if a.ref == self then
                a.angle = self.angle + bj_PI
                a.distance = dy
                a.slope = -self.slope
                a.alpha = -self.alpha
                a.square = dx
            end
        end

        ---@param a Coordinates
        function Coordinates:link(a)
            self.ref = a
            a.ref = self
            self:math(a)
        end

        ---@param toX number
        ---@param toY number
        ---@param toZ number
        function Coordinates:move(toX, toY, toZ)
            self.x = toX
            self.y = toY
            self.z = toZ + GetPointZ(toX, toY)
            if self.ref ~= self then
                self:math(self.ref)
            end
        end

        ---@param x number
        ---@param y number
        ---@param z number
        ---@return Coordinates
        function Coordinates.create(x, y, z)
            local c = setmetatable({}, Coordinates)
            c.ref = c
            c:move(x, y, z)
            return c
        end
    end

    -- -------------------------------------------------------------------------- --
    --                                  Missiles                                  --
    -- -------------------------------------------------------------------------- --
    ---@class Missile
    ---@field launched boolean
    ---@field collideZ boolean
    ---@field finished boolean
    ---@field paused boolean
    ---@field roll boolean
    ---@field source unit
    ---@field target unit?
    ---@field owner player
    ---@field dummy unit
    ---@field open number
    ---@field height number
    ---@field veloc number
    ---@field acceleration number
    ---@field collision number
    ---@field damage number
    ---@field travel number
    ---@field turn number
    ---@field data number
    ---@field type integer
    ---@field tileset integer
    ---@field Duration integer
    ---@field Speed integer
    ---@field Arc integer
    ---@field Curve integer
    ---@field Vision integer
    ---@field origin Coordinates
    ---@field impact Coordinates
    ---@field effect MissileEffect
    ---@field hitTargets Set
    ---@field onHit fun(unit: unit, delay: number): boolean
    ---@field onMissile fun(missile: Missile, delay: number): boolean
    ---@field onDestructable fun(destructable: destructable, delay: number): boolean
    ---@field onItem fun(item: item, delay: number): boolean
    ---@field onCliff fun(delay: number): boolean
    ---@field onTerrain fun(delay: number): boolean
    ---@field onTileset fun(tile: integer, delay: number): boolean
    ---@field onPeriod fun(delay: number): boolean
    ---@field onFinish fun(delay: number): boolean
    ---@field onBoundaries fun(delay: number): boolean
    ---@field onPause fun(): boolean
    ---@field onResume fun(): boolean
    ---@field onRemove fun()
    Missile = {}
    Missile.__index = Missile
    Missile.collection = SyncedTable.create() ---@type table<Missile, boolean>

    local missileProcessor = Processor.create(1);
    local yaw = 0
    local pitch = 0
    local travelled = 0

    ---@param delay number
    function Missile:OnHit(delay)
        if self.onHit then
            if self.allocated and self.collision > 0 then
                GroupEnumUnitsInRange(group, self.x, self.y, self.collision + COLLISION_SIZE, nil)
                local unit = FirstOfGroup(group)
                while unit do
                    if not self.hitTargets:contains(unit) then
                        if IsUnitInRangeXY(unit, self.x, self.y, self.collision) then
                            if self.collideZ then
                                local dx = GetPointZ(GetUnitX(unit), GetUnitY(unit)) + GetUnitFlyHeight(unit)
                                local dy = BlzGetUnitCollisionSize(unit)
                                if dx + dy >= self.z - self.collision and dx <= self.z + self.collision then
                                    self.hitTargets:addSingle(unit)
                                    if self.allocated and self.onHit(unit, delay) then
                                        self:terminate()
                                        break
                                    end
                                end
                            else
                                self.hitTargets:addSingle(unit)
                                if self.allocated and self.onHit(unit, delay) then
                                    self:terminate()
                                    break
                                end
                            end
                        end
                    end
                    GroupRemoveUnit(group, unit)
                    unit = FirstOfGroup(group)
                end
            end
        end
    end

    ---@param delay number
    function Missile:OnMissile(delay)
        if self.onMissile then
            if self.allocated and self.collision > 0 then
                for missile, _ in pairs(Missile.collection) do
                    if missile ~= self then
                        if not self.hitTargets:contains(missile) then
                            local dx = missile.x - self.x
                            local dy = missile.y - self.y
                            if SquareRoot(dx * dx + dy * dy) <= self.collision then
                                self.hitTargets:addSingle(missile)
                                if self.allocated and self.onMissile(missile, delay) then
                                    self:terminate()
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    ---@param delay number
    function Missile:OnDestructable(delay)
        if self.onDestructable then
            if self.allocated and self.collision > 0 then
                local dx = self.collision
                SetRect(rect, self.x - dx, self.y - dx, self.x + dx, self.y + dx)
                EnumDestructablesInRect(rect, nil, function()
                    local destructable = GetEnumDestructable()
                    if not self.hitTargets:contains(destructable) then
                        if self.collideZ then
                            local dz = GetPointZ(GetWidgetX(destructable), GetWidgetY(destructable))
                            local tz = GetDestructableOccluderHeight(destructable)
                            if dz + tz >= self.z - self.collision and dz <= self.z + self.collision then
                                self.hitTargets:addSingle(destructable)
                                if self.allocated and self.onDestructable(destructable, delay) then
                                    self:terminate()
                                    return
                                end
                            end
                        else
                            self.hitTargets:addSingle(destructable)
                            if self.allocated and self.onDestructable(destructable, delay) then
                                self:terminate()
                                return
                            end
                        end
                    end
                end)
            end
        end
    end

    ---@param delay number
    function Missile:OnItem(delay)
        if self.onItem then
            if self.allocated and self.collision > 0 then
                local dx = self.collision
                SetRect(rect, self.x - dx, self.y - dx, self.x + dx, self.y + dx)
                EnumItemsInRect(rect, nil, function()
                    local item = GetEnumItem()
                    if not self.hitTargets:contains(item) then
                        if self.collideZ then
                            local dz = GetPointZ(GetItemX(item), GetItemY(item))
                            if dz + ITEM_SIZE >= self.z - self.collision and dz <= self.z + self.collision then
                                self.hitTargets:addSingle(item)
                                if self.allocated and self.onItem(item, delay) then
                                    self:terminate()
                                    return
                                end
                            end
                        else
                            self.hitTargets:addSingle(item)
                            if self.allocated and self.onItem(item, delay) then
                                self:terminate()
                                return
                            end
                        end
                    end
                end)
            end
        end
    end

    ---@param delay number
    function Missile:OnCliff(delay)
        if self.onCliff then
            local dx = GetTerrainCliffLevel(self.nextX, self.nextY)
            local dy = GetTerrainCliffLevel(self.x, self.y)
            if dy < dx and self.z < (dx - GetMapCliffLevel()) * bj_CLIFFHEIGHT then
                if self.allocated and self.onCliff(delay) then
                    self:terminate()
                end
            end
        end
    end

    ---@param delay number
    function Missile:OnTerrain(delay)
        if self.onTerrain then
            if GetPointZ(self.x, self.y) > self.z then
                if self.allocated and self.onTerrain(delay) then
                    self:terminate()
                end
            end
        end
    end

    ---@param delay number
    function Missile:OnTileset(delay)
        if self.onTileset then
            local type = GetTerrainType(self.x, self.y)
            if type ~= self.tileset then
                if self.allocated and self.onTileset(type, delay) then
                    self:terminate()
                end
            end
            self.tileset = type
        end
    end

    ---@param delay number
    function Missile:OnPeriod(delay)
        if self.onPeriod then
            if self.allocated and self.onPeriod(delay) then
                self:terminate()
            end
        end
    end

    ---@param delay number
    function Missile:OnOrient(delay)
        local angle

        -- Homing or not
        if self.target and GetUnitTypeId(self.target) ~= 0 then
            self.impact:move(GetUnitX(self.target), GetUnitY(self.target), GetUnitFlyHeight(self.target) + self.toZ)
            local dx = self.impact.x - self.nextX
            local dy = self.impact.y - self.nextY
            angle = Atan2(dy, dx)
            self.travel = self.origin.distance - SquareRoot(dx * dx + dy * dy)
        else
            angle = self.origin.angle
            self.target = nil
        end

        -- turn rate
        if self.turn ~= 0 and not (Cos(self.curveAngle - angle) >= Cos(self.turn)) then
            if Sin(angle - self.curveAngle) >= 0 then
                self.curveAngle = self.curveAngle + self.turn
            else
                self.curveAngle = self.curveAngle - self.turn
            end
        else
            self.curveAngle = angle
        end

        local vel = self.veloc
        if delay > 1 then
            vel = vel * delay
        end

        yaw = self.curveAngle
        travelled = self.travel + vel
        self.veloc = self.veloc + self.acceleration
        self.travel = travelled
        pitch = self.origin.alpha
        self.prevX = self.x
        self.prevY = self.y
        self.prevZ = self.z
        self.x = self.nextX
        self.y = self.nextY
        self.z = self.nextZ
        self.nextX = self.x + vel * Cos(yaw)
        self.nextY = self.y + vel * Sin(yaw)

        -- arc calculation
        local s = travelled
        local d = self.origin.distance
        local h = self.height
        if h ~= 0 or self.origin.slope ~= 0 then
            self.nextZ = 4 * h * s * (d - s) / (d * d) + self.origin.slope * s + self.origin.z
            pitch = pitch - Atan(((4 * h) * (2 * s - d)) / (d * d))
        end

        -- curve calculation
        local c = self.open
        if c ~= 0 then
            local dx = 4 * c * s * (d - s) / (d * d)
            angle = yaw + bj_PI / 2
            self.x = self.x + dx * Cos(angle)
            self.y = self.y + dx * Sin(angle)
            yaw = yaw + Atan(-((4 * c) * (2 * s - d)) / (d * d))
        end
    end

    ---@param delay number
    function Missile:OnFinish(delay)
        if travelled >= self.origin.distance - 0.0001 then
            self.finished = true
            if self.onFinish then
                if self.allocated and self.onFinish(delay) then
                    self:terminate()
                else
                    if self.travel > 0 and not self.paused then
                        self:terminate()
                    end
                end
            else
                self:terminate()
            end
        else
            if not self.roll then
                self.effect:orient(yaw, -pitch, 0)
            else
                self.effect:orient(yaw, -pitch, Atan2(self.open, self.height))
            end
        end
    end

    ---@param delay number
    function Missile:OnBoundaries(delay)
        if not self.effect:move(self.x, self.y, self.z) then
            if self.onBoundaries then
                if self.allocated and self.onBoundaries(delay) then
                    self:terminate()
                end
            end
        else
            if self.dummy then
                SetUnitX(self.dummy, self.x)
                SetUnitY(self.dummy, self.y)
            end
        end
    end

    function Missile:OnPause()
        if self.onPause then
            if self.allocated and self.onPause() then
                self:terminate()
            end
        end
    end

    ---@param flag boolean
    function Missile:OnResume(flag)
        self.paused = flag
        if not self.paused then
            ---@param delay number
            missileProcessor:enqueueTask(function(delay) return self:move(delay) end, MISSILE_OP_COUNT, PERIOD)

            if self.onResume then
                if self.allocated and self.onResume() then
                    self:terminate()
                else
                    if self.finished then
                        self:terminate()
                    end
                end
            else
                if self.finished then
                    self:terminate()
                end
            end
        end
    end

    function Missile:OnRemove()
        if self.allocated and self.launched then
            self.allocated = false

            if self.onRemove then
                self.onRemove()
            end

            if self.dummy then
                Pool.recycle(self.dummy)
            end

            Missile.collection[self] = nil

            self.origin:destroy()
            self.impact:destroy()
            self.effect:destroy()
        end
    end

    -- ----------------------------- Curved movement ---------------------------- --
    ---@param value number
    function Missile:curve(value)
        self.open = Tan(value * bj_DEGTORAD) * self.origin.distance
        self.Curve = value
    end

    -- ----------------------------- Arced Movement ----------------------------- --
    ---@param value number
    function Missile:arc(value)
        self.height = Tan(value * bj_DEGTORAD) * self.origin.distance / 4
        self.Arc = value
    end

    -- ------------------------------ Missile Speed ----------------------------- --
    ---@param value number
    function Missile:speed(value)
        self.veloc = value * PERIOD
        self.Speed = value

        local vel = self.veloc
        local s = self.travel + vel
        local d = self.origin.distance
        self.nextX = self.x + vel * Cos(self.curveAngle)
        self.nextY = self.y + vel * Sin(self.curveAngle)

        if self.height ~= 0 or self.origin.slope ~= 0 then
            self.nextZ = 4 * self.height * s * (d - s) / (d * d) + self.origin.slope * s + self.origin.z
            self.z = self.nextZ
        end
    end

    -- ------------------------------- Flight Time ------------------------------ --
    ---@param value number
    function Missile:duration(value)
        self.veloc = RMaxBJ(0.00000001, (self.origin.distance - self.travel) * PERIOD / RMaxBJ(0.00000001, value))
        self.Duration = value

        local vel = self.veloc
        local s = self.travel + vel
        local d = self.origin.distance
        self.nextX = self.x + vel * Cos(self.curveAngle)
        self.nextY = self.y + vel * Sin(self.curveAngle)

        if self.height ~= 0 or self.origin.slope ~= 0 then
            self.nextZ = 4 * self.height * s * (d - s) / (d * d) + self.origin.slope * s + self.origin.z
            self.z = self.nextZ
        end
    end

    -- ------------------------------- Sight Range ------------------------------ --
    ---@param sightRange number
    function Missile:vision(sightRange)
        self.Vision = sightRange

        if self.dummy then
            SetUnitOwner(self.dummy, self.owner, false)
            BlzSetUnitRealField(self.dummy, UNIT_RF_SIGHT_RADIUS, sightRange)
        else
            if not self.owner then
                if self.source then
                    self.dummy = Pool.retrieve(self.x, self.y, self.z, 0)
                    SetUnitOwner(self.dummy, GetOwningPlayer(self.source), false)
                    BlzSetUnitRealField(self.dummy, UNIT_RF_SIGHT_RADIUS, sightRange)
                end
            else
                self.dummy = Pool.retrieve(self.x, self.y, self.z, 0)
                SetUnitOwner(self.dummy, self.owner, false)
                BlzSetUnitRealField(self.dummy, UNIT_RF_SIGHT_RADIUS, sightRange)
            end
        end
    end

    -- --------------------------- Bounce and Deflect --------------------------- --
    function Missile:bounce()
        self.origin:move(self.x, self.y, self.z - GetPointZ(self.x, self.y))

        travelled = 0
        self.travel = 0
        self.finished = false
    end

    function Missile:deflect(tx, ty, tz)
        local locZ = GetPointZ(self.x, self.y)

        if self.z < locZ and self.onTerrain then
            self.nextX = self.prevX
            self.nextY = self.prevY
            self.nextZ = self.prevZ
        end

        self.toZ = tz
        self.target = nil
        self.impact:move(tx, ty, tz)
        self.origin:move(self.x, self.y, self.z - locZ)

        travelled = 0
        self.travel = 0
        self.finished = false
    end

    function Missile:deflectTarget(unit)
        self:deflect(GetUnitX(unit), GetUnitY(unit), self.toZ)
        self.target = unit
    end

    -- ---------------------------- Flush hit targets --------------------------- --
    function Missile:flushAll()
        self.hitTargets = {}
    end

    function Missile:flush(target)
        if target then
            self.hitTargets[target] = nil
        end
    end

    function Missile:hitted(target)
        return self.hitTargets[target]
    end

    -- ------------------------------ Missile Pause ----------------------------- --
    function Missile:pause(flag)
        self:OnResume(flag)
    end

    -- ------------------------------ Reset members ----------------------------- --
    function Missile:reset()
        self.launched = false
        self.collideZ = false
        self.finished = false
        self.paused = false
        self.roll = false
        self.source = nil
        self.target = nil
        self.owner = nil
        self.dummy = nil
        self.open = 0.
        self.height = 0.
        self.veloc = 0.
        self.acceleration = 0.
        self.collision = 0.
        self.damage = 0.
        self.travel = 0.
        self.turn = 0.
        self.tileset = 0
        self.Duration = 0
        self.Speed = 0
        self.Arc = 0
        self.Curve = 0
        self.Vision = 0
        self.hitTargets = Set.create()
        self.onHit = nil
        self.onMissile = nil
        self.onDestructable = nil
        self.onItem = nil
        self.onCliff = nil
        self.onTerrain = nil
        self.onTileset = nil
        self.onPeriod = nil
        self.onFinish = nil
        self.onBoundaries = nil
        self.onPause = nil
        self.onResume = nil
        self.onRemove = nil
    end

    -- -------------------------------- Terminate ------------------------------- --
    function Missile:terminate()
        self:OnRemove()
    end

    -- -------------------------- Destroys the missile -------------------------- --
    function Missile:remove()
        if self.paused then
            self:OnPause()
        else
            self:OnRemove()
        end
    end

    -- ---------------------------- Missile movement --------------------------- --
    ---@param delay number
    ---@return boolean done
    function Missile:move(delay)
        if self.allocated and not self.paused then
            self:OnHit(delay)
            self:OnMissile(delay)
            self:OnDestructable(delay)
            self:OnItem(delay)
            self:OnCliff(delay)
            self:OnTerrain(delay)
            self:OnTileset(delay)
            self:OnPeriod(delay)
            self:OnOrient(delay)
            self:OnFinish(delay)
            self:OnBoundaries(delay)
        else
            self:remove()
            return true
        end

        return false
    end

    -- --------------------------- Launch the Missile --------------------------- --
    function Missile:launch()
        if not self.launched and self.allocated then
            self.launched = true
            Missile.collection[self] = true

            ---@param delay number
            missileProcessor:enqueueTask(function(delay) return self:move(delay) end, MISSILE_OP_COUNT, PERIOD)
        end
    end

    -- --------------------------- Main Creator method -------------------------- --
    ---@param x number
    ---@param y number
    ---@param z number
    ---@param toX number
    ---@param toY number
    ---@param toZ number
    ---@return Missile
    function Missile.create(x, y, z, toX, toY, toZ)
        local self = setmetatable({}, Missile)

        self:reset()

        self.origin = Coordinates.create(x, y, z)
        self.impact = Coordinates.create(toX, toY, toZ)
        self.effect = MissileEffect.create(x, y, self.origin.z)
        self.origin:link(self.impact)
        self.allocated = true
        self.curveAngle = self.origin.angle
        self.x = x
        self.y = y
        self.z = self.impact.z
        self.prevX = x
        self.prevY = y
        self.prevZ = self.impact.z
        self.nextX = x
        self.nextY = y
        self.nextZ = self.impact.z
        self.toZ = toZ

        return self
    end
end)
if Debug then Debug.endFile() end
