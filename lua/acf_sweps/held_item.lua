-- Shared first-person hand rig for armor and medical items.
if SERVER then AddCSLuaFile() end
local function ResetViewModel(self)
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    local vm = owner:GetViewModel()
    if IsValid(vm) then vm:SetMaterial("") vm:SetPlaybackRate(1) end
end
function SWEP:Deploy()
    self:SetHoldType("slam")
    self:SendWeaponAnim(ACT_VM_DRAW)
    self.ItemIdleAt = CurTime() + 0.7
    return true
end
function SWEP:PlayItemUse()
    self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
    local owner = self:GetOwner()
    if IsValid(owner) then
        local vm = owner:GetViewModel()
        if IsValid(vm) then
            vm:SetPlaybackRate(math.max(vm:SequenceDuration(), 0.1) / 0.85)
        end
    end
    self.ItemIdleAt = CurTime() + 0.85
end
function SWEP:Think()
    if self.ItemIdleAt and CurTime() >= self.ItemIdleAt then
        self.ItemIdleAt = nil
        ResetViewModel(self)
        self:SendWeaponAnim(ACT_VM_IDLE)
    end
end
local OldHolster = SWEP.Holster
function SWEP:Holster(...)
    if OldHolster and OldHolster(self, ...) == false then return false end
    ResetViewModel(self)
    return true
end
function SWEP:OnRemove()
    ResetViewModel(self)
    if CLIENT and IsValid(self.HeldItemModel) then self.HeldItemModel:Remove() end
    if CLIENT and IsValid(self.HeldWorldItemModel) then self.HeldWorldItemModel:Remove() end
end
if SERVER then return end

function SWEP:ShouldDrawViewModel() return true end
-- The SLAM supplies the arm skeleton/animation; hide only its device mesh.
-- The separate gmod_hands entity remains visible through UseHands.
function SWEP:PreDrawViewModel(vm)
    vm:SetMaterial("engine/occlusionproxy")
end
function SWEP:PostDrawViewModel(vm)
    vm:SetMaterial("")
end
function SWEP:GetViewModelPosition(pos, ang)
    local started = self:GetNWFloat(self.ItemUseKey, -10)
    local progress = math.Clamp((CurTime()-started)/0.85,0,1)
    local motion = math.sin(progress*math.pi)
    pos = pos + ang:Forward()*(-motion*3) + ang:Up()*(motion*1.5)
    return pos,ang
end
-- Model origins differ (battery, kit and vial); align a point inside the
-- model's bounds to the palm rather than embedding its origin in the fingers.
local function HeldModel(self, field)
    local model = self[field]
    if IsValid(model) and model:GetModel() ~= string.lower(self.WorldModel) then
        model:Remove()
        model = nil
    end
    if not IsValid(model) then
        model = ClientsideModel(self.WorldModel, RENDERGROUP_OPAQUE)
        if not IsValid(model) then return end
        model:SetNoDraw(true)
        self[field] = model
    end
    return model
end
local function DrawInHand(self, model, matrix)
    local minimum, maximum = model:GetModelBounds()
    local size = maximum - minimum
    local scale = self.ItemModelScale or 0.45
    local longest = math.max(size.x, size.y, size.z, 0.01)
    scale = math.min(scale, (self.ItemMaxHeldSize or 7) / longest)
    model:SetModelScale(scale, 0)
    local grip = (minimum + maximum) * 0.5
    grip.z = grip.z - size.z * (self.ItemGripBelowCenter or 0)
    local palm, angle = LocalToWorld(self.ItemHandPos, self.ItemHandAng,
        matrix:GetTranslation(), matrix:GetAngles())
    local offset = LocalToWorld(grip * scale, Angle(), Vector(), angle)
    local origin = palm - offset
    model:SetPos(origin)
    model:SetAngles(angle)
    model:SetRenderOrigin(origin)
    model:SetRenderAngles(angle)
    model:SetupBones()
    model:DrawModel()
end
function SWEP:ViewModelDrawn(vm)
    if not IsValid(vm) then return end
    local bone = vm:LookupBone("ValveBiped.Bip01_R_Hand")
    if not bone then return end
    local matrix = vm:GetBoneMatrix(bone)
    if not matrix then return end
    local model = HeldModel(self, "HeldItemModel")
    if model then DrawInHand(self, model, matrix) end
end
function SWEP:DrawWorldModel()
    local owner = self:GetOwner()
    if not IsValid(owner) then self:DrawModel() return end
    local bone = owner:LookupBone("ValveBiped.Bip01_R_Hand")
    if not bone then self:DrawModel() return end
    local matrix = owner:GetBoneMatrix(bone)
    if not matrix then self:DrawModel() return end
    local model = HeldModel(self, "HeldWorldItemModel")
    if model then DrawInHand(self, model, matrix) end
end
