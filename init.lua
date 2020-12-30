local current_modname = minetest.get_current_modname()
local path = minetest.get_modpath(current_modname)

local mod_util = dofile(path.."/utils/mod.lua")
local mod = mod_util.export({}).from(current_modname)

mod.config = dofile(path.."/config.lua")

local tool_util = dofile(path.."/utils/toolnode.lua")

function register(items)
	for name,def in pairs(items) do
		tool_util.register_toolnode(def)
	end
end

minetest.register_on_mods_loaded(function()
	if mod.config.items.tools.enabled then
		register(minetest.registered_tools)
	end
	
	if mod.config.items.craftitems.enabled then
		register(minetest.registered_craftitems)
	end
end)
