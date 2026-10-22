AddCSLuaFile()
if SERVER then AddCSLuaFile("acf_sweps/hud_theme.lua") end
if CLIENT and not ACFSwepsTheme then include("acf_sweps/hud_theme.lua") end
SWEP.Base = "weapon_base"
SWEP.PrintName = "ACF Grenade Base"
SWEP.Category = "ACF Infantry"
SWEP.Spawnable = false
SWEP.AdminOnly = false
SWEP.UseHands = false -- CSS viewmodels include their own arms.
SWEP.ViewModelFOV = 60
SWEP.HoldType = "grenade"
SWEP.Slot = 4
SWEP.DrawAmmo = false
SWEP.Caliber = 60
SWEP.IconOverride = "vgui/acf_sweps/red_blue_soldier_v2.png"
SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 101
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "ACFInfantrySmokeGrenade"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.ThrowSpeed = 650
SWEP.ThrowUpwardSpeed = 90
SWEP.FuseTime = 2
function SWEP:Initialize() self:SetHoldType(self.HoldType) end
function SWEP:Deploy()
    self:SendWeaponAnim(ACT_VM_DRAW)
    self:SetNextPrimaryFire(CurTime() + 0.6)
    self:SetNextSecondaryFire(CurTime() + 0.6)
    if SERVER then self:SetNW2Bool("GrenadePrimed", false) end
    return true
end
function SWEP:PrimeGrenade(drop)
    if self.ThrowAt or self:GetNW2Bool("GrenadePrimed", false) then return end
    if self:Clip1() <= 0 then self:Reload() return end
    if CLIENT and not IsFirstTimePredicted() then return end
    self:SendWeaponAnim(ACT_VM_PULLPIN)
    self:SetNextPrimaryFire(CurTime() + 0.8)
    self:SetNextSecondaryFire(CurTime() + 0.8)
    if SERVER then
        self.DropGrenade = drop
        self:SetNW2Bool("GrenadeDropMode", drop)
        self.ReadyAt = CurTime() + 0.8
        self:SetNW2Bool("GrenadePrimed", true)
    end
end
function SWEP:PrimaryAttack() self:PrimeGrenade(false) end
function SWEP:SecondaryAttack() self:PrimeGrenade(true) end
function SWEP:Reload()
    if CLIENT or self.ThrowAt or self:GetNW2Bool("GrenadePrimed", false) or self:Clip1() > 0 then return end
    local owner = self:GetOwner()
    if not IsValid(owner) or owner:GetAmmoCount(self.Primary.Ammo) <= 0 then return end
    owner:RemoveAmmo(1, self.Primary.Ammo)
    self:SetClip1(1)
    self:SendWeaponAnim(ACT_VM_DRAW)
    self:SetNextPrimaryFire(CurTime() + 0.6)
    self:SetNextSecondaryFire(CurTime() + 0.6)
end
function SWEP:ThrowGrenade(drop)
    local owner = self:GetOwner()
    if not IsValid(owner) or not owner:Alive() or owner:GetActiveWeapon() ~= self or self:Clip1() <= 0 then return end
    -- Keep grenade spam bounded without imposing a permanent inventory cap.
    local count = 0
    for _, entity in ipairs(ents.FindByClass("acf_infantry_grenade")) do
        if entity.Thrower == owner then count = count + 1 end
    end
    if count >= 6 then return end
    local direction = owner:GetAimVector()
    local start = owner:GetShootPos()
    local destination = start + direction * 22
    if drop then
        -- Spawn a clear hull just in front of the feet, independent of aim pitch.
        local forward = owner:GetForward()
        forward = Vector(forward.x, forward.y, 0):GetNormalized()
        start = owner:GetPos() + Vector(0, 0, 12)
        destination = owner:GetPos() + forward * 22 + Vector(0, 0, 8)
    end
    local trace = util.TraceHull({start = start, endpos = destination,
        mins = Vector(-3, -3, -3), maxs = Vector(3, 3, 3), filter = owner, mask = MASK_SOLID})
    if trace.StartSolid then return end
    local grenade = ents.Create("acf_infantry_grenade")
    if not IsValid(grenade) then return end
    grenade:SetPos(trace.HitPos)
    grenade:SetAngles(direction:Angle())
    grenade:SetOwner(owner)
    grenade.Thrower = owner
    grenade:SetNW2String("GrenadeKind", self.GrenadeKind)
    grenade.FuseTime = self.FuseTime
    grenade:Spawn()
    local physics = grenade:GetPhysicsObject()
    if not IsValid(physics) then grenade:Remove() return end
    if drop then
        physics:SetVelocity(owner:GetVelocity())
    else
        physics:SetVelocity(owner:GetVelocity() + direction * self.ThrowSpeed + Vector(0, 0, self.ThrowUpwardSpeed))
    end
    physics:AddAngleVelocity(VectorRand() * 400)
    self:TakePrimaryAmmo(1)
    owner:SetAnimation(PLAYER_ATTACK1)
