AddCSLuaFile()
local Anim = include("acf_sweps/named_animation.lua")
SWEP.Base = "weapon_base"
SWEP.Category = "ACF Infantry"
SWEP.SubCategory = "Throwables and Deployables"
SWEP.Spawnable = false
SWEP.UseHands = false -- Donor models already contain arms.
SWEP.ViewModelFOV = 60
SWEP.HoldType = "slam"
SWEP.Slot = 4
SWEP.DrawAmmo = false
SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 101
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "ACFInfantryC4"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

function SWEP:PlayDeployableAnimation(name, duration)
    local sequences = self.DeployableSequences
    Anim.Play(self, sequences and sequences[name] or name, duration)
end
function SWEP:Initialize() self:SetHoldType(self.HoldType) end
function SWEP:Deploy()
    self:SetNextPrimaryFire(CurTime() + 0.9)
    self:SetNextSecondaryFire(CurTime() + 0.9)
    if SERVER then
        self:PlayDeployableAnimation("draw", 0.9)
        if self.DeploySound then self:EmitSound(self.DeploySound, 65) end
    end
    return true
end
function SWEP:GetDeployableLimit()
    return self.MaxDeployed or (self.DeployableKind == "c4" and 15 or 8)
end
function SWEP:GetDeployedCount()
    local count = 0
    for _, entity in ipairs(ents.FindByClass("acf_infantry_deployable")) do
        if entity.Placer == self:GetOwner() and entity:GetNW2String("ExplosiveKind") == self.DeployableKind
            and not entity.Exploded then count = count + 1 end
    end
    return count
end
function SWEP:Reload()
    if CLIENT or self.PendingPlacement or self:Clip1() > 0 then return end
    local owner = self:GetOwner()
    if not IsValid(owner) or owner:GetAmmoCount(self.Primary.Ammo) <= 0 then return end
    owner:RemoveAmmo(1, self.Primary.Ammo)
    self:SetClip1(1)
    self:PlayDeployableAnimation( "draw", 0.8)
    self:SetNextPrimaryFire(CurTime() + 0.8)
end
function SWEP:PrimaryAttack()
    if CLIENT or self.PendingPlacement then return end
    local owner = self:GetOwner()
    if not IsValid(owner) or not owner:Alive() then return end
    if self:Clip1() <= 0 then self:Reload() return end
    if self:GetDeployedCount() >= self:GetDeployableLimit() then return end
    -- Validate again at release: moving or turning during the animation is allowed.
    self.PendingPlacement = CurTime() + 0.5
    self:SetNextPrimaryFire(CurTime() + 1.4)
    self:SetNextSecondaryFire(CurTime() + 1.4)
    self:PlayDeployableAnimation( self.DeployableKind == "claymore" and "drawbackhigh" or "throw", 0.8)
    owner:SetAnimation(PLAYER_ATTACK1)
