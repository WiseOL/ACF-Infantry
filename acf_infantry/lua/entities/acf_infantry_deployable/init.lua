AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")
local C4Attachment = include("acf_sweps/c4_attachment.lua")

local function ACFReady()
    return ACF and ACF.Damage and ACF.Damage.createExplosion and ACF.Damage.getBlastRadius and ACF.Damage.Objects
        and ACF.Damage.Objects.DamageInfo
end
function ENT:Initialize()
    local claymore = self:GetNW2String("ExplosiveKind") == "claymore"
    self:SetModel(claymore and "models/hoff/weapons/claymore/w_claymore.mdl" or "models/weapons/insurgency/w_c4.mdl")
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
function ENT:ConfigureC4Throw(owner, forwardSpeed, upwardSpeed, levelRange)
    if self:GetNW2String("ExplosiveKind") ~= "c4" then return end
    local physics = self:GetPhysicsObject()
    if not IsValid(physics) or not IsValid(owner) then return end
    local origin = self:GetPos()
    local ground = util.TraceLine({start = owner:GetPos() + Vector(0, 0, 8),
        endpos = owner:GetPos() - Vector(0, 0, 4096), filter = {owner, self}, mask = MASK_SOLID})
    if not ground.Hit or ground.StartSolid or ground.HitSky then return end
    local height = origin.z - ground.HitPos.z + self:OBBMins().z
    if height <= 0 then return end
    local releaseOffset = (origin - owner:GetPos()):Length2D()
    local flightTime = math.max(levelRange - releaseOffset, 1) / forwardSpeed
    local gravity = 2 * (height + upwardSpeed * flightTime) / (flightTime * flightTime)
    self.C4ThrowAcceleration = Vector(0, 0, -gravity)
    -- Per-device gravity preserves the exact launch velocity while calibrating
    -- a clear, level throw. No global gravity or other equipment is changed.
    physics:EnableGravity(false)
    physics:EnableDrag(false)
end
function ENT:PhysicsUpdate(physics)
    self:CheckC4Attachment()
    if self.C4ThrowAcceleration and not self.Stuck and not self.Exploded
        and self:GetNW2String("ExplosiveKind") == "c4" and IsValid(physics) then
        physics:ApplyForceCenter(self.C4ThrowAcceleration * physics:GetMass() * engine.TickInterval())
    end
end
function ENT:StickC4(target, position, normal)
    if self.Stuck or self.Exploded or self:GetNW2String("ExplosiveKind") ~= "c4" then return false end
    if not IsValid(target) or target == self or target:IsPlayer() or target:IsNPC() or target:IsNextBot() then return false end
    local world = target:IsWorld()
    local point = position + normal * 1.5
    local angle = normal:Angle()
    angle:RotateAroundAxis(angle:Right(), 90)
    local localPoint = not world and target:WorldToLocal(point)
    local localAngle = not world and target:WorldToLocalAngles(angle)
    self.Stuck = true
    -- Parenting remains deferred out of the physics callback. Preserve the
    -- child prop's local contact, even if its assembly moves before this runs.
    timer.Simple(0, function()
        if not IsValid(self) or self.Exploded then return end
        if not world and not IsValid(target) then self.Stuck = false return end
        self.C4ThrowAcceleration = nil
        self:SetMoveType(MOVETYPE_NONE)
        if world then
            self:SetPos(point)
            self:SetAngles(angle)
        else
            self:SetParent(target)
            self:SetLocalPos(localPoint)
            self:SetLocalAngles(localAngle)
        end
        self:EmitSound("weapons/c4/handling/c4_plant_place.wav", 65)
    end)
    return true
end
function ENT:CheckC4Attachment(start)
    if self.Stuck or self.Exploded or self:GetNW2String("ExplosiveKind") ~= "c4" then return false end
    local finish = self:GetPos()
    start = start or self.C4LastPosition
    self.C4LastPosition = finish
    if not start or start:DistToSqr(finish) < 0.0001 then return false end
    local trace = C4Attachment.Trace(start, finish, self)
    if trace.Hit and not trace.StartSolid and not trace.HitSky then
        return self:StickC4(trace.Entity, trace.HitPos, trace.HitNormal)
    end
    return false
