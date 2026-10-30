-- Server-only contact sweep for parented props without independent VPhysics.
if ACFInfantryC4Attachment then return ACFInfantryC4Attachment end
local M = {}
ACFInfantryC4Attachment = M
local tick, candidates = -1, {}
local function ParentedProps()
    local now = engine.TickCount()
    if now == tick then return candidates end
    tick, candidates = now, {}
    -- Parented non-solid props can be absent from physics/spatial traces.
    for _, pattern in ipairs({"prop_*", "acf_*"}) do
        for _, entity in ipairs(ents.FindByClass(pattern)) do
            if IsValid(entity) and IsValid(entity:GetParent()) and not entity:GetNoDraw()
                and entity:GetClass() ~= "acf_infantry_deployable" then
                candidates[#candidates + 1] = entity
            end
        end
    end
    return candidates
end
function M.Trace(start, finish, charge)
    local result = util.TraceLine({start = start, endpos = finish, mask = MASK_SOLID,
        filter = function(entity)
            return entity ~= charge and not entity:IsPlayer() and not entity:IsNPC() and not entity:IsNextBot()
        end})
    if result.StartSolid then return result end
    local delta = finish - start
    local fraction = result.Hit and result.Fraction or 1
    local mins = Vector(math.min(start.x, finish.x), math.min(start.y, finish.y), math.min(start.z, finish.z))
    local maxs = Vector(math.max(start.x, finish.x), math.max(start.y, finish.y), math.max(start.z, finish.z))
    for _, target in ipairs(ParentedProps()) do
        if IsValid(target) and target ~= charge and IsValid(target:GetParent()) then
            local low, high = target:WorldSpaceAABB()
            if high.x >= mins.x and low.x <= maxs.x and high.y >= mins.y and low.y <= maxs.y
                and high.z >= mins.z and low.z <= maxs.z then
                local position, normal, amount = util.IntersectRayWithOBB(start, delta,
                    target:GetPos(), target:GetAngles(), target:OBBMins(), target:OBBMaxs())
                if position and normal and amount >= 0 and amount <= fraction then
                    fraction = amount
                    result = {Hit = true, HitPos = position, HitNormal = normal, Entity = target,
                        Fraction = amount, StartSolid = false, HitSky = false}
                end
            end
        end
    end
    return result
end
return M
