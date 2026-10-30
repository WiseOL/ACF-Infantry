AddCSLuaFile()

include("weapon_acf_base.lua")


SWEP.Base                   = "weapon_acf_base"
SWEP.PrintName = "ACF AT4"

SWEP.IconOffset				= Vector(-2, -8, 0)
SWEP.IconAngOffset			= Angle()

SWEP.UseHands               = false -- Matching Insurgency arms are drawn by the presentation helper.
SWEP.ViewModel              = "models/weapons/insurgency/v_at4.mdl"
SWEP.ViewModelFOV			= 60

SWEP.ShotSound				= Sound("weapons/at4/at4_tp.wav")
SWEP.WorldModel             = "models/weapons/insurgency/w_at4.mdl"
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

SWEP.Caliber = 152
SWEP.ACFProjMass = 1
SWEP.ACFType = "HEAT"
SWEP.ACFMuzzleVel = 1
SWEP.Tracer = 0
SWEP.InfantryMissile = "BGM-71E"
SWEP.ArmingWalkMultiplier = 0.5
SWEP.ArmedSprintMultiplier = 0.5
SWEP.LauncherReloadTime = 4

SWEP.IronSightPos = Vector(-1.30, 0, 0.67) -- Lower the sight slightly around the true center crosshair.
SWEP.IronSightAng = Angle(1.85, -2.3, 7.738)
SWEP.PitchAdjust			= 0

SWEP.SprintAng				= Angle(-5, -10, 0) -- The angle the viewmodel turns to when the player is sprinting

SWEP.AimFocused				= 0.0
SWEP.AimUnfocused			= 5

SWEP.CustomAnim				= false
SWEP.AimAnim				= ACT_VM_DEPLOY
SWEP.IdleAnim				= ACT_VM_UNDEPLOY

SWEP.CustomWorldModelPos = false -- Use the donor world model attachment.
SWEP.OffsetWorldModelPos	= Vector(0, 1, -1.5)
SWEP.OffsetWorldModelAng	= Angle(-2, -1, 178)

SWEP.FakeFire				= true	-- This shakes the aim bloom so you can't just quickshot to victory
SWEP.MoveBloom				= 2

SWEP.Zoom					= 1.2
SWEP.Recovery				= 0.5

SWEP.Handling = 0.5 -- Preserve original bloom while halving firing spread.


SWEP.InfantryProjectile = 20.0
SWEP.InfantryPropellant = 18.00
SWEP.InfantryLinerAngle = 90.0
SWEP.InfantryStandoffRatio = 0.00
SWEP.InfantryGuidance = "ACF.Missiles.Guidance.WireSACLOS"
include("acf_sweps/launcher_rounds.lua").ApplyMissile(SWEP)

SWEP.IconOverride = "vgui/acf_sweps/at4.png"
SWEP.ACFMenuImage = "vgui/acf_sweps/at4.png"
SWEP.ACFMenuImageScale = 0.75 -- Centered, with margins like the other launcher previews.
SWEP.ACFMenuImageRotation = 25 -- Diagonal menu presentation only.
SWEP.SubCategory = "Launchers"
include("acf_sweps/insurgency_at4.lua").Apply(SWEP)

-- Grounded firing only; SMAW and other equipment are unaffected.
include("acf_sweps/grounded_launcher.lua").Apply(SWEP)
