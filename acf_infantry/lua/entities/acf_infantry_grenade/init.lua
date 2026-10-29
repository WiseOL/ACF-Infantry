AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("effects/acf_infantry_safe_smoke/init.lua")
include("shared.lua")
local UP = Vector(0, 0, 1)
local GAS_DAMAGE_ID = 0xACF003
-- Bypass suit armor only for our marked gas hits. Generic damage avoids the
-- HEV toxin/antitoxin announcements and engine poison-specific behavior.
hook.Add("HandlePlayerArmorReduction", "ACFInfantryGasArmorBypass", function(target, damage)
    if damage:GetDamageCustom() ~= GAS_DAMAGE_ID then return end
    local source = damage:GetInflictor()
    if not IsValid(source) or source:GetClass() ~= "acf_infantry_grenade" then return end
    local kind = source:GetNW2String("GrenadeKind", "")
    if kind == "gas" or kind == "venom" then return true end
end)

local function InWater(position)
    return bit.band(util.PointContents(position), CONTENTS_WATER + CONTENTS_SLIME) ~= 0
end
function ENT:Initialize()
    local models = {smoke = "models/weapons/w_eq_smokegrenade.mdl",
        fire = "models/weapons/w_eq_fraggrenade.mdl", gas = "models/weapons/w_eq_flashbang.mdl", venom = "models/weapons/w_eq_flashbang.mdl"}
    self:SetModel(models[self:GetNW2String("GrenadeKind", "smoke")] or models.smoke)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
    self:SetCustomCollisionCheck(true)
    local physics = self:GetPhysicsObject()
    if IsValid(physics) then physics:SetMass(0.4) physics:Wake() end
    self.BurstAt = CurTime() + (self.FuseTime or 2)
    self.NextBounce = 0
    -- Fuse is wall-clock based, independent of physics sleep or contact.
    -- Think retains its deadline check; Burst prevents duplicate detonation.
    timer.Simple(self.FuseTime or 2, function()
        if IsValid(self) and not self.Burst then self:Detonate() end
    end)
end
function ENT:PhysicsCollide(data)
    if data.Speed > 60 and CurTime() >= self.NextBounce then
        self:EmitSound("weapons/hegrenade/he_bounce-1.wav", 65, 100, 0.6)
        self.NextBounce = CurTime() + 0.15
    end
