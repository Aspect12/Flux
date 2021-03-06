Cable.receive('fl_hook_run_cl', function(hook_name, ...)
  hook.run(hook_name, ...)
end)

Cable.receive('fl_player_initial_spawn', function(ply_index)
  hook.run('PlayerInitialSpawn', Entity(ply_index))
end)

Cable.receive('fl_player_disconnected', function(ply_index)
  hook.run('PlayerDisconnected', Entity(ply_index))
end)

Cable.receive('fl_player_model_changed', function(ply_index, new_model, old_model)
  util.wait_for_ent(ply_index, function(player)
    hook.run('PlayerModelChanged', player, new_model, old_model)
  end)
end)

Cable.receive('fl_notification', function(message, arguments, color)
  if istable(arguments) then
    for k, v in pairs(arguments) do
      if isstring(v) then
        arguments[k] = t(v)
      elseif isentity(v) and IsValid(v) then
        if v:IsPlayer() then
          arguments[k] = hook.run('GetPlayerName', v) or v:name()
        else
          arguments[k] = tostring(v) or v:GetClass()
        end
      end
    end
  end

  color = color and Color(color.r, color.g, color.b) or color_white
  message = t(message, arguments)

  Flux.Notification:add(message, 8, color:darken(50))

  chat.AddText(color, message)
end)

Cable.receive('fl_player_take_damage', function()
  PLAYER.last_damage = CurTime()
end)
