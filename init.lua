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

-- nodes

-- formspec for program_node
local function program_node_formspec(code,is_error)
   local code = code or ""
   local is_error = (is_error == "true")
   local formspec = "formspec_version[4]" ..
      "size[25,25]" ..
      "label[1,1;Bitte Code eingeben!]" ..
      "style_type[label;textcolor=red]" ..
      (is_error and "label[16,1;FEHLER!]" or "") ..
      "style_type[label;textcolor=]" ..
      "button_exit[21.5,0.5;3,1;exit;Schließen]" ..
      "style[save;textcolor=green]" ..
      "button[21.5,22;3,2;save;Speichern]" ..
      "textarea[1,2;20,20;code;hier:;".. code .."]" ..
      "button[1,22;20,2;enter;Ausführen!]"
   return formspec
end


core.register_node("astridmod:virus", {
                      description = "Eat the world",
                      tiles = {"astridmod_virus_node.png"},
                      groups = {fleshy = 30, cracky=3}
})

-- include function_shards in player inventory into program_block prelude
function fshard_prelude(player)
   local inv = player:get_inventory()
   local main_inv = inv:get_list("main")
   local acc = ""
   for i = 1,9 do -- check in hotbar slots
      local stack = main_inv[i]
      if stack:get_name() == "astridmod:function_shard" then
         acc = acc .. stack:get_meta():get_string("text") .. "\n"
      end
   end
   return acc
end

-- convenience functions for program_node
local nodetable = {
   luft = "air",
   stein = "mcl_core:stone",
   erde = "mcl_core:dirt",
   kies = "mcl_core:gravel",
   sand = "mcl_core:sand",
   eisen = "mcl_core:ironblock",
   gold = "mcl_core:goldblock",
   diamant = "mcl_core:diamondblock",
   glas = "mcl_core:glass",
   weiß = "mcl_wool:white",
   silber = "mcl_wool:silver",
   grau = "mcl_wool:gray",
   schwarz = "mcl_wool:black",
   lila = "mcl_wool:purple",
   blau = "mcl_wool:blue",
   hellblau = "mcl_wool:light_blue",
   cyan = "mcl_wool:cyan",
   gruen = "mcl_wool:green",
   gelbgruen = "mcl_wool:lime",
   gelb = "mcl_wool:yellow",
   braun = "mcl_wool:brown",
   orange = "mcl_wool:orange",
   rot = "mcl_wool:red",
   magenta = "mcl_wool:magenta",
   pink = "mcl_wool:pink"
}

local function baue(pos, name)
   core.set_node(pos, {name = name})
end

local static_prelude = "local x = vector.new(1,0,0)\n" ..
   "local y = vector.new(0,1,0)\n" ..
   "local z = vector.new(0,0,1)\n"

for k,v in pairs(nodetable) do
   static_prelude = static_prelude ..
      "local " .. k .. " = \"" .. v .. "\"\n"
end

-- program node
core.register_node("astridmod:program_node", {
                      description = "Programmable block",
                      tiles = {"astridmod_program_node_top.png",
                               "astridmod_program_node_bottom.png",
                               "astridmod_program_node_face.png"
                      },
                      groups = {cracky = 3},
                      diggable = false,
                      paramtype2 = "4dir",
                      on_place = function(itemstack, placer, pointed_thing)
                         local p1 = pointed_thing.above
                         local param2 = 0

                         if placer then
                            local placer_pos = placer:get_pos()
                            if placer_pos then
                               param2 = core.dir_to_facedir(vector.subtract(p1, placer_pos))
                            end
                         end
                         return core.item_place_node(itemstack, placer, pointed_thing, param2)
                      end,
                      after_place_node = function(pos, placer, itemstack, pointed_thing)
                         if placer and placer:is_player() then
                            local meta = core.get_meta(pos)
                            meta:set_string("owner", placer:get_player_name())
                         end
                         local meta = core.get_meta(pos)
                         meta:set_string("error", "false")
                         meta:set_string("formspec", program_node_formspec("", "false"))
                      end,
                      on_receive_fields = function(pos, formname, fields, player)
                         if fields.quit then
                            return
                         end
                         if fields.enter then
                            local meta = core.get_meta(pos)
                            local node = core.get_node(pos)
                            local y = vector.new(0,1,0)
                            local function rbaue(offset, name)
                               local roffset = offset:rotate_around_axis(-y,node.param2*math.pi/2)
                               core.set_node(pos+roffset, {name = name})
                            end
                            local ptable = { pos = pos,
                                             player = player,
                                             baue = baue,
                                             rbaue = rbaue,
                                             direction=node.param2}

                            local prelude = static_prelude ..
                               "local ptable = ...\n"
                            for k,_ in pairs(ptable) do
                               prelude = prelude ..
                                  "local " .. k .. " = " .. "ptable." .. k .. "\n"
                            end
                            prelude = prelude .. "\n" .. fshard_prelude(player)

                            local f = loadstring(prelude ..
                                                 fields.code)
                            status, res = pcall(f, ptable)

                            if status == false then
                               meta:set_string("error", "true")
                               core.chat_send_player(player:get_player_name(), res)
                            else
                               meta:set_string("error", "false")
                            end
                            meta:set_string("code", fields.code)
                            meta:set_string("formspec", program_node_formspec(fields.code, meta:get_string("error")))
                         end
                         if fields.save then
                            local meta = core.get_meta(pos)
                            meta:set_string("code", fields.code)
                            meta:set_string("formspec", program_node_formspec(fields.code, meta:get_string("error")))
                         end
                      end
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
                         core.sound_play("astridmod_pain")
                         core.node_dig(pos, node, digger)
                      end

})

core.register_craft({
      type = "shapeless",
      output = "astridmod:program_node 3",
      recipe = { "mcl_core:dirt", "mcl_core:stone" }
})

local function use_function_shard(itemstack, user, pointed_thing)
   local text = itemstack:get_meta():get_string("text")
   local formspec = "formspec_version[4]" ..
      "size[25,25]" ..
      "label[1,1;Bitte Code eingeben!]" ..
      "button_exit[21.5,0.5;3,1;exit;Schließen]" ..
      "style[enter;textcolor=green]" ..
      "textarea[1,2;20,20;code;hier:;" .. text .. "]" ..
      "button[1,22;20,2;enter;Speichern!]"
   core.show_formspec(user:get_player_name(), "function_shard_entry", formspec)
end

core.register_craftitem("astridmod:function_shard", {
                           description = "Funktionsscherbe",
                           inventory_image = "astridmod_function_shard.png",
                           stack_max = 1,
                           on_secondary_use = use_function_shard,
                           on_place = use_function_shard
})

core.register_on_player_receive_fields(function(player, formname, fields)
      if (formname == "function_shard_entry") then
         local stack = player:get_wielded_item()
         if (stack:get_name() == "astridmod:function_shard") then
            local meta = stack:get_meta()
            if fields.enter then
               meta:set_string("text", fields.code)
               player:set_wielded_item(stack)
            end
         end
      end
end)
