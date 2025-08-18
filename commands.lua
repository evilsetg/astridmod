-- chatcommands
core.register_chatcommand("sonic", {
                             func = function(name, param)
                                local player = core.get_player_by_name(name)
                                player:set_physics_override({
                                      speed = 50.0,
                                      jump = 2.0
                                })
                             end,
})

core.register_chatcommand("unsonic", {
                             func = function(name, param)
                                local player = core.get_player_by_name(name)
                                player:set_physics_override({
                                      speed = 1.0,
                                      jump = 1.0
                                })
                             end,
})
