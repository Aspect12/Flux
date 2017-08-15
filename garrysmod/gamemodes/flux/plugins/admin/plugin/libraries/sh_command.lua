--[[
	Flux © 2016-2017 TeslaCloud Studios
	Do not share or re-distribute before
	the framework is publicly released.
--]]

library.New("command", fl)
local stored = fl.command.stored or {}
local aliases = fl.command.aliases or {}
fl.command.stored = stored
fl.command.aliases = aliases

function fl.command:Create(id, data)
	if (!id or !data) then return end

	data.uniqueID = id:MakeID()
	data.name = data.name or "Unknown"
	data.description = data.description or "An undescribed command."
	data.syntax = data.syntax or "[none]"
	data.immunity = data.immunity or false
	data.playerArg = data.playerArg or nil
	data.arguments = data.arguments or 0

	stored[id] = data

	-- Add original command name to aliases table.
	aliases[id] = data.uniqueID

	if (data.aliases) then
		for k, v in ipairs(data.aliases) do
			aliases[v] = id
		end
	end

	fl.admin:PermissionFromCommand(data)
end

function fl.command:FindByID(id)
	id = id:utf8lower()

	if (stored[id]) then return stored[id] end
	if (aliases[id]) then return stored[aliases[id]] end
end

function fl.command:Find(id)
	id = id:utf8lower()

	local found = self:FindByID(id)

	if (found) then
		return found
	end

	for k, v in pairs(aliases) do
		if (k:find(id)) then
			return stored[v]
		end
	end
end

-- A function to find all commands by given search string.
function fl.command:FindAll(id)
	local hits = {}

	for k, v in pairs(aliases) do
		if (k:find(id) or v:find(id)) then
			table.insert(hits, v)
		end
	end

	return hits
end

function fl.command:ExtractArguments(text)
	local arguments = {}
	local word = ""
	local skip = 0

	for i = 1, #text do
		if (skip > 0) then
			skip = skip - 1

			continue
		end

		local char = text:utf8sub(i, i)

		if ((char == "\"" or char == "'" or char == "{") and word == "") then
			local endPos = text:find("\"", i + 1)
			local isTable = false

			if (!endPos) then
				endPos = text:find("'", i + 1)

				if (!endPos) then
					endPos = text:find("}", i + 1)
					isTable = true
				end
			end

			if (endPos) then
				if (!isTable) then
					table.insert(arguments, text:utf8sub(i + 1, endPos - 1))
				else
					local text = text:utf8sub(i, endPos)
					local tab = util.BuildTableFromString(text)

					if (tab) then
						table.insert(arguments, tab)
					else
						table.insert(arguments, text)
					end
				end

				skip = endPos - i
			else
				word = word..char
			end
		elseif (char == " ") then
			if (word != "") then
				table.insert(arguments, word)
				word = ""
			end
		else
			word = word..char
		end
	end

	if (word != "") then
		table.insert(arguments, word)
	end

	return arguments
end

