if SERVER then AddCSLuaFile() end
for _, entry in ipairs({{"ACFInfantrySmokeGrenade", "ACF Smoke Grenades"}, {"ACFInfantryFireGrenade", "ACF Fire Grenades"}, {"ACFInfantryGasGrenade", "ACF Nerve Gas Grenades"}, {"ACFInfantryVenomGrenade", "Venomous Agent X Grenades"}}) do
    game.AddAmmoType({name = entry[1], dmgtype = DMG_GENERIC, tracer = TRACER_NONE, maxcarry = 100})
    if CLIENT then language.Add(entry[1] .. "_ammo", entry[2]) end
end
