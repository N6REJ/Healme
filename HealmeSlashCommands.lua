Healme_Slash = "/hlme" -- the slash command

local function DumpVar(varName, Value)
	if (Value == nil) then 
		Healme_Print(varName .. " = (nil)")
	else
		Healme_Print(varName .. " = " .. tostring(Value))
	end
end

function Healme_InitSlashCommands()
	SLASH_Healme1 = Healme_Slash
	SlashCmdList["Healme"] = Healme_SlashCmdHandler
end	


local function printUsage()
	Healme_Print(Healme_AddonName .. " Commands")
	Healme_Print(Healme_Slash .. " - Shows " .. Healme_AddonName .. " commands.  (what you see here)")
	Healme_Print(Healme_Slash .. " config - Shows the " .. Healme_AddonName .. " config panel")
	Healme_Print(Healme_Slash .. " show [party | pets | me | tanks | 1-8] - Shows the corresponding " .. Healme_AddonName .. " frame")
	Healme_Print(Healme_Slash .. " toggle - Shows or Hides the current " .. Healme_AddonName .. " frames.")
	Healme_Print(Healme_Slash .. " reset frames - Resets the positions of all " .. Healme_AddonName .. " frames")
	Healme_Print(Healme_Slash .. " friends add [name or Target] - Adds name to the " .. Healme_AddonName .. " friends list.")
	Healme_Print(Healme_Slash .. " friends remove [name or Target] - Removes name from the " .. Healme_AddonName .. " friends list.")
	Healme_Print(Healme_Slash .. " friends show - Shows the current " .. Healme_AddonName .. " friends list.")
	Healme_Print(Healme_Slash .. " friends clear - clears the " .. Healme_AddonName .. " friends list.")
--		Healme_Print(Slash .. " reset - Resets the ".. Healme_AddonName .. " UI")
--		DEFAULT_CHAT_FRAME:AddMessage(Slash .. " debug - Toggles " .. Healme_AddonName .. " debugging")
--		DEFAULT_CHAT_FRAME:AddMessage(Slash .. " dump - Outputs " .. Healme_AddonName .. " variables for debugging purposes")
end

-- handles /hlm reset 
local function doReset(args)
	if (args == "frames") then 
		Healme_ResetAllFramePositions()
	elseif (cmd == "all") then
		Healme = nil
		Healme_Print("Reset all complete.  Please log out now.")
	elseif (cmd == "profiles") then
		Healme.Profiles = nil
		Healme_Print("Reset Profiles complete.  Please log out now.")
	else
		printUsage()
	end
end

-- handles /hlm debug
local function doDebug(args)
	Healme_Debug = not Healme_Debug
	if (Healme_Debug) then
		Healme_Print(Healme_AddonName .. " Debug is ON")
	else
		Healme_Print(Healme_AddonName .. " Debug is OFF")
	end
end

-- handles /hlm dump
local function doDump(args)
	if not IsAddOnLoaded("Blizzard_DebugTools") then
		LoadAddOn("Blizzard_DebugTools")
	end	
	DevTools_Dump("Healme = ")
	DevTools_Dump(Healme)
end

-- handles /hlm config
local function doConfig(args)
	Healme_ShowConfigPanel()
end

local function doToggle(args)
	Healme_ToggleAllFrames()
end

local mt = { __index =  function() return printUsage end }

local showHandlers = {
	["1"] = function() Healme_ShowHideGroupFrame(1, true) end,
	["2"] = function() Healme_ShowHideGroupFrame(2, true) end,
	["3"] = function() Healme_ShowHideGroupFrame(3, true) end,
	["4"] = function() Healme_ShowHideGroupFrame(4, true) end,
	["5"] = function() Healme_ShowHideGroupFrame(5, true) end,
	["6"] = function() Healme_ShowHideGroupFrame(6, true) end,
	["7"] = function() Healme_ShowHideGroupFrame(7, true) end,
	["8"] = function() Healme_ShowHideGroupFrame(8, true) end,
	party = function() Healme_ShowHidePartyFrame(true) end,
	pets = function() Healme_ShowHidePetsFrame(true) end,
	me = function() Healme_ShowHideMeFrame(true) end,
	friends = function() Healme_ShowHideFriendsFrame(true) end,
	damagers = function() Healme_ShowHideDamagersFrame(true) end,
	healers = function() Healme_ShowHideHealersFrame(true) end,
	tanks = function() Healme_ShowHideTanksFrame(true) end,
	target = function() Healme_ShowHideTargetFrame(true) end,
	focus = function() Healme_ShowHideFocusFrame(true) end,
}

