if SERVER then
    AddCSLuaFile()
    cleanup.Register("acf_infantry_explosives")
    local function RemoveOwned(player)
        for _, entity in ipairs(ents.FindByClass("acf_infantry_deployable")) do
            if entity.Placer == player and not entity.Exploded then entity:Remove() end
        end
    end
    hook.Add("PlayerDeath", "ACFInfantryDeployableCleanup", RemoveOwned)
    hook.Add("PlayerDisconnected", "ACFInfantryDeployableCleanup", RemoveOwned)
    hook.Add("PlayerSpawn", "ACFInfantryDeployableCleanup", RemoveOwned)
else
    language.Add("Cleanup_acf_infantry_explosives", "ACF Infantry Explosives")
    language.Add("Cleaned_acf_infantry_explosives", "Cleaned up ACF Infantry explosives")
end
