--[[Created by STR_Warrior]]--
a_Worlds = {}

function Initialize(Plugin)
	PLUGIN = Plugin
	PLUGIN:SetName("WE SpawnProtect")
	PLUGIN:SetVersion(1)
	
	local WE = cRoot:Get():GetPluginManager():GetPlugin("WorldEdit")
	if not WE then -- WorldEdit plugin doesn't exist. Bail out.
		LOGERROR("[WE SpawnProtect] WorldEdit plugin was not found. If it is installed then load this plugin after WorldEdit.")
		return false
	end
	
	cRoot:Get():ForEachWorld(function(World)
		local WorldIni = cIniFile()
		WorldIni:ReadFile(World:GetIniFileName())
		local Enabled = WorldIni:GetValueSetB("SpawnProtect", "Enable", true)
		if Enabled then
			local Radius = WorldIni:GetValueSetI("SpawnProtect", "ProtectRadius", 10)
			a_Worlds[World:GetName()] = {
				MinX = World:GetSpawnX() - Radius,
				MinY = World:GetSpawnY() - Radius,
				MinZ = World:GetSpawnZ() - Radius,
				
				MaxX = World:GetSpawnX() + Radius,
				MaxY = World:GetSpawnY() + Radius,
				MaxZ = World:GetSpawnZ() + Radius,
			}
			WE:Call("RegisterCallback", PLUGIN, "SpawnProtect", World)
		end
		WorldIni:WriteFile(World:GetIniFileName())
	end)
	
	-- We need this hook for when the server is starting up for the first time. Then the worlds aren't started so the spawn points are 0, 0, 0.
	cPluginManager.AddHook(cPluginManager.HOOK_WORLD_STARTED, OnWorldStarted);
	
	return true
end

function OnWorldStarted(World)
	local WorldIni = cIniFile()
	WorldIni:ReadFile(World:GetIniFileName())
	local Enabled = WorldIni:GetValueSetB("SpawnProtect", "Enable", true)
	if Enabled then
		local Radius = WorldIni:GetValueSetI("SpawnProtect", "ProtectRadius", 10)
		a_Worlds[World:GetName()] = {
			MinX = World:GetSpawnX() - Radius,
			MinY = World:GetSpawnY() - Radius,
			MinZ = World:GetSpawnZ() - Radius,
			
			MaxX = World:GetSpawnX() + Radius,
			MaxY = World:GetSpawnY() + Radius,
			MaxZ = World:GetSpawnZ() + Radius,
		}
	end
	WorldIni:WriteFile(World:GetIniFileName())
end

function SpawnProtect(a_MinX, a_MaxX, a_MinY, a_MaxY, a_MinZ, a_MaxZ, a_Player, a_World, a_Operation)
	if a_Player:HasPermission("we-spawnprotect.build") then
		return false
	end
	
	local WorldName = a_World:GetName()
	local Cuboid = cCuboid(a_Worlds[WorldName].MinX, a_Worlds[WorldName].MinY, a_Worlds[WorldName].MinZ, a_Worlds[WorldName].MaxX, a_Worlds[WorldName].MaxY, a_Worlds[WorldName].MaxZ)
	if Cuboid:DoesIntersect(cCuboid(a_MinX, a_MinY, a_MinZ, a_MaxX, a_MaxY, a_MaxZ)) then
		a_Player:SendMessage(cChatColor.Rose .. "You can't build in the spawn.")
		return true
	end
	return false
end
	