PLUGIN:set_global('Bolt')

util.include('cl_hooks.lua')
util.include('sv_hooks.lua')

function Bolt:OnPluginLoaded()
  plugin.add_extra('commands')
  plugin.add_extra('roles')

  local folder = self:get_folder()

  util.include_folder(folder..'/commands/')
  Bolt:include_roles(folder..'/roles/')
end

function Bolt:PluginIncludeFolder(extra, folder)
  if extra == 'roles' then
    Bolt:include_roles(folder..'/roles/')

    return true
  end
end

function Bolt:PlayerHasPermission(player, action, object)
  return Bolt:can(player, action, object)
end

function Bolt:PlayerIsRoot(player)
  return player.can_anything
end

function Bolt:OnPluginsLoaded()
  if Conditions then
    Conditions:register('bolt_role', {
      name = t'condition.role.name',
      text = t'condition.role.text'..' %s %s',
      format = function(panel, data)
        local panel_data = panel.data
        local operator = util.operator_to_symbol(panel_data.operator) or t'condition.select_operator'
        local parameter = panel_data.role or t'condition.select_parameter'
    
        return string.format(data.text, operator, parameter)
      end,
      icon = 'icon16/group.png',
      check = function(player, data)
        if !data.operator or !data.role then return false end

        return util.process_operator(data.operator, player:get_role(), data.role)
      end,
      set_parameters = function(id, data, panel, menu)
        panel:create_selector(data.name, 'condition.role.message', 'condition.roles', self:get_roles(), 
        function(selector, group)
          selector:add_choice(t(group.name), function()
            panel.data.role = group.id
      
            panel.update()
          end)
        end)
      end,
      set_operator = 'equal'
    })
  end
end
