-- Native ACF v2 ammunition/missile adapter. No guessed HEAT jet or APCR mass values.
if SERVER then AddCSLuaFile() end
local M = {}
local function Report(event, weapon, fields)
    if SERVER and ACFInfantryDiagnostics then ACFInfantryDiagnostics.Log(event, weapon, fields) end
end
local function Type(name)
    return ACF.Classes.GetTypeByName(name)
end
local function Convert(weapon)
    local gunClass = Type(weapon.InfantryMissile and
        (weapon.InfantryMissileClass or ("ACF.Missiles.AntiTankGuided." .. weapon.InfantryMissile)) or (weapon.InfantryGunClass or "ACF.Guns.Cannon"))
    local ammoClass = Type("ACF.Ammunition." .. weapon.ACFType)
    if not gunClass or not ammoClass then return false end
    local gun = gunClass()
    gun.Caliber = weapon.Caliber
    if weapon.InfantryMissile then
        gun.Guidance = Type(weapon.InfantryGuidance or "ACF.Missiles.Guidance.WireSACLOS")()
        gun.Fuze = Type(weapon.InfantryFuze or "ACF.Missiles.Fuze.Contact")()
        gun.Fuze.ArmingDelay = gunClass.ArmDelay or 0.1
        gun.Fuze.FuzeDistance = weapon.InfantryFuzeDistance or 40
    end
    local ammo = ammoClass()
    ammo.Weapon = gun
    ammo.Tracer = false
    ammo.FillerRatio = weapon.InfantryFillerRatio or 1
    if weapon.InfantryMissile then
        ammo.Projectile = weapon.InfantryProjectile or gunClass.Round.ProjLength
        ammo.Propellant = weapon.InfantryPropellant or gunClass.Round.PropLength -- keep the actual missile motor fuel
        ammo.LinerAngle = weapon.InfantryLinerAngle or 0
        ammo.StandoffRatio = weapon.InfantryStandoffRatio or 0
    else
        -- Cannon's 80/65 cm limits scale from 100 mm to 60 mm: 48/39 cm.
        -- APCR penetration at muzzle increases with propellant mass. 9 cm is minimum projectile.
        ammo.Projectile = weapon.InfantryProjectile or 9
        ammo.Propellant = weapon.InfantryPropellant or 39
    end
    if weapon.InfantryMissile then
        -- Generic gun rounds require a 1.5-caliber projectile. Authored missile
        -- warheads can be shorter (AT-3: 16 cm; TOW: 20 cm).
        local update = ammo.UpdateRoundData
        function ammo:UpdateRoundData()
            local minimum = math.min(self.GUIData.MinProjLength, gunClass.Round.ProjLength)
            self.GUIData.MinProjLength = minimum
            return update(self)
        end
    end
    ammo:VerifyData()
    local data = SERVER and ammo:ServerConvert() or ammo:BaseConvert()
    data.Type = weapon.ACFType
    data.AmmoType = "ACF.Ammunition." .. weapon.ACFType
    weapon.RoundData = ammo
    weapon.Bullet = data
    weapon.BulletData = data
    weapon.ACFMuzzleVel = data.MuzzleVel
    weapon.ACFProjMass = data.ProjMass
    weapon.ACFHEATStandoff = data.Standoff or 0
    weapon.ACFProjLen = data.ProjLength
    weapon.FillerMass = data.FillerMass or 0
    -- Refresh the crate-equivalent fields used by ACF effects and weapon information.
    if SERVER and IsValid and IsValid(weapon) then ammo:Network(weapon, data) end
    return true
end
local function ApplyNative(weapon)
    -- Populate the shared definition as well as each instance (ACF firing mutates bullets).
    weapon.FillerMass = weapon.FillerMass or 0
    weapon:SetupACFBullet()
    -- Q-menu/selection info reads the shared definition, before an instance is equipped.
    -- Previously it retained the placeholder (1 m/s, zero explosive filler).
    Convert(weapon)
    if CLIENT and weapon.ACFType == "HE" then
        function weapon:MeasurePenetration()
            if not self.RoundData then Convert(self) end
            local data = self.Bullet
            if not self.RoundData or not data or not data.FillerMass then
                self.PenText = "ACF round data unavailable"
                return
            end
            local stats = self.RoundData:GetDisplayData(data)
            self.PenText = string.format("HE: %.2f kg filler | %.1f m blast radius",
                data.FillerMass, stats.BlastRadius or 0)
        end
    end
    local baseInitialize = weapon.Initialize
    function weapon:Initialize()
        self.NativeRoundReady = Convert(self)
        baseInitialize(self)
    end
end
function M.ApplyAPCR(weapon)
    ApplyNative(weapon)
    local fire = weapon.PrimaryAttack
    function weapon:PrimaryAttack()
        if not self.NativeRoundReady then self.NativeRoundReady = Convert(self) end
        if not self.NativeRoundReady then return end
        return fire(self)
    end
