--[[
	Flux © 2016-2017 TeslaCloud Studios
	Do not share or re-distribute before
	the framework is publicly released.
--]]

function flCharacters:ClientIncludedSchema(player)
	character.Load(player)
end

function flCharacters:PostCharacterLoaded(player, character)
	hook.RunClient(player, "PostCharacterLoaded", character.uniqueID)
end

function flCharacters:OnActiveCharacterSet(player, character)
	player:Spawn()
	player:SetModel(character.model or "models/humans/group01/male_02.mdl")

	hook.Run("PostCharacterLoaded", player, character)
end

function flCharacters:DatabaseConnected()
	local queryObj = fl.db:Create("fl_characters")
		queryObj:Create("key", "INT NOT NULL AUTO_INCREMENT")
		queryObj:Create("steamID", "VARCHAR(25) NOT NULL")
		queryObj:Create("name", "VARCHAR(255) NOT NULL")
		queryObj:Create("faction", "TEXT NOT NULL")
		queryObj:Create("model", "TEXT NOT NULL")
		queryObj:Create("class", "TEXT DEFAULT NULL")
		queryObj:Create("physDesc", "TEXT DEFAULT NULL")
		queryObj:Create("inventory", "TEXT DEFAULT NULL")
		queryObj:Create("ammo", "TEXT DEFAULT NULL")
		queryObj:Create("money", "INT DEFAULT NULL")
		queryObj:Create("uniqueID", "INT DEFAULT NULL")
		queryObj:Create("charPermissions", "TEXT DEFAULT NULL")
		queryObj:Create("data", "TEXT DEFAULT NULL")
		queryObj:PrimaryKey("key")
	queryObj:Execute()
end