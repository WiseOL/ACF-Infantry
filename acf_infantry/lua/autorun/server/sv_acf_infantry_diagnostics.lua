-- Opt-in, administrator-only runtime trace. Never changes ACF damage results.
ACFInfantryDiagnostics = ACFInfantryDiagnostics or {}
local D = ACFInfantryDiagnostics
function D.Log(event, weapon, fields)
    if CurTime() > (D.Until or 0) then return end
    local out = {"[ACF Infantry vss-fix-6] " .. event}
    if IsValid(weapon) then out[#out + 1] = weapon:GetClass() end
    for key, value in SortedPairs(fields or {}) do out[#out + 1] = key .. "=" .. tostring(value) end
    local line = table.concat(out, " | ")
    print(line)
    if IsValid(D.Recipient) then D.Recipient:PrintMessage(HUD_PRINTCONSOLE, line .. "\n") end
end
concommand.Add("acf_infantry_missile_diagnostics", function(player)
    if IsValid(player) and not player:IsAdmin() then return end
    D.Until = CurTime() + 120
    D.Recipient = IsValid(player) and player or nil
    D.Log("Trace enabled for 120 seconds; fire each launcher", nil, {
        MakeMissile = ACF and type(ACF.MakeMissile) or "no ACF",
        Explosion = ACF and ACF.Damage and type(ACF.Damage.createExplosion) or "missing"})
    for _, class in ipairs({"weapon_acf_stinger", "weapon_acf_bazooka", "weapon_acf_panzerschreck"}) do
        local w = weapons.GetStored(class) or {}
        local b = w.Bullet or {}
        D.Log("Loaded definition: " .. class, nil, {
            build = w.InfantryMissileBuild or "OLD/MISSING ADAPTER",
            name = w.PrintName, projectile = b.ProjLength, propellant = b.PropLength,
            filler = b.FillerMass, liner = b.ConeAng, guidance = w.InfantryGuidance,
            reload = w.LauncherReloadTime})
    end
    if IsValid(player) then
        local w = player:GetActiveWeapon()
        if IsValid(w) then
            local info = debug.getinfo(w.PrimaryAttack, "S") or {}
            D.Log("Equipped weapon", w, {build = w.InfantryMissileBuild or "OLD/MISSING", source = info.short_src})
        end
    end
end)
hook.Add("ACF_PreDamageEntity", "ACFInfantryMissileTrace", function(entity)
    if not D.Exploding or not IsValid(entity) then return end
    D.Log("ACF damage reached target", entity, {health = entity.ACF and entity.ACF.Health})
end)
hook.Add("ACF_PostDamageEntity", "ACFInfantryMissileTrace", function(entity)
    if not D.Exploding or not IsValid(entity) then return end
    D.Log("ACF damage completed", entity, {health = entity.ACF and entity.ACF.Health})
end)