end
function M.ApplyMissile(weapon)
    weapon.InfantryMissileBuild = "vss-fix-6"
    ApplyNative(weapon)
    local deploy, think, drawHUD = weapon.Deploy, weapon.Think, weapon.DrawHUD
    function weapon:Deploy()
        local result = deploy(self)
        if SERVER then self:SetNW2Float("InfantryArmedAt", CurTime() + (self.LauncherArmingTime or 3)) end
        return result
    end
    function weapon:Think()
        think(self)
        if SERVER then
            local owner = self:GetOwner()
            if IsValid(owner) then
                self.IsComputer = true
                self.Computer = self
                self.HitPos = util.TraceLine({start = owner:GetShootPos(),
                    endpos = owner:GetShootPos() + owner:GetAimVector() * 52488,
                    filter = {owner, self, self.LastFired}, mask = MASK_SHOT}).HitPos
            end
            local finish = self:GetNW2Float("InfantryReloadAt", 0)
            if finish > 0 and CurTime() >= finish then
                self:SetNW2Float("InfantryReloadAt", 0)
                if IsValid(owner) then
                    local amount = math.min(1 - self:Clip1(), owner:GetAmmoCount(self.Primary.Ammo))
                    if amount > 0 then self:SetClip1(self:Clip1() + amount) owner:RemoveAmmo(amount, self.Primary.Ammo) end
                end
                self.Reloading = false
            end
        end
    end
    function weapon:Reload()
        if self:Clip1() >= 1 or self:Ammo1() <= 0 or self:GetNW2Float("InfantryReloadAt", 0) > 0 then return end
        self:SendWeaponAnim(ACT_VM_RELOAD)
        self:SetNWBool("iron", false)
        self:SetNextPrimaryFire(CurTime() + self.LauncherReloadTime)
        if SERVER then
            self.Reloading = true
            self:SetNW2Float("InfantryReloadAt", CurTime() + self.LauncherReloadTime)
        end
    end
    function weapon:PrimaryAttack()
        if CurTime() < self:GetNW2Float("InfantryArmedAt", math.huge) then Report("Blocked: launcher arming", self) return end
        if self:GetNW2Float("InfantryReloadAt", 0) > 0 or not self:CanPrimaryAttack() then return end
        local owner = self:GetOwner()
        if not IsValid(owner) or not owner:KeyDown(IN_ATTACK2) then return end
        if SERVER then
            if not ACF.MakeMissile then return end
            if not Convert(self) then Report("Round conversion unavailable", self) return end
            Report("Converted shot", self, {projectile = self.Bullet.ProjLength,
                propellant = self.Bullet.PropLength, filler = self.Bullet.FillerMass,
                liner = self.Bullet.ConeAng, guidance = self.InfantryGuidance})
            self.IsComputer = true
            self.Computer = self
            self.HitPos = owner:GetEyeTrace().HitPos
            self.ACF_Velocity = owner:GetVelocity()
            self.Missiles = self.Missiles or {}
            local direction = owner:GetAimVector()
            local pos = owner:GetShootPos() + direction * 40
            local point = {Position = self:WorldToLocal(pos), Angle = Angle()}
            local missile = ACF.MakeMissile(owner, point.Position,
                self:WorldToLocalAngles(direction:Angle()), self, point, self)
            if not IsValid(missile) then Report("Missile creation refused", self) return end
            local nativeDetonate = missile.Detonate
            if nativeDetonate then
                local source = self
                function missile:Detonate(destroyed)
                    Report("Detonation requested", source, {disabled = self.Disabled,
                        armed = self.FuzeData:IsArmed(), destroyed = destroyed,
                        filler = self.BulletData.FillerMass, motor = self.MotorEnabled})
                    return nativeDetonate(self, destroyed)
                end
            end
            missile.BulletData.Flight = direction
            missile.Filter[#missile.Filter + 1] = owner
            -- Native racks include their own loaded missile in Rack.Missiles.
            -- A handheld launcher's rack list is empty: explicitly ignore the
            -- flying missile itself or its trace can hit its own model.
            missile.Filter[#missile.Filter + 1] = missile
            missile.BulletData.Filter = missile.Filter
            if not self.InfantryAutonomous then
            local guidance = missile.GuidanceData
            -- Feed the native wire guidance from the player's aim directly.
            -- A held SWEP is not a Wire computer entity.
            -- Capture this instance, never the shared SWEP definition.
            local source = self
            function guidance:GetGuidance(entity)
                if not IsValid(owner) or not owner:Alive() or owner:GetActiveWeapon() ~= source
                    or not owner:KeyDown(IN_ATTACK2) then return {} end
                if self.WireSnapped then return {} end
                if not self:OnRange(entity) then self:SnapRope(entity) return {} end
                local start = owner:GetShootPos()
                local trace = util.TraceLine({start = start,
                    endpos = start + owner:GetAimVector() * 52488,
                    filter = {owner, source, entity}, mask = MASK_SHOT})
                return {TargetPos = trace.HitPos}
            end
            end
            if self.ACFType == "HE" then
                -- Keep native arming, impact/proximity detection, removal and motor
                -- shutdown; replace the synthetic missile-self prop hit with an
                -- explicit ACF explosion. Never create a second damaging bullet.
                function missile.FuzeData:HandleDetonation(entity, data)
                    if entity.InfantryHEExploded then return end
                    entity.InfantryHEExploded = true
                    local position = data.Pos or entity:GetPos()
                    local normal = entity.HitNormal
                    if normal then position = position + normal * 2 end
                    local filler = data.FillerMass or 0
                    local fragment = math.max((data.ProjMass or 0) - filler, 0.001)
                    if filler <= 0 then
                        ErrorNoHalt("[ACF Infantry] Stinger HE detonation has no filler.\n")
                        return
                    end
                    local info = ACF.Damage.Objects.DamageInfo(data.Owner, entity)
                    Report("HE damage call", entity, {filler = filler, fragment = fragment, position = position})
                    if ACFInfantryDiagnostics then ACFInfantryDiagnostics.Exploding = entity end
                    ACF.Damage.createExplosion(position, filler, fragment, {entity}, info)
                    if ACFInfantryDiagnostics then ACFInfantryDiagnostics.Exploding = nil end
                    Report("HE damage call completed", entity)
                    local effect = EffectData()
                    effect:SetOrigin(position)
                    effect:SetScale(1)
                    util.Effect("Explosion", effect, true, true)
                end
            end
            if ACFInfantryDiagnostics then
                local guidance = missile.GuidanceData
                local getGuidance = guidance.GetGuidance
                local source = self
                function guidance:GetGuidance(entity)
                    local result = getGuidance(self, entity)
                    if CurTime() >= (self.InfantryNextTrace or 0) then
                        self.InfantryNextTrace = CurTime() + 1
                        Report("Guidance tick", source, {target = result and result.TargetPos,
                            wireSnapped = self.WireSnapped, enabled = entity.UseGuidance,
                            speed = entity.ACF_Velocity and entity.ACF_Velocity:Length()})
                    end
                    return result
                end
            end
            missile:Launch()
            if self.OnInfantryMissileCreated then self:OnInfantryMissileCreated(missile) end
            Report("Missile launched", self, {
                projectile = missile.BulletData.ProjLength, propellant = missile.BulletData.PropLength,
                filler = missile.BulletData.FillerMass})
            self.LastFired = missile
            self:Recoil(self:GetPunch())
        end
        self:PostShot(1)
    end
    if CLIENT then
        local buildSelection = weapon.BuildWepSelectionText
        function weapon:BuildWepSelectionText()
            buildSelection(self)
            local data = self.Bullet
            self.DisplayText[#self.DisplayText + 1] = string.format(
                "Round: %.2f cm projectile / %.2f cm propellant", data.ProjLength or 0, data.PropLength or 0)
            self.DisplayText[#self.DisplayText + 1] = self.InfantryAutonomous and
                "Guidance: Infrared" or "Guidance: Wire (SACLOS)"
        end
        function weapon:DrawHUD()
            drawHUD(self)
            if ACFSwepsTheme and ACFSwepsTheme.VerticalHUD then return end
            local remaining = self:GetNW2Float("InfantryArmedAt", 0) - CurTime()
            local reload = self:GetNW2Float("InfantryReloadAt", 0) - CurTime()
            local label = reload > 0 and string.format("RELOADING %.1fs", reload)
                or remaining > 0 and string.format("ARMING %.1fs", remaining)
                or (self.InfantryAutonomous and "INFRARED | AIM AT TARGET AND FIRE" or "ARMED | HOLD AIM TO GUIDE")
            draw.SimpleText(label, "DermaDefaultBold", ScrW() / 2, ScrH() * 0.65,
                Color(70, 160, 230), TEXT_ALIGN_CENTER)
        end
    end
end
-- Movement caps are derived each tick; player speed settings and EPO are never overwritten.
local function Active(player)
    local weapon = player:GetActiveWeapon()
    if IsValid(weapon) and weapon.InfantryMissile and weapon.ArmingWalkMultiplier
        and weapon.ArmedSprintMultiplier then return weapon end
end
hook.Add("StartCommand", "ACFInfantryLauncherArming", function(player, command)
    local weapon = Active(player)
    if weapon and CurTime() < weapon:GetNW2Float("InfantryArmedAt", math.huge) then
        command:RemoveKey(IN_SPEED)
    end
end)
hook.Add("SetupMove", "ACFInfantryLauncherMovement", function(player, move)
    local weapon = Active(player)
    if not weapon or player:InVehicle() then return end
    local arming = CurTime() < weapon:GetNW2Float("InfantryArmedAt", math.huge)
    local cap = arming and player:GetWalkSpeed() * weapon.ArmingWalkMultiplier
        or move:KeyDown(IN_SPEED) and player:GetRunSpeed() * weapon.ArmedSprintMultiplier
        or nil
    if cap then
        move:SetMaxSpeed(math.min(move:GetMaxSpeed(), cap))
        move:SetMaxClientSpeed(math.min(move:GetMaxClientSpeed(), cap))
    end
end)
return M
