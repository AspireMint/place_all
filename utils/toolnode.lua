local current_modname = minetest.get_current_modname()
local path = minetest.get_modpath(current_modname)

local mod_util = dofile(path.."/utils/mod.lua")
local mod = mod_util.import.from(current_modname)

local util = {}

local MAX_WEAR = 65535
function place_node(placer, pos, node_name, itemstack)
	local dir = placer:get_look_dir()
	local param2 = minetest.dir_to_wallmounted(dir)
	minetest.set_node(pos, {name = node_name, param2 = param2})
	
	local amount = itemstack:get_wear()
	local meta = minetest.get_meta(pos)
	if amount ~= 0 then
		local wornout = math.floor((1-(amount/MAX_WEAR))*100)
		meta:set_string("infotext", "Condition: "..wornout.."%")
		meta:set_int("wear", amount)
	end
end

local get_wield_image = function(def)
	if def.wield_image and def.wield_image ~= "" then
		return def.wield_image
	else
		return def.inventory_image
	end
end

local can_dig = function(pos, player)
	local player_name = player and player:get_player_name() or ""
	if minetest.is_protected(pos, player_name) then
		minetest.record_protection_violation(pos, player_name)
		return false
	end
	return true
end

local swap = function(placer, pos, new_node_name, itemstack)
	local node = minetest.get_node(pos)
	local item_take = itemstack:take_item()
	minetest.after(0, function()
		minetest.node_dig(pos, node, placer)
		place_node(placer, pos, new_node_name, item_take)
	end)
	return itemstack
end

local split_name = function(name)
	return string.match(name, "([^.]*):(.*)")
end

util.register_toolnode = function(def)
	local origin, tool_name = split_name(def.name)
	if not origin then
		return
	end
	
	local ndef = {
		description = def.description,
		short_description = def.short_description,
		paramtype = "light",
		paramtype2 = "wallmounted",
		drawtype = "mesh",
		mesh = "place_all_wallmounted.obj",
		tiles = def.tiles or { def.inventory_image.."" },
		inventory_image = def.inventory_image,
		inventory_overlay = "overlay.png",
		wield_image = get_wield_image(def),
        wield_overlay = def.wield_overlay,
		wield_scale = def.wield_scale,
		sunlight_propagates = true,
		walkable = false,
		light_source = def.light_source,
		sounds = minetest.get_modpath("default") and default.node_sound_wood_defaults(),
		drop = def.name,
		groups = {
			wood = 1, --shhh
			choppy = 2,
			oddly_breakable_by_hand = 3,
			attached_node = 1,
			not_in_creative_inventory = mod.config.not_in_creative_inventory and 1 or nil
		}
	}
	
	ndef.selection_box = {
		type = "fixed",
		fixed = {
			{-1/2, -1/2, -1/2, 1/2, -7/16, 1/2}
		},
	}
	
	ndef.preserve_metadata = function(pos, oldnode, oldmeta, drops)
		local wear = oldmeta["wear"]
		if wear then
			drops[1]:set_wear(wear)
		end
	end
	
	ndef.can_dig = can_dig
	
	local new_node_name = current_modname..":"..origin.."_"..tool_name
	minetest.register_node(":"..new_node_name, ndef)
	
	local old_on_place = def.on_place
	minetest.override_item(def.name, {
		on_place = function(itemstack, placer, pointed_thing)
			if minetest.is_player(placer) and placer:get_player_control_bits() == 288 then
				if pointed_thing.type ~= "node" then
					return
				end
				
				local pos_under = pointed_thing.under
				if pos_under then
					local name = minetest.get_node(pos_under).name
					if split_name(name) == current_modname then
						if can_dig(pos_under) then
							return swap(placer, pos_under, new_node_name, itemstack)
						end
						return
					end
				end
				
				if minetest.check_player_privs(placer, "creative") then
					return
				end
				
				local pos = pointed_thing.above
				if not can_dig(pos, placer) then
					return
				end
				
				place_node(placer, pos, new_node_name, itemstack)
				itemstack:take_item()
				return itemstack
			end
			
			return old_on_place(itemstack, placer, pointed_thing)
		end
	})
end

return util
