PLUGIN:set_global('Attributes')

util.include('sv_hooks.lua')

function Attributes:PluginIncludeFolder(extra, folder)
  for k, v in pairs(attributes.types) do
    if extra == k then
      attributes.include_type(k, v, folder..'/'..k..'/')

      return true
    end
  end
end

function Attributes:OnPluginsLoaded()
  if Conditions then
    Conditions:register('attribute', {
      name = t'condition.attribute.name',
      text = t'condition.attribute.text'..' %s %s %s',
      format = function(panel, data)
        local panel_data = panel.data
        local attribute_name = t'condition.select_parameter'
        local operator = util.operator_to_symbol(panel_data.operator) or t'condition.select_operator'
        local attribute_value = panel_data.attribute_value or t'condition.select_parameter'

        if panel_data.attribute then
          attribute_name = attributes.find_by_id(panel_data.attribute).name
        end

        return string.format(data.text, t(attribute_name), operator, attribute_value)
      end,
      icon = 'icon16/chart_bar.png',
      check = function(player, entity, data)
        if !data.operator or !data.attribute or !data.attribute_value then return false end

        return util.process_operator(data.operator, player:get_attribute(data.attribute), data.attribute_value)
      end,
      set_parameters = function(id, data, panel, menu)
        panel:create_selector(data.name, 'condition.attribute.message1', 'condition.attributes', attributes.get_stored(), 
        function(selector, value)
          selector:add_choice(t(value.name), function()
            panel.data.attribute = value.attr_id
      
            panel.update()

            Derma_StringRequest(
              t(data.name),
              t'condition.attribute.message2',
              '',
              function(text)
                panel.data.attribute_value = tonumber(text)
        
                panel.update()
              end)
          end)
        end)
      end,
      set_operator = 'relational'
    })
  end
end
