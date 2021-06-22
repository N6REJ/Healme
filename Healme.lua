-- Healme - Maintained by Bearesquishy of Dalaran.  Based on Healium by Dourd of Argent Dawn EU
--
-- Programming notes
-- WARNING In LUA all logical operators consider false and nil as false and anything else as true.  This means not 0 is false!!!!!!!!
-- Color control characters |CAARRGGBB  then |r resets to normal, where AA == Alpha, RR = Red, GG = Green, BB = blue

Healme_Debug = false
local AddonVersion = "|cFFFFFF00 1.1|r"

HealmeDropDown = {} -- the dropdown menus on the config panel

local IsClassic = _G.WOW_PROJECT_ID == _G.WOW_PROJECT_CLASSIC

-- Constants
local LowHP = 0.6
local VeryLowHP = 0.3
local NamePlateWidth = 120
local _, HealmeClass = UnitClass("player")
local _, HealmeRace = UnitRace("player")
local HealmeSpec = GetSpecialization()
local MaxParty = 25 -- Max number of people in party
local MinRangeCheckPeriod = .2 -- .2 = 5Hz
local MaxRangeCheckPeriod = 2  -- 2 = .5Hz
local DefaultRangeCheckPeriod = .5
local DefaultButtonCount = 5

-- locale safe versions of spell names
local ActivatePrimarySpecSpellName = GetSpellInfo(63645)
local ActivateSecondarySpecSpellName = GetSpellInfo(63644)
local PWSName = GetSpellInfo(17) -- Power Word: Shield
local WeakendSoulName = GetSpellInfo(6788) -- Weakened Soul
local SwiftMendName = GetSpellInfo(18562) -- Swift Mend
local RejuvinationName = GetSpellInfo(774) -- Rejuvenation
local RegrowthName = GetSpellInfo(8936) -- Regrowth
local WildGrowthName = GetSpellInfo(48438) -- Wild Growth

--local LoadedTime = 0
local stable


-- Healme holds per character settings
Healme = {
  Scale = 1.0,									-- Scale of frames
  DoRangeChecks = true,							-- Whether or not to do range checks on buttons
  RangeCheckPeriod = .5,						-- Time period between range checks
  EnableCooldowns = true,						-- Whether or not to do cooldown animations on buttons
  ShowToolTips = true,							-- Whether or not to display a tooltip for the spell when hovering over buttons
  DisableNonHealSpec = true,
  ShowPercentage = true,						-- Whether or not to display the health percentage
  UseClassColors = false,						-- Whether or not to color the healthbar the color of the class instead of green/yellow/red
  ShowDefaultPartyFrames = false,				-- Whether or not to show the default party frames
  ShowPartyFrame = true,						-- Whether or not to show the party frame
  ShowPetsFrame = true,							-- Whether or not to show the pets frame
  ShowMeFrame = false,  						-- Whether or not to show the me frame
  ShowFriendsFrame = false,						-- Whether or not to show the friends frame
  ShowGroupFrames = { },  						-- Whether or not to show individual group frame
  ShowDamagersFrame = false,			     	-- Whether or not to show the Damagers frame
  ShowHealersFrame = false,						-- Whether or not to show the Heals frame
  ShowTanksFrame = false,						-- Whether or not to show the Tanks frame
  ShowTargetFrame = false,						-- Whether or not to show the target frame
  ShowFocusFrame = false,						-- Whether or not to show the focus frame
  ShowBuffs = true,								-- Whether or not to show your own buffs, that are configured in Healme to the left of the healthbar
  HideCloseButton = false,						-- Whether or not to hide the close (X) button, to prevent accidental closing of the Healme Frame
  HideCaptions = false,							-- Whether or not to hide the caption when the mouse leaves the caption area
  LockFrames = false,							-- Whether or not to prevent dragging of the frame
  EnableClique = false,							-- Whether or not to enable Clique support on the health bars
  EnableDebufs = true,							-- Whether or not to enable the debuf warning system
  EnableDebufAudio = true,						-- Whether or not to enable playing an audio file when a person has a debuf which the player can cure
  DebufAudioFile = nil,							-- The debuf audio file to play
  EnableDebufHealthbarHighlighting = true,		-- Whether or not to highlight the healthbar of a player when they have a debuf which you can cure
  EnableDebufButtonHighlighting = true,			-- Whether or not to highlight buttons which are assigned a spell that can cure a debuff on a player
  EnableDebufHealthbarColoring = false,			-- Whether or not to color the heatlhbar of a player when they have a debuf which you can cure
  ShowMana = true,								-- Whether or not to show mana
  ShowThreat = true,							-- Whether or not to show the threat warnings
  ShowRole = true,								-- Whether or not to show the role icon
  ShowIncomingHeals = true,						-- Whether or not to show incoming heals
  ShowRaidIcons = true,							-- Whether or not to show raid icons
  UppercaseNames = true,						-- Whether or not to show names in UPPERCASE
}

-- HealmeGlobal is the variable that holds all Healme settings that are not character specific
HealmeGlobal = {
  Friends = { },								-- List of Healme friends
}

--[[
Healme.Profiles is a table of tables with this signature
{
	ButtonCount -- Current button count (as set by slider)
	SpellNames -- Table of current spell names
	SpellIcons -- Table of current spell icons
	SpellTypes -- One of the Healme_Type_ (new in Healme 2.0)
	SpellRank -- Spell subtext if it has subtext, or nil (new in Healme 2.7.0)
	IDs -- item ID when SpelType is Healme_Type_Item
}
TODO refactor Healme.Profiles to instead contain a single table named Spells which contain a variable for each of the above tables
]]

