if SERVER then
    AddCSLuaFile()
    AddCSLuaFile("acf_sweps/hud_theme.lua")
    return
end
if not ACFSwepsTheme then include("acf_sweps/hud_theme.lua") end
local T = ACFSwepsTheme
local blue = Color(112, 191, 243)
local red = Color(255, 70, 70)
local function Row(rows, label, value, color)
    rows[#rows + 1] = {label, tostring(value), color}
end
function T.DrawVerticalHUD()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    local weapon = ply:GetActiveWeapon()
    local class = IsValid(weapon) and weapon:GetClass() or ""
    local infantry = string.StartWith(class, "weapon_acf_")
        or IsValid(weapon) and weapon.Base == "weapon_acf_base"
    local rows, statuses = {}, {}
    local count, capacity, title, magazineReserve
    local thermal = ply:GetWeapon("weapon_acf_thermal")
    local thermalOn = IsValid(thermal) and thermal:GetNWBool("ThermalEnabled", false)
    if infantry then
        title = weapon.PrintName or "ACF INFANTRY"
        if weapon.Base == "weapon_acf_base" then
            count, capacity = math.max(weapon:Clip1(), 0), math.max(weapon.Primary.ClipSize or 1, 1)
            magazineReserve = math.max(weapon:Ammo1(), 0)
            Row(rows, "RESERVE", magazineReserve)
            Row(rows, "AMMO TYPE", weapon.ACFType or weapon.Primary.Ammo or "--")
            Row(rows, "FIRE MODE", weapon.Primary.Automatic and "AUTOMATIC" or "SEMI-AUTO")
            Row(rows, "SAFETY [B]", weapon:GetNW2Bool("ACFInfantrySafety", false) and "ON" or "OFF",
                weapon:GetNW2Bool("ACFInfantrySafety", false) and red or blue)
            if weapon.InfantryMissile then
                Row(rows, "GUIDANCE", weapon.InfantryAutonomous and "INFRARED" or "WIRE SACLOS")
                local reload = weapon:GetNW2Float("InfantryReloadAt", 0) - CurTime()
                local arming = weapon:GetNW2Float("InfantryArmedAt", 0) - CurTime()
                Row(rows, "LAUNCHER", reload > 0 and string.format("RELOAD %.1fs", reload)
                    or arming > 0 and string.format("ARMING %.1fs", arming) or "ARMED", reload > 0 and red or blue)
            end
        elseif weapon.GrenadeKind then
            count, capacity = math.max(weapon:Clip1(), 0), 1
            Row(rows, "SPARE GRENADES", math.max(weapon:Ammo1(), 0))
            Row(rows, "FUSE", tostring(weapon.FuseTime or 2) .. " SECONDS")
            Row(rows, "PRIMARY", weapon:GetNW2Bool("GrenadePrimed", false)
                and (weapon:GetNW2Bool("GrenadeDropMode", false) and "DROPPING AT FEET" or "RELEASE TO THROW") or "HOLD TO PRIME")
            Row(rows, "RIGHT CLICK", "DROP AT FEET")
        elseif class == "weapon_acf_suitarmor" then
            title = "SUIT ARMOR"
            count, capacity = ply:Armor(), 200
            Row(rows, "PER USE", "+25 ARMOR", blue)
            Row(rows, "PRIMARY", "APPLY ARMOR")
        elseif class == "weapon_acf_healthstim" then
            Row(rows, "SYRINGES", tostring(ply:GetAmmoCount(weapon.Primary.Ammo)), blue)
            Row(rows, "HEALING", "+50 HP / 10s", blue)
            Row(rows, "PROTECTION", "15% / 20s")
            Row(rows, "LEFT CLICK", "INJECT SELF")
            Row(rows, "RIGHT CLICK", "INJECT OTHER")
        elseif class == "weapon_acf_epo" then
            Row(rows, "BOOST", "+20% / 30s", blue)
            Row(rows, "CRASH", "-30% / 30s", red)
            Row(rows, "PRIMARY", "USE EPO")
        elseif class == "weapon_acf_thermal" then
            Row(rows, "THERMAL", thermalOn and "ON" or "OFF", thermalOn and blue or red)
            Row(rows, "TOGGLE", "LEFT CLICK / N")
            if not FLIR or not isfunction(FLIR.enable) then Row(rows, "REQUIRES", "WIREMOD", red) end
        end
    end
    local boost = ply:GetNWFloat("ACFEPOExpires", 0) - CurTime()
    local crash = ply:GetNWFloat("ACFEPOCrashExpires", 0) - CurTime()
    if boost > 0 then Row(statuses, "EPO ACTIVE", math.ceil(boost) .. "s", blue)
    elseif crash > 0 then Row(statuses, "EPO CRASH", math.ceil(crash) .. "s", red) end
    local stim = ply:GetNWFloat("ACFInfantryStimExpires", 0) - CurTime()
    if stim > 0 then Row(statuses, "STIM / 15% DR", math.ceil(stim) .. "s", blue) end
    if thermalOn then Row(statuses, "THERMAL ON", "N TO TOGGLE", blue) end
    if not infantry and #statuses == 0 then return end
    local scale = math.Clamp(ScrH() / 1080, 0.65, 1.5)
    local width, margin = 190 * scale, 20 * scale
    local magCount = magazineReserve and math.ceil(magazineReserve / capacity) or 0
    local visibleMags = math.min(magCount, 4)
    local height = (title and 48 or 0) + (count and 86 or 0) + #rows * 40
        + (magazineReserve and (28 + visibleMags * 12 + (magCount > 4 and 16 or 0)) or 0)
        + (#statuses > 0 and (12 + #statuses * 40) or 0)
    height = height * scale
    local x, y = ScrW() - margin - width, math.max(margin, ScrH() - margin - height)
    -- Separate translucent strips and a single blue spine, without a big frame.
    local cursor = y
    local function Strip(h, accent)
        surface.SetDrawColor(11, 32, 46, 140)
        surface.DrawRect(x, cursor, width, h * scale)
        surface.SetDrawColor(accent or blue)
        surface.DrawRect(x, cursor, 2 * scale, h * scale)
    end
    local function Fit(text, font, xx, yy, maxWidth, color)
        surface.SetFont(font)
        local value = tostring(text)
        while #value > 1 and surface.GetTextSize(value) > maxWidth do value = string.sub(value, 1, -2) end
        draw.SimpleText(value, font, xx, yy, color or T.Color("COLOR_TEXT"))
    end
    if title then
        Strip(40)
        Fit(title, "DermaDefaultBold", x + 12 * scale, cursor + 13 * scale, width - 24 * scale, blue)
        cursor = cursor + 48 * scale
    end
    if count then
        Strip(78, count <= 0 and red or blue)
        local ratio = math.Clamp(count / capacity, 0, 1)
        surface.SetDrawColor(60, 90, 105, 180)
        surface.DrawRect(x + 10 * scale, cursor + 10 * scale, 4 * scale, 58 * scale)
        surface.SetDrawColor(count <= 0 and red or blue)
        surface.DrawRect(x + 10 * scale, cursor + (68 - 58 * ratio) * scale, 4 * scale, 58 * ratio * scale)
        T.Text(count, "DermaLarge", x + 26 * scale, cursor + 8 * scale, blue)
        T.Text("/ " .. capacity, "DermaDefaultBold", x + 26 * scale, cursor + 44 * scale)
        cursor = cursor + 86 * scale
    end
    local function DrawRows(list)
        for _, row in ipairs(list) do
            Strip(36, row[3])
            Fit(row[1], "DermaDefault", x + 12 * scale, cursor + 3 * scale, width - 24 * scale, T.Color("COLOR_PRIMARY_COLOR"))
            Fit(row[2], "DermaDefaultBold", x + 12 * scale, cursor + 18 * scale, width - 24 * scale, row[3])
            cursor = cursor + 40 * scale
        end
    end
    DrawRows(rows)
    if magazineReserve then
        Fit((capacity == 1 and "SPARE ROUNDS  " or "SPARE MAGS  ") .. magCount,
            "DermaDefaultBold", x + 12 * scale, cursor, width - 24 * scale, blue)
        cursor = cursor + 28 * scale
        for i = 1, visibleMags do
            T.Bar(x + 12 * scale, cursor, width - 24 * scale, 7 * scale,
                math.Clamp((magazineReserve - (i - 1) * capacity) / capacity, 0, 1), blue)
            cursor = cursor + 12 * scale
        end
        if magCount > 4 then
            Fit("+ " .. (magCount - 4) .. " MORE", "DermaDefault", x + 12 * scale, cursor, width - 24 * scale)
            cursor = cursor + 16 * scale
        end
    end
    if #statuses > 0 then cursor = cursor + 12 * scale DrawRows(statuses) end
end
hook.Add("HUDPaint", "ACFInfantryVerticalHUD", function()
    local ply = LocalPlayer()
    local weapon = IsValid(ply) and ply:GetActiveWeapon()
    -- Guns draw after their scope mask so the information remains visible.
    if IsValid(weapon) and weapon.Base == "weapon_acf_base" then return end
    T.DrawVerticalHUD()
end)
