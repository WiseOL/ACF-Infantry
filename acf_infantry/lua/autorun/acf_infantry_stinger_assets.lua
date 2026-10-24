-- FIM-92 model/sounds from ACF-Team/ACF-3-SWEPs b52ea0c.
-- Model/deploy: Rocks; seeker growl: FrazierWing (CC0). See README credits.
if SERVER then
    AddCSLuaFile()
    resource.AddFile("models/weapons/fim92/w_fim92.dx90.vtx")
    resource.AddFile("models/weapons/fim92/w_fim92.vvd")
    resource.AddFile("models/weapons/fim92/w_fim92.phy")
    resource.AddFile("models/weapons/fim92/c_fim92.vvd")
    resource.AddFile("models/weapons/fim92/c_fim92.dx90.vtx")
    resource.AddFile("models/weapons/fim92/w_fim92.mdl")
    resource.AddFile("models/weapons/fim92/c_fim92.mdl")
    resource.AddFile("materials/models/weapons/fim92/car_glass.vtf")
    resource.AddFile("materials/models/weapons/fim92/fim92.vmt")
    resource.AddFile("materials/models/weapons/fim92/fim92.vtf")
    resource.AddFile("materials/models/weapons/fim92/fim92_glow.vtf")
    resource.AddFile("materials/models/weapons/fim92/4carz1024_glass.vmt")
    resource.AddFile("materials/models/weapons/fim92/car_glass_ref.vtf")
    resource.AddFile("sound/weapons/fim92/seeker_growl.wav")
    resource.AddFile("sound/weapons/fim92/deploy.wav")
end
sound.Add({name = "Weapon_FIM92.Seeker", sound = "weapons/fim92/seeker_growl.wav", channel = CHAN_STATIC, volume = 0.5, level = 60})
sound.Add({name = "Weapon_FIM92.Shoot", sound = "^acf_missiles/missiles/missile_rocket.mp3", channel = CHAN_WEAPON, volume = 1, level = 150, pitch = {98, 102}})
sound.Add({name = "Weapon_FIM92.Deploy", sound = "weapons/fim92/deploy.wav", channel = CHAN_BODY, volume = 1, level = 75})
sound.Add({name = "Weapon_FIM92.ShellIn", sound = "bazooka/rocket_clipin.wav", channel = CHAN_BODY, volume = 1, level = 75})
