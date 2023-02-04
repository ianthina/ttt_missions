TTT_MISSIONS_VERSION = "1.0"


util.AddNetworkString("missionstate")

CreateConVar("ttt_missions_chance", "0.5", {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Chances that a player may be given a mission.", "0", "1")
CreateConVar("ttt_missions_max", "3", {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Maximum amount of missions that a player may be given.", "0", "10")

function InstantiateMission(mission, owners)
    --mission should be in index form.
    --TO DO: make it so that sending a table of owners or a single owner both work.
    local instance = {}
    instance.mission = mission
    instance.owners = {}
    for _, v in ipairs(owners) do
        table.insert(instance.owners, v:SteamID64())
    end
    instance.id = #MissionInstances + 1
    table.insert(MissionInstances, instance)
    MISSIONS[mission].Instantiate(#MissionInstances)
    if not InstancesByMission[mission] then
        InstancesByMission[mission] = {}
    end
    table.insert(InstancesByMission[mission], #MissionInstances)

    for _, v in ipairs(owners) do
        v:AddMission(#MissionInstances)
    end

    SendMissionState(instance)
end

function SendMissionState(instance)
    local ownertbl = {}
    for _, v in ipairs(instance.owners) do
        table.insert(ownertbl, player.GetBySteamID64(v))
    end
    
    net.Start("missionstate")
    net.WriteTable(instance)
    net.Send(ownertbl)
end

function MissionHook(mission, callback)
    if InstancesByMission[mission] then
        for i, v in ipairs(InstancesByMission[mission]) do
            local result = callback(v)
            if not result == nil then
                return result
            end
        end
    end
end

function GiveRandomMission(ply)
    local weightedValidMissions = {}
    for i, v in ipairs(MISSIONS) do
        if GetConVar("ttt_mission_" .. string.lower(v.name) .. "_enabled"):GetBool() and ply:ValidMission(i) and not ply:HasMission(i) then
            for _ = #ply:GetMissions(), GetConVar("ttt_mission_" .. string.lower(v.name) .. "_weight"):GetInt() do
                table.insert(weightedValidMissions, i)
            end
        end
    end
    return weightedValidMissions[math.random(1, #weightedValidMissions)]
end

local function missionsbegin()
    for _, v in pairs(player.GetAll()) do
        if v:IsTerror() then
            if GetConVar("ttt_missions_max"):GetInt() then
                for i=1, GetConVar("ttt_missions_max"):GetInt() do
                    if math.random() < GetConVar("ttt_missions_chance"):GetFloat() then
                        local randommission = GiveRandomMission(v)
                        if randommission then
                            InstantiateMission(randommission, {v})    
                        end
                    end
                end
            end
        end
    end
end

hook.Add("TTTBeginRound", "MissionsBegin", missionsbegin)

