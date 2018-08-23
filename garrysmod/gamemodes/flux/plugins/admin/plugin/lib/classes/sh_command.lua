class "Command"

Command.id = "undefined"
Command.name = "Unknown"
Command.description = "An undescribed command."
Command.syntax = "[none]"
Command.immunity = false
Command.player_arg = nil
Command.arguments = 0
Command.no_console = false

function Command:Command(id)
  self.id = id
end

function Command:OnRun() end

function Command:__tostring()
  return "Command ["..self.id.."]["..self.name.."]"
end

function Command:register()
  fl.command:Create(self.id, self)
end