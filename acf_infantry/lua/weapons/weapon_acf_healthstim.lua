if SERVER then AddCSLuaFile("acf_sweps/hud_theme.lua") end
if CLIENT and not ACFSwepsTheme then include("acf_sweps/hud_theme.lua") end
AddCSLuaFile()

SWEP.Base = "weapon_base"
SWEP.PrintName = "ACF Health Stim"
SWEP.Author = "ACF server customization"
SWEP.Category = "ACF Infantry"
SWEP.Instructions = "Left click: Apply health kit to yourself. Right click: Apply to a nearby player or NPC. +50 HP over 10 seconds (cap 100) and 15% damage reduction for 20 seconds. One charge per injection; repeat use refreshes effects."
SWEP.Purpose = "Heals up to 100 HP and reduces incoming damage by 15% for 20 seconds."
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.UseHands = false
SWEP.ViewModel = "models/healthvial.mdl"
SWEP.ViewModelFOV = 60
SWEP.WorldModel = "models/healthvial.mdl"
SWEP.HoldType = "slam"
SWEP.IconOverride = "entities/item_healthvial.png"
SWEP.Slot = 5
SWEP.SlotPos = 1
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "ACFInfantryStim"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.DisableDuplicator = true

function SWEP:BuildWepSelectionText()
    self.DisplayText = { "+50 HP over 10 seconds (cap 100)", "15% damage reduction for 20 seconds", "One charge per use; refreshes active effects" }
    self.ControlText = { "Left click: Heal yourself", "Right click: Heal nearby player or NPC; keep aiming until injection finishes" }
end

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

-- Temporary stock health-kit prop. It has no syringe injection sequences.
-- Keep the established application timing independent of model animations.
local sequenceTimes = {deploy = 0.6, idle = 2, inject = 3.4, inject_other = 2.64}
function SWEP:PlayStimSequence(name)
    return sequenceTimes[name] or 1
end

function SWEP:Deploy()
    local duration = self:PlayStimSequence("deploy")
    self.StimIdleAt = CurTime() + duration
    self:SetNextPrimaryFire(self.StimIdleAt)
    self:SetNextSecondaryFire(self.StimIdleAt)
    return true
end

local function Living(target)
    return IsValid(target) and (target:IsPlayer() and target:Alive()
        or target:IsNPC() and target:Health() > 0)
end

function SWEP:OtherTarget()
    local owner = self:GetOwner()
    if not IsValid(owner) or not owner:IsPlayer() or not owner:Alive() then return end
    owner:LagCompensation(true)
    local start = owner:GetShootPos()
    local trace = util.TraceLine({start = start, endpos = start + owner:GetAimVector() * 64,
        filter = owner, mask = MASK_SHOT})
    owner:LagCompensation(false)
    if Living(trace.Entity) and trace.Entity ~= owner then return trace.Entity end
end

function SWEP:CancelOtherInjection()
    self.StimTarget = nil
    self.StimFinishAt = nil
    self.StimSoundAt = nil
    self:SetNWFloat("StimAnimationEnd", 0)
    self.StimIdleAt = 0
end

function SWEP:Think()
    if CLIENT then return end
    if self.StimTarget then
        local owner = self:GetOwner()
        if not IsValid(owner) or owner:GetActiveWeapon() ~= self
            or self:OtherTarget() ~= self.StimTarget then
            self:CancelOtherInjection()
        else
            if self.StimSoundAt and CurTime() >= self.StimSoundAt then
                owner:EmitSound("items/smallmedkit1.wav")
                self.StimSoundAt = nil
            end
            if CurTime() >= self.StimFinishAt then
                local target = self.StimTarget
                self:CancelOtherInjection()
                self:ApplyStim(target)
                self:FinishStimUse()
                return
            end
        end
    end
    if not self.StimUsed and not self.StimTarget and CurTime() >= (self.StimIdleAt or 0) then
        self.StimIdleAt = CurTime() + self:PlayStimSequence("idle")
    end
end

