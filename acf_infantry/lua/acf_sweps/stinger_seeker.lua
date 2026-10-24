-- FIM-92 presentation/seeker adapted from ACF-Team/ACF-3-SWEPs b52ea0c.
-- Keeps ACF Infantry's VSS ammunition conversion, launch and damage path.
if SERVER then AddCSLuaFile() end
local M = {}
local function Position(target)
    return target.ACF_Position or target:WorldSpaceCenter()
end
function M.FindTarget(owner, pos, dir, cone, current)
    if not ACF or not ACF.GetEntitiesInCone then return end
    local standing = owner:InVehicle() and owner:GetVehicle() or owner:GetGroundEntity()
    local contraption = IsValid(standing) and standing.CFW_GetContraption and standing:CFW_GetContraption() or nil
    local best, bestDot
    local cosine = math.cos(math.rad(cone))
    for target in pairs(ACF.GetEntitiesInCone(pos, dir, cone, contraption)) do
        if IsValid(target) and target ~= owner and target.ACF_Position then
            local point = Position(target)
            local delta = point - pos
            if delta:LengthSqr() >= 38750 then
                local dot = delta:GetNormalized():Dot(dir)
                if dot >= cosine then
                    local trace = util.TraceLine({start = pos, endpos = point, mask = MASK_SOLID_BRUSHONLY})
                    if not trace.Hit then
                        if target == current then return target end
                        if not bestDot or dot > bestDot then best, bestDot = target, dot end
                    end
                end
            end
        end
    end
    return best
