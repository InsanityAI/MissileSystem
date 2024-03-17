if Debug then Debug.beginFile "MissileSystem/Movement/BasicMovement" end
OnInit.module("MissileSystem/Movement/BasicMovement", function(require)
    require "MissileSystem/Movement/MissileMovementModule"

    --- Default missile movement, if targettingHandler for missile is not specified, goes in a straight line, otherwise homes towards the target.
    ---@class BasicMovement: MissileMovementModule
    ---@field movementSpeed number negative move speed will probably cause missile to go backwards, Don't know why you'd need this...
    ---@field rotationSpeed number 0 or less causes instant turn-rate
    BasicMovement = {}
    BasicMovement.__index = BasicMovement
    setmetatable(BasicMovement, MissileMovementModule)

    --- temp variables
    local vectorX, vectorY, vectorZ ---@type number, number, number?
    local ms, rs ---@type number, number
    local dAngleXY, dAngleZ ---@type number, number?
    local angleAngle ---@type number
    local orientXY, orientZ ---@type number, number?
    ---

    ---@type MovementHandler
    function BasicMovement:handleMissile(missile, delay, distanceToTarget, terrainAngleToTarget, heightAngleToTarget)
        ms = delay > 1 and self.movementSpeed * delay or self.movementSpeed

        if missile.targetting then -- every movement type should handle if there is no targetting involved (only missile and delay parameters are available then.)
            rs = delay > 1 and self.rotationSpeed * delay or self.rotationSpeed
            if rs <= 0 then
                orientXY = terrainAngleToTarget
                if heightAngleToTarget ~= nil then
                    orientZ = heightAngleToTarget
                else
                    orientZ = nil
                end
            else
                dAngleXY = terrainAngleToTarget - missile.groundAngle
                if heightAngleToTarget ~= nil then
                    dAngleZ = heightAngleToTarget - missile.heightAngle
                    if (terrainAngleToTarget ^ 2 + heightAngleToTarget ^ 2) > rs ^ 2 then
                        angleAngle = math.atan(dAngleZ, dAngleXY)
                        dAngleXY = ((dAngleXY > 0) and 1 or -1) * rs * math.cos(angleAngle)
                        dAngleZ = ((dAngleZ > 0) and 1 or -1) * rs * math.sin(angleAngle)
                    end
                    orientZ = missile.heightAngle + dAngleZ
                else
                    if math.abs(dAngleXY) > rs then
                        dAngleXY = (dAngleXY > 0 and 1 or -1) * rs
                    end
                    orientZ = nil
                end
                orientXY = missile.groundAngle + dAngleXY
            end
        else -- straight line movement
            orientXY, orientZ = missile.groundAngle, missile.heightAngle
        end

        -- TODO: fix position compensations with angular movement, instead of just movement speed compensation... (derivations?)

        if orientZ then
            vectorZ, ms = ms * math.sin(orientZ), ms * math.cos(orientZ)
        end
        vectorX, vectorY = ms * math.cos(orientXY), ms * math.sin(orientXY)
        return ms, vectorX, vectorY, vectorZ, orientXY, orientZ
    end

    ---@param movementSpeed number
    ---@param rotationSpeed number
    ---@return BasicMovement
    function BasicMovement.create(movementSpeed, rotationSpeed)
        return setmetatable({
            movementSpeed = BasicMovement.normalize(movementSpeed),
            rotationSpeed = BasicMovement.normalize(rotationSpeed)
        }, BasicMovement) --[[@as BasicMovement]]
    end

    ---@param movementSpeed number
    function BasicMovement:updateMovementSpeed(movementSpeed)
        self.movementSpeed = self.normalize(movementSpeed)
    end

    ---@param rotationSpeed number
    function BasicMovement:updateRotationSpeed(rotationSpeed)
        self.rotationSpeed = self.normalize(rotationSpeed)
    end
end)
if Debug then Debug.endFile() end