if (SERVER) then
	local macros = {
		-- Target everyone in a user group.
		["@"] = function(player, str)
			local groupName = str:utf8sub(2, str:utf8len()):utf8lower()
			local toReturn = {}

			for k, v in ipairs(_player.GetAll()) do
				if (v:GetUserGroup() == groupName) then
					table.insert(toReturn, v)
				end
			end

			return toReturn, "@"
		end,
		-- Target everyone with str in their name.
		["("] = function(player, str)
			local name = str:utf8sub(2, str:utf8len() - 1)
			local toReturn = _player.Find(name)

			if (IsValid(toReturn)) then
				toReturn = {toReturn}
			end

			if (!istable(toReturn)) then
				toReturn = {}
			end

			return toReturn, "("
		end,
		-- Target the first person whose nick is exactly str.
		["["] = function(player, str)
			local name = str:utf8sub(2, str:utf8len() - 1)

			for k, v in ipairs(_player.GetAll()) do
				if (v:Name() == name) then
					return {v}, "["
				end
			end

			return false, "["
		end,
		-- Target yourself.
		["^"] = function(player, str)
			if (IsValid(player)) then
				return {player}, "^"
			else
				return false, "^"
			end
		end,
		-- Target everyone.
		["*"] = function(player, str)
			return _player.GetAll(), "*"
		end
	}

	function fl.command:PlayerFromString(player, str)
		local start = str:utf8sub(1, 1)
		local parser = macros[start]

		if (isfunction(parser)) then
			return parser(player, str)
		else
			local target = _player.Find(str)

			if (IsValid(target)) then
				return {target}
			elseif (istable(target) and #target > 0) then
				return target
			end
		end

		return false
	end

	function fl.command:Interpret(player, text)
		local args

		if (istable(text)) then
			args = text
		elseif (isstring(text)) then
			args = self:ExtractArguments(text)
		end

		if (!isstring(args[1])) then
			if (!IsValid(player)) then
				ErrorNoHalt("[Flux:Command] You must enter a command!\n")
			else
				fl.player:Notify(player, "You must enter a command!")
			end

			return
		end

		local command = args[1]:utf8lower()

		table.remove(args, 1)

		local cmdTable = self:FindByID(command)

		if (cmdTable) then
			if ((!IsValid(player) and !cmdTable.noConsole) or player:HasPermission(cmdTable.uniqueID)) then
				if (cmdTable.arguments == 0 or cmdTable.arguments <= #args) then
					if (cmdTable.immunity or cmdTable.playerArg != nil) then
						local targetArg = args[(cmdTable.playerArg or 1)]
						local targets = {}

						if (istable(targetArg)) then
							local cache = {}

							for k, v in pairs(targetArg) do
								local target, kind = fl.command:PlayerFromString(player, v)

								if (istable(target)) then
									for k2, v2 in ipairs(target) do
										if (IsValid(v2) and !cache[v2]) then
											cache[v2] = true

											table.insert(targets, v2)
										end
									end
								end
							end
						else
							local target, kind = fl.command:PlayerFromString(player, targetArg)
							local cache = {}

							if (istable(target)) then
								for k, v in ipairs(target) do
									if (IsValid(v) and !cache[v]) then
										cache[v] = true

										table.insert(targets, v)
									end
								end
							else
								if (IsValid(player)) then
									fl.player:Notify(player, L("Commands_PlayerInvalid", tostring(targetArg)))
								else
									if (kind != "^") then
										ErrorNoHalt("'"..tostring(targetArg).."' is not a valid player!")
									else
										ErrorNoHalt("[Flux:Command] You cannot target yourself as console.")
									end
								end

								return
							end
						end

						if (istable(targets) and #targets > 0) then
							for k, v in ipairs(targets) do
								if (cmdTable.immunity and IsValid(player) and !fl.admin:CheckImmunity(player, v, cmdTable.canBeEqual)) then
									fl.player:Notify(player, L("Commands_HigherImmunity", v:Name()))

									return
								end
							end

							-- One step less for commands.
							args[cmdTable.playerArg or 1] = targets
						else
							if (IsValid(player)) then
								fl.player:Notify(player, L("Commands_PlayerInvalid", tostring(targetArg)))
							else
								ErrorNoHalt("'"..tostring(targetArg).."' is not a valid player!\n")
							end

							return
						end
					end

					-- Let plugins hook into this and abort command's execution if necessary.
					if (!hook.Run("PlayerRunCommand", player, cmdTable, args)) then
						if (IsValid(player)) then
							ServerLog(player:Name().." has used /"..cmdTable.name.." "..text:utf8sub(cmdTable.name:utf8len() + 2, text:utf8len()))
						end

						self:Run(player, cmdTable, args)
					end
				else
					fl.player:Notify(player, "/"..cmdTable.name.." "..cmdTable.syntax)
				end
			else
				if (IsValid(player)) then
					fl.player:Notify(player, "#Commands_NoAccess")
				else
					ErrorNoHalt("[Flux] This command cannot be run from console!\n")
				end
			end
		else
			if (IsValid(player)) then
				fl.player:Notify(player, L("Commands_NotValid", command))
			else
				ErrorNoHalt("'"..command.."' is not a valid command!\n")
			end
		end
	end

	-- Warning: this function assumes that command is valid and all permission checks have been done.
	function fl.command:Run(player, cmdTable, arguments)
		if (cmdTable.OnRun) then
			local success, result = pcall(cmdTable.OnRun, cmdTable, player, unpack(arguments))

			if (!success) then
				ErrorNoHalt("[Flux] "..cmdTable.uniqueID.." command has failed to run!\n")
				ErrorNoHalt(result.."\n")
			end
		end
	end

	netstream.Hook("Flux::Command::Run", function(player, command)
		fl.command:Interpret(player, command)
	end)
else
	function fl.command:Send(command)
		netstream.Start("Flux::Command::Run", command)
	end
end

concommand.Add("flCmd", function(player, cmd, args)
	if (SERVER) then
		fl.command:Interpret(player, args)
	else
		fl.command:Send(args)
	end
end)

concommand.Add("flc", function(player, cmd, args)
	if (SERVER) then
		fl.command:Interpret(player, args)
	else
		fl.command:Send(args)
	end
end)