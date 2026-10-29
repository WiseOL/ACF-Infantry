AddCSLuaFile()

include("weapon_acf_base.lua")


SWEP.Base                   = "weapon_acf_base"
SWEP.PrintName = "ACF SMAW"

SWEP.IconOffset				= Vector(4, -4, 0)
SWEP.IconAngOffset			= Angle(0 , -85 , 0)

SWEP.UseHands               = true
SWEP.ViewModel              = "models/weapons/reshed_acfextras/at/acf_smawrecoilessrifle.mdl"
SWEP.ViewModelFOV			= 90

SWEP.ShotSound				= Sound("weapons/smaw/fire2.wav")
SWEP.WorldModel             = "models/weapons/reshed_acfextras/at/col_acf_smawrecoilessrifle.mdl"
SWEP.HoldType               = "passive"

SWEP.Slot                   = 4
SWEP.SlotPos                = 0

SWEP.Spawnable              = true
SWEP.AdminOnly              = false

SWEP.m_WeaponDeploySpeed    = 1
SWEP.Spread                 = 0.05 -- Slightly tighter spread, SMAW is accurate
SWEP.RecoilMod              = 0.25 -- Recoilless rifle, minimal felt recoil

SWEP.Primary.ClipSize       = 1
SWEP.Primary.DefaultClip    = 101
SWEP.Primary.Ammo           = "RPG_Round"
SWEP.Primary.Automatic      = false
SWEP.Primary.Delay          = 0.15
SWEP.CarrySpeedMul			= 1.0

SWEP.UseHybrid				= false

-- Native 40 mm cannon APCR. Maximum legal propellant (26 cm), minimum projectile (6 cm).
SWEP.Caliber = 40
SWEP.ACFProjMass = 1
SWEP.ACFType = "APCR"
SWEP.ACFMuzzleVel = 1
SWEP.Tracer = 0
SWEP.InfantryNativeAPCR = true

-- Aim table adjusted for 220 m/s muzzle velocity (flatter trajectory)
SWEP.AimTable = {}
SWEP.AimTable[1] = {IronPos = Vector(-2.95, 0, -0.7), IronAng = Angle(0, 0, -5),  PitchAdjust = 0, Text = "100m"} -- 100m

SWEP.AimFocused				= 0.5 -- Tighter aim when focused (better optics simulation)
SWEP.AimUnfocused			= 4

SWEP.SprintPos				= Vector(0.34, 3.49, 4.2) -- The position the viewmodel moves to when the player is sprinting
SWEP.SprintAng				= Angle(-20.532, 10.793, -14.963) -- The angle the viewmodel turns to when the player is sprinting


--Bruh do yall not have a 3d artist for source
SWEP.CustomWorldModelPos	= false -- An attempt at fixing the broken worldmodel position

SWEP.FakeFire				= true	-- This shakes the aim bloom so you can't just quickshot to victory
SWEP.MoveBloom				= 1.5 -- Slightly less bloom, weapon is balanced

SWEP.Zoom					= 1.5 -- SMAW has better optics
SWEP.Recovery				= 0.3 -- Faster recovery due to recoilless design

SWEP.Handling = 0.5 -- Preserve original bloom while halving firing spread.

SWEP:SetupACFBullet()

function SWEP:Think()
	if self.BaseClass.Think then
		self.BaseClass.Think(self)
	end

	-- Switch holdtype based on aiming state
	local isAiming = self:GetNWBool("iron", false)
	if isAiming and self:GetHoldType() ~= "rpg" then
		self:SetHoldType("rpg")
	elseif not isAiming and self:GetHoldType() ~= "passive" then
		self:SetHoldType("passive")
	end
end

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end
	local Ply = self:GetOwner()

	local AimMod = self:GetAimMod()
	local Punch = self:GetPunch()

	if SERVER then
		local Aim = self:ResolveAim()
		local Right = Aim:Right()
		local Up = Aim:Up()

		local Cone = math.tan(math.rad(self.Spread * AimMod))
		local randUnitSquare = (Up * (2 * math.random() - 1) + Right * (2 * math.random() - 1))
		local Spread = randUnitSquare:GetNormalized() * Cone * (math.random() ^ (1 / ACF.GunInaccuracyBias))
		local Dir = (Aim:Forward() + Spread):GetNormalized()

		self:ShootBullet(Ply:GetShootPos(), (Dir:Angle() + Angle(self.AimTable[self:GetNW2Int("aimsetting", 1)].PitchAdjust, 0, 0)):Forward())

		self:Recoil(Punch * 0.15) -- Recoilless rifle: drastically reduced recoil
	end

	self:PostShot(1)
end

local FiremodeSound = Sound("Weapon_SMG1.Special2")
function SWEP:SecondaryAttack()
	local Owner = self:GetOwner()
	if Owner:KeyDown(IN_USE) and (CurTime() > self.NextAttack2Toggle) then

		if SERVER then
			local cursetting = self:GetNW2Int("aimsetting", 1)
			if (cursetting + 1) > #self.AimTable then cursetting = 1 else cursetting = cursetting + 1 end
			self:SetNW2Int("aimsetting", cursetting)
			self:GetOwner():PrintMessage(4, "Range: " .. self.AimTable[cursetting].Text)
		else
			self:EmitSound(FiremodeSound)
		end

		self.NextAttack2Toggle = CurTime() + 0.25
		return true
	end

	return true
end

if CLIENT then
	function SWEP:GetViewAim()
		return self.AimTable[self:GetNW2Int("aimsetting", 1)]
	end
end

function SWEP:CalcView( _, pos, ang, _ )
	local attachment = self:GetOwner():GetViewModel():GetAttachment( self:GetOwner():GetViewModel():LookupAttachment( "1" ) )
	ang = ang + Angle( self:GetOwner():GetViewModel():WorldToLocalAngles( attachment.Ang ).x, self:GetOwner():GetViewModel():WorldToLocalAngles( attachment.Ang ).y, self:GetOwner():GetViewModel():WorldToLocalAngles( attachment.Ang ).z )
	return pos, ang
end



sound.Add({
	name = 			"rshd_acf.SMAWRaise",
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound = 			"weapons/smaw/raise.wav"
})

sound.Add({
	name = 			"rshd_acf.SMAWOut",
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound = 			"weapons/smaw/out.wav"
})

sound.Add({
	name = 			"rshd_acf.SMAWIn",
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound = 			"weapons/smaw/in.wav"
})

sound.Add({
	name = 			"rshd_acf.SMAWLower",
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound = 			"weapons/smaw/reshoulderlol.wav"
})
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


SWEP.InfantryProjectile = 6.0
SWEP.InfantryPropellant = 26.00
include("acf_sweps/launcher_rounds.lua").ApplyAPCR(SWEP)

SWEP.SubCategory = "Launchers"
