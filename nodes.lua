-- nodes
local modpath = core.get_modpath(core.get_current_modname())
-- formspec for program_node
local function style_errline(code, errline)
   if errline == nil then
      return code
   end
   local errstring = "ERROR -> "
   local last_offset = 0
   local offset = 0
   local lcounter = 1
   while lcounter <= errline do
      last_offset = offset
      offset,offset = code:find("\n", offset+1)
      offset = offset or code:len()
      lcounter = lcounter + 1
   end
   return code:sub(1,last_offset) ..
      (code:sub(last_offset+1, last_offset+errstring:len()) == errstring and
       "" or
       errstring)  ..
            code:sub(last_offset+1,code:len())
end

local function program_node_formspec(code, is_error, errline)
   local code = code or ""
   local is_error = (is_error == "true")
   local formspec = "formspec_version[4]" ..
      "size[25,25]" ..
      "label[1,1;Bitte Code eingeben!]" ..
      "style_type[label;textcolor=white]" ..
      (is_error and "box[15.9,0.5;2.3,1;#900000B0]" or "") ..
      (is_error and "label[16,1;FEHLER!]" or "") ..
      "style_type[label;textcolor=]" ..
      "button_exit[21.5,0.5;3,1;exit;Schließen]" ..
      "style[save;bgcolor=green]" ..
      "button[21.5,22;3,2;save;Speichern]" ..
      "textarea[1,2;20,20;code;hier:;"..
      style_errline(core.formspec_escape(code), errline) .."]" ..
      "button[1,22;20,2;enter;Ausführen!]"
   return formspec
end

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
convenience = dofile(modpath.."/convenience.lua") -- load convenience bindings
raetsel = dofile(modpath.."/raetsel.lua") -- load riddles

local static_prelude = "local nv = vector.new(0,0,0)\n" ..
   "local x = vector.new(1,0,0)\n" ..
   "local y = vector.new(0,1,0)\n" ..
   "local z = vector.new(0,0,1)\n"

for k,v in pairs(convenience.nodetable) do
   static_prelude = static_prelude ..
      "local " .. k .. " = \"" .. v .. "\"\n"
end

local y = vector.new(0,1,0)
-- r_decorator transform a function(pos) into
-- function(offset) with offset from program_node
local function r_decorator(f,pos,param2)
   return function(...)
      local tab = {...}
      tab[1] = pos + tab[1]:rotate_around_axis(-y, param2*math.pi/2)
      return f(unpack(tab))
   end
end

-- program node
core.register_node("astridmod:program_node", {
                      description = "Programmierblock",
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
                         meta:set_string("formspec", program_node_formspec("", "false", nil))
                      end,
                      on_receive_fields = function(pos, formname, fields, player)
                         if fields.quit then
                            return
                         end
                         if fields.enter then
                            local meta = core.get_meta(pos)
                            local node = core.get_node(pos)
                            local y = vector.new(0,1,0)

                            local twasistda = r_decorator(
                               function(tpos)
                                  local dasistda = core.get_node_or_nil(tpos)
                                  core.chat_send_player(player:get_player_name(), dasistda.name)
                               end, pos, node.param2)

                            local istdasda = r_decorator(
                               function(tpos, name)
                                  local test_node = core.get_node(tpos)
                                  if (test_node.name == name) then
                                     convenience.baue(pos+y,gruen)
                                  else
                                     convenience.baue(pos+y,rot)
                                  end
                               end, pos, node.param2)

                            local ptable = { pos = pos,
                                             player = player,
                                             baue = convenience.baue,
                                             entferne = convenience.entferne,
                                             schreibe = convenience.entferne,
                                             block = convenience.block,
                                             rotiere = convenience.rotiere,
                                             rbaue = r_decorator(convenience.baue, pos, node.param2),
                                             raetsel = raetsel,
                                             direction=node.param2,
                                             wasistda = r_decorator(convenience.wasistda, pos, node.param2),
                                             twasistda = twasistda,
                                             istdasda = istdasda
                                             }

                            local prelude = static_prelude ..
                               "local ptable = ...\n"
                            for k,_ in pairs(ptable) do
                               prelude = prelude ..
                                  "local " .. k .. " = " .. "ptable." .. k .. "\n"
                            end
                            prelude = prelude .. "\n" .. fshard_prelude(player)

                            local prelude_length = select(2, prelude:gsub('\n', '\n'))

                            local f
                            local err
                            local errline = nil
                            local _
                            f, err = loadstring(prelude ..
                                                 fields.code)
                            if f == nil then
                               meta:set_string("error", "true")
                               _,_,errline = err:find("^.*:(%d+):.*$")
                               errline = tonumber(errline) - prelude_length
                               err = err:gsub("^(.*:)%d+(:.*)$", "%1" .. errline .. "%2")
                               core.chat_send_player(player:get_player_name(), err)
                           else
                               local status, err = pcall(f, ptable)
                               if status == false then
                                  meta:set_string("error", "true")
                                  _,_,errline = err:find("^.*:(%d+):.*$")
                                  errline = tonumber(errline) - prelude_length
                                  err = err:gsub("^(.*:)%d+(:.*)$", "%1" .. errline .. "%2")
                                  core.chat_send_player(player:get_player_name(), err)
                               else
                                  meta:set_string("error", "false")
                               end
                            end
                            meta:set_string("code", fields.code)
                            meta:set_string("formspec", program_node_formspec(fields.code,
                                                                              meta:get_string("error"),
                                                                              errline
                            ))
                         end
                         if fields.save then
                            local meta = core.get_meta(pos)
                            meta:set_string("code", fields.code)
                            meta:set_string("formspec", program_node_formspec(fields.code,
                                                                              meta:get_string("error"),
                                                                              nil
                            ))
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

core.register_node("astridmod:virus", {
                      description = "Eat the world",
                      tiles = {"astridmod_virus_node.png"},
                      groups = {fleshy = 30, cracky=3}
})

-- function shard will inject all code it contains into program node prelude
local function use_function_shard(itemstack, user, pointed_thing)
   local text = itemstack:get_meta():get_string("text")
   local formspec = "formspec_version[4]" ..
      "size[25,25]" ..
      "label[1,1;Bitte Code eingeben!]" ..
      "button_exit[21.5,0.5;3,1;exit;Schließen]" ..
      "style[enter;textcolor=green]" ..
      "textarea[1,2;20,20;code;hier:;" ..
      core.formspec_escape(text) .. "]" ..
      "button[1,22;20,2;enter;Speichern!]"
   core.show_formspec(user:get_player_name(), "function_shard_entry", formspec)
end

core.register_craftitem("astridmod:function_shard", {
                           description = "Funktionsdiskette",
                           inventory_image = "astridmod_floppy.png",
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
