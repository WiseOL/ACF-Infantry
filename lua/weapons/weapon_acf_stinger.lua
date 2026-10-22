AddCSLuaFile()
include("weapon_acf_base.lua")
SWEP.Base = "weapon_acf_base"
SWEP.PrintName = "ACF Stinger"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Slot = 4
SWEP.SlotPos = 3
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_rpg.mdl"
SWEP.WorldModel = "models/weapons/w_rocket_launcher.mdl"
SWEP.ViewModelFOV = 60
SWEP.HoldType = "rpg"
-- The shoulder-mounted RPG model clips across the screen with the base sprint tilt.
SWEP.SprintAng = Angle(0, 0, 0)
SWEP.ShotSound = Sound("Weapon_RPG.Single")
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
SWEP.IronSightPos = Vector(-6, -2, 1)
SWEP.IronSightAng = Angle()
SWEP.Zoom = 1.2
SWEP.Recovery = 0.5
SWEP.Instructions = "Hold secondary attack to aim at an ACF aircraft, then primary attack to launch. The infrared seeker acquires targets after launch and guides independently. Reload takes 10 seconds."

SWEP.InfantryProjectile = 60.0
SWEP.InfantryPropellant = 80.00
include("acf_sweps/launcher_rounds.lua").ApplyMissile(SWEP)

SWEP.SubCategory = "Launchers"