setmetatable(showHandlers, mt)

-- handles /hlm show
local function doShow(args)
	if args == nil then
		Healme_ShowHidePartyFrame(true)
		return
	end
	
	return showHandlers[args]()
end

--[[ *************************************************************************************
									TEST
************************************************************************************* --]]
local function doTest(args)
	local _, unit, name, subgroup, className, role, server
	if args == "roles" then
		Healme_Print("test - roles")
		for i=1, 40, 1 do
			name, _, subgroup, _, _, className, _, _, _, role = GetRaidRosterInfo(i)
			if role then
				Healme_Print(name .. " - " .. role)
			end
		end
	end
end


--[[ *************************************************************************************
									FRIENDS
************************************************************************************* --]]


local function GetFriendsTarget(args)
	local friend = args
	
	if args == nil then
		local realm
		friend, realm  = UnitName("Target")
		if realm ~= nil then
			if realm:len() > 0 then
				friend = friend .. "-" .. realm
			end
		end
	end
	
	if friend == nil then
		Healme_Warn("No unit specified")
		return nil
	end

	return friend
end

-- handles /hlm friends add
local function doFriendsAdd(args)
	local friend = GetFriendsTarget(args)
	
	if friend == nil then 
		return
	end
	
	local f = HealmeGlobal.Friends[string.lower(friend)]
	if f then
		Healme_Warn(friend .. " is already in the friends list.")
		return
	end
	
	HealmeGlobal.Friends[string.lower(friend)] = friend
	Healme_UpdateFriends()
	Healme_Print(friend .. " added to friends list")
end

-- handles  /hlm friends remove
local function doFriendsRemove(args)
	local friend = GetFriendsTarget(args)
	
	if friend == nil then 
		return
	end
	
	local num = tonumber(friend)

	if num then
		local index = 1
		for k, v in pairs(HealmeGlobal.Friends) do
			if index == num then 
				friend = v
			end
			index = index + 1
		end
	end
	
	local f = HealmeGlobal.Friends[string.lower(friend)]
	if f == nil then
		Healme_Warn(friend .. " is not in the friends list.")
		return
	end	
	
	HealmeGlobal.Friends[string.lower(friend)] = nil
	Healme_UpdateFriends()
	Healme_Print(f .. " removed from friends list.")
end

-- handles /hlm friends show
local function doFriendsShow(args)
	local friends = ""
	local index = 1
	Healme_Print("Listing " .. Healme_AddonName .. " friends:")
	for k, v in pairs(HealmeGlobal.Friends) do
		Healme_Print("Friend (" .. index .. ") " .. v)
		index = index + 1
	end
end

local function doFriendsClear(args)
	HealmeGlobal.Friends = {}
	Healme_UpdateFriends()
	Healme_Print("Friends cleared.")
end

local friendsHandlers = {
	add = doFriendsAdd,
	remove = doFriendsRemove,
	show = doFriendsShow,
	clear = doFriendsClear,
	list = doFriendsShow,
}

setmetatable(friendsHandlers, mt)

--handles /hlm friends
local function doFriends(val)
	if val == nil then
		doFriendsShow()
		return
	end
	
	local switch = val:match("([^ ]+)")
	local args = val:match("[^ ]+ (.+)")	

	return friendsHandlers[switch](args)
end

local handlers = {
	reset = doReset,
	dump = doDump,
	config = doConfig,
	show = doShow,
	friend = doFriends,
	friends = doFriends,
	debug = doDebug,	
	test = doTest,
	toggle = doToggle,
}

setmetatable(handlers, mt)

-- handles the slash commands for this addon
function Healme_SlashCmdHandler(cmd)
	local switch = cmd:match("([^ ]+)")
	local args = cmd:match("[^ ]+ (.+)")	
	return handlers[switch](args)
end

