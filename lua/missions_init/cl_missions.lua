local MissionHUD
hook.Add("OnGamemodeLoaded", "MissionHUDInit", function()
MissionHUD = vgui.Create("DFrame")
MissionHUD:SetVisible(false)
MissionHUD:SetSizable(false)
MissionHUD:SetDraggable(false)
MissionHUD:SetTitle("Missions")
MissionHUD:ShowCloseButton(false)
MissionHUD:DockPadding(5,5,5,5)
MissionHUD:SetPos(ScrW() * 0.65, ScrH() * 0.05)
MissionHUD:SetSize(ScrW() * 0.3, ScrH() * 0.3)
end)

local function AddMissionToHUD(mission)
            local MissionInfo = vgui.Create("DFrame", MissionHUD)
            MissionInfo:SetVisible(false)
            MissionInfo:SetSizable(false)
            MissionInfo:SetDraggable(false)
            MissionInfo:SetTitle(MISSIONS[MissionInstances[mission].mission].printname)
            MissionInfo:ShowCloseButton(false)
            MissionInfo:Dock(TOP)
            MissionInfo:DockPadding(5,5,5,5)
            MissionInfo.mission = mission
            local MissionInstruction = vgui.Create("DLabel", MissionInfo)
            MissionInstruction:SetEnabled(false)
            MissionInstruction:SetSize(ScrW() * 0.3, 15)
            MissionInstruction:SetWrap(true)
            MissionInstruction:SetAutoStretchVertical(true)
            MissionInstruction:Dock(FILL)
end

net.Receive("missionstate", function(len, ply)
    local instance = net.ReadTable()
    print(instance)
    MissionInstances[instance.id] = instance
    if not InstancesByMission[instance.mission] then
        InstancesByMission[instance.mission] = {}
    end
    table.insert(InstancesByMission[instance.mission], instance.id)

    local owners = {}
    for _, v in ipairs(instance.owners) do
        table.insert(owners, player.GetBySteamID64(v))
    end

    for _, v in ipairs(owners) do
        v:AddMission(instance.id)
        if v == LocalPlayer() then
            AddMissionToHUD(instance.id)
        end
    end
    
end)

hook.Add("TTTBeginRound", "MissionHUDInit", function()
    MissionHUD:SetVisible(true)
end)

hook.Add("TTTEndRound", "MissionHUDClear", function()
    MissionHUD:SetVisible(false)
    MissionHUD:Clear()
end)

hook.Add("HUDPaint", "MissionsHUD", function()
    local client = LocalPlayer()
    if client:GetMissions() then
        if (not #client:GetMissions()) or (not round_state == ROUND_ACTIVE) then
            return
        end
    end
    for _, v in pairs(MissionHUD:GetChildren()) do
        if v.mission and v:IsValid() then
            local instance = MissionInstances[v.mission]
            local mission = MISSIONS[instance.mission]
            v:GetChildren()[1]:SetText(mission.GetInstruction(instance))
            v:SizeToContents()
            v:SetVisible(true)
        end
    end
    MissionHUD:SizeToContents()
end)