end
function ENT:CreateFirePatches()
    local origin = self:GetPos()
    local points, delays = {}, {}
    self.FireStarted = CurTime()
    self:SetNW2Float("FireStarted", self.FireStarted)
    local function PlacementFilter(entity)
        return entity ~= self and not (entity:IsPlayer() or entity:IsNPC() or entity:IsNextBot())
    end
    -- Keep overlapping coverage, but jitter the grid and ignite outward over time.
    -- Ground and visibility checks prevent fire spreading through walls or water.
    local spacing = 80
    local steps = math.floor(self.FireReach / spacing)
    for x = -steps, steps do
        for y = -steps, steps do
            local offset = Vector(x * spacing, y * spacing, 0)
            if x ~= 0 or y ~= 0 then
                offset = offset + Vector(math.Rand(-14, 14), math.Rand(-14, 14), 0)
            end
            if offset:LengthSqr() <= self.FireReach ^ 2 then
                local ground = util.TraceLine({start = origin + offset + UP * 24,
                    endpos = origin + offset - UP * 160, filter = PlacementFilter, mask = MASK_SOLID})
                local pos = ground.HitPos + UP * 3
                if ground.Hit and not ground.HitSky and ground.HitNormal.z > 0.5 and not InWater(pos) then
                    local line = util.TraceLine({start = origin + UP * 8, endpos = pos + UP * 8,
                        filter = PlacementFilter, mask = MASK_SOLID})
                    if not line.Hit then
                        points[#points + 1] = pos
                        -- Center lights immediately; outer patches follow over ~2 seconds.
                        delays[#points] = (x == 0 and y == 0) and 0
                            or offset:Length() / self.FireReach * 2 + math.Rand(0, 0.3)
                    end
                end
            end
        end
    end
    self.FirePoints, self.FirePointDelays = points, delays
    for index, pos in ipairs(points) do
        self:SetNW2Vector("FirePoint" .. index, pos)
        self:SetNW2Float("FirePointDelay" .. index, delays[index])
    end
    self:SetNW2Int("FirePointCount", #points)
    return #points > 0
end
local function SmokeRound(self, prefix)
    local ammoType = ACF.Classes.GetTypeByName("ACF.Ammunition.SM")
    if not ammoType then
        ErrorNoHalt("[ACF Infantry] Native SM ammo unavailable for grenade smoke.\n")
        return
    end
    local ammo = ammoType()
    -- Grenade-local specs: stock VSS launchers start at 40 mm and would
    -- clamp the requested payload. No global edits.
    ammo.Weapon = {
        ID = "ACF.Guns.SmokeLauncher", Caliber = self[prefix .. "Caliber"],
        CaliberLimits = {Base = self[prefix .. "Caliber"], Min = self[prefix .. "Caliber"], Max = self[prefix .. "Caliber"]},
        Round = {MaxLength = self[prefix .. "Projectile"] + self[prefix .. "Propellant"],
            PropLength = self[prefix .. "Propellant"]},
    }
    ammo.Projectile = self[prefix .. "Projectile"]
    ammo.Propellant = self[prefix .. "Propellant"]
    ammo.FillerRatio = self[prefix .. "FillerRatio"]
    ammo.SmokeWPRatio = self[prefix .. "WPRatio"]
    ammo.Tracer = false
    ammo:VerifyData()
    return ammo:BaseConvert()
end
function ENT:CreateGasSmoke()
    local data = SmokeRound(self, "GasSmoke")
    if not data then return end
    -- Visual only: native WP damage clouds would add unintended burn damage.
    ACF.Utilities.Effects.CreateEffect("ACF_Smoke", {
        Origin = self:GetPos(), Normal = -UP,
        Scale = math.max((data.FillerMass or 0) * 8 * ACF.MeterToInch, 0),
        Magnitude = math.max((data.WPMass or 0) * 8 * ACF.MeterToInch, 0),
        Start = self.GasSmokeColor, Radius = data.Caliber,
    }, true, true)
end
function ENT:Detonate()
    if self.Burst then return end
    self.Burst = true
    local kind = self:GetNW2String("GrenadeKind", "smoke")
    if kind == "smoke" then
        local data = SmokeRound(self, "Smoke")
        if data then
            -- A private client-only smoke visual: never call native SM impact,
            -- WP cloud creation, explosions, Ignite, or any damage functions.
            local effect = EffectData()
            effect:SetOrigin(self:GetPos())
            effect:SetScale(math.max((data.FillerMass or 0) * 8 * ACF.MeterToInch, 0))
            effect:SetMagnitude(math.max((data.WPMass or 0) * 8 * ACF.MeterToInch, 0))
            effect:SetRadius(data.Caliber)
            effect:SetStart(self.SmokeColor)
            effect:SetSurfaceProp(self.SmokeDuration)
            util.Effect("acf_infantry_safe_smoke", effect, true, true)
        end
        -- Use the finite CSS grenade burst, never an unmanaged ambient loop.
        self:EmitSound("weapons/smokegrenade/sg_explode.wav", 65, 100, 0.6)
        self:Remove()
        return
    end
    if kind == "gas" or kind == "venom" then
        self.GasReverseMovement = kind == "gas"
        if kind == "venom" then
            self.GasDamage = 8
            self.GasDuration = 15
            self.GasSmokeColor = Vector(216, 125, 73)
        end
        if self:WaterLevel() > 0 then self:Remove() return end
        self:SetMoveType(MOVETYPE_NONE)
        self:SetSolid(SOLID_NONE)
        self:SetNoDraw(true)
        self.GasUntil = CurTime() + self.GasDuration
        self.NextGas = CurTime()
        self:CreateGasSmoke()
        -- Use the finite CSS grenade burst, never an unmanaged ambient loop.
        self:EmitSound("weapons/smokegrenade/sg_explode.wav", 65, 100, 0.6)
        return
    end
    -- Unknown grenade kinds must never fall through into fire behavior.
    if kind ~= "fire" then self:Remove() return end
    if self:WaterLevel() > 0 or not self:CreateFirePatches() then self:Remove() return end
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_NONE)
    self:SetNW2Bool("Burning", true)
    self.BurnUntil = CurTime() + self.FireDuration
    self.NextBurn = CurTime()
    self:SetNW2Float("BurnUntil", self.BurnUntil)
    self:EmitSound("ambient/fire/ignite.wav", 75, 100)
    self.FireSound = CreateSound(self, "ambient/fire/fire_small_loop1.wav")
    if self.FireSound then self.FireSound:PlayEx(0.6, 100) end
    ACF.Utilities.Effects.CreateEffect("ACF_Explosion", {
        Origin = self:GetPos(), Normal = UP, Scale = 10}, true, true)
end
function ENT:BurnTick(dt)
    local attacker = IsValid(self.Thrower) and self.Thrower or game.GetWorld()
    for _, target in ipairs(ents.FindInSphere(self:GetPos(), self.FireReach)) do
        if target ~= self and IsValid(target) and target:WaterLevel() < 2 then
            local origin, hit
            for index, point in ipairs(self.FirePoints) do
                if CurTime() >= self.FireStarted + self.FirePointDelays[index] and not InWater(point) then
                    local nearest = target:NearestPoint(point + UP * 8)
                    if nearest:DistToSqr(point) <= self.FireRadius ^ 2
                        and nearest:DistToSqr(self:GetPos()) <= self.FireReach ^ 2 then
                        local trace = util.TraceLine({start = point + UP * 8, endpos = nearest,
                            filter = self, mask = MASK_SHOT})
                        if not trace.Hit or trace.Entity == target then origin = point hit = nearest break end
                    end
                end
            end
            if origin then
                if target:IsPlayer() or target:IsNPC() or target:IsNextBot() then
                    local damage = DamageInfo()
                    damage:SetDamage(self.FireDamage * dt)
                    damage:SetDamageType(DMG_BURN)
                    damage:SetAttacker(attacker)
                    damage:SetInflictor(self)
                    damage:SetDamagePosition(hit)
                    target:TakeDamageInfo(damage)
                elseif ACF.Check(target) and target.ACF then
                    -- Low-penetration thermal wear; armor reduces it through VSS ACF.
                    local objects = ACF.Damage.Objects
                    local result = objects.DamageResult(4 * dt, 1, target.ACF.Armour or 1)
                    local info = objects.DamageInfo(attacker, self, DMG_BURN, origin, hit)
                    ACF.Damage.dealDamage(target, result, info)
                end
            end
        end
    end
end
function ENT:GasTick(dt)
    local attacker = IsValid(self.Thrower) and self.Thrower or game.GetWorld()
    for _, target in ipairs(ents.FindInSphere(self:GetPos(), self.GasRadius)) do
        if IsValid(target) and (target:IsPlayer() or target:IsNPC() or target:IsNextBot())
            and target:Health() > 0 and target:WaterLevel() < 2 then
            local point = target:WorldSpaceCenter()
            local trace = util.TraceLine({start = self:GetPos() + UP * 8, endpos = point,
                filter = self, mask = MASK_SHOT})
            if not trace.Hit or trace.Entity == target then
                if target:IsPlayer() and self.GasReverseMovement ~= false then
                    target:SetNW2Float("ACFInfantryGasUntil", math.max(
                        target:GetNW2Float("ACFInfantryGasUntil", 0), CurTime() + 0.4))
                end
                local damage = DamageInfo()
                damage:SetDamage(self.GasDamage * dt)
                damage:SetDamageType(DMG_GENERIC)
                damage:SetDamageCustom(GAS_DAMAGE_ID)
                damage:SetAttacker(attacker)
                damage:SetInflictor(self)
                damage:SetDamagePosition(point)
                target:TakeDamageInfo(damage)
            end
        end
    end
end
function ENT:Think()
    local now = CurTime()
    if not self.Burst and now >= self.BurstAt then self:Detonate() end
    if not IsValid(self) then return end
    if self.GasUntil then
        if now >= self.GasUntil or self:WaterLevel() > 0 then self:Remove() return end
        if now >= self.NextGas then self.NextGas = now + 0.25 self:GasTick(0.25) end
    end
    if self.BurnUntil then
        if now >= self.BurnUntil or self:WaterLevel() > 0 then self:Remove() return end
        if now >= self.NextBurn then
            self.NextBurn = now + 0.25
            self:BurnTick(0.25)
        end
    end
    self:NextThink(now + 0.05)
    return true
end
function ENT:OnRemove()
    if self.FireSound then self.FireSound:Stop() self.FireSound = nil end
    self:StopSound("ambient/fire/fire_small_loop1.wav")
    self:StopSound("ambient/gas/steam2.wav")
end
