--[[
	Flux © 2016-2018 TeslaCloud Studios
	Do not share or re-distribute before
	the framework is publicly released.
--]]

PLUGIN:SetAlias("flFactions")

plugin.add_extra("factions")

util.Include("cl_hooks.lua")
util.Include("sv_hooks.lua")

function flFactions:PluginIncludeFolder(extra, folderName)
	if (extra == "factions") then
		faction.IncludeFactions(folderName.."/factions/")

		return true
	end
end

function flFactions:ShouldNameGenerate(player)
	if (player:IsBot()) then
		return false
	end
end