end
function M.Apply(weapon)
    weapon.InfantryLockRequired = true
    weapon.LockTime = 2
    weapon.SeekInterval = 0.1
    function weapon:GetSeekTarget() return self:GetNW2Entity("InfantrySeekTarget") end
    function weapon:GetSeekStart() return self:GetNW2Float("InfantrySeekStart", 0) end
    function weapon:IsSeeking() return self:GetSeekStart() > 0 end
    function weapon:IsLocked() return self:IsSeeking() and CurTime() - self:GetSeekStart() >= self.LockTime end
    function weapon:ClearSeeker()
        if SERVER then
            self:SetNW2Entity("InfantrySeekTarget", NULL)
            self:SetNW2Float("InfantrySeekStart", 0)
        end
    end
    function weapon:UpdateSeeker()
        local owner = self:GetOwner()
        if not IsValid(owner) or not owner:Alive() or owner:GetActiveWeapon() ~= self
            or not self:GetNWBool("iron", false) or self:Clip1() <= 0
            or self:GetNW2Float("InfantryReloadAt", 0) > 0
            or self:GetNW2Bool("ACFInfantrySafety", false) then
            self:ClearSeeker()
            return
        end
        if CurTime() < (self.InfantryNextSeek or 0) then return end
        self.InfantryNextSeek = CurTime() + self.SeekInterval
        local class = ACF and ACF.Classes and ACF.Classes.GetTypeByName(self.InfantryMissileClass)
        if not class or not class.SeekCone then self:ClearSeeker() return end
        local target = M.FindTarget(owner, owner:GetShootPos(), owner:GetAimVector(), class.SeekCone, self:GetSeekTarget())
        if not IsValid(target) then self:ClearSeeker() return end
        self:SetNW2Vector("InfantrySeekPos", Position(target))
        if target ~= self:GetSeekTarget() then
            self:SetNW2Entity("InfantrySeekTarget", target)
            self:SetNW2Float("InfantrySeekStart", CurTime())
        end
    end
    -- Invoked after native Launch configures guidance, without changing the payload.
    function weapon:OnInfantryMissileCreated(missile)
        if IsValid(missile) and self:IsLocked() and missile.GuidanceData then missile.GuidanceData.Target = self:GetSeekTarget() end
    end
    local think, primary, reload = weapon.Think, weapon.PrimaryAttack, weapon.Reload
    local holster, remove, deploy = weapon.Holster, weapon.OnRemove, weapon.Deploy
    function weapon:Think()
        think(self)
        if SERVER then self:UpdateSeeker() end
    end
    function weapon:PrimaryAttack()
        if self:Clip1() <= 0 then return primary(self) end
        if SERVER then
            self.InfantryNextSeek = 0
            self:UpdateSeeker() -- recheck visibility/target validity at trigger time
        end
        -- Server has the authoritative lock. No ammo or missile is spent on a rejected shot.
        if not self:IsLocked() then
            if SERVER then
                self:SetNW2Float("InfantryNoLockAt", CurTime())
                self:EmitSound("buttons/button10.wav", 60)
            end
            self:SetNextPrimaryFire(CurTime() + 0.25)
            return
        end
        local result = primary(self)
        if SERVER and self:Clip1() <= 0 then self:ClearSeeker() end
        return result
    end
    function weapon:Reload()
        local result = reload(self)
        if SERVER and self:GetNW2Float("InfantryReloadAt", 0) > 0 then self:ClearSeeker() end
        return result
    end
    function weapon:Deploy()
        self:ClearSeeker()
        self.InfantryNextSeek = 0
        return deploy(self)
    end
    function weapon:Holster()
        local result = holster(self)
        if result ~= false then
            self:ClearSeeker()
            if CLIENT then self:StopSeekerTone() end
        end
        return result
    end
    function weapon:OnRemove()
        if CLIENT then self:StopSeekerTone() end
        if remove then return remove(self) end
    end
    if SERVER then return end
    function weapon:StopSeekerTone() if self.SeekerTone then self.SeekerTone:Stop() end end
    function weapon:UpdateSeekerTone()
        if not self:IsSeeking() then self:StopSeekerTone() return end
        if not self.SeekerTone then self.SeekerTone = CreateSound(self, "Weapon_FIM92.Seeker") end
        if not self.SeekerTone:IsPlaying() then self.SeekerTone:Play() end
        self.SeekerTone:ChangePitch(self:IsLocked() and 170 or 100, 0.1)
    end
    local drawHUD = weapon.DrawHUD
    function weapon:DrawHUD()
        drawHUD(self) -- Keep Infantry's scope and vertical ammo/status UI.
        local scale = math.Clamp(ScrH() / 1080, 0.65, 1.5)
        local blue, red = Color(112, 191, 243), Color(255, 70, 70)
        local noLock = self:GetNW2Float("InfantryNoLockAt", -10)
        if CurTime() - noLock < 1 and CurTime() % 0.25 < 0.125 then
            draw.SimpleTextOutlined("NO LOCK", "DermaDefaultBold", ScrW() / 2,
                ScrH() / 2 + 48 * scale, red, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, color_black)
        end
        if not self:IsSeeking() then return end
        local locked = self:IsLocked()
        if not locked and CurTime() % 0.25 > 0.125 then return end
        local target = self:GetSeekTarget()
        local point = (IsValid(target) and Position(target) or self:GetNW2Vector("InfantrySeekPos")):ToScreen()
        if not point.visible then return end
        local size, color = 24 * scale, locked and red or blue
        surface.SetDrawColor(color)
        surface.DrawOutlinedRect(point.x - size, point.y - size, size * 2, size * 2, 2)
        draw.SimpleTextOutlined(locked and "LOCK" or "ACQUIRING", "DermaDefaultBold",
            point.x, point.y + size + 4, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, color_black)
    end
    -- Upstream ADS offsets, eased sight transition and reduced sight sway, scoped to this weapon.
    function weapon:TranslateFOV(fov)
        local owner = self:GetOwner()
        local delta = math.Clamp(RealTime() - (self.RateTime or 0), 0, 0.1)
        local sprint = owner:IsSprinting() and owner:GetAbsVelocity():LengthSqr() > 10000
        self.SprintScale = math.Approach(self.SprintScale or 0, sprint and 1 or 0, delta * 7)
        local aimed = self:GetNWBool("iron", false) and not self.Reloading
            and self:GetNW2Float("InfantryReloadAt", 0) <= 0 and not self.TempOut
        self.IronScale = math.Approach(self.IronScale or 0, aimed and 1 - self.SprintScale or 0, delta / 0.25)
        self.RateTime = RealTime()
        if owner:KeyDown(IN_ZOOM) then return fov end
        local amount = math.Clamp((self.IronScale - 0.75) / 0.25, 0, 1)
        return Lerp(amount, fov, fov / self.Zoom)
    end
    function weapon:GetViewModelPosition(pos, ang)
        local up, right, forward = ang:Up(), ang:Right(), ang:Forward()
        local amount = math.Clamp((self.IronScale or 0) / 0.75, 0, 1)
        amount = amount < 0.5 and 2 * amount * amount or 1 - (-2 * amount + 2) ^ 2 / 2
        local sprint = self.SprintScale or 0
        ang:RotateAroundAxis(right, self.SprintAng.x * sprint + self.IronSightAng.x * amount)
        ang:RotateAroundAxis(up, self.SprintAng.y * sprint + self.IronSightAng.y * amount)
        ang:RotateAroundAxis(forward, self.SprintAng.z * sprint + self.IronSightAng.z * amount)
        self.SwayScale = Lerp(amount * (1 - sprint), 1, 0.05)
        self.BobScale = self.SwayScale
        local shift = self.IronSightPos * amount + self.IdlePos * (1 - amount)
        return pos + right * shift.x + forward * shift.y + up * shift.z, ang
    end
end
if CLIENT then
    local previous
    hook.Add("Think", "ACFInfantryStingerTone", function()
        local owner = LocalPlayer()
        local weapon = IsValid(owner) and owner:Alive() and owner:GetActiveWeapon() or nil
        if not (IsValid(weapon) and weapon.InfantryLockRequired) then weapon = nil end
        if previous ~= weapon and IsValid(previous) then previous:StopSeekerTone() end
        previous = weapon
        if weapon then weapon:UpdateSeekerTone() end
    end)
end
return M
