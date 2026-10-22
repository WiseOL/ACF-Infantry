if SERVER then AddCSLuaFile("acf_sweps/hud_theme.lua") end
if CLIENT and not ACFSwepsTheme then include("acf_sweps/hud_theme.lua") end
AddCSLuaFile()

SWEP.Base = "weapon_base"
SWEP.PrintName = "ACF Suit Armor"
SWEP.Author = "ACF server customization"
SWEP.Category = "ACF Infantry"
SWEP.Instructions = "Left click: Add 25 suit armor, up to 200. Eight successful uses per item."
SWEP.Purpose = "Adds 25 suit armor per use, capped at 200."
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.UseHands = false
SWEP.ViewModel = "models/items/battery.mdl"
SWEP.ViewModelFOV = 60
SWEP.WorldModel = "models/items/battery.mdl"
SWEP.IconOverride = "entities/item_battery.png"
SWEP.HoldType = "slam"
SWEP.Slot = 5
SWEP.SlotPos = 0
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.DisableDuplicator = true

-- The pack's spawn-menu tooltip invokes this for every weapon in its category.
function SWEP:BuildWepSelectionText()
    self.DisplayText = { "Armor: +25 per use (max 200)", "Eight uses per item" }
    self.ControlText = { "Left click: Apply armor" }
end

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
    if SERVER then self:SetNWInt("ArmorUsesLeft", 8) end
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 0.85)
    if CLIENT then return end
    local owner = self:GetOwner()
    if not IsValid(owner) or not owner:IsPlayer() or not owner:Alive() then return end
    local usesLeft = self:GetNWInt("ArmorUsesLeft", 8)
    if usesLeft <= 0 then return end
    if owner:Armor() >= 200 then

        return
    end
    self:SetNWFloat("ArmorUseStart", CurTime())
    owner:SetAnimation(PLAYER_ATTACK1)
    usesLeft = usesLeft - 1
    self:SetNWInt("ArmorUsesLeft", usesLeft)
    owner:SetArmor(math.min(owner:Armor() + 25, 200))
    owner:EmitSound("ItemBattery.Touch")

    if usesLeft == 0 then
        timer.Simple(0.85, function() if IsValid(self) then self:Remove() end end)
    end
end

function SWEP:SecondaryAttack() end
function SWEP:Reload() end

function SWEP:Holster()
    return CurTime() >= self:GetNWFloat("ArmorUseStart", -1) + 0.85
end


if CLIENT then
    -- Uses the same HEV battery asset as the world model and Q-menu preview.
    function SWEP:DrawHUD()
        if ACFSwepsTheme and ACFSwepsTheme.VerticalHUD then return end
        local uiScale = math.Clamp(ScrH() / 1080, 0.75, 1.5)
        local uiW, uiH = 240 * uiScale, 76 * uiScale
        local uiX, uiY = ScrW() - uiW - 20 * uiScale, ScrH() - 190 * uiScale
        ACFSwepsTheme.Panel(8, uiX, uiY, uiW, uiH, Color(15, 18, 24, 220))
        ACFSwepsTheme.Text("SUIT ARMOR", "DermaLarge",
            uiX + 12 * uiScale, uiY + 9 * uiScale, Color(70, 150, 255))
        ACFSwepsTheme.Text("+25 ARMOR PER USE", "DermaDefaultBold",
            uiX + 12 * uiScale, uiY + 48 * uiScale, ACFSwepsTheme.Color("COLOR_PRIMARY_COLOR"))
    end

end

-- Render the battery itself at its native scale; no SLAM rig or hand entities.
function SWEP:Deploy()
    self:SetHoldType(self.HoldType)
    local owner = self:GetOwner()
    local viewmodel = IsValid(owner) and owner:GetViewModel()
    if IsValid(viewmodel) then viewmodel:SetModelScale(1, 0) end
    return true
end

if CLIENT then
    -- Draw a bounds-aligned plate instead of putting a full-size prop against
    -- the viewmodel camera. Also handles servers that replace the HEV battery.
    function SWEP:PreDrawViewModel(vm)
        vm:SetMaterial("engine/occlusionproxy")
    end
    function SWEP:PostDrawViewModel(vm)
        vm:SetMaterial("")
    end
    function SWEP:ViewModelDrawn(vm)
        if not IsValid(self.ArmorDisplayModel) then
            self.ArmorDisplayModel = ClientsideModel(self.WorldModel, RENDERGROUP_OPAQUE)
            if IsValid(self.ArmorDisplayModel) then self.ArmorDisplayModel:SetNoDraw(true) end
        end
        local model = self.ArmorDisplayModel
        if not IsValid(model) then return end
        local minimum, maximum = model:GetModelBounds()
        local size = maximum - minimum
        local dimensions = {size.x, size.y, size.z}
        local thin, tall = 1, 1
        for i = 2, 3 do
            if dimensions[i] < dimensions[thin] then thin = i end
            if dimensions[i] > dimensions[tall] then tall = i end
        end
        if thin == tall then thin, tall = 1, 3 end
        local view = EyeAngles()
        local axes = {}
        axes[thin] = -view:Forward()
        axes[tall] = view:Up()
        if not axes[1] then axes[1] = axes[2]:Cross(axes[3])
        elseif not axes[2] then axes[2] = axes[3]:Cross(axes[1])
        else axes[3] = axes[1]:Cross(axes[2]) end
        local rotation = axes[1]:AngleEx(axes[3])
        local scale = math.min(1, 16 / math.max(dimensions[tall], 0.01))
        local progress = math.Clamp((CurTime() - self:GetNWFloat("ArmorUseStart", -10)) / 0.85, 0, 1)
        local motion = math.sin(progress * math.pi)
        local center = EyePos() + view:Forward() * (34 - motion * 6)
            + view:Right() * 11 - view:Up() * (10 - motion * 5)
        local offset = LocalToWorld((minimum + maximum) * (0.5 * scale), Angle(), Vector(), rotation)
        model:SetModelScale(scale, 0)
        model:SetPos(center - offset)
        model:SetAngles(rotation)
        model:SetupBones()
        model:DrawModel()
    end
    function SWEP:OnRemove()
        if IsValid(self.ArmorDisplayModel) then self.ArmorDisplayModel:Remove() end
    end
end

SWEP.SubCategory = "Utility"
