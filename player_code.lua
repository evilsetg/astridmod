local modpath = core.get_modpath(core.get_current_modname())
convenience = dofile(modpath.."/convenience.lua") -- load convenience bindings
raetsel = dofile(modpath.."/raetsel.lua") -- load riddles

-- convenience functions for program_node
local static_prelude = "local nv = vector.new(0,0,0)\n" ..
   "local x = vector.new(1,0,0)\n" ..
   "local y = vector.new(0,1,0)\n" ..
   "local z = vector.new(0,0,1)\n"

for k,v in pairs(convenience.nodetable) do
   static_prelude = static_prelude ..
      "local " .. k .. " = \"" .. v .. "\"\n"
end

-- r_decorator transform a function(pos) into
-- function(offset) with offset from program_node
local function r_decorator(f,pos,param2)
   local y = vector.new(0,1,0)
   return function(...)
      local tab = {...}
      tab[1] = pos + tab[1]:rotate_around_axis(-y, param2*math.pi/2)
      return f(unpack(tab))
   end
end

-- include function_shards in player inventory into player code prelude
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

-- player code evaluation
local function eval_player_code(code, player, pos, dir)
   local y = vector.new(0,1,0)

   local twasistda = r_decorator(
      function(tpos)
         local dasistda = core.get_node_or_nil(tpos)
         core.chat_send_player(player:get_player_name(), dasistda.name)
      end, pos, dir)

   local istdasda = r_decorator(
      function(tpos, name)
         local test_node = core.get_node(tpos)
         if (test_node.name == name) then
            convenience.baue(pos+y,gruen)
         else
            convenience.baue(pos+y,rot)
         end
      end, pos, dir)

   local ptable = { pos = pos,
                    player = player,
                    baue = convenience.baue,
                    entferne = convenience.entferne,
                    schreibe = convenience.entferne,
                    block = convenience.block,
                    rotiere = convenience.rotiere,
                    rbaue = r_decorator(convenience.baue, pos, dir),
                    raetsel = raetsel,
                    richtung=dir,
                    wasistda = r_decorator(convenience.wasistda, pos, dir),
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
                       code)
   if f == nil then
      _,_,errline = err:find("^.*:(%d+):.*$")
      errline = tonumber(errline) - prelude_length
      err = err:gsub("^(.*:)%d+(:.*)$", "%1" .. errline .. "%2")
      core.chat_send_player(player:get_player_name(), err)
      return err,errline
   else
      local status, err = pcall(f, ptable)
      if status == false then
         _,_,errline = err:find("^.*:(%d+):.*$")
         errline = tonumber(errline) - prelude_length
         err = err:gsub("^(.*:)%d+(:.*)$", "%1" .. errline .. "%2")
         core.chat_send_player(player:get_player_name(), err)
         return err, errline
      else
         return nil
      end
   end
end

return {eval_player_code = eval_player_code}