function SWEP:ApplyStim(target)
    self.StimUsed = true
    self:GetOwner():RemoveAmmo(1, self.Primary.Ammo)
    local token = {}
    target.ACFHealthStimActive = token
    target.ACFHealthStimExpires = CurTime() + 20
    target:SetNWFloat("ACFInfantryStimExpires", target.ACFHealthStimExpires)
    local timerName = "ACFHealthStim_" .. target:EntIndex()
    local protectionTimer = timerName .. "_Protection"
    local function cancel()
        if IsValid(target) and target.ACFHealthStimActive ~= token then return end
        timer.Remove(timerName)
        timer.Remove(protectionTimer)
        if IsValid(target) and target.ACFHealthStimActive == token then
            target.ACFHealthStimActive = nil
            target.ACFHealthStimExpires = nil
            target:SetNWFloat("ACFInfantryStimExpires", 0)
        end
    end
    timer.Create(protectionTimer, 20, 1, cancel)
    local ticks = 0
    timer.Create(timerName, 0.2, 50, function()
        if target.ACFHealthStimActive ~= token then return end
        if not Living(target) then cancel() return end
        ticks = ticks + 1
        local health, maximum = target:Health(), math.min(100, target:GetMaxHealth())
        if health < maximum then target:SetHealth(math.min(health + 1, maximum)) end
        if ticks >= 50 then timer.Remove(timerName) end
    end)
end

function SWEP:FinishStimUse()
    local owner = self:GetOwner()
    if not IsValid(owner) or owner:GetAmmoCount(self.Primary.Ammo) <= 0 then self:Remove() return end
    self.StimUsed = false
    self.StimPlayback = nil
    self:SetNWFloat("StimAnimationEnd", 0)
    self.StimIdleAt = CurTime() + self:PlayStimSequence("idle")
end

function SWEP:BeginInjection(target, other)
    if self.StimUsed or self.StimTarget or not Living(target) then return end
    local owner = self:GetOwner()
    if not Living(owner) or not owner:IsPlayer() or owner:GetAmmoCount(self.Primary.Ammo) <= 0 then return end
    self:SetNWFloat("StimUseStart", CurTime())
    local duration = self:PlayStimSequence(other and "inject_other" or "inject")
    duration = duration + 0.2 -- let the final animation frames finish before consumption/removal
    self:SetNWFloat("StimAnimationEnd", CurTime() + duration)
    self:SetNextPrimaryFire(CurTime() + duration)
    self:SetNextSecondaryFire(CurTime() + duration)
    owner:SetAnimation(PLAYER_ATTACK1)
    if other then
        self.StimTarget = target
        self.StimFinishAt = CurTime() + duration
        self.StimSoundAt = CurTime() + 0.3
    else
        self:ApplyStim(target)
        timer.Simple(0.3, function()
            if IsValid(self) and Living(owner) then owner:EmitSound("items/smallmedkit1.wav") end
        end)
        timer.Simple(duration, function() if IsValid(self) then self:FinishStimUse() end end)
    end
end

function SWEP:PrimaryAttack()
    if SERVER then self:BeginInjection(self:GetOwner(), false) end
end

function SWEP:SecondaryAttack()
    if SERVER then self:BeginInjection(self:OtherTarget(), true) end
end

function SWEP:OnDrop()
    if SERVER and self.StimTarget then self:CancelOtherInjection() end
end

function SWEP:Reload() end

if SERVER then
    -- Cancel at death/spawn so healing never continues into another life.
    local function CancelStim(ply)
        timer.Remove("ACFHealthStim_" .. ply:EntIndex())
        timer.Remove("ACFHealthStim_" .. ply:EntIndex() .. "_Protection")
        ply.ACFHealthStimActive = nil
        ply.ACFHealthStimExpires = nil
        ply:SetNWFloat("ACFInfantryStimExpires", 0)
    end
    hook.Add("EntityTakeDamage", "ACFHealthStimDamageReduction", function(target, damage)
        if Living(target) and target.ACFHealthStimActive
            and (target.ACFHealthStimExpires or 0) > CurTime() then
            damage:ScaleDamage(0.85)
        end
    end)
    hook.Add("PlayerDeath", "ACFHealthStimCancel", CancelStim)
    hook.Add("PlayerSpawn", "ACFHealthStimCancel", CancelStim)
    hook.Add("PlayerDisconnected", "ACFHealthStimCancel", CancelStim)
