if SERVER then AddCSLuaFile("acf_sweps/hud_theme.lua") end
if CLIENT and not ACFSwepsTheme then include("acf_sweps/hud_theme.lua") end
AddCSLuaFile()
local Class = "weapon_acf_thermal"
local function Equipped(ply)
    if not IsValid(ply) or not ply:Alive() then return nil end
    local w = ply:GetWeapon(Class)
    if IsValid(w) then return w end
end
if SERVER then
    util.AddNetworkString("ACFWireThermalToggle")
    function ACFWireThermalToggle(ply)
        local w = Equipped(ply)
        if not w or not FLIR or not isfunction(FLIR.enable) then return end
        if CurTime() < (ply.ACFThermalNextToggle or 0) then return end
        ply.ACFThermalNextToggle = CurTime() + 0.3
        w:SetNWBool("ThermalEnabled", not w:GetNWBool("ThermalEnabled", false))
    end
    net.Receive("ACFWireThermalToggle", function(_, ply) ACFWireThermalToggle(ply) end)
    hook.Add("PlayerDeath", "ACFWireThermalReset", function(ply)
        local w = ply:GetWeapon(Class)
        if IsValid(w) then w:SetNWBool("ThermalEnabled", false) end
    end)
    return
end

-- Wire's camera controller sends FLIR.enable messages. Combine that demand
-- with goggles instead of replacing the camera controller or its networking.
local state = {goggles = false, camera = false}
local hookedFLIR
local function InstallBridge()
    if not FLIR or not isfunction(FLIR.enable) then return false end
    if hookedFLIR == FLIR and FLIR.enable == state.wrapper then return true end
    state.camera = FLIR.enabled == true and not state.goggles
    local original = FLIR.enable
    state.original = original
    state.wrapper = function(enabled)
        state.camera = enabled == true
        original(state.camera or state.goggles)
    end
    FLIR.enable = state.wrapper
    hookedFLIR = FLIR
    return true
end
local wasDown = false
local nextCheck = 0
hook.Add("Think", "ACFWireThermalBridge", function()
    local ply = LocalPlayer()
    local w = Equipped(ply)
    local down = input.IsKeyDown(KEY_N)
    if down and not wasDown and w and not gui.IsGameUIVisible() and not vgui.CursorVisible()
        and not IsValid(vgui.GetKeyboardFocus()) then
        net.Start("ACFWireThermalToggle") net.SendToServer()
    end
    wasDown = down
    if CurTime() < nextCheck then return end
    nextCheck = CurTime() + 0.1
    if not InstallBridge() then return end
    state.goggles = IsValid(w) and w:GetNWBool("ThermalEnabled", false) or false
    local desired = state.camera or state.goggles
    if FLIR.enabled ~= desired then state.original(desired) end
end)
hook.Add("HUDPaint", "ACFWireThermalStatus", function()
        if ACFSwepsTheme and ACFSwepsTheme.VerticalHUD then return end
    local w = Equipped(LocalPlayer())
    if not IsValid(w) or not w:GetNWBool("ThermalEnabled", false) then return end
    local x, y = 20, ScrH() - 185
    ACFSwepsTheme.Panel(6, x, y, 240, 30, Color(15, 18, 24, 225))
    ACFSwepsTheme.Text("THERMAL ON  |  N: TOGGLE", "DermaDefaultBold", x + 10, y + 8, ACFSwepsTheme.Color("COLOR_PRIMARY_COLOR"))
end)
hook.Add("ShutDown", "ACFWireThermalCleanup", function()
    if hookedFLIR and hookedFLIR.enable == state.wrapper then
        state.goggles = false
        state.original(state.camera)
        hookedFLIR.enable = state.original
    end
end)
