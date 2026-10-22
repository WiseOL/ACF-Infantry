if SERVER then AddCSLuaFile() end
-- Fresh movement data is rebuilt on each prediction replay. Mutating and
-- re-inverting a reused CUserCmd can oscillate between opposite directions.
hook.Remove("StartCommand", "ACFInfantryNerveGasMovement")
hook.Add("SetupMove", "ACFInfantryNerveGasMovement", function(player, move)
    if not player:Alive() or player:InVehicle()
        or player:GetNW2Float("ACFInfantryGasUntil", 0) <= CurTime() then return end
    move:SetForwardSpeed(-move:GetForwardSpeed())
    move:SetSideSpeed(-move:GetSideSpeed())
    local original = move:GetButtons()
    local buttons = bit.band(original, bit.bnot(bit.bor(IN_FORWARD, IN_BACK, IN_MOVELEFT, IN_MOVERIGHT)))
    for _, pair in ipairs({{IN_FORWARD, IN_BACK}, {IN_BACK, IN_FORWARD},
        {IN_MOVELEFT, IN_MOVERIGHT}, {IN_MOVERIGHT, IN_MOVELEFT}}) do
        if bit.band(original, pair[1]) ~= 0 then buttons = bit.bor(buttons, pair[2]) end
    end
    move:SetButtons(buttons)
end)
if SERVER then
    local function Clear(player) player:SetNW2Float("ACFInfantryGasUntil", 0) end
    hook.Add("PlayerSpawn", "ACFInfantryClearGas", Clear)
    hook.Add("PlayerDeath", "ACFInfantryClearGas", Clear)
end
