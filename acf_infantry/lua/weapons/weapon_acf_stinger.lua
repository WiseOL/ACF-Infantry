AddCSLuaFile()
include("weapon_acf_base.lua")
SWEP.Base = "weapon_acf_base"
SWEP.PrintName = "ACF Stinger"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Slot = 4
SWEP.SlotPos = 3
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/fim92/c_fim92.mdl"
SWEP.WorldModel = "models/weapons/fim92/w_fim92.mdl"
SWEP.ViewModelFOV = 54
SWEP.HoldType = "rpg"
SWEP.SprintAng = Angle(-10, -10, 0)
SWEP.IdlePos = Vector(3, 5, -1.5)
SWEP.Scope = true
SWEP.CustomWorldModelPos = true
SWEP.OffsetWorldModelPos = Vector(0, 0, -2)
SWEP.OffsetWorldModelAng = Angle(14, 0, 180)
SWEP.ShotSound = Sound("Weapon_FIM92.Shoot")
SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 101
SWEP.Primary.Ammo = "RPG_Round"
SWEP.Primary.Automatic = false
SWEP.Primary.Delay = 0.5
SWEP.CarrySpeedMul = 1
SWEP.UseHybrid = false
SWEP.Caliber = 70
SWEP.ACFType = "HE"
SWEP.ACFProjLen = 60
SWEP.ACFProjMass = 1
SWEP.ACFMuzzleVel = 1
SWEP.FillerMass = 0
SWEP.Tracer = 0
SWEP.InfantryMissile = "FIM-92"
SWEP.InfantryMissileClass = "ACF.Missiles.SurfaceToAir.FIM-92"
SWEP.InfantryGuidance = "ACF.Missiles.Guidance.Infrared"
SWEP.InfantryFuze = "ACF.Missiles.Fuze.Radio"
SWEP.InfantryFuzeDistance = 118.11 -- 3 m, in Source inches
SWEP.InfantryFillerRatio = 0.48
SWEP.InfantryAutonomous = true
SWEP.LauncherArmingTime = 0
SWEP.LauncherReloadTime = 2
SWEP.Spread = 0.05
SWEP.Handling = 0.5
SWEP.RecoilMod = 0.025
SWEP.AimFocused = 0
SWEP.AimUnfocused = 1
SWEP.IronSightPos = Vector(-0.6, -11, -1.2)
SWEP.IronSightAng = Angle(0, 0, -30)
SWEP.Zoom = 1.5
SWEP.Recovery = 0.5
SWEP.Instructions = "Hold secondary attack on an ACF target for a two-second infrared lock, then fire. Guidance is autonomous after launch. Reload takes 2 seconds."

SWEP.InfantryProjectile = 60.0
SWEP.InfantryPropellant = 80.00
include("acf_sweps/launcher_rounds.lua").ApplyMissile(SWEP)

include("acf_sweps/stinger_seeker.lua").Apply(SWEP)

SWEP.SubCategory = "Launchers"

-- Grounded firing only; SMAW and other equipment are unaffected.
include("acf_sweps/grounded_launcher.lua").Apply(SWEP)
