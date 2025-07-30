local modpath = core.get_modpath(core.get_current_modname())
convenience = dofile(modpath.."/convenience.lua")

local function baue(pos,name)
   local nlookup = convenience.nodetable[name]
   core.set_node(pos, { name = (nlookup or name) })
end

local raetsel = {}

raetsel[1] = {
   bauplan = function(pos)
      local size = 10
      local offset = {x = 3, y = 0, z = 3}
      local start = {
         x = pos.x + offset.x,
         y = pos.y + offset.y,
         z = pos.z + offset.z
      }
      -- Glaskasten bauen
      for i = 0, size-1 do
         for j = 0, size-1 do
            for k = 0, size-1 do
               local p = {
                  x = start.x + i,
                  y = start.y + j,
                  z = start.z + k
               }
               baue(p, "glas")
            end
         end
      end
      -- Erdklötze an festen Positionen im Kasten platzieren
      local erde_positionen = {
         {2,2,2}, {3,3,3}, {4,4,4}, {5,5,5}, {6,6,6},
         {2,7,2}, {7,2,7}, {7,7,2}, {2,7,7}, {5,2,5}
      }
      for _, rel in ipairs(erde_positionen) do
         local p = {
            x = start.x + rel[1],
            y = start.y + rel[2],
            z = start.z + rel[3]
         }
         baue(p, "erde")
      end
   end,
   test = function(pos)
      local offset = {x = 3, y = 0, z = 3}
      local start = {
         x = pos.x + offset.x,
         y = pos.y + offset.y,
         z = pos.z + offset.z
      }
      local erde_positionen = {
         {2,2,2}, {3,3,3}, {4,4,4}, {5,5,5}, {6,6,6},
         {2,7,2}, {7,2,7}, {7,7,2}, {2,7,7}, {5,2,5}
      }
      for _, rel in ipairs(erde_positionen) do
         local p = {
            x = start.x + rel[1],
            y = start.y + rel[2],
            z = start.z + rel[3]
         }
         local node = core.get_node(p)
         if node.name ~= "gold" and node.name ~= "mcl_core:goldblock" then
            return false -- Mindestens ein Block ist kein Gold!
         end
      end
      return true -- Alle Erdklötze sind Gold!
   end
}

raetsel[2] = {
   bauplan = function(pos)
      local size_x, size_y, size_z = 10, 20, 10
      local offset = {x = 5, y = 0, z = 5}
      local start = {
         x = pos.x + offset.x,
         y = pos.y + offset.y,
         z = pos.z + offset.z
      }

      -- Bereich aus Luft "säubern"
      for i = 0, size_x-1 do
         for j = 0, size_y-1 do
            for k = 0, size_z-1 do
               baue({x = start.x + i, y = start.y + j, z = start.z + k}, "luft")
            end
         end
      end

      -- Plattformen bauen (so, dass man nicht direkt hochspringen kann)
      local plattformen = {
         {x=2, y=2, z=2},
         {x=7, y=6, z=3},
         {x=3, y=10, z=7},
         {x=6, y=14, z=5},
         {x=4, y=18, z=8}
      }
      for _, rel in ipairs(plattformen) do
         -- Jede Plattform ist 3x3 groß
         for dx = 0,2 do
            for dz = 0,2 do
               baue({
                     x = start.x + rel.x + dx,
                     y = start.y + rel.y,
                     z = start.z + rel.z + dz
                    }, "stein")
            end
         end
      end

      -- Truhe mit Preis auf oberster Plattform
      local truhe_pos = {
         x = start.x + plattformen[#plattformen].x + 1,
         y = start.y + plattformen[#plattformen].y + 1,
         z = start.z + plattformen[#plattformen].z + 1
      }
      baue(truhe_pos, "truhe")
      -- Preis in die Truhe legen (z.B. Diamant)
      local truhe_meta = core.get_meta(truhe_pos)
      truhe_meta:get_inventory():set_stack("main", 1, "diamant")
   end,
   test = nil
}

return raetsel