-- Global Constants
Healme_MaxButtons = 15		-- Max Possible buttons
Healme_AddonName = "Healme"
Healme_AddonColor = "|cFF55AAFF"
Healme_AddonColoredName = Healme_AddonColor .. Healme_AddonName .. "|r"
Healme_MaxClassSpells = 20 -- For now this is manually set to the max number of class specific spells in Healme_Spell.Name which currently is priest

Healme_Type_Spell = 0  -- note that nil also means Spell!  This is because we don't init the Spelltypes table.
Healme_Type_Macro = 1
Healme_Type_Item = 2

-- NEW FRAMES VARIABLES
Healme_Units = { { } } -- table of tables that maps unit names to their frame, used for efficient handling of UNIT_HEALTH so each button doesn't get a UNIT_HEALTH event for every unit.
Healme_Frames = { } -- table of all created "unit" frames.  Can access buttons from each of these.
Healme_ShownFrames = { } -- table of all shown "unit" frames.
Healme_FixNameplates = { } -- nameplates that need various updates when out of combat

--[[
List of spells, icons for the spells, and SlotIDs.
These only contain specifically selected spells in HealmeSpells.lua
The Name gets filled in in Healme_InitSpells(). Healme_UpdateSpells() will fill in the ID and Icon if
the player actually has the spell.
--]]
Healme_Spell = {
  Name = {},
  Icon = {},
  ID = {} -- This is the spell SlotID (spellbook index), not the global SpellID
}

local HealmeFrame = nil

function Healme_Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage(Healme_AddonColor .. Healme_AddonName .. "|r " .. tostring(msg))
end

function Healme_DebugPrint(...)
	if (Healme_Debug) then
		local result = "Debug: "

		for i = 1, select("#", ...) do
			result = result .. " " .. tostring(select(i, ...))
		end

		Healme_Print(result)
	end
end

