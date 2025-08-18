local modpath = core.get_modpath(core.get_current_modname())

dofile(modpath .. "/commands.lua")
dofile(modpath .. "/nodes.lua")

core.register_privilege("abbauen", {
                           description = "Spieler darf abbauen",
                           give_to_singleplayer = false,
                           give_to_admin = false
})

core.register_privilege("setzen", {
                           description = "Spieler darf Blöcke setzen",
                           give_to_singleplayer = false,
                           give_to_admin = false
})

-- Abbauen global verhindern (für alle Blöcke, wenn verboten)
core.register_on_dignode(function(pos, oldnode, digger)
      if not digger then return end
      if digger:is_player() then
         local has_bypass = core.check_player_privs(digger, "protection_bypass")
         local has_dig_privilege = core.check_player_privs(digger, "abbauen")
         if not (has_bypass or has_dig_privilege) then
            minetest.set_node(pos, oldnode)
            minetest.chat_send_player(digger:get_player_name(),
                                      "Du darfst gerade nichts abbauen!")
         end
      end
end)

-- Setzen von Blöcken verhindern (für alle Blöcke, wenn verboten)
core.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
      if not placer then return end
      if placer:is_player() then
         local has_bypass = core.check_player_privs(placer, "protection_bypass")
         local has_place_privilege = core.check_player_privs(placer, "setzen")
         if not (has_bypass or has_place_privilege) then
            -- Ausnahme für programmierbaren Block
            if newnode.name == "astridmod:program_node" then
               return
            end
            core.remove_node(pos)
            core.chat_send_player(placer:get_player_name(), "Du darfst gerade nichts setzen!")
         end
         return true -- blockiert das Setzen
      end
end)

-- freeze time
core.settings:set("time_speed",0)
