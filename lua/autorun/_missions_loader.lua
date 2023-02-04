if engine.ActiveGamemode() == "terrortown" then
    AddCSLuaFile("missions_init/sh_missions.lua")
    include("missions_init/sh_missions.lua")
end