function Healme_Warn(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|CFFFF0000Warning|r: " .. tostring(msg))
end

function Healme_GetProfile()
	local currentSpec

	if not IsClassic then
		currentSpec = GetSpecialization()
	end

	if not currentSpec then
		currentSpec = 1
	end

	return Healme.Profiles[currentSpec]
end

function Healme_SetProfileSpell(profile, index, spellName, spellID, spellIcon, spellRank)
	profile.SpellNames[index] = spellName
	profile.SpellIcons[index] = spellIcon
	profile.SpellTypes[index] = Healme_Type_Spell
	profile.SpellRanks[index] = spellRank
	profile.IDs[index] = spellID
end

function Healme_SetProfileItem(profile, index, itemName, itemID, itemIcon)
	profile.SpellNames[index] = itemName
	profile.SpellIcons[index] = itemIcon
	profile.SpellTypes[index] = Healme_Type_Item
	profile.SpellRanks[index] = nil
	profile.IDs[index] = itemID
end

function Healme_SetProfileMacro(profile, index, macroName, macroID, macroIcon)
	profile.SpellNames[index] = macroName
	profile.SpellIcons[index] = macroIcon
	profile.SpellTypes[index] = Healme_Type_Macro
	profile.SpellRanks[index] = nil
	profile.IDs[index] = macroID
end

function Healme_OnLoad(frame)
	HealmeFrame = frame
 	Healme_Print(AddonVersion.." |cFF00FF00Loaded |rClick The MiniMap button for options.")
	Healme_Print("Type " .. Healme_Slash .. " for a list of slash commands." )

 	-- Do not use the VARIABLES_LOADED event for anything meaningful since VARIABLES_LOADED's order can no longer be relied upon. (it kind of seems random to me)
	HealmeFrame:RegisterEvent("ADDON_LOADED")
	HealmeFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	HealmeFrame:RegisterEvent("SPELLS_CHANGED")
	HealmeFrame:RegisterEvent("UNIT_HEALTH")
	HealmeFrame:RegisterEvent("UNIT_SPELLCAST_SENT")
	HealmeFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	HealmeFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	HealmeFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	HealmeFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
	HealmeFrame:RegisterEvent("UNIT_NAME_UPDATE")
	HealmeFrame:RegisterEvent("UNIT_AURA")
	HealmeFrame:RegisterEvent("PLAYER_LOGIN")
	HealmeFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

	if not IsClassic then
		HealmeFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
	end
end

local function Healme_ShowHidePercentage(frame)
	if Healme.ShowPercentage and (frame.HasRole == nil) then
		frame.HealthBar.HPText:Show()
	else
		frame.HealthBar.HPText:Hide()
	end
end

function Healme_UpdatePercentageVisibility()
	for _, k in ipairs(Healme_Frames) do
		Healme_ShowHidePercentage(k)
	end
end

-- Sets the health bar color based on the unit's health ONLY
local function UpdateHealthBar(HPPercent, frame)
	if (HPPercent > LowHP) then
		frame.HealthBar:SetStatusBarColor(0,1,0,1)
	end
	if (HPPercent < LowHP) then
		frame.HealthBar:SetStatusBarColor(1,0.9,0,1)
	end
	if (HPPercent < VeryLowHP) then
		frame.HealthBar:SetStatusBarColor(1,0,0,1)
	end
end

function Healme_UpdateClassColors()
	for _, k in ipairs(Healme_Frames) do
		if (k.TargetUnit) then
			if UnitExists(k.TargetUnit) then
				if Healme.UseClassColors then
					local class = select(2, UnitClass(k.TargetUnit)) or "WARRIOR"
					local color = RAID_CLASS_COLORS[class]
					k.HealthBar:SetStatusBarColor(color.r, color.g, color.b)
				else
					local Health = UnitHealth(k.TargetUnit)
					local MaxHealth = UnitHealthMax(k.TargetUnit)
					HPPercent =  Health / MaxHealth
					UpdateHealthBar(HPPercent, k)
				end
			end
		end
	end
end

function Healme_UpdateUnitName(unitName, NamePlate)
	if not NamePlate then return end
	if not UnitExists(unitName) then return end

	local playerName = UnitName(unitName)

	if playerName ~= nil and Healme.UppercaseNames then
		playerName = strupper(playerName)
	end

	NamePlate.HealthBar.name:SetText(playerName)
end

function Healme_UpdateUnitNames()
	for _, k in ipairs(Healme_Frames) do
		if (k.TargetUnit) then
			Healme_UpdateUnitName(k.TargetUnit, k)
		end
	end
end

function Healme_UpdateUnitHealth(unitName, NamePlate)
	if not unitName then return end
	if not NamePlate then return end
	if not UnitExists(unitName) then return end

	local Health = UnitHealth(unitName)
	local MaxHealth = UnitHealthMax(unitName)

	local isDead

	if UnitIsDeadOrGhost(unitName) then
		Health = 0
		isDead = 1
	end

	local HPPercent

	if MaxHealth == 0 then
		Health = 0
		HPPercent = 0
	else
		HPPercent = Health / MaxHealth
	end

	if HPPercent > 1 then
		HPPercent = 1
	end

	if HPPercent < 0 then
		HPPercent = 0
	end

	if isDead then
		NamePlate.HealthBar.HPText:SetText( "dead" )
	else
		NamePlate.HealthBar.HPText:SetText( format("%.1i%%", HPPercent*100))
	end

	NamePlate.HealthBar:SetMinMaxValues(0,MaxHealth)
	NamePlate.HealthBar:SetValue(Health)

	if Healme.EnableDebufs and Healme.EnableDebufHealthbarColoring and NamePlate.hasDebuf then
		NamePlate.HealthBar:SetStatusBarColor(NamePlate.debuffColor.r, NamePlate.debuffColor.g, NamePlate.debuffColor.b)
	elseif Healme.UseClassColors then
		local class = select(2, UnitClass(unitName)) or "WARRIOR"
		local color = RAID_CLASS_COLORS[class]
		NamePlate.HealthBar:SetStatusBarColor(color.r, color.g, color.b)
	else
		UpdateHealthBar(HPPercent, NamePlate)
	end

	-- incoming heals

	if (not IsClassic) and Healme.ShowIncomingHeals then
		local IncomingHealth = UnitGetIncomingHeals(unitName)

		if IncomingHealth then
			Health = Health + IncomingHealth
		else
			Health = 0
		end

		NamePlate.PredictBar:SetMinMaxValues(0,MaxHealth)
		NamePlate.PredictBar:SetValue(Health)
	end
end

function Healme_UpdateUnitMana(unitName, NamePlate)
	if not NamePlate then return end
	if not UnitExists(unitName) then return end

	if NamePlate.showMana == nil then return end

	local Mana = UnitPower(unitName, SPELL_POWER_MANA)
	local MaxMana = UnitPowerMax(unitName, SPELL_POWER_MANA)

	if UnitIsDeadOrGhost(unitName) then
		Mana = 0
	end

	NamePlate.ManaBar:SetMinMaxValues(0,MaxMana)
	NamePlate.ManaBar:SetValue(Mana)
end

function Healme_UpdateShowMana()
	if Healme.ShowMana then
		HealmeFrame:RegisterEvent("UNIT_POWER_UPDATE")
		HealmeFrame:RegisterEvent("UNIT_DISPLAYPOWER")
	else
		HealmeFrame:UnregisterEvent("UNIT_POWER_UPDATE")
		HealmeFrame:UnregisterEvent("UNIT_DISPLAYPOWER")
	end

	for _, k in ipairs(Healme_Frames) do
		if (k.TargetUnit) then
			HealmeUnitFames_CheckPowerType(k.TargetUnit, k)
			Healme_UpdateUnitMana(k.TargetUnit, k)
		end

		if InCombatLockdown() then
			k.fixShowMana = true
		else
			Healme_UpdateManaBarVisibility(k)
		end
	end
end

function Healme_UpdateManaBarVisibility(frame)
	if Healme.ShowMana then
		frame.ManaBar:Show()
		frame.HealthBar:SetWidth(111)
		frame.HealthBar:SetPoint("TOPLEFT", 7, -2)
		frame.PredictBar:SetWidth(111)
		frame.PredictBar:SetPoint("TOPLEFT", 7, -2)
	else
		frame.ManaBar:Hide()
		frame.HealthBar:SetWidth(116)
		frame.HealthBar:SetPoint("TOPLEFT", 2, -2)
		frame.PredictBar:SetWidth(116)
		frame.PredictBar:SetPoint("TOPLEFT", 2, -2)
	end

	Healme_UpdateUnitHealth(frame.TargetUnit, frame)
end

function Healme_UpdateShowBuffs()
	for _, k in ipairs(Healme_ShownFrames) do
		if (k.TargetUnit) then
			Healme_UpdateUnitBuffs(k.TargetUnit, k)
		end
	end
end


function Healme_UpdateUnitThreat(unitName, NamePlate)
	if IsClassic then return end
	if not NamePlate then return end
	if not UnitExists(unitName) then return end

	if Healme.ShowThreat == nil then
		NamePlate.AggroBar:SetAlpha(0)
		return
	end

	local status = UnitThreatSituation(unitName)

	if status and status > 1 then
		local r, g, b = GetThreatStatusColor(status)
		NamePlate.AggroBar:SetBackdropBorderColor(r,g,b,1)
		NamePlate.AggroBar:SetAlpha(1)
	else
		NamePlate.AggroBar:SetAlpha(0)
	end
end

function Healme_UpdateShowThreat()
	if IsClassic then return end
	if Healme.ShowThreat then
		HealmeFrame:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
	else
		HealmeFrame:UnregisterEvent("UNIT_THREAT_SITUATION_UPDATE")
	end

	for _, k in ipairs(Healme_Frames) do
		if (k.TargetUnit) then
			if Healme.ShowThreat then
				Healme_UpdateUnitThreat(k.TargetUnit, k)
			else
				k.AggroBar:SetAlpha(0)
			end
		end
	end
end


function Healme_UpdateUnitRole(unitName, NamePlate)
	if IsClassic then
		Healme.ShowRole = nil -- roles not supported on classic. This logic will cause below logic to hide the role icon.
	end

	if not NamePlate then return end
	if not UnitExists(unitName) then return end

	local icon = NamePlate.HealthBar.RoleIcon

	if not Healme.ShowRole then
		icon:Hide()
		NamePlate.HasRole = nil
		Healme_ShowHidePercentage(NamePlate)
		return
	end

	local role = UnitGroupRolesAssigned(unitName);

	if ( role == "TANK" or role == "HEALER" or role == "DAMAGER") then
		NamePlate.HasRole = true
		icon:SetTexCoord(GetTexCoordsForRoleSmallCircle(role))
		icon:Show()
	else
		NamePlate.HasRole = nil
		icon:Hide()
	end

	Healme_ShowHidePercentage(NamePlate)
end

local function Healme_UpdateRoles()
	for _, k in ipairs(Healme_Frames) do
		if (k.TargetUnit) then
			Healme_UpdateUnitRole(k.TargetUnit, k)
		end
	end
end

function Healme_UpdateShowRole()
	if Healme.ShowRole then
		HealmeFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
	else
		HealmeFrame:UnregisterEvent("GROUP_ROSTER_UPDATE")
	end

	Healme_UpdateRoles()
end

function Healme_UpdateShowIncomingHeals()
	if IsClassic then
		-- no support for heal prediction on classic.  just hide the frames
		for _, k in ipairs(Healme_Frames) do
				k.PredictBar:Hide()
		end
		return
	end

	if Healme.ShowIncomingHeals then
		HealmeFrame:RegisterEvent("UNIT_HEAL_PREDICTION")
	else
		HealmeFrame:UnregisterEvent("UNIT_HEAL_PREDICTION")
	end

	for _, k in ipairs(Healme_Frames) do
		if Healme.ShowIncomingHeals then
			k.PredictBar:Show()
		else
			k.PredictBar:Hide()
		end
	end
end

local function Healme_UpdateRaidIcons()
	for _, k in ipairs(Healme_Frames) do
		Healme_UpdateRaidTargetIcon(k)
	end
end

function Healme_UpdateShowRaidIcons()
	if Healme.ShowRaidIcons then
		HealmeFrame:RegisterEvent("RAID_TARGET_UPDATE")
	else
		HealmeFrame:UnregisterEvent("RAID_TARGET_UPDATE")
	end

	Healme_UpdateRaidIcons()
end

function Healme_UpdateShowTargetFrame()
	if Healme.ShowTargetFrame then
		Healme_DebugPrint("registering PLAYER_TARGET_CHANGED")
		HealmeFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
	else
		Healme_DebugPrint("UNregistering PLAYER_TARGET_CHANGED")
		HealmeFrame:UnregisterEvent("PLAYER_TARGET_CHANGED")
	end
end

function Healme_UpdateShowFocusFrame()
	if IsClassic then return end
	if Healme.ShowFocusFrame then
		Healme_DebugPrint("registering PLAYER_FOCUS_CHANGED")
		HealmeFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
	else
		Healme_DebugPrint("UNregistering PLAYER_FOCUS_CHANGED")
		HealmeFrame:UnregisterEvent("PLAYER_FOCUS_CHANGED")
	end
end

local function GetSpellCount()
	local tabs = GetNumSpellTabs()
	local name, texture, offset, numSpells = GetSpellTabInfo(tabs)
	return offset + numSpells
end

local function GetSpellSlotID(spell, subtext)
	if spell == nil then return end
	--new check in MoP.
	--This is required because spells for other specs appear in the spell book and are disabled, and we don't want disabled spells appearing by default.
	--GetSpellInfo() will return nil for those disabled spells.
	--Warning passing an index to GetSpellInfo() will still return a name for disabled spells, but passing the spell name causes it to return nil
	local name = GetSpellInfo(spell)
	if not name then
		return nil
	end

	local count = GetSpellCount()

	for i = 1, count do
        local spellName, spellSubName = GetSpellBookItemName(i, BOOKTYPE_SPELL)
        if not spellName then
            break
        end
        if (spellName == spell) then
			local slotType  = GetSpellBookItemInfo(i, BOOKTYPE_SPELL)
			if (slotType == "FUTURESPELL") then
				break
			end

			if not subtext then
				return i
			end

			Healme_DebugPrint("spell: ", spellName, "subtext:", spellSubName);
			if spellSubName == subtext then
				return i
			end
        end

        if (i > 300) then
            break
        end
    end

    return nil
end

-- Loops through Healme_Spell.Name[] and updates it's corresponding .ID[] and .Icon[]
-- Warning UpdateSpells() is a global function from Blizzard.
local function Healme_UpdateSpells()
	for k, v in ipairs (Healme_Spell.Name) do
		Healme_Spell.ID[k] = GetSpellSlotID(Healme_Spell.Name[k])
		if (Healme_Spell.ID[k]) then
			Healme_Spell.Icon[k] = GetSpellTexture(Healme_Spell.ID[k], BOOKTYPE_SPELL)
		else
			Healme_Spell.Icon[k] = nil
		end
	end

	Healme_UpdateButtonAttributes()
end

-- does special checks for specific buffs/debuffs
function Healme_UpdateSpecialBuffs(unit)

	if HealmeClass == "PRIEST" then
		local Profile = Healme_GetProfile()

		for i=1, Profile.ButtonCount, 1 do

			-- special check for Power Word: Shield
			if Profile.SpellNames[i] == PWSName then
				local units = Healme_Units[unit]

				if units then
					local name, _, _, _, weakendSoulduration, expirationTime, _, _, _, _, _, _, _, _, _ = AuraUtil.FindAuraByName(WeakendSoulName, unit)

					if name then
						local startTime = expirationTime - weakendSoulduration

						for _, frame in pairs(units) do
							local button = frame.buttons[i]
							if button and button:IsShown() then
								button.cooldown:SetCooldown(startTime, weakendSoulduration)
							end
						end
					end
				end
			end
		end
		return
	end

	if HealmeClass == "DRUID" then
		local Profile = Healme_GetProfile()

		for i=1, Profile.ButtonCount, 1 do

			-- special check for Swift Mend
			if Profile.SpellNames[i] == SwiftMendName then
				local units = Healme_Units[unit]

				if units then
					local buff1 = AuraUtil.FindAuraByName(RejuvinationName, unit)
					local buff2 = AuraUtil.FindAuraByName(RegrowthName, unit)
					local buff3 = AuraUtil.FindAuraByName(WildGrowthName, unit)

					local enabled = buff1 or buff2 or buff3

					for _, frame in pairs(units) do
						local button = frame.buttons[i]
						if button then
							if enabled then
								button.icon.disabled = nil
								button.icon:SetVertexColor(1.0, 1.0, 1.0)
							else
								button.icon.disabled = true
								button.icon:SetVertexColor(0.4, 0.4, 0.4)
							end
						end
					end


				end
			end
		end

		return

	end

end

-- Efficient cooldowns
local function GetCooldown(Profile, column)
	local start, duration, enable

	if Profile.IDs[column] ~= nil then

		if Profile.SpellTypes[column] == Healme_Type_Macro then
			local name = GetMacroSpell(Profile.SpellNames[column])
			if name then
				start, duration, enable = GetSpellCooldown(name)
			else
				enable = false
			end
		elseif Profile.SpellTypes[column] == Healme_Type_Item then
			-- Handle "item" cooldowns
			GetItemInfo(Profile.SpellNames[column])
			start, duration, enable = GetItemCooldown(Profile.IDs[column])
		else
			-- Handle "spell" cooldowns
			local name = Profile.SpellNames[column]
			if name then
				-- GetSpellCooldown doesn't seem to work with slotIDs but does with ranked spell names
				local rankedSpellName = Healme_MakeRankedSpellName(Profile.SpellNames[column], Profile.SpellRanks[column])
				start, duration, enable = GetSpellCooldown(rankedSpellName)
			else
				enable = false
			end
		end
	end

	return start, duration, enable
end

function Healme_UpdateButtonCooldown(frame, start, duration, enable)
	if frame then
		if frame:IsShown() and stable then

			-- temp fix for lua errors caused in patch 5.1.. Somehow these values are sometimes invalid for a few seconds after loading, and these explicit checks seem to fix it
			if start == nil then
				start = GetTime()
			end

			if duration == nil then
				duration = 0
			end

			if enable == nil then
				enable = 0
			end

			CooldownFrame_Set(frame.cooldown, start, duration, enable)
		end
	end
end

function Healme_UpdateButtonCooldownsByColumn(column)
	local Profile = Healme_GetProfile()

	local start, duration, enable = GetCooldown(Profile, column)

	for unit, j in pairs(Healme_Units) do
		for x,y in pairs(j) do
			local button = y.buttons[column]
			if button then
				Healme_UpdateButtonCooldown(button, start, duration, enable)
			end
		end
		Healme_UpdateSpecialBuffs(unit)
	end

end

local function Healme_UpdateButtonCooldowns()
	local count = Healme_GetProfile().ButtonCount

	for i=1, count, 1 do
		Healme_UpdateButtonCooldownsByColumn(i)
	end
end

function Healme_UpdateButtonIcon(button, texture)
	button.icon.disabled = nil

	if InCombatLockdown() then
		return
	end

	if (texture) then
		button.icon:SetTexture(texture)
	else
		button.icon:SetTexture("Interface/Icons/INV_Misc_QuestionMark")
	end
end

function Healme_UpdateButtonIcons()
	if InCombatLockdown() then
		return
	end

	local Profile = Healme_GetProfile()
	for i=1, Healme_MaxButtons, 1 do
		local texture = Profile.SpellIcons[i]

		for _, k in ipairs(Healme_Frames) do
			local button = k.buttons[i]
			if button then
				Healme_UpdateButtonIcon(button, texture)
			end
		end
   end
end

function Healme_SetButtonAttributes(button)
	-- update button.id even while in combat.
	-- This is needed because we use this for a number of things, including tooltips, and the IDs can now change while in combat due to spells dynamically changing.
	-- Spells (possibly not even configured in Healme) can dynamically change/rename, causing all other spellid to shift/change, so in those cases, we need to
	-- update the button.id to keep on the same spell.
	-- This actually fixed a hard to find Druid bug in 5.0 with Hurricane changing to Astral Storm and causing some spellIDs to shift around.
	local Profile = Healme_GetProfile()
	local index = button.index
	button.id = Profile.IDs[index]

	if InCombatLockdown() then
		return
	end

	local stype, spell, macro, item

	if Profile.SpellTypes[index] == Healme_Type_Macro then
		stype = "macro"
		macro = Profile.SpellNames[index]
	elseif Profile.SpellTypes[index] == Healme_Type_Item then
		stype = "item"
		item = Profile.SpellNames[index]
	else
		stype = "spell"
		--spell = Profile.SpellNames[index]
		local spellName = Profile.SpellNames[index]
		local spellSubtext = Profile.SpellRanks[index]
		spell = Healme_MakeRankedSpellName(spellName, spellSubtext)
	end


	button:SetAttribute("type", stype)
	button:SetAttribute("spell", spell)
	button:SetAttribute("macro", macro)
	button:SetAttribute("item", item)
end

function Healme_UpdateButtonAttributes()
	local Profile = Healme_GetProfile()

	for i=1, Healme_MaxButtons, 1 do

		-- update spell IDs
		if (Profile.SpellTypes[i] == nil) or (Profile.SpellTypes[i] == Healme_Type_Spell) then
			local name = Profile.SpellNames[i]
			local subtext = Profile.SpellRanks[i]
			if name then
				Profile.IDs[i] = GetSpellSlotID(name, subtext)
			end
		end

		for _,k in ipairs(Healme_Frames) do
			local button = k.buttons[i]
			if button then
				Healme_SetButtonAttributes(button)
			end
		end
	end

	Healme_UpdateCures()
end

local function UpdateButtonVisibility(frame)
	if InCombatLockdown() then
		return
	end

	-- Hide all buttons
	for i=1, Healme_MaxButtons, 1 do
		local button = frame.buttons[i]
		if button then
			button:Hide()
		end
	end

	if HealmePanelScrollFrameScrollChildSpecializationCheckButton:GetChecked() and not Healme_HealSpec() then
		return;
	else
		-- Show buttons.  The buttons will not actually show up unless their nameplate are visible so it's fine to show them like this.
		local count = Healme_GetProfile().ButtonCount

		for i=1, count, 1 do
			local button = frame.buttons[i]
			if button then
				button:Show()
			end
		end
	end
end

function Healme_UpdateButtonVisibility()
	if InCombatLockdown() then
		return
	end

	for _,k in ipairs(Healme_Frames) do
		UpdateButtonVisibility(k)
	end
end

function Healme_UpdateButtons()
	Healme_UpdateButtonVisibility()
	Healme_UpdateButtonAttributes()
	Healme_UpdateButtonIcons()
end

function Healme_RangeCheckButton(button)
	local Profile = Healme_GetProfile()

	if (Profile.SpellTypes[button.index] == nil) or (Profile.SpellTypes[button.index] == Healme_Type_Spell) then
		if (button.id) then
			local isUsable, noMana = IsUsableSpell(button.id, BOOKTYPE_SPELL)

			if noMana then
				button.icon:SetVertexColor(0.5, 0.5, 1.0)
			else
				if not button.icon.disabled then
					button.icon:SetVertexColor(1.0, 1.0, 1.0)
				end
			end

			local inRange = IsSpellInRange(button.id, BOOKTYPE_SPELL, button:GetParent().TargetUnit)

			if SpellHasRange(button.id, BOOKTYPE_SPELL)  then
				if (inRange == 0) or (inRange == nil) then
					button.icon:SetVertexColor(1.0, 0.3, 0.3)
				end
			end
		end
	end

	-- todo range check macros, and items
end

function Healme_DeepCopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

function Healme_UpdateRaidTargetIcon(frame)
	if (frame.TargetUnit) then
		if not UnitExists(frame.TargetUnit) then return end
		local index = GetRaidTargetIndex(frame.TargetUnit);
		if ( index  and Healme.ShowRaidIcons ) then
			SetRaidTargetIconTexture(frame.HealthBar.raidTargetIcon, index);
			frame.HealthBar.raidTargetIcon:Show();
		else
			frame.HealthBar.raidTargetIcon:Hide();
		end
	end
end


-- Sets persisted variables to their default, if they do not exist.
local function InitVariables()
	if (not Healme.RaidScale) then
		Healme.RaidScale = 1.0
	end

	if (not Healme.RangeCheckPeriod) then
		Healme.RangeCheckPeriod = DefaultRangeCheckPeriod
	end

	if (Healme.RangeCheckPeriod > MaxRangeCheckPeriod or Healme.RangeCheckPeriod < MinRangeCheckPeriod) then
		Healme.RangeCheckPeriod = DefaultRangeCheckPeriod
	end

	if Healme.ShowGroupFrames == nil then
		Healme.ShowGroupFrames = { }
	end

	if Healme.DisableNonHealSpec == nil then
		Healme.DisableNonHealSpec = true
	end

	if Healme.ShowToolTips == nil then
		Healme.ShowToolTips = true
	end

	if Healme.ShowMana == nil then
		Healme.ShowMana = true
	end

	if IsClassic then
		Healme.ShowThreat = false
		Healme.ShowRole = false
		Healme.ShowIncomingHeals = false
		Healme.ShowFocusFrame = false
	else
		if Healme.ShowThreat == nil then
			Healme.ShowThreat = true
		end

		if Healme.ShowRole == nil then
			Healme.ShowRole = true
		end

		if Healme.ShowIncomingHeals == nil then
			Healme.ShowIncomingHeals = true
		end

		if Healme.ShowFocusFrame == nil then
			Healme.ShowFocusFrame = false
		end
	end

	if Healme.ShowRaidIcons == nil then
		Healme.ShowRaidIcons = true
	end

	if Healme.ShowPercentage == nil then
		Healme.ShowPercentage = true
	end

	if Healme.UseClassColors == nil then
		Healme.UseClassColors = false
	end

	if Healme.ShowBuffs == nil then
		Healme.ShowBuffs = true
	end

	if Healme.ShowDefaultPartyFrames == nil then
		Healme.ShowDefaultPartyFrames = false
	end

	if Healme.ShowPartyFrame == nil then
		Healme.ShowPartyFrame = true
	end

	if Healme.ShowPetsFrame == nil then
		Healme.ShowPetsFrame = true
	end

	if Healme.ShowMeFrame == nil then
		Healme.ShowMeFrame = false
	end

	if Healme.ShowTanksFrame == nil then
		Healme.ShowTanksFrame = false
	end

	if Healme.ShowDamagersFrame == nil then
		Healme.ShowDamagersFrame = false
	end

	if Healme.ShowHealersFrame == nil then
		Healme.ShowHealersFrame = false
	end

	if Healme.ShowTargetFrame == nil then
		Healme.ShowTargetFrame = false
	end

	if Healme.ShowFriendsFrame == nil then
		Healme.ShowFriendsFrame = false
	end

	if Healme.HideCloseButton == nil then
		Healme.HideCloseButton = false
	end

	if Healme.HideCaptions == nil then
		Healme.HideCaptions = false
	end

	if Healme.LockFrames == nil then
		Healme.LockFrames = false
	end

	if Healme.EnableDebufs == nil then
		Healme.EnableDebufs = true
	end

	if Healme.EnableClique == nil then
		Healme.EnableClique = false
	end

	if Healme.EnableDebufAudio == nil then
		Healme.EnableDebufAudio = true
	end

	if Healme.EnableDebufHealthbarHighlighting == nil then
		Healme.EnableDebufHealthbarHighlighting = true
	end

	if Healme.EnableDebufButtonHighlighting == nil then
		Healme.EnableDebufButtonHighlighting = true
	end

	if Healme.EnableDebufHealthbarColoring == nil then
		Healme.EnableDebufHealthbarColoring = false
	end

	if Healme.UppercaseNames == nil then
		Healme.UppercaseNames = true
	end

	if HealmeGlobal.Friends == nil then
		HealmeGlobal.Friends = { }
	end

	if Healme.Profiles == nil then
		Healme.Profiles = { }
	end

	-- Healme.Profiles may exist at this point, but may not be fully inited
	local DefaultProfile = {
		ButtonCount = DefaultButtonCount,
		SpellNames = { },
		SpellIcons = { },
		SpellTypes = { },
		SpellRanks = { },
		IDs = { },
	}

	-- Make sure all Profile member tables exist. This is needed since new tables get added over various releases, and since Profiles variable gets saved/recalled by wow, the values may or may not exist depending on what verison of wow was last used when saving the variable.
	for i = 1,5 do
		if Healme.Profiles[i] == nil then
			Healme.Profiles[i] = Healme_DeepCopy(DefaultProfile)
		end

		-- SpellTypes was added in 2.0
		if Healme.Profiles[i].SpellTypes == nil then
			Healme.Profiles[i].SpellTypes = {}
		end

		-- IDs was added in 2.0
		if Healme.Profiles[i].IDs == nil then
			Healme.Profiles[i].IDs = {}
		end

		-- SpellRanks was added in 2.7.0
		if Healme.Profiles[i].SpellRanks == nil then
			Healme.Profiles[i].SpellRanks = {}
		end
	end

	-- remove old saved variables
	HealmeDropDownButton = nil
	HealmeDropDownButtonIcon = nil

end

function Healme_OnEvent(frame, event, ...)
	local arg1 = select(1, ...)
	local arg2 = select(2, ...)

	-------------------------------------------------------------
	-- [[ Update Unit Health Display Whenever Their HP Changes ]]
	-------------------------------------------------------------
    if (event == "UNIT_HEALTH") or (event == "UNIT_HEAL_PREDICTION") then
--		if (not HealmeActive) then return 0 end

		if Healme_Units[arg1] then
			for _,v  in pairs(Healme_Units[arg1]) do
				Healme_UpdateUnitHealth(arg1, v)
			end
		end
		return
	end

    if event == "UNIT_POWER_UPDATE" then
		if (arg2 == "MANA") and Healme_Units[arg1] then
			for _,v  in pairs(Healme_Units[arg1]) do
				Healme_UpdateUnitMana(arg1, v)
			end
		end
		return
	end

	if event == "UNIT_AURA" then
		if Healme_Units[arg1] then
			for _,v  in pairs(Healme_Units[arg1]) do
				if Healme.ShowBuffs then
					Healme_UpdateUnitBuffs(arg1, v)
				end
				Healme_UpdateSpecialBuffs(arg1)
			end
		end
		return
	end

	if (event == "UNIT_THREAT_SITUATION_UPDATE") and Healme.ShowThreat then
		if Healme_Units[arg1] then
			for _,v  in pairs(Healme_Units[arg1]) do
				Healme_UpdateUnitThreat(arg1, v)
			end
		end
		return
	end

	if (event == "SPELL_UPDATE_COOLDOWN") and Healme.EnableCooldowns then
		Healme_UpdateButtonCooldowns()
		return
	end

	if event == "PLAYER_REGEN_ENABLED" then
		for _,v in ipairs(Healme_FixNameplates) do
			Healme_ShowHidePercentage(v)

			if v.fixCreateButtons then
				Healme_CreateButtonsForNameplate(v)
				UpdateButtonVisibility(v)
				v.fixCreateButtons = nil
			end

			if v.fixShowMana then
				Healme_UpdateManaBarVisibility(v)
				v.fixShowMana = nil
			end
		end

		Healme_FixNameplates = {}
		return
	end

	if ((event == "UNIT_SPELLCAST_SENT") and ( (arg2 == ActivatePrimarySpecSpellName) or (arg2 == ActivateSecondarySpecSpellName))  ) then
--		DEFAULT_CHAT_FRAME:AddMessage("Healme Debug: Respecing Start")
		frame.Respecing = true
		return
	end

	if ( ((event == "UNIT_SPELLCAST_INTERRUPTED") or (event == "UNIT_SPELLCAST_SUCCEEDED")) and (arg1 == "player") and ( (arg2 == ActivatePrimarySpecSpellName) or (arg2 == ActivateSecondarySpecSpellName))  ) then
--		DEFAULT_CHAT_FRAME:AddMessage("Healme Debug: Respecing Interrupt or succeeded")
		frame.Respecing = nil
	end

	-- This is not sent during initialization during a reload
	if (event == "PLAYER_TALENT_UPDATE") then
		Healme_DebugPrint("PLAYER_TALENT_UPDATE")
		frame.Respecing = nil

		-- mainly to reset cures.
		Healme_InitSpells(HealmeClass, HealmeRace)

		Healme_UpdateSpells()
		Healme_UpdateButtons()
		Healme_Update_ConfigPanel()
		return
	end


	if ((event == "SPELLS_CHANGED") and (not frame.Respecing)) then
		Healme_DebugPrint("SPELLS_CHANGED")
		-- Populate the Healme_Spell Table with ID and Icon data.
		Healme_UpdateSpells()
	end

	if ((event == "PLAYER_ENTERING_WORLD") and (not frame.Respecing)) then
		stable = true
		Healme_DebugPrint("PLAYER_ENTERING_WORLD")
		-- Populate the Healme_Spell Table with ID and Icon data.
		Healme_UpdateSpells()
	end

	if event == "UNIT_DISPLAYPOWER" then
		if Healme_Units[arg1] then
			for i,v  in pairs(Healme_Units[arg1]) do
				HealmeUnitFames_CheckPowerType(arg1, v)
			end
		end

		return
	end

	if (event == "RAID_TARGET_UPDATE") and Healme.ShowRaidIcons then
		Healme_UpdateRaidIcons()
		return
	end

	if event == "UNIT_NAME_UPDATE" then
		if Healme_Units[arg1] then
			local name = strupper(UnitName(arg1))
			for _,v  in pairs(Healme_Units[arg1]) do
				v.HealthBar.name:SetText(name)
			end
		end
		return
	end

	if (event == "GROUP_ROSTER_UPDATE") and Healme.ShowRole then
		Healme_UpdateRoles()
		return
	end

	if (event == "PLAYER_TARGET_CHANGED") and Healme.ShowTargetFrame then
		Healme_DebugPrint("PLAYER_TARGET_CHANGED")
		Healme_UpdateTargetFrame()
		return
	end

	if (event == "PLAYER_FOCUS_CHANGED") and Healme.ShowFocusFrame then
		Healme_DebugPrint("PLAYER_FOCUS_CHANGED")
		Healme_UpdateFocusFrame()
		return
	end

	-- Use this ADDON_LOADED event instead of VARIABLES_LOADED.
	-- ADDON_LOADED will not be called until the variables are loaded.
	if ((event == "ADDON_LOADED") and (string.lower(arg1) == string.lower(Healme_AddonName))) then
		Healme_DebugPrint("ADDON_LOADED")

		InitVariables()
		Healme_InitSpells(HealmeClass, HealmeRace)
		Healme_InitDebuffSound()
		Healme_CreateMiniMapButton()
		Healme_CreateConfigPanel(HealmeClass, AddonVersion)
		Healme_InitSlashCommands()
		Healme_InitMenu()
		Healme_CreateUnitFrames()
		Healme_SetScale()
		Healme_UpdatePercentageVisibility()
		Healme_UpdateClassColors()
		Healme_UpdateShowMana()
		Healme_UpdateShowBuffs()
		Healme_UpdateFriends()
		Healme_UpdateShowThreat()
		Healme_UpdateShowIncomingHeals()
		Healme_UpdateShowRaidIcons()
		Healme_UpdateButtons()
		Healme_UpdateShowRole()
		LoadedTime = GetTime()

		return
	end

	if (event == "PLAYER_LOGIN") then
		-- moving the showing of frames to here from ADDON_LOADED to try to overcome units not being shown right after player logs in
		Healme_DebugPrint("PLAYER_LOGIN")

		Healme_ShowHidePartyFrame()
		Healme_ShowHidePetsFrame()
		Healme_ShowHideMeFrame()
		Healme_ShowHideTanksFrame()
		Healme_ShowHideHealersFrame()
		Healme_ShowHideDamagersFrame()
		Healme_ShowHideFriendsFrame()
		Healme_ShowHideTargetFrame()
		Healme_ShowHideFocusFrame()


		for i=1, 8, 1 do
			Healme_ShowHideGroupFrame(i)
		end

		Healme_NonSpecHide()
		Healme_UpdateButtonVisibility()
		return
	end

	-- spec change event
	if (event == "PLAYER_SPECIALIZATION_CHANGED") then
	-- OK ITS CHANGED, NOW WHAT?
		Healme_NonSpecHide()
		Healme_UpdateButtonVisibility()
		return
	end
end
