AddCSLuaFile()
SWEP.Base = "weapon_acf_deployable_base"
SWEP.PrintName = "ACF C4"
SWEP.Category = "ACF Infantry"
SWEP.SubCategory = "Throwables and Deployables"
SWEP.Spawnable = true
SWEP.DeployableKind = "c4"
SWEP.MaxDeployed = 15
SWEP.ViewModel = "models/weapons/insurgency/v_c4_sec.mdl"
SWEP.WorldModel = "models/weapons/insurgency/w_c4.mdl"
SWEP.IconOverride = "vgui/acf_sweps/c4.png"
SWEP.ACFMenuImage = "vgui/acf_sweps/c4.png"
SWEP.ACFMenuImageScale = 0.75 -- Proportional, centered preview matching other equipment icons.
SWEP.Primary.Ammo = "ACFInfantryC4"
SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 101
SWEP.Primary.Automatic = false
SWEP.ViewModelFOV = 69
SWEP.DeployableSequences = {draw = "base_draw", throw = "base_throw", fire = "det_detonate", idle = "base_idle", empty = "det_idle"}
include("acf_sweps/insurgency_hands.lua").Apply(SWEP)
