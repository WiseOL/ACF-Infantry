if SERVER then AddCSLuaFile() end
local M = {}

-- These viewmodels use Insurgency's L/R arm bones, not ValveBiped hands.
function M.Apply(weapon)
    if not CLIENT then return end
    function weapon:RemoveInsurgencyHands()
        if IsValid(self.InsurgencyHands) then self.InsurgencyHands:Remove() end
        self.InsurgencyHands = nil
    end
    function weapon:ViewModelDrawn(vm)
        local owner = self:GetOwner()
        if not IsValid(owner) or owner ~= LocalPlayer() or owner:GetActiveWeapon() ~= self then return end
        if self.ShouldDrawViewModel and not self:ShouldDrawViewModel() then return end
        vm = IsValid(vm) and vm or owner:GetViewModel()
        if not IsValid(vm) then return end
        local hands = self.InsurgencyHands
        if IsValid(hands) and hands:GetParent() ~= vm then self:RemoveInsurgencyHands() hands = nil end
        if not IsValid(hands) then
            hands = ClientsideModel("models/weapons/insurgency/v_hands_ins_l.mdl", RENDERGROUP_VIEWMODEL)
            if not IsValid(hands) then return end
            self.InsurgencyHands = hands
            hands:SetNoDraw(true)
            hands:SetParent(vm)
            hands:SetLocalPos(Vector())
            hands:SetLocalAngles(Angle())
            hands:AddEffects(EF_BONEMERGE)
        end
        hands:SetupBones()
        hands:DrawModel()
    end
    local holster, remove, drop = weapon.Holster, weapon.OnRemove, weapon.OnDrop
    function weapon:Holster(...)
        local callback = holster or (self.BaseClass and self.BaseClass.Holster)
        local result = callback and callback(self, ...)
        if result == false then return false end
        self:RemoveInsurgencyHands()
        return true
    end
    function weapon:OnRemove(...)
        self:RemoveInsurgencyHands()
        local callback = remove or (self.BaseClass and self.BaseClass.OnRemove)
        if callback then return callback(self, ...) end
    end
    function weapon:OnDrop(...)
        self:RemoveInsurgencyHands()
        local callback = drop or (self.BaseClass and self.BaseClass.OnDrop)
        if callback then return callback(self, ...) end
    end
end
return M
