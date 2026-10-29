if SERVER then AddCSLuaFile() end

local M = {}

-- Applied only to the launchers that require a stable firing position.
function M.Apply(weapon)
    local primary = weapon.PrimaryAttack
    function weapon:PrimaryAttack()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        -- KeyDown also rejects jump + fire before movement clears OnGround.
        if not owner:OnGround() or (owner:IsPlayer() and owner:KeyDown(IN_JUMP)) then return end
        return primary(self)
    end
end

return M
