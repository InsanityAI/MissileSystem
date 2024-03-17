if Debug then Debug.beginFile "MissileSystem" end
OnInit.module("MissileSystem", function(require)
    require "MissileSystem/Missile"
    local heightSuppliers = require "MissileSystem/WidgetHeightSuppliers" ---@type WidgetHeightSuppliers
    require "TaskProcessor"
    require "SetUtils"
    require "MapBounds"
    require "TimerQueue"

    local processor = Processor.create(1)
    local missileTQ = TimerQueue.create()
    MissileSystem = {
        PERIOD = 1 / 40,      -- update tick for missiles
        OP_COUNT = 100,       -- amount of operations a missile counts as when processing
        COLLISION_SIZE = 128, -- the average collision size compensation when detecting collisions
        ITEM_SIZE = 16,       -- item size used in z collision
        missiles = Set.create()
    }

    --- temp variables
    local rect = Rect(0, 0, 0, 0)
    local dx, dy ---@type number, number
    local heightDelta ---@type number
    local distance, terrainAngle, heightAngle ---@type number?, number?, number?
    local hitBoundary ---@type boolean
    ---

    ---@param heightSupplier fun(widget: widget, collideZMode: CollideZMode): height: number?
    ---@param collisionSizeGetter fun(widget: widget): height: number
    ---@return fun(missile: Missile, widget: widget): isInCollisionRange: boolean
    local function widgetHeightCheckFactory(heightSupplier, collisionSizeGetter)
        return function(missile, widget)
            local widgetHeight = heightSupplier(widget, missile.collideZ)
            if widgetHeight == nil then
                return true -- height is not taken into account for collision
            else
                return missile.missileZ + missile.collisionSize >= widgetHeight and
                    missile.missileZ - missile.collisionSize <= widgetHeight + collisionSizeGetter(widget)
            end
        end
    end

    local isUnitHeightInCollisionRange = widgetHeightCheckFactory(heightSuppliers.getUnitHeight, BlzGetUnitCollisionSize)
    local isDestructableHeightInCollisionRange = widgetHeightCheckFactory(heightSuppliers.getDestructableHeight,
        GetDestructableOccluderHeight)
    local isItemHeightInCollisionRange = widgetHeightCheckFactory(heightSuppliers.getItemHeight,
        function() return MissileSystem.ITEM_SIZE end)

    ---@param missile Missile
    ---@param delay number
    local function handleUnit(missile, delay)
        for unit in SetUtils.getUnitsInRange(missile.missileX, missile.missileY, missile.collisionSize + MissileSystem.COLLISION_SIZE):elements() do
            if not missile.collidedUnits:contains(unit) and
                (IsUnitInRangeXY(unit, missile.missileX, missile.missileY, missile.collisionSize)) then -- is range check necessary?
                if isUnitHeightInCollisionRange(missile, unit) then
                    missile.collidedUnits:addSingle(unit)
                    missile.onUnit(missile, unit, delay)
                end
            end
        end
    end

    ---@param missile Missile
    ---@param delay number
    local function handleMissile(missile, delay)
        for otherMissile in MissileSystem.missiles:elements() do
            if otherMissile ~= missile and not missile.collidedMissiles:contains(otherMissile) then
                dx, dy = missile.missileX - otherMissile.missileX, missile.missileY - otherMissile.missileY
                if (dx ^ 2 + dy ^ 2) <= (missile.collisionSize + otherMissile.collisionSize) ^ 2 then
                    missile.collidedMissiles:addSingle(otherMissile)
                    -- otherMissile.collidedMissiles:addSingle(missile) -- cheeky optimization cannot be done because we don't know the delay of the other missile...
                    missile.onMissile(missile, otherMissile, delay)
                end
            end
        end
    end

    ---@param missile Missile
    ---@param delay number
    local function handleDestructable(missile, delay)
        SetRect(rect,
            missile.missileX - missile.collisionSize,
            missile.missileY - missile.collisionSize,
            missile.missileX + missile.collisionSize,
            missile.missileY + missile.collisionSize
        )
        for destructable in SetUtils.getDestructablesInRect(rect):elements() do
            if not missile.collidedDestructables:contains(destructable) and isDestructableHeightInCollisionRange(missile, destructable) then
                missile.collidedDestructables:addSingle(destructable)
                missile.onDestructable(missile, destructable, delay)
            end
        end
    end

    ---@param missile Missile
    ---@param delay number
    local function handleItem(missile, delay)
        SetRect(rect,
            missile.missileX - missile.collisionSize,
            missile.missileY - missile.collisionSize,
            missile.missileX + missile.collisionSize,
            missile.missileY + missile.collisionSize
        )
        for item in SetUtils.getItemsInRect(rect):elements() do
            if not missile.collidedItems:contains(item) and isItemHeightInCollisionRange(missile, item) then
                missile.collidedItems:addSingle(item)
                missile.onItem(missile, item, delay)
            end
        end
    end

    ---@param missile Missile
    ---@param delay number
    local function handleCliff(missile, delay)
        local cliffDelta = GetTerrainCliffLevel(missile.nextMissileX, missile.nextMissileY) -
            GetTerrainCliffLevel(missile.missileX, missile.missileY)
        if (missile.collideZ == CollideZMode.NONE or missile.collideZ == CollideZMode.SAFE) and cliffDelta ~= 0 then
            missile.onCliff(missile, cliffDelta, delay)
        elseif missile.collideZ == CollideZMode.UNSAFE then
            if cliffDelta ~= 0 then
                heightDelta = GetPointZ(missile.nextMissileX, missile.nextMissileY) -
                    GetPointZ(missile.missileX, missile.missileY)
                if heightDelta > bj_CLIFFHEIGHT or heightDelta < bj_CLIFFHEIGHT then
                    missile.onCliff(missile, cliffDelta, delay)
                end
            end
        end
    end

    ---@param missile Missile
    ---@param delay number
    local function handleTerrain(missile, delay)
        if missile.collideZ == CollideZMode.UNSAFE and GetPointZ(missile.missileX, missile.missileY) > missile.missileZ or
            missile.collideZ == CollideZMode.SAFE and GetTerrainCliffLevel(missile.missileX, missile.missileY) * bj_CLIFFHEIGHT > missile.missileZ then
            missile.onTerrain(missile, delay)
        end
    end

    local offsetD ---@type number

    ---@param missile Missile
    ---@param delay number
    ---@return boolean done
    local function move(missile, delay)
        if missile.paused or missile.destroyed or not missile.movement then
            missile.processorTask = nil
            return true
        end
        if missile.targetting then
            distance, terrainAngle, heightAngle = missile.targetting:handleMissile(missile, delay)
        else
            distance, terrainAngle, heightAngle = nil, nil, nil
        end
        missile.movementTime = missile.movementTime + MissileSystem.PERIOD + delay
        offsetD, missile.nextMissileX, missile.nextMissileY, missile.nextMissileZ, missile.nextGroundAngle, missile.nextHeightAngle =
            missile.movement:handleMissile(missile, delay, distance, terrainAngle, heightAngle)
        missile.movedDistance = missile.movedDistance + offsetD

        hitBoundary = false
        if missile.nextMissileX > WorldBounds.maxX then
            missile.nextMissileX = WorldBounds.maxX
            hitBoundary = true
        elseif missile.nextMissileX < WorldBounds.minX then
            missile.nextMissileX = WorldBounds.minX
            hitBoundary = true
        end
        if missile.nextMissileY > WorldBounds.maxY then
            missile.nextMissileY = WorldBounds.maxY
            hitBoundary = true
        elseif missile.nextMissileY < WorldBounds.minY then
            missile.nextMissileY = WorldBounds.minY
            hitBoundary = true
        end

        if missile.onUnit and missile.collisionSize > 0 then handleUnit(missile, delay) end
        if missile.onMissile and missile.collisionSize > 0 then handleMissile(missile, delay) end
        if missile.onDestructable and missile.collisionSize > 0 then handleDestructable(missile, delay) end
        if missile.onItem and missile.collisionSize > 0 then handleItem(missile, delay) end
        if missile.onCliff then handleCliff(missile, delay) end
        if missile.onTerrain then handleTerrain(missile, delay) end
        -- removed onTileset
        if missile.onProcess then missile.onProcess(missile, delay) end
        if missile.onBoundaries and hitBoundary then missile.onBoundaries(missile, delay) end
        if missile.onFinish then missile.onFinish(missile, delay) end

        if missile.visionUnit then
            SetUnitX(missile.visionUnit, missile.nextMissileX)
            SetUnitY(missile.visionUnit, missile.nextMissileY)
        end

        missile.missileX = missile.nextMissileX
        missile.missileY = missile.nextMissileY
        missile.missileZ = missile.nextMissileZ
        missile.groundAngle = missile.nextGroundAngle
        missile.heightAngle = missile.nextHeightAngle

        for effect in missile.effects:elements() do
            effect:move(missile.missileX, missile.missileY, missile.missileZ)
            effect:orient(missile.groundAngle, missile.heightAngle, nil)
        end

        return missile.destroyed
    end

    function Missile:launch()
        MissileSystem.missiles:addSingle(self)
        if self.movement then
            self.processorTask = processor:enqueueTask(function(delay) return move(self, delay) end,
                MissileSystem.OP_COUNT, MissileSystem.PERIOD)
        end
    end

    function Missile:destroy()
        MissileSystem.missiles:removeSingle(self)
        if self.onDestroy then self:onDestroy() end
        if self.visionUnit then
            VisionDummyRecycler.release(self.visionUnit)
            self.visionUnit = nil
        end
        self.onUnit = nil
        self.onMissile = nil
        self.onDestructable = nil
        self.onItem = nil
        self.onCliff = nil
        self.onTerrain = nil
        self.onProcess = nil
        self.onFinish = nil
        self.onBoundaries = nil
        self.onPause = nil
        self.onResume = nil
        self.onDestroy = nil
        self.destroyed = true
        self.paused = true
    end
end)
if Debug then Debug.endFile() end