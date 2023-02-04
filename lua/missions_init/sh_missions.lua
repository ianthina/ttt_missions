AddCSLuaFile("cl_missions.lua")
if SERVER then
    include("sv_missions.lua")
else
    include("cl_missions.lua")
end

MISSIONS = {}
MISSIONS_MAX = 1

MissionInstances = {}
InstancesByMission = {}

local plymeta = FindMetaTable("Player")

local function TrueTableEmpty( tab )
	for k, _ in pairs( tab ) do
        if type(tab[k]) == "table" then
            TrueTableEmpty(tab[k])
        end
		tab[ k ] = nil
	end
end
local function missionscleanup()
    TrueTableEmpty(MissionInstances)
    TrueTableEmpty(InstancesByMission)
    for _, v in ipairs(player.GetAll()) do
        if v.missions then
            TrueTableEmpty(v.missions)            
        end
    end
end
hook.Add("TTTPrepareRound", "MissionsCleanup", missionscleanup)

function RegisterMission(mission)
    _G["MISSIONS_" .. string.upper(mission.name)] = MISSIONS_MAX
    MISSIONS[MISSIONS_MAX] = mission
    MISSIONS_MAX = MISSIONS_MAX + 1
    if SERVER then
        CreateConVar("ttt_mission_" ..  string.lower(mission.name) .. "_enabled", "0", {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Whether the mission" .. mission.name .. "is enabled or not", "0", "1")
        CreateConVar("ttt_mission_" .. string.lower(mission.name) .. "_weight", "1", {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Weight that" .. mission.name .. "will be selected.", "0", "100")
    end
end

local function AddMissionFiles(root)
    local rootfiles, dirs = file.Find(root .. "*", "LUA")
    for _, dir in ipairs(dirs) do
        local files, _ = file.Find(root .. dir .. "/*.lua", "LUA")
        for _, fil in ipairs(files) do
            local isClientFile = StringFind(fil, "cl_")
            local isSharedFile = fil == "shared.lua" or StringFind(fil, "sh_")

                if SERVER then
                -- Send client and shared files to clients
                if isClientFile or isSharedFile then AddCSLuaFile(root .. dir .. "/" .. fil) end
                -- Include non-client files
                if not isClientFile then include(root .. dir .. "/" .. fil) end
           end
          -- Include client and shared files
                if CLIENT and (isClientFile or isSharedFile) then include(root .. dir .. "/" .. fil) end
            end
        end
    
        -- Include and send client any files using the single file method
        for _, fil in ipairs(rootfiles) do
            if string.GetExtensionFromFilename(fil) == "lua" then
                if SERVER then AddCSLuaFile(root .. fil) end
                include(root .. fil)
            end
        end
    end
    
AddMissionFiles("missions/")

function plymeta:GetMissions()
    return self.missions
end

function plymeta:AddMission(instance)
    if not self.missions then
        self.missions = {}
    end
    table.insert(self.missions, instance)
end

function plymeta:HasMissionInstance(instance)
    if not self.missions then
        self.missions = {}
    end
    for _, v in self.missions do
        if v == instance then return true end
    end
    return false
end

function plymeta:HasMission(mission)
    if not self.missions then
        self.missions = {}
    end
    for _, v in ipairs(self.missions) do
        if MissionInstances[v].mission == mission then return v end          
    end
    return false
end

function plymeta:ValidMission(mission)
    local missiontbl = MISSIONS[mission]
    local valid = false
    if missiontbl.excludes then
        for _, v in ipairs(missiontbl.excludes) do
            if self:GetRole() == v then
                return false
            end
        end
        valid = true
    elseif missiontbl.includes then
        for _, v in ipairs(missiontbl.includes) do
            if self:GetRole() == v then
                valid = true
            end
        end
    else
        valid = true
    end
    if missiontbl.pred then
        valid = valid and missiontbl.pred()
    end
    return valid
end