end
function ENT:PhysicsCollide(data)
    self:StickC4(data.HitEntity, data.HitPos, data.HitNormal)
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
    local front = -self:GetRight() -- Both the BO1 model and the trigger cone face local -Right.
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
function ENT:GetExplosionFiller()
    local filler = self:GetNW2String("ExplosiveKind") == "claymore" and self.ClaymoreFiller or self.C4Filler
    if self:GetNW2String("ExplosiveKind") ~= "claymore" then return filler end
    local reach = self.ClaymoreRange * self.ClaymoreBlastReachMultiplier
    if ACF.Damage.getBlastRadius(filler) >= reach then return filler end
    -- Solve against the installed fork rather than hardcoding its radius formula.
    local low, high = filler, filler
    while ACF.Damage.getBlastRadius(high) < reach and high < 32 do high = high * 2 end
    for _ = 1, 32 do
        local middle = (low + high) * 0.5
        if ACF.Damage.getBlastRadius(middle) < reach then low = middle else high = middle end
    end
    return high
end
function ENT:CreateFragments(position, attacker, claymore)
    if not ACF.Ballistics or not ACF.Classes then error("Native ACF fragment APIs unavailable") end
    local ammoType = ACF.Classes.GetTypeByName("ACF.Ammunition.AP")
    if not ammoType then error("Native ACF AP ammunition unavailable") end
    local ammo = ammoType()
    local caliber = self.FragmentCaliber
    ammo.Weapon = {ID = "ACF.Guns.Cannon", Caliber = caliber,
        CaliberLimits = {Base = caliber, Min = caliber, Max = caliber},
        Round = {MaxLength = 2, PropLength = 0.1}}
    ammo.Projectile, ammo.Propellant, ammo.Tracer = caliber * 0.15, 0.01, false
    ammo:VerifyData()
    local template = ammo:ServerConvert()
    template.AmmoType = "ACF.Ammunition.AP"
    -- Calibrate launch speed using the installed AP penetration implementation.
    local low, high = 0, 10000
    for _ = 1, 32 do
        local middle = (low + high) * 0.5
        if ammo:GetPenetration(template, middle) < self.FragmentPenetration then low = middle else high = middle end
    end
    local speed = high
    local front, right, up = -self:GetRight(), self:GetForward(), self:GetUp()
    local count = claymore and self.ClaymorePellets or self.C4Pellets
    for _ = 1, count do
        local data = table.Copy(template)
        local direction
        if claymore then
            local horizontal = math.tan(math.rad(math.Rand(-30, 30)))
            local vertical = math.tan(math.rad(math.Rand(-10, 10)))
            direction = (front + right * horizontal + up * vertical):GetNormalized()
        else
            -- Uniform sphere, without bias toward its poles.
            local z, angle = math.Rand(-1, 1), math.Rand(0, math.pi * 2)
            local radius = math.sqrt(1 - z * z)
            direction = Vector(radius * math.cos(angle), radius * math.sin(angle), z)
        end
        data.Owner, data.Gun, data.Pos = attacker, self, position + direction * 3
        data.Flight = direction * speed * ACF.MeterToInch
        data.Filter = {self}
        data.NoEffect = true
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
    local filler = self:GetExplosionFiller()
    -- Fragment conversion must not suppress the blast if a server API differs.
    local ok, err = pcall(self.CreateFragments, self, position, attacker, claymore)
    if not ok then ErrorNoHalt("[ACF Infantry] Explosive fragments failed: " .. tostring(err) .. "\n") end
    ACF.Damage.createExplosion(position, filler,
        claymore and self.ClaymoreFragmentMass or self.C4FragmentMass, {self}, info)
    local effect = EffectData()
    effect:SetOrigin(position)
    effect:SetNormal(self:GetUp())
    effect:SetScale(ACF.Damage.getBlastRadius(filler))
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
        self:EmitSound("buttons/button17.wav", 65)
        timer.Simple(0.25, function() if IsValid(self) then self:Detonate() end end)
    end
    self:NextThink(CurTime() + 0.1)
    return true
end
