ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "ACF Infantry Grenade"
ENT.Spawnable = false
ENT.DoNotDuplicate = true
ENT.DisableDuplicator = true
ENT.FireDuration = 15
ENT.FireRadius = 120 -- overlapping patch radius, Source units
ENT.FireReach = 250 -- hard outer limit from the grenade, Source units
ENT.FireDamage = 15 -- HP/second to characters, before normal damage hooks/armor

ENT.GasDamage = 3 -- HP/second, before normal damage hooks/armor
ENT.GasRadius = 250
ENT.GasDuration = 15
ENT.GasSmokeColor = Vector(209, 33, 33)
ENT.GasSmokeCaliber = 20 -- mm
ENT.GasSmokeProjectile = 11.13 -- cm
ENT.GasSmokePropellant = 0.05 -- cm
ENT.GasSmokeFillerRatio = 1
ENT.GasSmokeWPRatio = 0.01 -- native VSS SmokeWPRatio input

ENT.SmokeDuration = 30
ENT.SmokeColor = Vector(190, 195, 200)
ENT.SmokeCaliber = 20 -- mm
ENT.SmokeProjectile = 17.49 -- cm
ENT.SmokePropellant = 0.01 -- cm
ENT.SmokeFillerRatio = 1
ENT.SmokeWPRatio = 0.07 -- native VSS SmokeWPRatio input; visual only
