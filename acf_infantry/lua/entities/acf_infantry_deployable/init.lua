AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

local function ACFReady()
    return ACF and ACF.Damage and ACF.Damage.createExplosion and ACF.Damage.getBlastRadius and ACF.Damage.Objects
        and ACF.Damage.Objects.DamageInfo
end
function ENT:Initialize()
    local claymore = self:GetNW2String("ExplosiveKind") == "claymore"
    self:SetModel(claymore and "models/krazy/cod4rm/claymore_armed.mdl" or "models/krazy/cod4rm/misc/c4.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(claymore and MOVETYPE_NONE or MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    self:SetUseType(SIMPLE_USE)
    self.ArmedAt = CurTime() + (claymore and 1.5 or 1)
    self:SetNW2Float("ArmedAt", self.ArmedAt)
    self.ExpiresAt = CurTime() + 180
    self:SetHealth(10)
    local physics = self:GetPhysicsObject()
    if IsValid(physics) then physics:SetMass(claymore and 1.6 or 0.7) physics:Wake() end
end
function ENT:PhysicsCollide(data)
    if self.Stuck or self.Exploded or self:GetNW2String("ExplosiveKind") ~= "c4" then return end
    local target = data.HitEntity
    if not IsValid(target) or target:IsPlayer() or target:IsNPC() or target:IsNextBot() then return end
    self.Stuck = true
    local position, normal = data.HitPos, data.HitNormal
    -- Defer parenting/collision changes until after the physics callback.
    timer.Simple(0, function()
        if not IsValid(self) or self.Exploded then return end
        self:SetPos(position + normal * 1.5)
        local angle = normal:Angle()
        angle:RotateAroundAxis(angle:Right(), 90)
        self:SetAngles(angle)
        self:SetMoveType(MOVETYPE_NONE)
        if IsValid(target) and not target:IsWorld() then self:SetParent(target) end
        self:EmitSound("rm_c4/plant.wav", 65)
    end)
end
function ENT:Use(player)
    if self.Exploded or self.Triggered or player ~= self.Placer or not player:Alive()
        or player:GetShootPos():DistToSqr(self:GetPos()) > 96 ^ 2 then return end
    local ammo = self:GetNW2String("ExplosiveKind") == "c4" and "ACFInfantryC4" or "ACFInfantryClaymore"
    if player:GetAmmoCount(ammo) >= 100 then return end
    player:GiveAmmo(1, ammo, true)
    self:Remove()
end
function ENT:OnTakeDamage(damage)
    if self.Exploded or damage:GetDamage() <= 0 then return end
    self:SetHealth(self:Health() - damage:GetDamage())
    if self:Health() <= 0 then
        -- Arming is respected even when the device is shot.
        if CurTime() >= self.ArmedAt then self:Detonate() else self:Remove() end
    end
end
function ENT:ClaymoreTarget()
    local origin = self:GetPos() + self:GetUp() * 11
    local front = -self:GetRight() -- Donor armed model's front-facing direction.
    for _, target in ipairs(ents.FindInSphere(origin, self.ClaymoreRange)) do
        if IsValid(target) and target ~= self and target ~= self.Placer then
            local living = (target:IsPlayer() and target:Alive())
                or ((target:IsNPC() or target:IsNextBot()) and target:Health() > 0)
            local movingVehicle = target:GetVelocity():LengthSqr() > 50 ^ 2
                and (target:IsVehicle() or (ACF and ACF.Check and ACF.Check(target)))
            if living or movingVehicle then
                local point = target:WorldSpaceCenter()
                local delta = point - origin
                if delta:LengthSqr() <= self.ClaymoreRange ^ 2 and front:Dot(delta:GetNormalized()) >= self.ClaymoreTriggerCos then
                    local tr = util.TraceLine({start = origin, endpos = point, filter = self, mask = MASK_SHOT})
                    if not tr.Hit or tr.Entity == target then return true end
                end
            end
        end
    end
    return false
end
function ENT:CreateForwardFragments(position, attacker)
    if not ACF.Ballistics or not ACF.Classes then return end
    local ammoType = ACF.Classes.GetTypeByName("ACF.Ammunition.AP")
    if not ammoType then return end
    local ammo = ammoType()
    ammo.Weapon = {ID = "ACF.Guns.Cannon", Caliber = 4.5,
        CaliberLimits = {Base = 4.5, Min = 4.5, Max = 4.5},
        Round = {MaxLength = 1, PropLength = 0.1}}
    ammo.Projectile, ammo.Propellant, ammo.Tracer = 0.675, 0.01, false
    ammo:VerifyData()
    local template = ammo:ServerConvert()
    local front, right, up = -self:GetRight(), self:GetForward(), self:GetUp()
    for _ = 1, self.ClaymorePellets do
        local data = table.Copy(template)
        local horizontal = math.tan(math.rad(math.Rand(-30, 30)))
        local vertical = math.tan(math.rad(math.Rand(-10, 10)))
        local direction = (front + right * horizontal + up * vertical):GetNormalized()
        data.Owner, data.Gun, data.Pos = attacker, self, position + front * 3
        data.Flight = direction * self.ClaymorePelletSpeed * ACF.MeterToInch
        data.Filter = {self}
        data.NoEffect = true -- native ACF flight/damage, without an ammo-crate tracer dependency
        data.KillTime = ACF.Utilities.Clock.CurTime + 2
        ACF.Ballistics.CreateBullet(data)
    end
end
function ENT:Detonate()
    if self.Exploded or CurTime() < self.ArmedAt then return end
    if not ACFReady() then
        ErrorNoHalt("[ACF Infantry] VSS ACF explosion API unavailable; explosive not detonated.\n")
        return
    end
    self.Exploded = true -- Set before native damage can trigger chain reactions.
    local claymore = self:GetNW2String("ExplosiveKind") == "claymore"
    local attacker = IsValid(self.Placer) and self.Placer or game.GetWorld()
    local position = self:GetPos() + (claymore and self:GetUp() * 11 or self:GetUp() * 4)
    self:SetNoDraw(true)
    self:SetSolid(SOLID_NONE)
    self:SetMoveType(MOVETYPE_NONE)
    local info = ACF.Damage.Objects.DamageInfo(attacker, self, DMG_BLAST, position)
    if claymore then self:CreateForwardFragments(position, attacker) end
    ACF.Damage.createExplosion(position, claymore and self.ClaymoreFiller or self.C4Filler,
        claymore and self.ClaymoreFragmentMass or self.C4FragmentMass, {self}, info)
    local effect = EffectData()
    effect:SetOrigin(position)
    effect:SetNormal(self:GetUp())
    effect:SetScale(ACF.Damage.getBlastRadius(claymore and self.ClaymoreFiller or self.C4Filler))
    util.Effect("ACF_Explosion", effect, true, true)
    self:EmitSound("ambient/explosions/explode_4.wav", 90)
    -- Keep the inflictor valid for the short-lived ACF forward fragments.
    timer.Simple(2.1, function() if IsValid(self) then self:Remove() end end)
end
function ENT:Think()
    if self.Exploded then return end
    if not IsValid(self.Placer) or not self.Placer:Alive() or CurTime() >= self.ExpiresAt then self:Remove() return end
    if self:GetNW2String("ExplosiveKind") == "claymore" and not self.Triggered
        and CurTime() >= self.ArmedAt and self:ClaymoreTarget() then
        self.Triggered = true
        self:EmitSound("rm_claymore/trigger.wav", 65)
        timer.Simple(0.25, function() if IsValid(self) then self:Detonate() end end)
    end
    self:NextThink(CurTime() + 0.1)
    return true
end
