-- Syringe assets supplied with ACF Infantry; original credits remain in README.md.
if SERVER then AddCSLuaFile() end
game.AddAmmoType({name = "ACFInfantryStim", dmgtype = DMG_GENERIC, tracer = TRACER_NONE, maxcarry = 100})
if CLIENT then language.Add("ACFInfantryStim_ammo", "ACF Health Stims") end
if SERVER then
    -- Also support loose-file server installs through the configured download system.
    resource.AddFile("models/weapons/darky_m/c_syringe_v2.dx80.vtx")
    resource.AddFile("models/weapons/darky_m/c_syringe_v2.dx90.vtx")
    resource.AddFile("models/weapons/darky_m/c_syringe_v2.mdl")
    resource.AddFile("models/weapons/darky_m/c_syringe_v2.sw.vtx")
    resource.AddFile("models/weapons/darky_m/c_syringe_v2.vvd")
    resource.AddFile("models/weapons/darky_m/w_syringe_v2.dx80.vtx")
    resource.AddFile("models/weapons/darky_m/w_syringe_v2.dx90.vtx")
    resource.AddFile("models/weapons/darky_m/w_syringe_v2.mdl")
    resource.AddFile("models/weapons/darky_m/w_syringe_v2.phy")
    resource.AddFile("models/weapons/darky_m/w_syringe_v2.sw.vtx")
    resource.AddFile("models/weapons/darky_m/w_syringe_v2.vvd")
    resource.AddFile("materials/entities/rust_syringe.png")
    resource.AddFile("materials/models/darky_m/syringe/med_syringe.vmt")
    resource.AddFile("materials/models/darky_m/syringe/med_syringe_dif.vtf")
    resource.AddFile("materials/models/darky_m/syringe/med_syringe_nrm.vtf")
    resource.AddFile("materials/vgui/hud/weapon_rust_syringe.vmt")
    resource.AddFile("materials/vgui/hud/weapon_rust_syringe.vtf")
    resource.AddFile("sound/weapons/rust_mp3/syringe-deploy.mp3")
    resource.AddFile("sound/weapons/rust_mp3/syringe-inject-friend-foley.mp3")
    resource.AddFile("sound/weapons/rust_mp3/syringe-inject-friend.mp3")
    resource.AddFile("sound/weapons/rust_mp3/syringe-inject-self-foley.mp3")
    resource.AddFile("sound/weapons/rust_mp3/syringe-inject-self.mp3")
    resource.AddFile("sound/weapons/rust_mp3/syringe-pop-button-cap.mp3")
    resource.AddFile("sound/weapons/rust_mp3/syringe-pop-cap.mp3")
end
-- Register only missing event aliases, including model-embedded cap/foley events.
-- The original addon may already have registered these during autorun.
local sounds = {
    "syringe-deploy", "syringe-inject-friend-foley", "syringe-inject-friend",
    "syringe-inject-self-foley", "syringe-inject-self",
    "syringe-pop-button-cap", "syringe-pop-cap",
}
for _, name in ipairs(sounds) do
    local alias = "darky_rust." .. name
    if not sound.GetProperties(alias) then
        sound.Add({name = alias, channel = CHAN_STATIC, volume = 1,
            soundlevel = 180, sound = "weapons/rust_mp3/" .. name .. ".mp3"})
    end
end
