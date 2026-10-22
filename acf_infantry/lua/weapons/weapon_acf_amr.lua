AddCSLuaFile()

include("weapon_acf_base.lua")

SWEP.Base                   = "weapon_acf_base"
SWEP.PrintName              = "ACF Anti-Material Rifle"

SWEP.IconOffset				= Vector(4, 4, 0)
SWEP.IconAngOffset			= Angle(0, 180, 0)

SWEP.UseHands               = false
SWEP.ViewModel              = "models/weapons/v_sniper.mdl"

SWEP.ShotSound				= Sound(")acf_base/weapons/sniper_fire.mp3")
SWEP.WorldModel             = "models/weapons/w_sniper.mdl"
SWEP.HoldType               = "ar2"

SWEP.Slot                   = 3
SWEP.SlotPos                = 0

SWEP.Spawnable              = true
SWEP.AdminOnly              = false

SWEP.m_WeaponDeploySpeed    = 1.5
SWEP.Spread                 = 0.375
SWEP.RecoilMod              = 0.5

SWEP.Primary.ClipSize       = 1
SWEP.Primary.DefaultClip    = 101
SWEP.Primary.Ammo           = "XBowBolt"
SWEP.Primary.Automatic      = false
SWEP.CarrySpeedMul			= 1.0
SWEP.Primary.Delay          = 1.25

SWEP.UseHybrid				= false

SWEP.CalcDistance			= 100
SWEP.CalcDistance2			= 300

SWEP.Caliber = 27 -- Native 27 mm autocannon APCR.
SWEP.ACFProjMass            = 0.1 -- kg of projectile
SWEP.ACFType                = "APCR"
SWEP.ACFMuzzleVel           = 700 -- m/s of bullet leaving the barrel
SWEP.Tracer                 = 1

SWEP.IronSightPos           = Vector(-5.775, -4, 0.92)

SWEP.Scope					= true
SWEP.Zoom					= 8
SWEP.HasDropCalc			= true
SWEP.Recovery				= 0.2

SWEP.AimFocused				= 0.1
SWEP.AimUnfocused			= 3

SWEP.Handling = 0.5 -- Preserve original bloom while halving firing spread.

SWEP:SetupACFBullet()

local Reload = Sound("acf_base/weapons/sniper_reload.mp3")

function SWEP:PrimaryAttack()
	if self:Clip1() <= 0 then
		self:EmitSound( "Weapon_Pistol.Empty" )
		self:Reload()
		self:SetNextPrimaryFire(CurTime() + 0.25)

		self.LastShot = CurTime()
		if SERVER then self:SetNWFloat("lastshot", self.LastShot) end

		return false
	end

	local Punch = self:GetPunch()
	self:Recoil(Punch)
	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

	if not self:CanPrimaryAttack() then return end

	local Ply = self:GetOwner()
	local AimMod = self:GetAimMod()

	if SERVER then
		local Aim = self:ResolveAim()
		local Right = Aim:Right()
		local Up = Aim:Up()

		local Cone = math.tan(math.rad(self.Spread * AimMod))
		local randUnitSquare = (Up * (2 * math.random() - 1) + Right * (2 * math.random() - 1))
		local Spread = randUnitSquare:GetNormalized() * Cone * (math.random() ^ (1 / ACF.GunInaccuracyBias))
		local Dir = (Aim:Forward() + Spread):GetNormalized()

		self:ShootBullet(Ply:GetShootPos(), Dir)

	end

	self:PostShot(1)
end

function SWEP:Reload()
	self:SetNWBool("iron", false)

	if self:Ammo1() > 0 and self:Clip1() < self:GetMaxClip1() then
		self:DefaultReload(ACT_VM_RELOAD)
		self:EmitSound(Reload)
	end
end

-- Additional 2x accuracy while aiming; retains existing hip-fire behavior.
function SWEP:GetAimMod()
    local modifier = self.BaseClass.GetAimMod(self)
    local owner = self:GetOwner()
    if IsValid(owner) and owner:IsPlayer() and self:GetNWBool("iron", false)
        and not owner:IsSprinting() then
        return modifier * 0.5
    end
    return modifier
end

SWEP.InfantryGunClass = "ACF.Guns.Autocannon"
SWEP.InfantryProjectile = 4.05
SWEP.InfantryPropellant = 17.55
include("acf_sweps/launcher_rounds.lua").ApplyAPCR(SWEP)

SWEP.SubCategory = "Weapons"
