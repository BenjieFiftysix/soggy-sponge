--[[
  -  Sponge mod for Minetest
  -  water removal for survival

made by Benjie/Fiftysix - 27/8/18
updated 22/12/20

Soggy sponges can rarely be found deep in the sea where the darkness begins.
These can be cooked into dry sponges, and then placed near a liquid to remove an area of it
They will hold the water away until they are removed.
This will cause them to become soggy, so to use them again they have to be cooked.

Sponges create a 9x9 area of air-like nodes that water can't flow through (checks for protection)
If sponges have cleared more than 3 nodes of liquid, they become soggy sponges
removing a sponge or soggy sponge will turn a 9x9 area of air-like nodes back into air
(air-like nodes can be removed in protection by removing a sponge outside the protection, they are not meant to be permanent)
]]--

local area = 4  -- The "radius" (of the cube) to clear water
local keep_dry = 3  -- The maximum amount of water cleared where the sponge doesn't turn soggy

local modname = minetest.get_current_modname()


-- called by after_destruct()
local destruct = function(pos)  -- removing the air-like nodes
    
    -- find all sponges that intersect with this sponge's area
    local sponge_info = minetest.find_nodes_in_area(
        {x=pos.x-area*2, y=pos.y-area*2, z=pos.z-area*2}, {x=pos.x+area*2, y=pos.y+area*2, z=pos.z+area*2},
        {modname..":soggy_sponge", modname..":sponge"}, true
    )
    local sponges = {}
    for _, p in pairs(sponge_info) do
        local node = minetest.get_node(p)
        if node.param1 == 1 or node.name == modname..":sponge" then
            table.insert(sponges, p)
        end
    end

    for x = pos.x-area, pos.x+area do
        for y = pos.y-area, pos.y+area do
            for z = pos.z-area, pos.z+area do
                local n = minetest.get_node({x=x, y=y, z=z}).name
                if n == modname..":liquid_stop" then
                    
                    -- check if position intersects with another sponge
                    local intersect = false
                    for _, s_pos in pairs(sponges) do
                        if math.abs(s_pos.x-x) <= area and math.abs(s_pos.y-y) <= area and math.abs(s_pos.z-z) <= area then
                            intersect = true
                            break
                        end
                    end
                    
                    if not intersect then
                        minetest.remove_node({x=x, y=y, z=z})
                    end
                end
            end
        end
    end
end

-- called by after_place_node()
local construct = function(pos, placer, itemstack, pointed_thing)
    local playername = placer:get_player_name()

    if not minetest.is_protected(pos, playername) then
        local count = 0
        
        for x = pos.x-area, pos.x+area do
            for y = pos.y-area, pos.y+area do
                for z = pos.z-area, pos.z+area do
                    
                    local n = minetest.get_node({x=x, y=y, z=z}).name
                    local def = minetest.registered_nodes[n]
                    if def ~= nil and (n == "air" or def["drawtype"] == "liquid" or def["drawtype"] == "flowingliquid") then
                        local p = {x=x, y=y, z=z}
                        if not minetest.is_protected(p, playername) then
                            if n ~= "air" then
                                count = count + 1  -- counting liquids
                            end
                            minetest.set_node(p, {name=modname..":liquid_stop"})
                        end
                    end
                end
            end
        end
        
        if count > keep_dry then  -- turns soggy if it removed more than `keep_dry` nodes
            minetest.swap_node(pos, {name=modname..":soggy_sponge", param1=1})
        end
    end
end


minetest.register_node(modname..":liquid_stop", {  -- air-like node
    description = "liquid blocker for sponges",
    drawtype = "airlike",
    drop = {max_items=0, items={}},
    groups = {not_in_creative_inventory=1},
    pointable = false,
    walkable = false,
    floodable = false,
    sunlight_propagates = true,
    paramtype = "light",
    buildable_to = true,
})


minetest.register_node(modname..":sponge", {  -- dry sponge
    description = "Sponge",
    tiles = {"sponge_sponge.png"},
    groups = {crumbly=3},
    sounds = default.node_sound_dirt_defaults(),
    
    after_place_node = construct,
    
    after_destruct = destruct,
})


minetest.register_node(modname..":soggy_sponge", {  -- soggy sponge
    description = "Soggy sponge",
    tiles = {"sponge_soggy_sponge.png"},
    groups = {crumbly=3},
    sounds = default.node_sound_dirt_defaults(),
    
    after_destruct = destruct,
})

minetest.register_craft({  -- cooking soggy sponge back into dry sponge
    type = "cooking",
    recipe = modname..":soggy_sponge",
    output = modname..":sponge",
    cooktime = 2,
})

minetest.register_decoration({  -- sponges are found deep in the sea
    name = modname..":sponges",
    deco_type = "simple",
    place_on = {"default:sand"},
    spawn_by = "default:water_source",
    num_spawn_by = 3,
    fill_ratio = 0.0003,
    y_max = -12,
    flags = "force_placement",
    decoration = modname..":soggy_sponge",
})
