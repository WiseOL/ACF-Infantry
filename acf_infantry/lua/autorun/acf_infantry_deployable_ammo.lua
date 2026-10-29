if SERVER then AddCSLuaFile() end
for _, entry in ipairs({{"ACFInfantryC4", "ACF C4 Charges"}, {"ACFInfantryClaymore", "ACF Claymores"}}) do
    game.AddAmmoType({name = entry[1], dmgtype = DMG_BLAST, tracer = TRACER_NONE, maxcarry = 100})
    if CLIENT then language.Add(entry[1] .. "_ammo", entry[2]) end
end
