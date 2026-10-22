if SERVER then AddCSLuaFile() end
local HeavyWeapons = {weapon_acf_30cal = true, weapon_acf_m249 = true}
-- Apply a movement cap while held, without overwriting player speed settings.
-- Native crouch/slow-walk behavior and current EPO speed settings are preserved.
hook.Add("SetupMove", "ACFInfantryHeavyWeaponSpeed", function(player, move)
    if player:InVehicle() or player:GetMoveType() ~= MOVETYPE_WALK then return end
    local weapon = player:GetActiveWeapon()
    if not IsValid(weapon) or not HeavyWeapons[weapon:GetClass()] then return end
    local speed = player:GetWalkSpeed()
    if move:KeyDown(IN_SPEED) then
        speed = player:GetRunSpeed()
    elseif move:KeyDown(IN_WALK) then
        speed = player:GetSlowWalkSpeed()
    end
    move:SetMaxSpeed(math.min(move:GetMaxSpeed(), speed) * 0.85)
    move:SetMaxClientSpeed(math.min(move:GetMaxClientSpeed(), speed) * 0.85)
end)
