local convenience = {}

convenience.nodetable = {
   -- blocks
   luft = "air",
   stein = "mcl_core:stone",
   erde = "mcl_core:dirt",
   gras = "mcl_core:dirt_with_grass",
   kies = "mcl_core:gravel",
   sand = "mcl_core:sand",
   eisen = "mcl_core:ironblock",
   gold = "mcl_core:goldblock",
   diamant = "mcl_core:diamondblock",
   glas = "mcl_core:glass",
   gras = "mcl_core:dirt_with_grass",
   holz = "mcl_core:wood",
   stamm = "mcl_core:tree",
   blaetter = "mcl_core:leaves",
   wasser = "mcl_core:water_source",
   lava = "mcl_core:lava_source",
   kohlestein = "mcl_core:stone_with_coal",
   eisenstein = "mcl_core:stone_with_iron",
   goldstein = "mcl_core:stone_with_gold",
   diamantstein = "mcl_core:stone_with_diamond",
   ziegel = "mcl_core:brickblock",
   -- other nodes
   fackel = "mcl_torches:torch",
   tuer = "mcl_doors:door_wood",
   truhe = "mcl_chests:chest",
   werkbank = "mcl_crafting_table:crafting_table",
   ofen = "mcl_furnaces:furnace",
   bett = "mcl_beds:bed",
   -- colors
   weiß = "mcl_wool:white",
   hellgrau = "mcl_wool:silver",
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

convenience.baue =  function(pos, name)
   core.set_node(pos, {name = name})
end

convenience.entferne = function(pos)
   core.set_node(pos, {name = "air"})
end

convenience.schreibe = function(text)
   core.chat_send_all(text)
end

return convenience
