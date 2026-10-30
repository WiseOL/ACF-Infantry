if SERVER then AddCSLuaFile() end
local Anim = include("acf_sweps/named_animation.lua")
local Hands = include("acf_sweps/insurgency_hands.lua")
local M = {}

function M.Apply(weapon)
    local think, reload = weapon.Think, weapon.Reload
    function weapon:Reload()
        -- Predict visibility immediately, without waiting for the server's
        -- reload deadline. Server ammo/timing validation stays authoritative.
        if CLIENT and self:Clip1() < 1 and self:Ammo1() > 0
            and self:GetNW2Float("InfantryReloadAt", 0) == 0
            and CurTime() >= (self.AT4ReloadHideUntil or 0) then
            self.AT4ReloadHideUntil = CurTime() + self.LauncherReloadTime - 1
        end
        return reload(self)
    end
    function weapon:SendWeaponAnim(activity)
        local names = {
            [ACT_VM_IDLE] = "base_idle",
            [ACT_VM_DRAW] = "base_ready",
            [ACT_VM_PRIMARYATTACK] = self:GetNWBool("iron", false) and "base_iron_fire" or "base_fire",
            [ACT_VM_RELOAD] = "base_toss",
        }
        local name = names[activity]
        -- The toss is 41 frames at 31 fps. Do not stretch it over the
        -- entire ammo reload; the draw occupies the final part of that window.
        if name then Anim.PlayOwner(self, name, activity == ACT_VM_RELOAD and (40 / 31) or 0) end
    end
    function weapon:Think()
        local finish = self:GetNW2Float("InfantryReloadAt", 0)
        think(self)
        -- Start exactly one replacement draw at one second remaining.
        -- Fit its natural ~0.97-second animation into that final second.
        local drawDuration = 1
        if SERVER and finish > 0 and self.AT4ReloadDrawDeadline ~= finish
            and CurTime() >= finish - drawDuration then
            self.AT4ReloadDrawDeadline = finish
            Anim.PlayOwner(self, "base_draw", drawDuration)
        end
        -- Keep the completed non-looping toss pose during the middle of the
        -- reload. An idle reset would snap the discarded tube back on screen.
        if self:GetNW2Float("InfantryReloadAt", 0) == 0 then
            Anim.Idle(self, "base_idle")
        end
    end
    if CLIENT then
        function weapon:ShouldDrawViewModel()
            if CurTime() < (self.AT4ReloadHideUntil or 0) then return false end
            local finish = self:GetNW2Float("InfantryReloadAt", 0)
            return finish == 0 or finish - CurTime() <= 1
        end
        function weapon:PreDrawViewModel()
            if not self:ShouldDrawViewModel() then return true end
        end
        function weapon:GetViewModelPosition(pos, ang)
            local amount = math.Clamp((self.IronScale or 0) / 0.75, 0, 1)
            local owner = self:GetOwner()
            local aiming = self:GetNWBool("iron", false)
                and self:GetNW2Float("InfantryReloadAt", 0) == 0
            -- Copy the angle: don't rotate the engine's incoming view angle.
            ang = Angle(ang.p, ang.y, ang.r)
            if not aiming and IsValid(owner) and owner:IsSprinting() then
                local sprint = math.Clamp(self.SprintScale or 0, 0, 1)
                ang:RotateAroundAxis(ang:Right(), self.SprintAng.p * sprint)
                ang:RotateAroundAxis(ang:Up(), self.SprintAng.y * sprint)
                ang:RotateAroundAxis(ang:Forward(), self.SprintAng.r * sprint)
            end
            -- Keep translations in the incoming camera basis. Rotating the
            -- basis first made the previous left/up correction enter the tube.
            local right, forward, up = ang:Right(), ang:Forward(), ang:Up()
            local offset, rotation = self.IronSightPos, self.IronSightAng
            ang:RotateAroundAxis(ang:Right(), rotation.p * amount)
            ang:RotateAroundAxis(ang:Up(), rotation.y * amount)
            ang:RotateAroundAxis(ang:Forward(), rotation.r * amount)
            pos = pos + right * (offset.x * amount)
                + forward * (offset.y * amount) + up * (offset.z * amount)
            return pos, ang
        end
        function weapon:DrawHUD()
            if ACFSwepsTheme and ACFSwepsTheme.DrawVerticalHUD then
                ACFSwepsTheme.DrawVerticalHUD()
            end
        end
    end
    Hands.Apply(weapon)
end
return M
