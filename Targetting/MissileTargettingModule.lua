if Debug then Debug.beginFile "MissileSystem/Targetting/MissileTargettingModule" end
OnInit.module("MissileSystem/Targetting/MissileTargettingModule", function(require)
    ---@alias TargettingHandler fun(self: MissileTargettingModule, missile: Missile, delay: number): distance: number, terrainAngle: number, heightAngle: number?

    ---@class MissileTargettingModule abstract
    ---@field handleMissile TargettingHandler
    MissileTargettingModule = {}
    MissileTargettingModule.__index = MissileTargettingModule

    ---@param missile Missile
    function MissileTargettingModule:applyToMissile(missile)
        missile.targetting = self
    end
end)
if Debug then Debug.endFile() end