end

function SWEP:Holster()
    return CurTime() >= self:GetNWFloat("StimAnimationEnd", 0)
end

if CLIENT then
    function SWEP:DrawHUD()
        if ACFSwepsTheme and ACFSwepsTheme.VerticalHUD then return end
        local x, y = ScrW() - 320, ScrH() - 190
        ACFSwepsTheme.Panel(8, x, y, 300, 96, Color(15, 18, 24, 220))
        ACFSwepsTheme.Text("HEALTH STIM", "DermaLarge", x + 12, y + 9, ACFSwepsTheme.Color("COLOR_SUCCESS_TEXT"))
        ACFSwepsTheme.Text("+50 HP / 10s | 15% REDUCTION / 20s", "DermaDefaultBold", x + 12, y + 48, ACFSwepsTheme.Color("COLOR_TEXT"))
        ACFSwepsTheme.Text("LMB: SELF   |   RMB: OTHER", "DermaDefaultBold", x + 12, y + 72, ACFSwepsTheme.Color("COLOR_TEXT"))
    end
end


SWEP.SubCategory = "Utility"

if CLIENT then
    function SWEP:PreDrawViewModel(vm) vm:SetMaterial("engine/occlusionproxy") end
    function SWEP:PostDrawViewModel(vm) vm:SetMaterial("") end
    function SWEP:ViewModelDrawn()
        if not IsValid(self.HealthVialDisplay) then
            self.HealthVialDisplay = ClientsideModel(self.WorldModel, RENDERGROUP_OPAQUE)
            if IsValid(self.HealthVialDisplay) then self.HealthVialDisplay:SetNoDraw(true) end
        end
        local model = self.HealthVialDisplay
        if not IsValid(model) then return end
        local low, high = model:GetModelBounds()
        local size = high - low
        local dimensions = {size.x, size.y, size.z}
        local thin, tall = 1, 1
        for i = 2, 3 do
            if dimensions[i] < dimensions[thin] then thin = i end
            if dimensions[i] > dimensions[tall] then tall = i end
        end
        if thin == tall then thin, tall = 1, 3 end
        local view = EyeAngles()
        local axes = {}
        axes[thin], axes[tall] = -view:Forward(), view:Up()
        if not axes[1] then axes[1] = axes[2]:Cross(axes[3])
        elseif not axes[2] then axes[2] = axes[3]:Cross(axes[1])
        else axes[3] = axes[1]:Cross(axes[2]) end
        local angle = axes[1]:AngleEx(axes[3])
        local scale = math.min(1, 6 / math.max(dimensions[tall], 0.01))
        local start = self:GetNWFloat("StimUseStart", -10)
        -- Match Suit Armor: a brief lift toward the face, then return to rest.
        -- Presentation timing is independent of the healing/application delay.
        local progress = math.Clamp((CurTime() - start) / 0.85, 0, 1)
        local motion = math.sin(progress * math.pi)
        local center = EyePos() + view:Forward() * (24 - motion * 6)
            + view:Right() * 8 - view:Up() * (8 - motion * 5)
        local offset = LocalToWorld((low + high) * (0.5 * scale), Angle(), Vector(), angle)
        model:SetModelScale(scale, 0)
        model:SetPos(center - offset)
        model:SetAngles(angle)
        model:SetupBones()
        model:DrawModel()
    end
    function SWEP:DrawWorldModel()
        local owner = self:GetOwner()
        if not IsValid(owner) then self:DrawModel() return end
        owner:SetupBones()
        local bone = owner:LookupBone("ValveBiped.Bip01_R_Hand")
        local matrix = bone and owner:GetBoneMatrix(bone)
        if not matrix then self:DrawModel() return end
        local pos, ang = LocalToWorld(Vector(2, 0, -1), Angle(0, 90, 90), matrix:GetTranslation(), matrix:GetAngles())
        self:SetRenderOrigin(pos)
        self:SetRenderAngles(ang)
        self:DrawModel()
        self:SetRenderOrigin()
        self:SetRenderAngles()
    end
    function SWEP:OnRemove()
        if IsValid(self.HealthVialDisplay) then self.HealthVialDisplay:Remove() end
    end
end
