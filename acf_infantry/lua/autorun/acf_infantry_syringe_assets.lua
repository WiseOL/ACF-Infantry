-- Health-stim charge pool; HL:A syringe presentation is registered separately.
if SERVER then AddCSLuaFile() end
game.AddAmmoType({name = "ACFInfantryStim", dmgtype = DMG_GENERIC, tracer = TRACER_NONE, maxcarry = 100})
if CLIENT then language.Add("ACFInfantryStim_ammo", "ACF Medical Charges") end
