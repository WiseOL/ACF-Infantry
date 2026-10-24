-- Armor plate supplied with ACF Infantry, isolated from the default HEV battery.
if SERVER then
    AddCSLuaFile()
    resource.AddFile("models/acf_infantry/armor_plate.phy")
    resource.AddFile("models/acf_infantry/armor_plate.sw.vtx")
    resource.AddFile("models/acf_infantry/armor_plate.vvd")
    resource.AddFile("models/acf_infantry/armor_plate.mdl")
    resource.AddFile("models/acf_infantry/armor_plate.dx90.vtx")
    resource.AddFile("models/acf_infantry/armor_plate.dx80.vtx")
    resource.AddFile("materials/models/items/armorplate/plate.vmt")
    resource.AddFile("materials/models/items/armorplate/plate.vtf")
    resource.AddFile("sound/acf_infantry/armor_plate_use.wav")
    resource.AddFile("lua/weapons/weapon_acf_suitarmor.lua")
end
