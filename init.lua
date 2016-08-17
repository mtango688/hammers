-- a proper implementation of sledge hammers (as defined by gsmanners)
--
-- this hammer digs perpendicular to pointed_thing (the direction a block would place)
-- so your aim doesn't really matter (just which side of the block you point at)
--
-- license: WTFPL

local function get_3x3s(pointed_thing)
	local r = {}

	local under = pointed_thing.under
	local above = pointed_thing.above

	local a = 0		-- forward/backward
	if math.abs(under.x - above.x) > 
		math.abs(under.z - above.z) then a = 1 end -- sideways

	local b = 0		-- horizontal
	if under.y ~= above.y then b = 1 end	-- vertical

	local c = 1
	for x=-1,1 do
	for y=-1,1 do
		if x ~= 0 or y ~= 0 then

			-- determine next perpendicular node
			local k = {x=0, y=0, z=0}
			if a > 0 then
				k.z = under.z + x
				if b > 0 then
					k.x = under.x + y
					k.y = under.y
				else
					k.x = under.x
					k.y = under.y + y
				end
			else
				k.x = under.x + x
				if b > 0 then
					k.y = under.y
					k.z = under.z + y
				else
					k.y = under.y + y
					k.z = under.z
				end
			end
			r[c] = {x=k.x, y=k.y, z=k.z}
			c = c + 1

		end
	end
	end

	return r
end

-- record pointed_thing and hope it doesn't suddenly change for some reason

local punch = {}

local function on_punch(pos, node, puncher, pointed_thing)
	if puncher then
		local wielded = puncher:get_wielded_item()
		local rank = minetest.get_item_group(wielded:get_name(), "hammer")
		if rank > 0 then
			local n = puncher:get_player_name()
			local p = pointed_thing.above
			if pointed_thing.type == "node" and p then
				punch.n = {x=p.x, y=p.y, z=p.z}
			end
		end
	end
end

local busy = {}

local function on_hammer(pos, oldnode, digger)
	if not digger then return end

	if digger then
		local n = digger:get_player_name()
		if not busy.n then
			local wielded = digger:get_wielded_item()
			local rank = minetest.get_item_group(wielded:get_name(), "hammer")
			if rank > 0 then
				busy.n = true
	
				local p = { under = {x=pos.x, y=pos.y, z=pos.z} }
				p.above = {x=pos.x, y=pos.y+1, z=pos.z}
				if punch.n then
					p.above = punch.n
				end
	
				local caps = wielded:get_tool_capabilities()
				for _,k in ipairs(get_3x3s(p)) do
					local node = minetest.get_node(k)
					local level = minetest.get_item_group(node.name, "level")
					local cracky = minetest.get_item_group(node.name, "cracky")
					local tc = caps.groupcaps.cracky.times[cracky]
					if tc and rank >= level then
						minetest.node_dig(k, node, digger)
					end
				end
				busy.n = nil
			end
		end
	end
end

-- on_use doesn't work like normal tools and after_use doesn't provide needed info
-- which is pretty lame, but what else is new?

minetest.register_on_punchnode(on_punch)
minetest.register_on_dignode(on_hammer)

minetest.register_tool("hammers:hammer_stone", {
	description = "Stone Hammer",
	groups = {hammer=1},
	inventory_image = "hammers_stone.png",
	tool_capabilities = {
		full_punch_interval = 2.5,
		max_drop_level=0,
		groupcaps={
			cracky = {times={[2]=3.0, [3]=2.5}, uses=250, maxlevel=1},
		},
		damage_groups = {fleshy=7},
	},
})

minetest.register_tool("hammers:hammer_bronze", {
	description = "Bronze Hammer",
	groups = {hammer=2},
	inventory_image = "hammers_bronze.png",
	tool_capabilities = {
		full_punch_interval = 0.5,
		max_drop_level=1,
		groupcaps={
			cracky = {times={[1]=1.0, [2]=0.75, [3]=0.5}, uses=500, maxlevel=2},
		},
		damage_groups = {fleshy=7},
	},
})

minetest.register_tool("hammers:hammer_obsidian", {
	description = "Obsidian Hammer",
	groups = {hammer=3},
	inventory_image = "hammers_obsidian.png",
	tool_capabilities = {
		full_punch_interval = 1.5,
		max_drop_level=1,
		groupcaps={
			cracky = {times={[1]=2.5, [2]=2.0, [3]=1.5}, uses=900, maxlevel=3},
		},
		damage_groups = {fleshy=8},
	},
})

minetest.register_craft({
	output = "hammers:hammer_stone",
	recipe = {
		{"default:stone_block","default:stone_block","default:stone_block"},
		{"", "default:steel_ingot",""},
		{"", "default:steel_ingot",""}
	}
})

minetest.register_craft({
	output = "hammers:hammer_bronze",
	recipe = {
		{"default:bronze_ingot", "default:bronze_ingot", "default:bronze_ingot"},
		{"default:bronze_ingot", "default:bronze_ingot", "default:bronze_ingot"},
		{"", "hammers:hammer_stone", ""}
	}
})

minetest.register_craft({
	output = "hammers:hammer_obsidian",
	recipe = {
		{"default:obsidian", "default:obsidian", "default:obsidian"},
		{"default:obsidian", "default:obsidian", "default:obsidian"},
		{"", "hammers:hammer_stone", ""}
	}
})
