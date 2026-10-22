if SERVER then
    AddCSLuaFile()
    util.AddNetworkString("ACFInfantryStimDiagnostics")
end
local enabled = {}
local function Log(ply, realm)
    local weapon = ply:GetActiveWeapon()
    if not IsValid(weapon) or weapon:GetClass() ~= "weapon_acf_healthstim" then return end
    local vm = ply:GetViewModel()
    if not IsValid(vm) then print("[ACF Stim trace " .. realm .. "] no viewmodel") return end
    local sequence = vm:GetSequence()
    local fields = {}
    for _, name in ipairs({"idle", "deploy", "inject", "inject_other"}) do
        fields[#fields + 1] = name .. "=" .. tostring(vm:LookupSequence(name))
    end
    print(string.format("[ACF Stim trace %s] build=stim-trace-1 player=%s model=%s seq=%s:%s cycle=%.3f rate=%.3f useStart=%.3f useEnd=%.3f %s",
        realm, ply:Nick(), tostring(vm:GetModel()), tostring(sequence), tostring(vm:GetSequenceName(sequence)),
        vm:GetCycle(), vm:GetPlaybackRate(), weapon:GetNWFloat("StimUseStart", 0),
        weapon:GetNWFloat("StimAnimationEnd", 0), table.concat(fields, " ")))
end
if SERVER then
    net.Receive("ACFInfantryStimDiagnostics", function(_, ply)
        if (ply.ACFStimDiagnosticCooldown or 0) > CurTime() then return end
        ply.ACFStimDiagnosticCooldown = CurTime() + 20
        enabled[ply] = {expires = CurTime() + 15, next = 0}
        net.Start("ACFInfantryStimDiagnostics") net.Send(ply)
        print("[ACF Stim trace SERVER] started 15-second trace for " .. ply:Nick())
    end)
    hook.Add("Think", "ACFInfantryStimDiagnostics", function()
        for ply, state in pairs(enabled) do
            if not IsValid(ply) or CurTime() > state.expires then enabled[ply] = nil
            elseif CurTime() >= state.next then
                state.next = CurTime() + 0.5
                Log(ply, "SERVER")
            end
        end
    end)
else
    concommand.Add("acf_infantry_stim_diagnostics", function()
        net.Start("ACFInfantryStimDiagnostics") net.SendToServer()
    end)
    local expires, nextLog = 0, 0
    net.Receive("ACFInfantryStimDiagnostics", function()
        expires, nextLog = CurTime() + 15, 0
        print("[ACF Stim trace CLIENT] build=stim-trace-1; use the health stim now. Copy CLIENT and SERVER trace lines after testing.")
    end)
    hook.Add("Think", "ACFInfantryStimDiagnostics", function()
        if CurTime() > expires or CurTime() < nextLog then return end
        nextLog = CurTime() + 0.5
        local ply = LocalPlayer()
        if IsValid(ply) then Log(ply, "CLIENT") end
    end)
end
