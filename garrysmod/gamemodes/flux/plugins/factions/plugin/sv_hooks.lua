--[[
	Flux © 2016-2017 TeslaCloud Studios
	Do not share or re-distribute before
	the framework is publicly released.
--]]

function flFactions:PostPlayerSpawn(player)
	local playerFaction = player:GetFaction()

	if (playerFaction) then
		player:SetTeam(playerFaction.teamID or 1)
	end
end

function PLUGIN:OnPlayerRestored(player)
	if (player:IsBot()) then
		local factions = faction.GetAll()

		if (table.Count(factions) > 0) then
			local randomFaction = table.Random(factions)

			player:SetNetVar("faction", randomFaction.uniqueID)

			if (randomFaction.HasGender) then
				player:SetNetVar("gender", (math.random(0, 1) == 0) and CHAR_GENDER_MALE or CHAR_GENDER_FEMALE)
			end

			local factionModels = randomFaction.Models

			if (istable(factionModels)) then
				local randomModel = "models/humans/group01/male_01.mdl"
				local universal = factionModels.universal or {}

				if (randomFaction.HasGender) then
					local male = factionModels.male or {}
					local female = factionModels.female or {}

					local gender = player:GetNetVar("gender", -1)

					if (gender == -1 and #universal > 0) then
						randomModel = universal[math.random(#universal)]
					elseif (gender == CHAR_GENDER_MALE and #male > 0) then
						randomModel = male[math.random(#male)]
					elseif (gender == CHAR_GENDER_FEMALE and #female > 0) then
						randomModel = female[math.random(#female)]
					end
				elseif (#universal > 0) then
					randomModel = universal[math.random(#universal)]
				end

				player:SetNetVar("model", randomModel)
			end

			player:SetTeam(randomFaction.teamID or 1)
		end
	end
end