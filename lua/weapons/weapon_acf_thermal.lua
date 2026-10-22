if SERVER then AddCSLuaFile("acf_sweps/hud_theme.lua") end
if CLIENT and not ACFSwepsTheme then include("acf_sweps/hud_theme.lua") end
AddCSLuaFile()
SWEP.Base = "weapon_base"
SWEP.PrintName = "ACF Thermal Goggles"
SWEP.IconOverride = "vgui/acf_sweps/thermal_goggles_logo_v2.png"
SWEP.ACFMenuImage = "vgui/acf_sweps/thermal_goggles_logo_v2.png"
if SERVER then resource.AddFile("materials/vgui/acf_sweps/thermal_goggles_logo_v2.png") end
SWEP.Category = "ACF Infantry"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.ViewModel = "models/weapons/c_arms.mdl"
SWEP.WorldModel = ""
SWEP.UseHands = false
SWEP.DrawViewModel = false
SWEP.HoldType = "normal"
SWEP.Slot = 5
SWEP.SlotPos = 3
SWEP.DrawAmmo = false
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.Instructions = "Left click or N: toggle Wiremod thermal vision. Requires Wiremod."
function SWEP:BuildWepSelectionText()
    self.DisplayText = { "Wiremod FLIR thermal vision", "Left click / N: toggle", "Requires Wiremod" }
    self.ControlText = { "Left click / N: toggle thermal" }
end
function SWEP:Initialize() self:SetHoldType(self.HoldType) end
function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 0.3)
    if SERVER and ACFWireThermalToggle then ACFWireThermalToggle(self:GetOwner()) end
end
function SWEP:Holster() return true end
function SWEP:OnDrop()
    if SERVER then self:SetNWBool("ThermalEnabled", false) end
end
function SWEP:SecondaryAttack() end
function SWEP:Reload() end
if CLIENT then
    -- No carried, dropped, or translucent world model for this wearable utility.
    function SWEP:DrawWorldModel() end
    function SWEP:DrawWorldModelTranslucent() end
    function SWEP:ShouldDrawViewModel() return false end
    function SWEP:DrawHUD()
        if ACFSwepsTheme and ACFSwepsTheme.VerticalHUD then return end
        local available = FLIR and isfunction(FLIR.enable)
        local active = self:GetNWBool("ThermalEnabled", false)
        local text = not available and "WIREMOD REQUIRED" or (active and "THERMAL ON" or "THERMAL OFF")
        local x, y = ScrW() - 290, ScrH() - 110
        ACFSwepsTheme.Panel(8, x, y, 270, 90, Color(15, 18, 24, 225))
        ACFSwepsTheme.Text(text, "DermaLarge", x + 12, y + 12, active and ACFSwepsTheme.Color("COLOR_PRIMARY_COLOR") or ACFSwepsTheme.Color("COLOR_TEXT"))
        ACFSwepsTheme.Text("LEFT CLICK / N TO TOGGLE", "DermaDefaultBold", x + 12, y + 55, ACFSwepsTheme.Color("COLOR_TEXT"))
    end
end

SWEP.SubCategory = "Utility"
