local function set_formspec(meta,code)
   code = code or ""
   is_error = meta:get_string("error") == "true"
   meta:set_string("code", code)
   meta:set_string("formspec",
                   "formspec_version[4]" ..
                   "size[25,25]" ..
                   "label[1,1;Enter code]" ..
                   "style_type[label;textcolor=red]" ..
                   (is_error and "label[16,1;ERROR!]" or "") ..
                   "style_type[label;textcolor=]" ..
                   "button_exit[20,1;2,1;exit;exit]" ..
                   "style[save;textcolor=green]" ..
                   "button[22,22;2,2;save;save]" ..
                   "textarea[1,2;20,20;x;here:;".. code .."]" ..
                   "button[1,22;20,2;enter;Done!]")
end


core.register_node("astridmod:virus", {
                      description = "Eat the world",
                      tiles = {"astridmod_virus_node.png"},
                      groups = {fleshy = 30, cracky=3},
                      on_timer = function(pos)
                         -- local x = vector.new(1,0,0)
                         -- local y = vector.new(0,1,0)
                         -- local z = vector.new(0,0,1)
                         -- for _,p in pairs({x,-x,y,-y,z,-z}) do
                         --    local inode = core.get_node(pos+p)
                         --    if not (inode.name == "astridmod:virus" or inode.name == "air") then
                         --       core.set_node(pos+p, { name = "astridmod:virus"})
                         --    end
                         -- end
                         return false
                      end,
                      on_construct = function(pos, placer, itemstack, pointed_thing)
                         timer = core.get_node_timer(pos)
                         timer:start(4.0)
                      end
})
                      

core.register_node("astridmod:program_node", {
                      description = "Programmable block",
                      tiles = {"astridmod_program_node.png"},
                      groups = {cracky = 3},
                      after_place_node = function(pos, placer, itemstack, pointed_thing)
                         if placer and placer:is_player() then
                            local meta = core.get_meta(pos)
                            meta:set_string("owner", placer:get_player_name())
                            core.chat_send_player(placer:get_player_name(), "Hallo!")
                         end
                         local meta = core.get_meta(pos)
                         meta:set_string("formspec",
                                         "formspec_version[4]" ..
                                         "size[25,25]" ..
                                         "label[1,1;Enter code]" ..
                                         "button_exit[20,1;2,1;exit;exit]" ..
                                         "style[save;textcolor=green]" ..
                                         "button[22,22;2,2;save;save]" ..
                                         "textarea[1,2;20,20;x;here:;]" ..
                                         "button[1,22;20,2;enter;Done!]")
                         meta:set_string("error", "false")
                      end,
                      on_receive_fields = function(pos, formname, fields, player)
                         if fields.quit then
                            return
                         end
                         if fields.enter then
                            local meta = core.get_meta(pos)
                            local prelude = "local x = vector.new(1,0,0)" ..
                               "local y = vector.new(0,1,0)" ..
                               "local z = vector.new(0,0,1)" ..
                               "local pos = ..."
                            local f = loadstring(prelude .. fields.x)
                            status, res = pcall(f, pos)
                            if status == false then
                               print("ERROR in code!")
                               print(res)
                               meta:set_string("error", "true")
                               core.chat_send_player(player:get_player_name(), res)
                            else
                               meta:set_string("error", "false")
                            end
                            set_formspec(meta, fields.x)
                         end
                         if fields.save then
                            local meta = core.get_meta(pos)
                            set_formspec(meta, fields.x)
                         end
                      end
})

core.register_chatcommand("sonic", {
    func = function(name, param)
        local player = core.get_player_by_name(name)
        player:set_physics_override({
            speed = 50.0, -- set gravity to 10% of its original value
                           -- (0.1 * 9.81)
        })
    end,
})

core.register_chatcommand("unsonic", {
    func = function(name, param)
        local player = core.get_player_by_name(name)
        player:set_physics_override({
            speed = 1.0, -- set gravity to 10% of its original value
                           -- (0.1 * 9.81)
        })
    end,
})


core.register_node("astridmod:emperor_node", {
                      description = "Hail the emperor",
                      tiles = {"astridmod_emperor_node.png"},
                      groups = {cracky = 3},
                      after_place_node = function(pos, placer, itemstack, pointed_thing)
                         if placer and placer:is_player() then
                            local meta = core.get_meta(pos)
                            meta:set_string("owner", placer:get_player_name())
                         end
                      end,
                      on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
                         core.chat_send_player(clicker:get_player_name(), "Hail the Emperor!")
                         core.sound_play("astridmod_argenta")
                      end,
                      on_dig = function(pos, node, digger)
                         print(node)
                         core.sound_play("astridmod_pain")
                         core.node_dig(pos, node, digger)
                      end

})

core.register_craft({
      type = "shapeless",
      output = "astridmod:program_node 3",
      recipe = { "mcl_core:dirt", "mcl_core:stone" }
})
