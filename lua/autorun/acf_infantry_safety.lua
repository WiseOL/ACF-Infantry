if SERVER then AddCSLuaFile() end
local function Supported(weapon)
    -- All Infantry firearms and launchers use this base; grenades/utilities do not.
    return IsValid(weapon) and weapon.Base == "weapon_acf_base"
end
if SERVER then
    util.AddNetworkString("ACFInfantrySafetyToggle")
    net.Receive("ACFInfantrySafetyToggle", function(_, player)
        if not player:Alive() or CurTime() < (player.ACFInfantryNextSafety or 0) then return end
        local weapon = player:GetActiveWeapon()
        if not Supported(weapon) then return end
        player.ACFInfantryNextSafety = CurTime() + 0.25
        local enabled = not weapon:GetNW2Bool("ACFInfantrySafety", false)
        weapon:SetNW2Bool("ACFInfantrySafety", enabled)
        -- Require a fresh trigger press after disengaging the safety.
        weapon:SetNW2Bool("ACFInfantryTriggerRelease", true)
        weapon:EmitSound("buttons/lightswitch2.wav", 55, enabled and 90 or 110, 0.35)
    end)
end
hook.Add("StartCommand", "ACFInfantryGunSafety", function(player, command)
    local weapon = player:GetActiveWeapon()
    if not Supported(weapon) then return end
    if SERVER and weapon:GetNW2Bool("ACFInfantryTriggerRelease", false) and not command:KeyDown(IN_ATTACK) then
        weapon:SetNW2Bool("ACFInfantryTriggerRelease", false)
    end
    if weapon:GetNW2Bool("ACFInfantrySafety", false) or weapon:GetNW2Bool("ACFInfantryTriggerRelease", false) then
        command:RemoveKey(IN_ATTACK)
    end
end)
if CLIENT then
    local nextRequest = 0
    local function Toggle()
        local player = LocalPlayer()
        if not IsValid(player) or not player:Alive() or not Supported(player:GetActiveWeapon())
            or CurTime() < nextRequest then return end
        nextRequest = CurTime() + 0.25
        net.Start("ACFInfantrySafetyToggle")
        net.SendToServer()
    end
    concommand.Add("acf_infantry_toggle_safety", Toggle)
    hook.Add("PlayerButtonDown", "ACFInfantrySafetyKey", function(player, key)
        if player == LocalPlayer() and key == KEY_B and IsFirstTimePredicted()
            and not gui.IsGameUIVisible() and not vgui.CursorVisible() then Toggle() end
    end)
    hook.Add("HUDPaint", "ACFInfantrySafetyStatus", function()
        if ACFSwepsTheme and ACFSwepsTheme.VerticalHUD then return end
        local player = LocalPlayer()
        if not IsValid(player) or not player:Alive() then return end
        local weapon = player:GetActiveWeapon()
        if not Supported(weapon) then return end
        local safe = weapon:GetNW2Bool("ACFInfantrySafety", false)
        draw.SimpleText(safe and "SAFETY ON  [B]" or "SAFETY OFF  [B]", "DermaDefaultBold",
            ScrW() * 0.5, ScrH() * 0.72, safe and Color(255, 195, 70) or Color(150, 200, 210), TEXT_ALIGN_CENTER)
    end)
end
