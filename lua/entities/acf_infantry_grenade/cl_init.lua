include("shared.lua")
-- Reuse the flame/ember materials used by VSS ACF's explosion effect.
function ENT:Draw()
    if not self:GetNW2Bool("Burning", false) then self:DrawModel() end
end
function ENT:Think()
    if not self:GetNW2Bool("Burning", false) then return end
    if CurTime() >= self:GetNW2Float("BurnUntil", 0) then return end
    if CurTime() < (self.NextFlames or 0) then return end
    self.NextFlames = CurTime() + 0.12
    local viewer = LocalPlayer()
    if not IsValid(viewer) or viewer:GetPos():DistToSqr(self:GetPos()) > 2500 ^ 2 then return end
    if not self.FireEmitter then self.FireEmitter = ParticleEmitter(self:GetPos()) end
    local emitter = self.FireEmitter
    if not emitter then return end
    for i = 1, self:GetNW2Int("FirePointCount", 0) do
        local point = self:GetNW2Vector("FirePoint" .. i)
        local origin = point + Vector(math.Rand(-40, 40), math.Rand(-40, 40), 0)
        -- Keep flame visuals inside the same outer limit as damage.
        if origin:DistToSqr(self:GetPos()) > self.FireReach ^ 2 then origin = point end
        local flame = emitter:Add("particles/flamelet" .. math.random(1, 5), origin)
        if flame then
            flame:SetVelocity(Vector(0, 0, math.Rand(50, 85)))
            flame:SetDieTime(0.6) flame:SetStartAlpha(240) flame:SetEndAlpha(0)
            flame:SetStartSize(math.Rand(18, 25)) flame:SetEndSize(3)
            flame:SetRoll(math.Rand(0, 360)) flame:SetColor(255, 190, 95)
        end
    end
end
function ENT:OnRemove()
    if self.FireEmitter then self.FireEmitter:Finish() self.FireEmitter = nil end
end
