-- imports
local modpath = core.get_modpath(core.get_current_modname())
player_code = dofile(modpath .. "/player_code.lua")
convenience = dofile(modpath.."/convenience.lua") -- load convenience bindings
raetsel = dofile(modpath.."/raetsel.lua") -- load riddles

-- nodes
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
                         local meta = core.get_meta(pos)
                         local errline
                         if fields.enter then
                            local err
                            local node = core.get_node(pos)
                            err, errline = player_code.eval_player_code(fields.code, player, pos, node.param2)
                            if (err ~= nil) then
                               meta:set_string("error", "true")
                               meta:set_string("errmsg", err)
                            else
                               meta:set_string("error", "false")
                               meta:set_string("errmsg", "")
                            end
                         end
                         if fields.save or fields.enter then
                            meta:set_string("code", fields.code)
                            meta:set_string("formspec",
                                            program_node_formspec(fields.code,
                                                                  meta:get_string("error"),
                                                                  errline))
                         end
                      end
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
   core.show_formspec(user:get_player_name(), "astridmod:function_shard_entry", formspec)
end

core.register_craftitem("astridmod:function_shard", {
                           description = "Funktionsdiskette",
                           inventory_image = "astridmod_floppy.png",
                           stack_max = 1,
                           on_secondary_use = use_function_shard,
                           on_place = use_function_shard
})

core.register_on_player_receive_fields(function(player, formname, fields)
      if (formname == "astridmod:function_shard_entry") then
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

local function wand_write_spell(itemstack, user, pointed_thing)
   local spell = itemstack:get_meta():get_string("spell")
   local formspec = "formspec_version[4]" ..
      "size[25,25]" ..
      "label[1,1;Bitte Code eingeben!]" ..
      "button_exit[21.5,0.5;3,1;exit;Schließen]" ..
      "style[enter;textcolor=green]" ..
      "textarea[1,2;20,20;code;hier:;" ..
      core.formspec_escape(spell) .. "]" ..
      "button[1,22;20,2;enter;Speichern!]"
   core.show_formspec(user:get_player_name(), "astridmod:codewand_entry", formspec)
end

core.register_on_player_receive_fields(function(player, formname, fields)
      if (formname == "astridmod:codewand_entry") then
         local stack = player:get_wielded_item()
         if (stack:get_name() == "astridmod:code_wand") then
            local meta = stack:get_meta()
            if fields.enter then
               meta:set_string("spell", fields.code)
               player:set_wielded_item(stack)
            end
         end
      end
end)

function rad_to_param2(rad)
   if rad >= math.pi then
      mrad = rad - 2*math.pi
   else
      mrad = rad
   end
   if (mrad >=  - (math.pi)/4 and mrad < math.pi/4) then
      return 0
   elseif (rad >= math.pi/4 and rad < 3*math.pi/4) then
      return 3
   elseif (rad >= 3*math.pi/4 and rad < 5*math.pi/4) then
      return 2
   else
      return 1
   end
end


local function wand_on_use(itemstack, user, pointed_thing)
   local meta = itemstack:get_meta()
   local code = meta:get_string("spell")
   local dir = rad_to_param2(user:get_look_horizontal())
   local pos
   if (pointed_thing.type == "node") then
      pos = pointed_thing.under
   else
      pos = user:get_pos()
   end
   player_code.eval_player_code(code, user, pos, dir)
end


core.register_tool("astridmod:code_wand", {
                      description = "Zauberstab",
                      inventory_image = "astridmod_codewand.png",
                      on_secondary_use = wand_write_spell,
                      on_place = wand_write_spell,
                      on_use = wand_on_use
})
