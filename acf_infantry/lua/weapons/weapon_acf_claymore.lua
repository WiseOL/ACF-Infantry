AddCSLuaFile()
SWEP.Base = "weapon_acf_deployable_base"
SWEP.PrintName = "ACF Claymore"
SWEP.Category = "ACF Infantry"
SWEP.SubCategory = "Throwables and Deployables"
SWEP.Spawnable = true
SWEP.DeployableKind = "claymore"
SWEP.MaxDeployed = 8
SWEP.ViewModel = "models/hoff/weapons/claymore/c_claymore.mdl"
SWEP.WorldModel = "models/hoff/weapons/claymore/w_claymore.mdl"
SWEP.IconOverride = "vgui/acf_sweps/claymore_bo1.png"
SWEP.ACFMenuImage = "vgui/acf_sweps/claymore_bo1.png"
SWEP.ACFMenuImageScale = 0.75 -- Proportional, centered preview matching other equipment icons.
SWEP.Primary.Ammo = "ACFInfantryClaymore"
SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 101
SWEP.Primary.Automatic = false
SWEP.UseHands = true
SWEP.ViewModelFOV = 70
SWEP.DeploySound = "hoff/mpl/seal_claymore/ammo.wav"
SWEP.DeployableSequences = {draw = "pullout", drawbackhigh = "throw", idle = "idle", empty = "idle"}

if CLIENT then
    function SWEP:DrawWorldModel()
        local owner = self:GetOwner()
        if IsValid(owner) then
            local bone = owner:LookupBone("ValveBiped.Bip01_R_Hand")
            if bone then
                local pos, ang = owner:GetBonePosition(bone)
                if pos and ang then
                    pos = pos + ang:Right() * 8 + ang:Forward() * 3.5 + ang:Up() * 7
                    ang:RotateAroundAxis(ang:Right(), 180)
                    ang:RotateAroundAxis(ang:Up(), 90)
                    self:SetRenderOrigin(pos)
                    self:SetRenderAngles(ang)
                    self:DrawModel()
                    return
                end
            end
        end
        self:SetRenderOrigin(nil)
        self:SetRenderAngles(nil)
        self:DrawModel()
    end
end