end
function SWEP:PlaceExplosive()
    local owner = self:GetOwner()
    if not IsValid(owner) or not owner:Alive() or owner:GetActiveWeapon() ~= self
        or self:Clip1() <= 0 or self:GetDeployedCount() >= self:GetDeployableLimit() then return end
    if not ACF or not ACF.Damage or not ACF.Damage.createExplosion
        or not ACF.Damage.getBlastRadius or not ACF.Damage.Objects
        or not ACF.Damage.Objects.DamageInfo then return end
    if self.DeployableKind == "claymore" and (not ACF.Ballistics or not ACF.Classes) then return end
    local kind = self.DeployableKind
    local trace
    if kind == "claymore" then
        local forward = Angle(0, owner:EyeAngles().y, 0):Forward()
        local start = owner:GetPos() + forward * 42 + Vector(0, 0, 36)
        trace = util.TraceHull({start = start, endpos = start - Vector(0, 0, 80),
            mins = Vector(-4, -4, 0), maxs = Vector(4, 4, 8), filter = owner, mask = MASK_SOLID})
        if trace.StartSolid or not trace.Hit or trace.HitSky or trace.HitNormal.z < 0.7
            or (IsValid(trace.Entity) and (trace.Entity:IsPlayer() or trace.Entity:IsNPC() or trace.Entity:IsNextBot())) then return end
        -- Don't plant through a wall that separates the player and placement point.
        local clear = util.TraceLine({start = owner:GetShootPos(), endpos = trace.HitPos + Vector(0, 0, 12),
            filter = owner, mask = MASK_SOLID})
        if clear.Hit then return end
    else
        trace = util.TraceHull({start = owner:GetShootPos(), endpos = owner:GetShootPos() + owner:GetAimVector() * 28,
            mins = Vector(-3, -3, -3), maxs = Vector(3, 3, 3), filter = owner, mask = MASK_SOLID})
        if trace.StartSolid then return end
    end
    local entity = ents.Create("acf_infantry_deployable")
    if not IsValid(entity) then return end
    entity.Placer = owner
    entity:SetNW2String("ExplosiveKind", kind)
    entity:SetPos(trace.HitPos + (kind == "claymore" and Vector(0, 0, 1) or Vector()))
    entity:SetAngles(Angle(0, owner:EyeAngles().y - 90, 0))
    entity:SetOwner(owner)
    entity:Spawn()
    if kind == "claymore" then
        entity:EmitSound("hoff/mpl/seal_claymore/plant.wav", 65)
        if IsValid(trace.Entity) and not trace.Entity:IsWorld() then entity:SetParent(trace.Entity) end
    else
        local physics = entity:GetPhysicsObject()
        if not IsValid(physics) then entity:Remove() return end
        entity:CheckC4Attachment(owner:GetShootPos())
        entity:ConfigureC4Throw(owner, 578, 100, 433.5)
        physics:SetVelocity(owner:GetAimVector() * 578 + Vector(0, 0, 100) + owner:GetVelocity())
        physics:AddAngleVelocity(Vector(0, 90, 0))
    end
    self:TakePrimaryAmmo(1)
    self:SetNW2Int("InfantryDeployedCount", self:GetDeployedCount())
    cleanup.Add(owner, "acf_infantry_explosives", entity)
end
function SWEP:SecondaryAttack()
    if CLIENT or self.DeployableKind ~= "c4" or self.PendingPlacement then return end
    local owner = self:GetOwner()
    if not IsValid(owner) or not owner:Alive() then return end
    self:SetNextPrimaryFire(CurTime() + 0.8)
    self:SetNextSecondaryFire(CurTime() + 0.8)
    self:PlayDeployableAnimation( "fire", 0.5)
    for _, entity in ipairs(ents.FindByClass("acf_infantry_deployable")) do
        if entity.Placer == owner and entity:GetNW2String("ExplosiveKind") == "c4"
            and CurTime() >= entity.ArmedAt then entity:Detonate() end
    end
end
function SWEP:Think()
    if CLIENT then
        local sequences = self.DeployableSequences
        local idle = sequences and (self:Clip1() > 0 and sequences.idle or sequences.empty) or "idle"
        Anim.Idle(self, idle)
        return
    end
    if self.PendingPlacement and CurTime() >= self.PendingPlacement then
        self.PendingPlacement = nil
        self:PlaceExplosive()
        self.ReloadAt = CurTime() + 0.9
    end
    if self.ReloadAt and CurTime() >= self.ReloadAt then self.ReloadAt = nil self:Reload() end
    if CurTime() >= (self.NextCountUpdate or 0) then
        self.NextCountUpdate = CurTime() + 0.25
        self:SetNW2Int("InfantryDeployedCount", self:GetDeployedCount())
    end
end
function SWEP:Holster() return not self.PendingPlacement end
function SWEP:OnDrop() self.PendingPlacement = nil self.ReloadAt = nil end
function SWEP:OnRemove() self.PendingPlacement = nil end
function SWEP:BuildWepSelectionText()
    self.DisplayText = self.DeployableKind == "c4"
        and {"Remote ACF HE charge; 0.625 kg TNT-equivalent filler", "15 active charges per player; 1 second arming"}
        or {"Directional ACF fragmentation mine", "1.5 second arming; 180 unit / 80 degree trigger cone", "8 active mines per player"}
    self.ControlText = {"Left click: " .. (self.DeployableKind == "c4" and "Throw sticky charge" or "Plant on ground ahead"),
        "Reload: ready another", "Use on your deployed explosive: recover it"}
    if self.DeployableKind == "c4" then self.ControlText[#self.ControlText + 1] = "Right click: detonate your armed C4" end
end
