if SERVER then AddCSLuaFile() end
local Anim = include("acf_sweps/named_animation.lua")
local M = {}

function M.Apply(weapon)
    local deploy, think, reload = weapon.Deploy, weapon.Think, weapon.Reload
    function weapon:SendWeaponAnim(activity)
        local empty = self:Clip1() <= 0
        local names = {
            [ACT_VM_IDLE] = empty and "idle_empty" or "idle",
            [ACT_VM_DRAW] = empty and "draw_empty" or "ready",
            [ACT_VM_PRIMARYATTACK] = "fire",
            [ACT_VM_RELOAD] = "reload",
        }
        local name = names[activity]
        if name then Anim.Play(self, name, activity == ACT_VM_RELOAD and self.LauncherReloadTime or 0) end
    end
    function weapon:Deploy()
        self.JavelinLastAim = false
        self.JavelinScopeAt = nil
        return deploy(self)
    end
    function weapon:Reload()
        local result = reload(self)
        if self:GetNW2Float("InfantryReloadAt", 0) > 0 then self:SetNWBool("iron", false) end
        return result
    end
    function weapon:Think()
        think(self)
        if SERVER then
            local aiming = self:GetNWBool("iron", false)
                and self:GetNW2Float("InfantryReloadAt", 0) == 0
            if aiming ~= self.JavelinLastAim then
                self.JavelinLastAim = aiming
                self:SetNW2Float("JavelinScopeAt", aiming and CurTime() + 0.75 or 0)
                if self:GetNW2Float("InfantryReloadAt", 0) == 0 then
                    Anim.Play(self, aiming and "iron_in" or "iron_out", aiming and 0.75 or 0.4)
                end
            end
        end
        Anim.Idle(self, self:Clip1() <= 0 and "idle_empty" or "idle")
    end

    if not CLIENT then return end
    function weapon:JavelinInScope()
        local at = self:GetNW2Float("JavelinScopeAt", 0)
        return at > 0 and CurTime() >= at and self:GetNWBool("iron", false)
            and self:GetNW2Float("InfantryReloadAt", 0) == 0
    end
    function weapon:JavelinReloading()
        return self:GetNW2Float("InfantryReloadAt", 0) > 0
    end
    function weapon:JavelinModelHidden()
        -- Hide from the start of aim, not only after the 0.75s overlay delay.
        -- Otherwise iron_in moves the scope housing through the camera.
        return self:JavelinReloading() or self:GetNWBool("iron", false)
    end
    function weapon:ShouldDrawViewModel()
        return not self:JavelinModelHidden()
    end
    function weapon:PreDrawViewModel()
        -- Covers aim entry, the scoped view and reload without global state.
        if self:JavelinModelHidden() then return true end
    end
    function weapon:TranslateFOV(fov)
        local owner = self:GetOwner()
        local at = self:GetNW2Float("JavelinScopeAt", 0)
        local target = at > 0 and self:GetNWBool("iron", false)
            and self:GetNW2Float("InfantryReloadAt", 0) == 0 and 1 or 0
        self.IronScale = math.Approach(self.IronScale or 0, target, FrameTime() / 0.75)
        self.SprintScale = 0
        if IsValid(owner) and owner:KeyDown(IN_ZOOM) then return fov end
        return Lerp(self.IronScale, fov, math.min(fov, 30))
    end
    function weapon:GetViewModelPosition(pos, ang)
        -- The donor's iron_in sequence supplies the sight motion itself.
        local owner = self:GetOwner()
        if IsValid(owner) and owner:IsSprinting() then
            ang:RotateAroundAxis(ang:Right(), -8.99)
            ang:RotateAroundAxis(ang:Forward(), -5.029)
            pos = pos - ang:Up() * 0.633
        end
        return pos, ang
    end
    local materials = {}
    local function Layer(name)
        materials[name] = materials[name] or Material("models/javelin/" .. name)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.SetMaterial(materials[name])
        surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
    end
    function weapon:DrawHUD()
        if self:JavelinInScope() then
            Layer("noise")
            Layer("overlay")
            Layer("day")
            Layer(self:Clip1() > 0 and "msl" or "nomsl")
            -- Retain SACLOS guidance: do not advertise a fake lock or top attack.
            Layer("dir")
            local x, y = ScrW() * 0.5, ScrH() * 0.5
            local color = ACFSwepsTheme and ACFSwepsTheme.Color("COLOR_PRIMARY_COLOR") or color_white
            surface.SetDrawColor(color)
            surface.DrawLine(x - 22, y, x - 7, y)
            surface.DrawLine(x + 7, y, x + 22, y)
            surface.DrawLine(x, y - 22, x, y - 7)
            surface.DrawLine(x, y + 7, x, y + 22)
            draw.SimpleText("WIRE SACLOS", "DermaDefaultBold", x, ScrH() * 0.76,
                color, TEXT_ALIGN_CENTER)
        end
        -- The global HUDPaint hook skips ACF guns: draw their panel here,
        -- after the scope mask, including when the launcher isn't aimed.
        if ACFSwepsTheme and ACFSwepsTheme.DrawVerticalHUD then
            ACFSwepsTheme.DrawVerticalHUD()
        end
    end
end
return M
