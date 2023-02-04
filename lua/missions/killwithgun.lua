AddCSLuaFile()

local MISSION = {}
MISSION.name = "killwithgun"
MISSION.printname = "Contract Killer"
MISSION.desc = [[Kill a player with a given gun.]]
MISSION.pred = function () return true end
MISSION.Instantiate = function(instance)
    local weps = {}
    -- this is supposed to be ents.TTT.GetSpawnableSWEPs() but that's a nil value for some reason.
    for k,v in pairs(weapons.GetList()) do
        if v and v.AutoSpawnable and (not WEPS.IsEquipment(v)) then
           table.insert(weps, v)
        end
    end
    local inst = MissionInstances[instance]
    local wep = weps[math.random(#weps)]
    inst.weapon = wep.ClassName

    for _, v in ipairs(inst.owners) do
        local owner = player.GetBySteamID64(v)
        if owner then
            local playerWeapons = owner:GetWeapons()
            for _, k in ipairs(playerWeapons) do
                if k:GetSlot() == wep.Slot then
                    owner:DropWeapon(k)
                end
            end
            owner:Give(inst.weapon)
        end
    end
end
MISSION.GetInstruction = function(instance)
    return "Kill a player with a " .. instance.weapon .. "."
end

RegisterMission(MISSION)

if SERVER then
    hook.Add("PlayerDeath", "KillWithGunDeath", function(victim, infl, attacker)
        if not (IsValid(infl) or IsPlayer(attacker) or IsPlayer(victim)) then return end
        MissionHook(MISSION_KILLWITHGUN, function(instance)
            if attacker:HasMissionInstance(instance) and (infl:GetClass() == instance.weapon) then
                instance.status = 1

                local owners = {}
                for _, v in ipairs(instance.owners) do
                    table.insert(owners, player.GetBySteamID64(v))
                end

                net.Start("missionstate")
                net.WriteTable(instance)
                net.Send(owners)
            end
        end)
    end)
end

