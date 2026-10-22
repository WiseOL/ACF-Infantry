if SERVER then AddCSLuaFile("acf_sweps/hud_theme.lua") end
if CLIENT and not ACFSwepsTheme then include("acf_sweps/hud_theme.lua") end
AddCSLuaFile()
if SERVER then util.AddNetworkString("ACFInfantryStimSequence") end

SWEP.Base = "weapon_base"
SWEP.PrintName = "ACF Health Stim"
SWEP.Author = "ACF server customization"
SWEP.Category = "ACF Infantry"
SWEP.Instructions = "Left click: Heal yourself. Right click: Heal a nearby player or NPC. +50 HP over 10 seconds (cap 100) and 15% damage reduction for 20 seconds. One charge per injection; repeat use refreshes effects."
SWEP.Purpose = "Heals up to 100 HP and reduces incoming damage by 15% for 20 seconds."
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/darky_m/c_syringe_v2.mdl"
SWEP.ViewModelFOV = 60
SWEP.WorldModel = "models/weapons/darky_m/w_syringe_v2.mdl"
SWEP.HoldType = "slam"
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

-- Use the same native weapon activities as the original Rust syringe addon.
-- SendWeaponAnim updates weapon animation state as well as the viewmodel;
-- directly forcing viewmodel sequences leaves that state out of sync.
local sequenceActivities = {deploy = ACT_VM_DRAW, idle = ACT_VM_IDLE,
    inject = ACT_VM_THROW, inject_other = ACT_VM_SECONDARYATTACK}
local sequenceTimes = {deploy = 2.38, idle = 60 / 30, inject = 3.4, inject_other = 2.64}
function SWEP:PlayStimSequence(name, started, confirmedDuration)
    local owner = self:GetOwner()
    local vm = IsValid(owner) and owner:GetViewModel()
    local duration = sequenceTimes[name] or 1
    local injection = name == "inject" or name == "inject_other"
    started = started or CurTime()
    if IsValid(vm) then
        local index = vm:LookupSequence(name)
        if index and index >= 0 then
            local length = vm:SequenceDuration(index)
            if length and length > 0 then duration = math.max(duration, length) end
            local activity = sequenceActivities[name]
            if activity and vm:SelectWeightedSequence(activity) >= 0 then
                self:SendWeaponAnim(activity)
            else
                -- Fallback for a replacement model without activity bindings.
                vm:SendViewModelMatchingSequence(index)
                vm:SetCycle(0)
            end
            vm:SetPlaybackRate(1)
        end
    end
    if confirmedDuration then duration = math.max(duration, confirmedDuration) end
    if CLIENT then
        if injection then
            self.StimPlayback = {name = name, started = started, duration = duration}
        else
            self.StimPlayback = nil
        end
    end
    if SERVER and IsValid(owner) and owner:IsPlayer() then
        net.Start("ACFInfantryStimSequence")
        net.WriteEntity(self)
        net.WriteString(name)
        net.WriteFloat(started)
        net.WriteFloat(duration)
        net.Send(owner)
    end
    return duration
end

function SWEP:Deploy()
    local duration = self:PlayStimSequence("deploy")
    self.StimIdleAt = CurTime() + duration
    self:SetNextPrimaryFire(self.StimIdleAt)
    self:SetNextSecondaryFire(self.StimIdleAt)
    return true
end

if CLIENT then
    net.Receive("ACFInfantryStimSequence", function()
        local weapon, name = net.ReadEntity(), net.ReadString()
        local started, duration = net.ReadFloat(), net.ReadFloat()
        if IsValid(weapon) and weapon:GetClass() == "weapon_acf_healthstim" and sequenceTimes[name] then
            -- Ignore an older idle/deploy event arriving after injection began.
            if weapon.StimPlayback and started < weapon.StimPlayback.started then return end
            weapon.PendingStimStart = started
            weapon.PendingStimDuration = duration
            weapon.PendingStimSequence = name
            weapon.PendingStimSequenceUntil = CurTime() + 1
        end
    end)
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
    if CLIENT then
        if self.PendingStimSequence then
            local owner = self:GetOwner()
            if IsValid(owner) and owner == LocalPlayer() and owner:GetActiveWeapon() == self then
                self:PlayStimSequence(self.PendingStimSequence, self.PendingStimStart, self.PendingStimDuration)
                self.PendingStimSequence = nil
            elseif CurTime() >= self.PendingStimSequenceUntil then
                self.PendingStimSequence = nil
            end
        end
        return
    end
    if self.StimTarget then
        local owner = self:GetOwner()
        if not IsValid(owner) or owner:GetActiveWeapon() ~= self
            or self:OtherTarget() ~= self.StimTarget then
            self:CancelOtherInjection()
        else
            if self.StimSoundAt and CurTime() >= self.StimSoundAt then
                owner:EmitSound("darky_rust.syringe-inject-friend")
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
            if IsValid(self) and Living(owner) then owner:EmitSound("darky_rust.syringe-inject-self") end
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
