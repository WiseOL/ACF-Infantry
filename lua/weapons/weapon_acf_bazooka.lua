AddCSLuaFile()

include("weapon_acf_base.lua")


SWEP.Base                   = "weapon_acf_base"
SWEP.PrintName = "ACF Bazooka"

SWEP.IconOffset				= Vector(4, -4, 0)
SWEP.IconAngOffset			= Angle()

SWEP.UseHands               = false
SWEP.ViewModel              = "models/weapons/bazooka/v_bazooka.mdl"
SWEP.ViewModelFOV			= 45

SWEP.ShotSound				= Sound("Weapon_Bazooka.Shoot")
SWEP.WorldModel             = "models/weapons/bazooka/w_bazooka.mdl"
SWEP.HoldType               = "rpg"

SWEP.Slot                   = 4
SWEP.SlotPos                = 0

SWEP.Spawnable              = true
SWEP.AdminOnly              = false

SWEP.m_WeaponDeploySpeed    = 1
SWEP.Spread                 = 0.375
SWEP.RecoilMod              = 0.025

SWEP.Primary.ClipSize       = 1
SWEP.Primary.DefaultClip    = 101
SWEP.Primary.Ammo           = "RPG_Round"
SWEP.Primary.Automatic      = false
SWEP.Primary.Delay          = 0.2
SWEP.CarrySpeedMul			= 1.0
SWEP.UseHybrid				= false

SWEP.Caliber = 125
SWEP.ACFProjMass = 1
SWEP.ACFType = "HEAT"
SWEP.ACFMuzzleVel = 1
SWEP.Tracer = 0
SWEP.InfantryMissile = "AT-3"
SWEP.ArmingWalkMultiplier = 0.75
SWEP.ArmedSprintMultiplier = 0.7
SWEP.LauncherReloadTime = 4

SWEP.AimTable = {{IronPos = Vector(-3.83, -8, -0.4), IronAng = Angle(), PitchAdjust = 0, Text = "GUIDED"}}

SWEP.SprintAng				= Angle(-5, -10, 0) -- The angle the viewmodel turns to when the player is sprinting

SWEP.AimFocused				= 0.75
SWEP.AimUnfocused			= 5

SWEP.CustomAnim				= true
SWEP.AimAnim				= ACT_VM_DEPLOY
SWEP.IdleAnim				= ACT_VM_UNDEPLOY

SWEP.SprintAng				= Angle(-10, -10, 0) -- The angle the viewmodel turns to when the player is sprinting

SWEP.CustomWorldModelPos	= true -- An attempt at fixing the broken worldmodel position
SWEP.OffsetWorldModelPos	= Vector(0, 0, 1)
SWEP.OffsetWorldModelAng	= Angle(10, 0, 180)

SWEP.FakeFire				= true	-- This shakes the aim bloom so you can't just quickshot to victory
SWEP.MoveBloom				= 2

SWEP.Zoom					= 1.2
SWEP.Recovery				= 0.5

SWEP.Handling = 0.5 -- Preserve original bloom while halving firing spread.


SWEP.InfantryProjectile = 16.0
SWEP.InfantryPropellant = 26.00
SWEP.InfantryLinerAngle = 90.0
SWEP.InfantryStandoffRatio = 0.00
SWEP.InfantryGuidance = "ACF.Missiles.Guidance.WireSACLOS"
include("acf_sweps/launcher_rounds.lua").ApplyMissile(SWEP)

SWEP.SubCategory = "Launchers"