end
function SWEP:Think()
    if CLIENT then return end
    local owner = self:GetOwner()
    if not IsValid(owner) or not owner:Alive() then
        self:SetNW2Bool("GrenadePrimed", false) self.ThrowAt = nil return
    end
    local now = CurTime()
    if self:GetNW2Bool("GrenadePrimed", false) and now >= (self.ReadyAt or now)
        and (self.DropGrenade or not owner:KeyDown(IN_ATTACK)) then
        self:SetNW2Bool("GrenadePrimed", false)
        self:SendWeaponAnim(ACT_VM_THROW)
        self.ThrowAt = now + 0.2
        self:SetNextPrimaryFire(now + 1.2)
        self:SetNextSecondaryFire(now + 1.2)
    end
    if self.ThrowAt and now >= self.ThrowAt then
        self.ThrowAt = nil
        self:ThrowGrenade(self.DropGrenade)
        self.DropGrenade = nil
        self:SetNW2Bool("GrenadeDropMode", false)
        self.DrawAt = now + 0.7
    end
    if self.DrawAt and now >= self.DrawAt then
        self.DrawAt = nil
        if self:Clip1() == 0 then self:Reload() else self:SendWeaponAnim(ACT_VM_DRAW) end
    end
end
function SWEP:Holster()
    if self.ThrowAt then return false end
    if SERVER then self:SetNW2Bool("GrenadePrimed", false) end
    return true
end
function SWEP:OnDrop() self.ThrowAt = nil self:SetNW2Bool("GrenadePrimed", false) end
function SWEP:BuildWepSelectionText()
    local descriptions = {venom = "15 second cloud; 250 unit radius; 8 HP/second; no movement effect", smoke = "30 second smoke cloud; visual only, no ignition or damage",
        fire = "15 second continuous fire area; 250 unit reach; 15 HP/second before armor",
        gas = "15 second gas cloud; 250 unit radius; 3 HP/second and reversed WASD while exposed"}
    self.DisplayText = {tostring(self.FuseTime) .. " second fuse after throwing", descriptions[self.GrenadeKind], "CSS models and throwing animations"}
    self.ControlText = {"Hold primary: pull pin", "Release primary: throw", "Right click: pull pin and drop at feet", "Reload: ready another grenade"}
end
if CLIENT then
    function SWEP:DrawHUD()
        if ACFSwepsTheme and ACFSwepsTheme.VerticalHUD then return end
        local T = ACFSwepsTheme
        local scale = math.Clamp(ScrH() / 1080, 0.65, 2)
        local w, h = 300 * scale, 100 * scale
        local x, y = ScrW() - w - 28 * scale, ScrH() - h - 28 * scale
        T.Panel(nil, x, y, w, h)
        T.Text(self.PrintName, "DermaLarge", x + 14 * scale, y + 10 * scale)
        T.Row("GRENADES", self:Clip1() + self:Ammo1(), x + 12 * scale, y + 52 * scale, w - 24 * scale, scale)
        if self:GetNW2Bool("GrenadePrimed", false) then
            draw.SimpleText("RELEASE TO THROW", "DermaDefaultBold", ScrW()/2, ScrH()*0.65,
                T.Color("COLOR_WARNING_TEXT"), TEXT_ALIGN_CENTER)
        end
    end
end
