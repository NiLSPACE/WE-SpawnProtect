
--[[Created by STR_Warrior]]--




--- This dictionary stores each world in which the WE SpawnProtect is activated
-- Each world's table contains MaxX, MaxZ, MinX, MinZ specifying the block coordinates of the protection
g_Worlds = {}





function Initialize(a_Plugin)
	cPluginManager.AddHook(cPluginManager.HOOK_PLUGINS_LOADED, OnPluginsLoaded)
	
	return true
end





function OnPluginsLoaded()
	-- Add a WE Hook to each world that currently exists
	cRoot:Get():ForEachWorld(
		function (a_World)
			HookWorld(a_World:GetName())
		end
	)
end





--- Adds a WE hook for the specified world
function HookWorld(a_WorldName)
	assert(type(a_WorldName) == "string")
	
	-- If the world is not yet in the world dictionary, add it:
	if (g_Worlds[a_WorldName] == nil) then
		g_Worlds[a_WorldName] = {}
	end
	
	-- If the world hasn't been hooked yet, hook it
	if not(g_Worlds[a_WorldName].IsHooked) then
		g_Worlds[a_WorldName].IsHooked = cPluginManager:CallPlugin("WorldEdit", "RegisterAreaCallback", cPluginManager:GetCurrentPlugin():GetName(), "WorldEditCallback", a_WorldName)
		-- Display a log message to the admin if the world is protected
		if (g_Worlds[a_WorldName].IsHooked) then
			LOGINFO("WE-SpawnProtect is protecting world " .. a_WorldName)
		end
	end
	
end





--- Returns the protection params for the specified world
-- Loads the values from the World.ini file, if not already loaded
function GetWorldProtectionParams(a_World)
	assert(type(a_World) == "userdata")
	
	-- Make sure the world's entry exists
	local res = g_Worlds[a_World:GetName()]
	if (res == nil) then
		res = {}
		g_World[a_World:GetName()] = res
		LOGWARNING("WE-SpawnProtect: weird state, reading protection params for a world that hasn't been hooked")
	end
	
	-- If the world params have already been loaded before, just return them from cache:
	if ((res ~= nil) and res.IsLoaded) then
		return res;
	end
	
	-- Load the params from World.ini:
	local WorldIni = cIniFile()
	WorldIni:ReadFile(a_World:GetIniFileName())
	local IsEnabled = WorldIni:GetValueSetB("SpawnProtect", "Enable", true)
	if (IsEnabled) then
		local Radius = WorldIni:GetValueSetI("SpawnProtect", "ProtectRadius", 10)
		res.MaxX = a_World:GetSpawnX() + Radius
		res.MaxZ = a_World:GetSpawnZ() + Radius
		res.MinX = a_World:GetSpawnX() - Radius
		res.MinZ = a_World:GetSpawnZ() - Radius
	end
	WorldIni:WriteFile(a_World:GetIniFileName())
	res.IsLoaded = true
	return res
end





--- WorldEdit calls this function for each operation that it wants to execute
-- This function returns true to abort the operation, false to continue
function WorldEditCallback(a_MinX, a_MaxX, a_MinY, a_MaxY, a_MinZ, a_MaxZ, a_Player, a_World, a_Operation)
	-- Allow permission-based override
	if (a_Player:HasPermission("we-spawnprotect.build")) then
		return false
	end
	
	-- Check if the area affected by the operation is protected:
	local WorldParams = GetWorldProtectionParams(a_World)
	if (
		(WorldParams.MinX == nil) or (WorldParams.MaxX == nil) or
		(WorldParams.MinZ == nil) or (WorldParams.MaxZ == nil)
	) then
		-- This world is not protected
		return false
	end
	local ProtectedCuboid = cCuboid(WorldParams.MinX, 0, WorldParams.MinZ, WorldParams.MaxX, 255, WorldParams.MaxZ)
	if (ProtectedCuboid:DoesIntersect(cCuboid(a_MinX, a_MinY, a_MinZ, a_MaxX, a_MaxY, a_MaxZ))) then
		a_Player:SendMessage(cChatColor.Rose .. "You can't build in the spawn.")
		return true
	end
	
	-- Outside the protected area:
	return false
end
	