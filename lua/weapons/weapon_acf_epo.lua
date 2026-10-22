if SERVER then AddCSLuaFile("acf_sweps/hud_theme.lua") end
if CLIENT and not ACFSwepsTheme then include("acf_sweps/hud_theme.lua") end
AddCSLuaFile()
SWEP.Base = "weapon_base"
SWEP.PrintName = "ACF Erythropoietin (EPO)"
SWEP.Author = "ACF server customization"
SWEP.Category = "ACF Infantry"
SWEP.Instructions = "Left click: +20% sprint speed and jump height for 30 seconds, then -30% sprint speed and jump power for 30 seconds. Single use."
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.ViewModel = "models/weapons/c_arms.mdl"
SWEP.WorldModel = "models/weapons/w_defuser.mdl"
SWEP.HoldType = "normal"
SWEP.Slot = 5
SWEP.SlotPos = 2
SWEP.DrawAmmo = false
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.DisableDuplicator = true

function SWEP:BuildWepSelectionText()
    self.DisplayText = { "+20% sprint speed / jump height", "30s boost, then 30s crash (-30%)", "Single use; cannot stack during boost or crash" }
    self.ControlText = { "Left click: Use EPO" }
end
function SWEP:Initialize() self:SetHoldType(self.HoldType) end

local function RestoreEPO(ply)
    if not IsValid(ply) then return end
    timer.Remove("ACFEPO_" .. ply:EntIndex())
    local state = ply.ACFEPOState
    if not state then return end
    -- Preserve independent speed changes made by other addons during the effect.
    if math.abs(ply:GetRunSpeed() - state.BoostRun) < 0.01 then ply:SetRunSpeed(state.Run) end
    if math.abs(ply:GetJumpPower() - state.BoostJump) < 0.01 then ply:SetJumpPower(state.Jump) end
    ply.ACFEPOState = nil
    ply:SetNWFloat("ACFEPOExpires", 0)
    ply:SetNWFloat("ACFEPOCrashExpires", 0)
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 0.5)
    if CLIENT then return end
    local ply = self:GetOwner()
    if self.Used or not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() or ply.ACFEPOState then return end
    self.Used = true
    local state = {Run = ply:GetRunSpeed(), Jump = ply:GetJumpPower()}
    state.BoostRun = state.Run * 1.2
    state.BoostJump = state.Jump * math.sqrt(1.2)
    ply.ACFEPOState = state
    ply:SetRunSpeed(state.BoostRun)
    ply:SetJumpPower(state.BoostJump)
    ply:SetNWFloat("ACFEPOExpires", CurTime() + 30)
    ply:EmitSound("items/smallmedkit1.wav")
    timer.Create("ACFEPO_" .. ply:EntIndex(), 30, 1, function()
        if not IsValid(ply) or ply.ACFEPOState ~= state then return end
        if not ply:Alive() then RestoreEPO(ply) return end
        -- Restore our boost before applying the crash to the baseline values.
        if math.abs(ply:GetRunSpeed() - state.BoostRun) < 0.01 then ply:SetRunSpeed(state.Run) end
        if math.abs(ply:GetJumpPower() - state.BoostJump) < 0.01 then ply:SetJumpPower(state.Jump) end
        state.Run = ply:GetRunSpeed()
        state.Jump = ply:GetJumpPower()
        state.BoostRun = state.Run * 0.7
        state.BoostJump = state.Jump * 0.7
        ply:SetRunSpeed(state.BoostRun)
        ply:SetJumpPower(state.BoostJump)
        ply:SetNWFloat("ACFEPOExpires", 0)
        ply:SetNWFloat("ACFEPOCrashExpires", CurTime() + 30)
        timer.Create("ACFEPO_" .. ply:EntIndex(), 30, 1, function()
            if IsValid(ply) and ply.ACFEPOState == state then RestoreEPO(ply) end
        end)
    end)
    self:Remove()
end
function SWEP:SecondaryAttack() end
function SWEP:Reload() end

if SERVER then
    hook.Add("PlayerDeath", "ACFEPOCleanup", RestoreEPO)
    hook.Add("PlayerDisconnected", "ACFEPOCleanup", RestoreEPO)
    hook.Add("PlayerSpawn", "ACFEPOCleanup", RestoreEPO)
end
if CLIENT then
    function SWEP:ShouldDrawViewModel() return false end
    function SWEP:DrawHUD()
        if ACFSwepsTheme and ACFSwepsTheme.VerticalHUD then return end
        local x, y = ScrW() - 300, ScrH() - 110
        ACFSwepsTheme.Panel(8, x, y, 280, 90, Color(15, 18, 24, 225))
        ACFSwepsTheme.Text("EPO", "DermaLarge", x + 12, y + 10, ACFSwepsTheme.Color("COLOR_WARNING_TEXT"))
        ACFSwepsTheme.Text("+20% SPRINT / JUMP HEIGHT", "DermaDefaultBold", x + 12, y + 48, ACFSwepsTheme.Color("COLOR_TEXT"))
        ACFSwepsTheme.Text("30s BOOST / 30s CRASH", "DermaDefaultBold", x + 12, y + 68, ACFSwepsTheme.Color("COLOR_TEXT"))
    end
    hook.Add("HUDPaint", "ACFEPOEffectTimer", function()
        if ACFSwepsTheme and ACFSwepsTheme.VerticalHUD then return end
        local ply = LocalPlayer()
        if not IsValid(ply) or not ply:Alive() then return end
        local remaining = ply:GetNWFloat("ACFEPOExpires", 0) - CurTime()
        local crash = false
        if remaining <= 0 then
            remaining = ply:GetNWFloat("ACFEPOCrashExpires", 0) - CurTime()
            crash = true
        end
        if remaining <= 0 then return end
        local x, y = math.max(10, ScrW() - 230), (ScrH() - 30) * 0.5
        ACFSwepsTheme.Panel(6, x, y, 210, 30, Color(15, 18, 24, 225))
        ACFSwepsTheme.Text((crash and "EPO CRASH  " or "EPO ACTIVE  ") .. math.ceil(remaining) .. "s", "DermaDefaultBold", x + 10, y + 8, crash and ACFSwepsTheme.Color("COLOR_ERROR_TEXT") or ACFSwepsTheme.Color("COLOR_WARNING_TEXT"))
    end)
end

SWEP.SubCategory = "Utility"
