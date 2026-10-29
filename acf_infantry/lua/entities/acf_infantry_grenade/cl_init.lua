include("shared.lua")
-- Reuse the flame/ember materials used by VSS ACF's explosion effect.
function ENT:Draw()
    if not self:GetNW2Bool("Burning", false) then self:DrawModel() end
end
function ENT:Think()
    if not self:GetNW2Bool("Burning", false) then return end
    if CurTime() >= self:GetNW2Float("BurnUntil", 0) then
        self:StopSound("ambient/fire/fire_small_loop1.wav")
        return
    end
    if CurTime() < (self.NextFlames or 0) then return end
    self.NextFlames = CurTime() + 0.05
    self.NextPatchFlames = self.NextPatchFlames or {}
    local viewer = LocalPlayer()
    if not IsValid(viewer) or viewer:GetPos():DistToSqr(self:GetPos()) > 2500 ^ 2 then return end
    if not self.FireEmitter then self.FireEmitter = ParticleEmitter(self:GetPos()) end
    local emitter = self.FireEmitter
    if not emitter then return end
    local started = self:GetNW2Float("FireStarted", math.huge)
    for i = 1, self:GetNW2Int("FirePointCount", 0) do
        local active = CurTime() >= started + self:GetNW2Float("FirePointDelay" .. i, 0)
        if active and CurTime() >= (self.NextPatchFlames[i] or 0) then
            self.NextPatchFlames[i] = CurTime() + math.Rand(0.08, 0.2)
            local point = self:GetNW2Vector("FirePoint" .. i)
            local origin = point + Vector(math.Rand(-40, 40), math.Rand(-40, 40), 0)
            if origin:DistToSqr(self:GetPos()) > self.FireReach ^ 2 then origin = point end
            local flame = emitter:Add("particles/flamelet" .. math.random(1, 5), origin)
            if flame then
                local lifetime = math.Rand(0.45, 0.85)
                local lateral = Vector(math.Rand(-12, 12), math.Rand(-12, 12), 0)
                if (origin + lateral * lifetime):DistToSqr(self:GetPos()) > self.FireReach ^ 2 then lateral = Vector() end
                flame:SetVelocity(lateral + Vector(0, 0, math.Rand(45, 90)))
                flame:SetDieTime(lifetime)
                flame:SetStartAlpha(math.Rand(210, 245)) flame:SetEndAlpha(0)
                flame:SetStartSize(math.Rand(18, 28)) flame:SetEndSize(math.Rand(2, 5))
                flame:SetRoll(math.Rand(0, 360)) flame:SetColor(255, math.random(160, 210), math.random(65, 100))
            end
        end
    end
end
function ENT:OnRemove()
    -- Stop entity audio locally too, including removal before the normal expiry.
    self:StopSound("ambient/fire/fire_small_loop1.wav")
    self:StopSound("ambient/gas/steam2.wav")
    if self.FireEmitter then self.FireEmitter:Finish() self.FireEmitter = nil end
end
