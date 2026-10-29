include("shared.lua")
local laser = Material("cable/redlaser")
function ENT:Draw()
    self:DrawModel()
    if self:GetNW2String("ExplosiveKind") ~= "claymore" or self:GetNoDraw()
        or CurTime() < self:GetNW2Float("ArmedAt", math.huge) then return end
    local origin = self:GetPos() + self:GetUp() * 11
    local front, right = -self:GetRight(), self:GetForward()
    render.SetMaterial(laser)
    for _, side in ipairs({-1, 1}) do
        local direction = (front + right * side * math.tan(math.rad(30))):GetNormalized()
        local trace = util.TraceLine({start = origin, endpos = origin + direction * self.ClaymoreRange,
            filter = self, mask = MASK_SHOT})
        render.DrawBeam(origin + right * side * 2.8, trace.HitPos, 0.7, 0, 1, Color(255, 70, 70))
    end
end
