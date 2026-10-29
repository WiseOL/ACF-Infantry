if SERVER then AddCSLuaFile() end
if ACFInfantryNamedAnimation then return ACFInfantryNamedAnimation end
local M = {}
ACFInfantryNamedAnimation = M

local function LocalPlay(weapon, name, duration)
    local owner = weapon:GetOwner()
    if not IsValid(owner) then return end
    local vm = owner:GetViewModel()
    if not IsValid(vm) then return end
    local sequence = vm:LookupSequence(name)
    if not sequence or sequence < 0 then return end
    local natural = math.max(vm:SequenceDuration(sequence), 0.05)
    vm:SendViewModelMatchingSequence(sequence)
    vm:SetPlaybackRate(duration > 0 and natural / duration or 1)
    weapon.InfantryAnimationEnd = CurTime() + (duration > 0 and duration or natural)
end

function M.Play(weapon, name, duration)
    duration = duration or 0
    LocalPlay(weapon, name, duration)
    if SERVER then
        local owner = weapon:GetOwner()
        if not IsValid(owner) or not owner:IsPlayer() then return end
        net.Start("ACFInfantryNamedAnimation")
        net.WriteEntity(weapon)
        net.WriteString(name)
        net.WriteFloat(duration)
        net.Send(owner)
    end
end

-- These donor models have sequence names, not ACT_VM activity mappings.
-- Explicit owner-client playback also works if server sequence lookup fails.
if SERVER then
    util.AddNetworkString("ACFInfantryNamedAnimation")
else
    net.Receive("ACFInfantryNamedAnimation", function()
        local weapon, name, duration = net.ReadEntity(), net.ReadString(), net.ReadFloat()
        if not IsValid(weapon) or weapon:GetOwner() ~= LocalPlayer()
            or LocalPlayer():GetActiveWeapon() ~= weapon then return end
        LocalPlay(weapon, name, duration)
    end)
end

function M.Idle(weapon, name)
    if CLIENT and CurTime() >= (weapon.InfantryAnimationEnd or math.huge) then
        LocalPlay(weapon, name or "idle", 0)
    end
end
return M
