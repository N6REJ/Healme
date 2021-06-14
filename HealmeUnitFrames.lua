-- Unit Frames Code

local IsClassic = _G.WOW_PROJECT_ID == _G.WOW_PROJECT_CLASSIC

local PartyFrame = nil
local PetsFrame = nil
local MeFrame = nil
local DamagersFrame = nil
local HealersFrame = nil
local TanksFrame = nil
local FriendsFrame = nil
local GroupFrames = { }
local TargetFrame = nil
local FocusFrame = nil

local PartyFrameWasShown = nil
local PetsFrameWasShown = nil
local MeFrameWasShown = nil
local DamagersFrameWasShown = nil
local HealersFrameWasShown = nil
local TanksFrameWasShown = nil
local FriendsFrameWasShown = nil
local GroupFramesWasShown = { }
local TargetFrameWasShown = nil
local FocusFrameWasShown = nil

local MaxBuffs = 6
local xSpacing = 2
local NamePlateHeight = 28
local LastDebuffSoundTime = GetTime()

local UnitFrames = { } -- table of all unit frames

ClickCastFrames = ClickCastFrames or {} -- used by Clique and any other click cast frames
local DebuffSoundPath

-- locale safe versions of spell names
local RejuvenationGermination = GetSpellInfo(155777) -- Rejuvenation (Germination) is a buff when a druid with the Germination talent casts Rejuvenation on a target
local EternalFlame = GetSpellInfo(156322) -- Eternal Flame is a buff when a paladin with the Eternal Flame talent casts Word of Glory on a target
local Atonement = GetSpellInfo(81749) -- Atonement: Plea, Power Word: Shield, Shadow Mend, and Power Word: Radiance also apply Atonement to your target for 15 sec.\
local GlimmerOfLight = GetSpellInfo(325983) -- Glimmer of Light is a buff when a paladin with the Glimmer of Light talent casts Holy Shock
local Tranquility = GetSpellInfo(740) -- Tranquility - HOT from Druid casting Tranquility

local defaults = {
		["PartyFrameWasShown"] = true,
		["PetFrameWasShown"] = true,
		["MeFrameWasShown"] = false,
		["FriendsFrameWasShown"] = false,
		["DamagersFrameWasShown"] = false,
		["HealersFrameWasShown"] = false,
		["TanksFrameWasShown"] = false,
		["TargetFrameWasShown"] = false,
		["FocusFrameWasShown"] = false,
		["Group1FrameWasShown"] = false,
		["Group2FrameWasShown"] = false,
		["Group3FrameWasShown"] = false,
		["Group4FrameWasShown"] = false,
		["Group5FrameWasShown"] = false,
		["Group6FrameWasShown"] = false,
		["Group7FrameWasShown"] = false,
		["Group8FrameWasShown"] = false,
}

Healme = Healme or defaults;

-- sounds ids from https://wow.tools/files/#search=&page=1&sort=0&desc=asc
Healme_Sounds = {
	{ ["Alliance Bell"] = { fileid = 566564 }},
	{ ["Bellow"] = { fileid = 566234 }},
	{ ["Dwarf Horn"] = {fileid = 566064 }},
	{ ["Gruntling Horn A"] = { fileid = 598076 }},
	{ ["Gruntling Horn B"] = { fileid = 598196 }},
	{ ["Horde Bell"] = { fileid = 565853 }},
	{ ["Man Scream"] = { fileid = 598052 }},
	{ ["Night Elf Bell"] = { fileid = 566558 }},
	{ ["Space Death"] = { fileid = 567198 }},
	{ ["Tribal Bell"] = { fileid = 566027 }},
	{ ["Wisp"] = { fileid = 567294 }},
	{ ["Woman Scream"] = { fileid = 598223 } },
	{ ["Vocal: Purge Debuff"] = { localfile = 1, path = "Interface\\AddOns\\Healme\\sounds\\purge_debuff.mp3"}}
}

function Healme_GetSoundPath(sound)
	for i,j in ipairs(Healme_Sounds) do
		if sound == next(j, nil) then

			-- use "localfile = 1" in table for files included in Healme
			if j[sound].localfile == 1 then
				return j[sound].path
			else
				return j[sound].fileid
			end
		end
	end

	return nil
end

function Healme_InitDebuffSound()
	DebuffSoundPath = Healme_GetSoundPath(Healme.DebufAudioFile)

	if DebuffSoundPath == nil then
		Healme.DebufAudioFile = "Alliance Bell"
		DebuffSoundPath = Healme_GetSoundPath(Healme.DebufAudioFile)
	end
end

function Healme_PlayDebuffSound()
	Healme_DebugPrint("playing sound " .. DebuffSoundPath)
	PlaySoundFile(DebuffSoundPath, "Master")
end

local function CreateButton(ButtonName,ParentFrame,xoffset)
	local button = CreateFrame("Button", ButtonName, ParentFrame, "HealmeHealButtonTemplate")
	button:SetPoint("LEFT", ParentFrame, "RIGHT", xoffset, 0)
	return button
end

-- please make sure we are not in combat before calling this function
function Healme_CreateButtonsForNameplate(frame)
	local x = xSpacing
	local Profile = Healme_GetProfile()

	for i=1, Healme_MaxButtons, 1 do
		name = frame:GetName()
		button = CreateButton(name.."_Heal"..i, frame, x)
		x = x + xSpacing + NamePlateHeight

		button.index = i -- .index is used by drag operation
		frame.buttons[i] = button

		-- set spell attribute for button
		Healme_SetButtonAttributes(button)

		-- set icon for button
		local texture = Profile.SpellIcons[i]
		Healme_UpdateButtonIcon(button, texture)

		if (i > Profile.ButtonCount) then
			button:Hide()

			if button:IsShown() then
				Healme_Warn("Failed to hide heal button")
			end
		else
			button:Show()

			if not button:IsShown() then
				Healme_Warn("Failed to show heal button")
			end
		end
	end
end

local function SetHeaderAttributes(frame)
--	frame.initialConfigFunction = initialConfigFunction
	frame:SetAttribute("showPlayer", "true")
	frame:SetAttribute("maxColumns", 1)
	frame:SetAttribute("columnAnchorPoint", "LEFT")
	frame:SetAttribute("point", "TOP")
	frame:SetAttribute("template", "HealmeUnitFrames_ButtonTemplate")
	frame:SetAttribute("templateType", "Button")
	frame:SetAttribute("unitsPerColumn", 5)
end

local function CreateHeader(TemplateName, FrameName, ParentFrame)
	local f = CreateFrame("Frame", FrameName, ParentFrame, TemplateName)
	ParentFrame.hdr = f
	f:SetPoint("TOPLEFT", ParentFrame, "BOTTOMLEFT")
	SetHeaderAttributes(f)
	return f
end

local function UpdateCloseButton(frame)
	-- Hide close button if set to
	if not InCombatLockdown() then
		if Healme.HideCloseButton then
			frame.CaptionBar.CloseButton:Hide()
		else
			frame.CaptionBar.CloseButton:Show()
		end
	end
end

local function UpdateHideCaption(frame)
	if Healme.HideCaptions then
		frame.CaptionBar:SetAlpha(0)
	else
		frame.CaptionBar:SetAlpha(1)
	end
end

local function CreateUnitFrame(FrameName, Caption, IsPet, Group)
	local uf = CreateFrame("Frame", FrameName, UIParent, "HealmeUnitFrameTemplate")
	table.insert(UnitFrames, uf)
	uf.CaptionBar.Caption:SetText(Caption)
	UpdateCloseButton(uf)
	UpdateHideCaption(uf)
	return uf
end

local function CreatePetHeader(FrameName, ParentFrame)
	local h = CreateHeader("SecureGroupPetHeaderTemplate", FrameName, ParentFrame)
	h:SetAttribute("filterOnPet", "true")
	h:SetAttribute("unitsPerColumn", 40) -- allow pets frame to show more than 5
	h:SetAttribute("showSolo", "true")
	h:SetAttribute("showRaid", "true")
	h:SetAttribute("showParty", "true")
	h:Show()
	return h
end

local function CreateGroupHeader(FrameName, ParentFrame, Group)
	local h = CreateHeader("SecureGroupHeaderTemplate", FrameName, ParentFrame)
	h:SetAttribute("groupFilter", Group)
	h:SetAttribute("showRaid", "false")
	h:SetAttribute("showSolo", "false")
	h:SetAttribute("showParty", "false")
	h:Show()
	return h
end

local function CreateDamagersHeader(FrameName, ParentFrame)
	local h = CreateHeader("SecureGroupHeaderTemplate", FrameName, ParentFrame)
	h:SetAttribute("unitsPerColumn", 40) -- allow  frame to show more than 5
	h:SetAttribute("roleFilter", "DAMAGER")
	h:SetAttribute("showParty", "false")
	h:SetAttribute("showRaid", "true")
	h:SetAttribute("showSolo", "false")
	h:Show()
	return h
end

local function CreateHealersHeader(FrameName, ParentFrame)
	local h = CreateHeader("SecureGroupHeaderTemplate", FrameName, ParentFrame)
	h:SetAttribute("unitsPerColumn", 40) -- allow frame to show more than 5
	h:SetAttribute("roleFilter", "HEALER")
	h:SetAttribute("showParty", "false")
	h:SetAttribute("showRaid", "true")
	h:SetAttribute("showSolo", "false")
	h:Show()
	return h
end

local function CreateTanksHeader(FrameName, ParentFrame)
	local h = CreateHeader("SecureGroupHeaderTemplate", FrameName, ParentFrame)
	h:SetAttribute("unitsPerColumn", 40) -- allow frame to show more than 5
	h:SetAttribute("roleFilter", "MT,TANK")
	h:SetAttribute("showParty", "false")
	h:SetAttribute("showRaid", "true")
	h:SetAttribute("showSolo", "false")
	h:Show()
	return h
end

local function CreatePartyHeader(FrameName, ParentFrame)
	local h = CreateHeader("SecureGroupHeaderTemplate", FrameName, ParentFrame)
	h:SetAttribute("showSolo", "false")
	h:SetAttribute("showRaid", "false")
	h:SetAttribute("showParty", "true")
	h:Show()
	return h
end

local function CreateMeHeader(FrameName, ParentFrame)
	local h = CreateHeader("SecureGroupHeaderTemplate", FrameName, ParentFrame)
	h:SetAttribute("showSolo", "true")
	h:SetAttribute("showRaid", "false")
	h:SetAttribute("showParty", "false")
	h:SetAttribute("nameList", UnitName("Player"))
	h:Show()
	return h
end

local function CreateFriendsHeader(FrameName, ParentFrame)
	local h = CreateHeader("SecureGroupHeaderTemplate", FrameName, ParentFrame)
	h:SetAttribute("showSolo", "true")
	h:SetAttribute("showRaid", "true")
	h:SetAttribute("showParty", "true")
	h:SetAttribute("unitsPerColumn", 20) -- allow friends frame to show more than 5
	h:Show()
	return h
end

local function CreateCustomHeader(FrameName, ParentFrame, Unit)
	local h = CreateFrame("Button", FrameName, ParentFrame, "HealmeUnitFrames_ButtonTemplate")
	h.isCustom = true
	ParentFrame.hdr = h
	h:SetAttribute("unit", Unit)
	h:SetPoint("TOPLEFT", ParentFrame, "BOTTOMLEFT")
	RegisterUnitWatch(h)
	h:Show()
	return h
end

local function CreateGroupUnitFrame(FrameName, Caption, Group)
	local uf = CreateUnitFrame(FrameName, Caption)
	local h = CreateGroupHeader(FrameName .. "_Header", uf, Group)
	return uf
end

local function CreateDamagersUnitFrame(FrameName, Caption)
	local uf = CreateUnitFrame(FrameName, Caption)
	local h = CreateDamagersHeader(FrameName .. "_Header", uf)
	return uf
end

local function CreateHealersUnitFrame(FrameName, Caption)
	local uf = CreateUnitFrame(FrameName, Caption)
	local h = CreateHealersHeader(FrameName .. "_Header", uf)
	return uf
end

local function CreateTanksUnitFrame(FrameName, Caption)
	local uf = CreateUnitFrame(FrameName, Caption)
	local h = CreateTanksHeader(FrameName .. "_Header", uf)
	return uf
end

local function CreatePetUnitFrame(FrameName, Caption)
	local uf = CreateUnitFrame(FrameName, Caption)
	local h = CreatePetHeader(FrameName .. "_Header", uf)
	return uf
end

local function CreateMeUnitFrame(FrameName, Caption)
	local uf = CreateUnitFrame(FrameName, Caption)
	local h = CreateMeHeader(FrameName .. "_Header", uf)
	return uf
end

local function CreateFriendsUnitFrame(FrameName, Caption)
	local uf = CreateUnitFrame(FrameName, Caption)
	local h = CreateFriendsHeader(FrameName .. "_Header", uf)
	return uf
end

local function CreatePartyUnitFrame(FrameName, Caption)
	local uf = CreateUnitFrame(FrameName, Caption)
	local h = CreatePartyHeader(FrameName .. "_Header", uf)
	return uf
end

local function CreateTargetUnitFrame(FrameName, Caption)
	local uf = CreateUnitFrame(FrameName, Caption)
	local h = CreateCustomHeader(FrameName .. "_Header", uf, "target")
	return uf
end

local function CreateFocusUnitFrame(FrameName, Caption)
	local uf = CreateUnitFrame(FrameName, Caption)
	local h = CreateCustomHeader(FrameName .. "_Header", uf, "focus")
	return uf
end

function Healme_UpdateCloseButtons()
	for _,j in pairs(UnitFrames) do
		UpdateCloseButton(j)
	end
end

function Healme_UpdateHideCaptions()
	for _,j in pairs(UnitFrames) do
		UpdateHideCaption(j)
	end
end

function HealmeUnitFrames_OnEnter(frame)
	frame:SetAlpha(1)
end

function HealmeUnitFrames_OnLeave(frame)
	if Healme.HideCaptions then
		frame:SetAlpha(0)
	end
end

function HealmeUnitFrames_OnMouseDown(frame, button)
	if button == "LeftButton" and not Healme.LockFrames then
		frame:StartMoving()
	end

	if button == "RightButton" then
		Lib_ToggleDropDownMenu(1, nil, HealmeMenu, frame, 0, 0)
	end
end

function HealmeUnitFrames_OnMouseUp(frame, button)
	if button == "LeftButton" then
		frame:StopMovingOrSizing()
	end

	if button == "RightButton" then

	end
end

function HealmeUnitFrames_ShowHideFrame(frame, show)
	if frame == PartyFrame then
		Healme.ShowPartyFrame = show
		Healme_ShowPartyCheck:SetChecked(Healme.ShowPartyFrame)
		return
	end

	if frame == PetsFrame then
		Healme.ShowPetsFrame = show
		Healme_ShowPetsCheck:SetChecked(Healme.ShowPetsFrame)
		return
	end

	if frame == MeFrame then
		Healme.ShowMeFrame = show
		Healme_ShowMeCheck:SetChecked(Healme.ShowMeFrame)
		return
	end

	if frame == FriendsFrame then
		Healme.ShowFriendsFrame = show
		Healme_ShowFriendsCheck:SetChecked(Healme.ShowFriendsFrame)
		return
	end

	if frame == DamagersFrame then
		Healme.ShowDamagersFrame = show
-- TODO DAMAGERS/HEALERS frame
		Healme_ShowDamagersCheck:SetChecked(Healme.ShowDamagersFrame)
		return
	end

	if frame == HealersFrame then
		Healme.ShowHealersFrame = show
-- TODO DAMAGERS/HEALERS frame
		Healme_ShowHealersCheck:SetChecked(Healme.ShowHealersFrame)
		return
	end

	if frame == TanksFrame then
		Healme.ShowTanksFrame = show
		Healme_ShowTanksCheck:SetChecked(Healme.ShowTanksFrame)
		return
	end

	if frame == TargetFrame then
		Healme_DebugPrint("ShowHide Target Frame")
		Healme.ShowTargetFrame = show
		Healme_ShowTargetCheck:SetChecked(Healme.ShowTargetFrame)
		Healme_UpdateShowTargetFrame()
		Healme_UpdateTargetFrame()
		return
	end

	if (not IsClassic) and (frame == FocusFrame) then
		Healme_DebugPrint("ShowHide Focus Frame")
		Healme.ShowFocusFrame = show
		Healme_ShowFocusCheck:SetChecked(Healme.ShowFocusFrame)
		Healme_UpdateShowFocusFrame()
		Healme_UpdateFocusFrame()
		return
	end


	for i,j in ipairs(GroupFrames) do
		if frame == j then
			Healme.ShowGroupFrames[i] = show
			Healme_ShowGroup1Check:SetChecked(Healme.ShowGroupFrames[1])
			Healme_ShowGroup2Check:SetChecked(Healme.ShowGroupFrames[2])
			Healme_ShowGroup3Check:SetChecked(Healme.ShowGroupFrames[3])
			Healme_ShowGroup4Check:SetChecked(Healme.ShowGroupFrames[4])
			Healme_ShowGroup5Check:SetChecked(Healme.ShowGroupFrames[5])
			Healme_ShowGroup6Check:SetChecked(Healme.ShowGroupFrames[6])
			Healme_ShowGroup7Check:SetChecked(Healme.ShowGroupFrames[7])
			Healme_ShowGroup8Check:SetChecked(Healme.ShowGroupFrames[8])
			return
		end
	end
end

function HealmeUnitFrames_Button_OnLoad(frame)
	frame.buttons = { }
	frame:RegisterForClicks("AnyUp")

	table.insert(Healme_Frames, frame)

	if Healme.EnableClique then
		ClickCastFrames[frame] = true
	end

	-- configure buff frames
	frame.buffs = { }

	local framename = frame:GetName()
	for i=1, MaxBuffs, 1 do
		local buffframe = _G[framename.."_Buff"..i]
		local name = buffframe:GetName()
		buffframe.icon = _G[name.."Icon"]
		buffframe.cooldown = _G[name.."Cooldown"]
		buffframe.count = _G[name.."Count"]
		buffframe.border = _G[name.."Border"]
		buffframe.id = i
		frame.buffs[i] = buffframe
	end

	if InCombatLockdown() then
		frame.fixCreateButtons = true
		table.insert(Healme_FixNameplates, frame)
		Healme_DebugPrint("Unit frame created during combat. Its buttons will not be available until combat ends.")
	else
		if (not Healme.ShowPercentage) then frame.HealthBar.HPText:Hide() end
		Healme_CreateButtonsForNameplate(frame)
	end

	frame:RegisterForDrag("RightButton")
end

function HealmeUnitFames_CheckPowerType(UnitName, NamePlate)
	local _, powerType = UnitPowerType(UnitName)
	if  (Healme.ShowMana == false) or (UnitExists(UnitName) == nil) or (powerType ~= "MANA") then
--	if  UnitManaMax(UnitName) == nil then
		NamePlate.ManaBar:SetStatusBarColor( .5, .5, .5 )
		NamePlate.ManaBar:SetMinMaxValues(0,1)
		NamePlate.ManaBar:SetValue(1)
		NamePlate.showMana = nil
		return nil
	else
		local powerColor = PowerBarColor[powerType];
		NamePlate.ManaBar:SetStatusBarColor( powerColor.r, powerColor.g, powerColor.b )
		NamePlate.showMana = true
	end

	return true
end



function HealmeUnitFrames_Button_OnShow(frame)
	table.insert(Healme_ShownFrames, frame)
end

function HealmeUnitFrames_Button_OnHide(frame)
	Healme_ShownFrames[frame] = nil

	local parent = frame:GetParent()

	if not frame.isCustom then
		parent = parent:GetParent()
	end

	if parent.childismoving then
		parent:StopMovingOrSizing()
		parent.childismoving = nil
	end

end

function HealmeUnitFrames_Button_OnAttributeChanged(frame, name, value)
	if name == "unit" or name == "unitsuffix" then
		local newUnit = SecureButton_GetUnit(frame)
		local oldUnit = frame.TargetUnit

		Healme_DebugPrint(newUnit)

--		if newUnit == oldUnit then
--			return
--		end

		if newUnit then
			for i=1, Healme_MaxButtons, 1 do
				local button = frame.buttons[i]
				if not button then break end

				-- update cooldowns
				Healme_UpdateButtonCooldown(button)
			end


			if not Healme_Units[newUnit] then
				Healme_Units[newUnit] = { }
			end

			table.insert(Healme_Units[newUnit], frame)

			for i =1, MaxBuffs, 1 do
				frame.buffs[i].unit = newUnit
			end

			HealmeUnitFames_CheckPowerType(newUnit, frame)

			Healme_UpdateUnitName(newUnit, frame)
			Healme_UpdateUnitHealth(newUnit, frame)
			Healme_UpdateUnitMana(newUnit, frame)
			Healme_UpdateUnitBuffs(newUnit, frame)
			Healme_UpdateUnitThreat(newUnit, frame)
			Healme_UpdateUnitRole(newUnit, frame)
			Healme_UpdateSpecialBuffs(newUnit)
			Healme_UpdateRaidTargetIcon(frame)

			if not Healme.ShowIncomingHeals then
				frame.PredictBar:Hide()
			end

		end

		if oldUnit then
			if Healme_Units[oldUnit] then
				for i,v in ipairs(Healme_Units[oldUnit]) do
					if v == frame then
						table.remove(Healme_Units[oldUnit], i)
						break
					end
				end
			end
		end

		frame.TargetUnit = newUnit
	end
end

function HealmeUnitFrames_Button_OnMouseDown(frame, button)
	if button == "RightButton" and not Healme.LockFrames then
		local parent = frame:GetParent()

		if not frame.isCustom then
			parent = parent:GetParent()
		end

		parent.childismoving = true
		parent:StartMoving()
	end
end

function HealmeUnitFrames_Button_OnMouseUp(frame, button)
	if button == "RightButton" then
		local parent = frame:GetParent()

		if not frame.isCustom then
			parent = parent:GetParent()
		end

		parent:StopMovingOrSizing()
		parent.childismoving = nil
	end
end

local function IsAnyUnitFrameVisible()
	local visible

	for _,j in pairs(UnitFrames) do
		if j:IsShown() then
			return true
		end
	end

	return nil
end

function Healme_HealSpec()
	local _, _, classId = UnitClass('player');
	local specId = GetSpecialization();
	--[[[1] = 'Warrior',
		[2] = 'Paladin',
		[3] = 'Hunter',
		[4] = 'Rogue',
		[5] = 'Priest',
		[6] = 'DeathKnight',
		[7] = 'Shaman',
		[8] = 'Mage',
		[9] = 'Warlock',
		[10] = 'Monk',
		[11] = 'Druid',
		[12] = 'DemonHunter',]]

	if (classId == 2 and specId == 1) or
	(classId == 5 and specId == 2) or
	(classId == 7 and specId == 3) or
	(classId == 10 and specId == 2) or
	(classId == 11 and specId == 4)	then
		return true;
	end
	return false;
end

function Healme_NonSpecHide()
	if HealmePanelScrollFrameScrollChildSpecializationCheckButton:GetChecked() and not Healme_HealSpec() then
		local _Frame_Names = {'Party', 'Pet', 'Me', 'Friends', 'Damagers', 'Healers', 'Tanks', 'Target', 'Focus', 'Group'};
		for _, frameName in pairs(_Frame_Names) do
			if frameName == 'Group' then
				for i = 1, 8 do
					local frame = _G["Healme" .. frameName .. i .. "Frame"];
					frame:SetAlpha(0);
					frame:EnableMouse(false);
				end
			else
				local frame = _G["Healme" .. frameName .. "Frame"];
				frame:SetAlpha(0);
				frame:EnableMouse(false);
			end
		end
	else
		local _Frame_Names = {'Party', 'Pet', 'Me', 'Friends', 'Damagers', 'Healers', 'Tanks', 'Target', 'Focus', 'Group'};
		for _, frameName in pairs(_Frame_Names) do
			if frameName == 'Group' then
				for i = 1, 8 do
					local frame = _G["Healme" .. frameName .. i .. "Frame"];
					frame:SetAlpha(1);
					frame:EnableMouse(true);
				end
			else
				local frame = _G["Healme" .. frameName .. "Frame"];
				frame:SetAlpha(1);
				frame:EnableMouse(true);
			end
		end
	end
end

function Healme_ToggleAllFrames()
	if InCombatLockdown() then
		Healme_Warn("Can't toggle frames while in combat.")
		return
	end

	local hide = false

	if PartyFrame:IsShown() then hide = true end
	if PetsFrame:IsShown() then hide = true end
	if MeFrame:IsShown() then hide = true end
	if FriendsFrame:IsShown() then hide = true end
	if DamagersFrame:IsShown() then hide = true end
	if HealersFrame:IsShown() then hide = true end
	if TanksFrame:IsShown() then hide = true end
	if TargetFrame:IsShown() then hide = true end

	if not IsClassic then
		if FocusFrame:IsShown() then hide = true end
	end

	for i,j in ipairs(GroupFrames) do
		if j:IsShown() then
			hide = true
			break
		end
	end

	if hide then
		PartyFrameWasShown = PartyFrame:IsShown()
		PetsFrameWasShown = PetsFrame:IsShown()
		MeFrameWasShown = MeFrame:IsShown()
		FriendsFrameWasShown = FriendsFrame:IsShown()
		DamagersFrameWasShown = DamagersFrame:IsShown()
		HealersFrameWasShown = HealersFrame:IsShown()
		TanksFrameWasShown = TanksFrame:IsShown()
		TargetFrameWasShown = TargetFrame:IsShown()

		if not IsClassic then
			FocusFrameWasShown = FocusFrame:IsShown()
		end

		PartyFrame:Hide()
		PetsFrame:Hide()
		MeFrame:Hide()
		FriendsFrame:Hide()
		DamagersFrame:Hide()
		HealersFrame:Hide()
		TanksFrame:Hide()
		TargetFrame:Hide()

		if not IsClassic then
			FocusFrame:Hide()
		end

		for i,j in ipairs(GroupFrames) do
			GroupFramesWasShown[i] = j:IsShown()
			j:Hide()
		end

		Healme_Print("Current frames are now hidden.")
		return
	end

	-- after this point, we know we are showing frames

	if PartyFrameWasShown then PartyFrame:Show() end
	if PetsFrameWasShown then PetsFrame:Show() end
	if MeFrameWasShown then MeFrame:Show() end
	if FriendsFrameWasShown then FriendsFrame:Show() end
	if DamagersFrameWasShown then DamagersFrame:Show() end
	if HealersFrameWasShown then HealersFrame:Show() end
	if TanksFrameWasShown then TanksFrame:Show() end
	if TargetFrameWasShown then TargetFrame:Show() end

	if not IsClassic then
		if FocusFrameWasShown then FocusFrame:Show() end
	end

	for i,j in ipairs(GroupFramesWasShown) do
		if j then
			GroupFrames[i]:Show()
		end
	end

	if IsAnyUnitFrameVisible() == nil then
		PartyFrame:Show()
		PetsFrame:Show()
	end

	Healme_Print("Current frames are now shown.")
end

function Healme_ShowHidePartyFrame(show)
	if InCombatLockdown() then return end
	if (show ~= nil) then Healme.ShowPartyFrame = show end

	if Healme.ShowPartyFrame then
		PartyFrame:Show()
	else
		PartyFrame:Hide()
	end
end

function Healme_ShowHidePetsFrame(show)
	if InCombatLockdown() then return end
	if (show ~= nil) then Healme.ShowPetsFrame = show end

	if Healme.ShowPetsFrame then
		PetsFrame:Show()
	else
		PetsFrame:Hide()
	end
end

function Healme_ShowHideMeFrame(show)
	if InCombatLockdown() then return end
	if (show ~= nil) then Healme.ShowMeFrame = show end

	if Healme.ShowMeFrame then
		MeFrame:Show()
	else
		MeFrame:Hide()
	end
end

function Healme_ShowHideFriendsFrame(show)
	if InCombatLockdown() then return end
	if (show ~= nil) then Healme.ShowFriendsFrame = show end

	if Healme.ShowFriendsFrame then
		FriendsFrame:Show()
	else
		FriendsFrame:Hide()
	end
end

function Healme_ShowHideDamagersFrame(show)
	if InCombatLockdown() then return end
	if (show ~= nil) then Healme.ShowDamagersFrame = show end

	if Healme.ShowDamagersFrame then
		DamagersFrame:Show()
	else
		DamagersFrame:Hide()
	end
end

function Healme_ShowHideHealersFrame(show)
	if InCombatLockdown() then return end
	if (show ~= nil) then Healme.ShowHealersFrame = show end

	if Healme.ShowHealersFrame then
		HealersFrame:Show()
	else
		HealersFrame:Hide()
	end
end

function Healme_ShowHideTanksFrame(show)
	if InCombatLockdown() then return end
	if (show ~= nil) then Healme.ShowTanksFrame = show end

	if Healme.ShowTanksFrame then
		TanksFrame:Show()
	else
		TanksFrame:Hide()
	end
end

function Healme_ShowHideTargetFrame(show)
	if InCombatLockdown() then return end
	if (show ~= nil) then Healme.ShowTargetFrame = show end

	if Healme.ShowTargetFrame then
		TargetFrame:Show()
	else
		TargetFrame:Hide()
	end

	Healme_UpdateShowTargetFrame()
end

function Healme_ShowHideFocusFrame(show)
	if IsClassic then return end
	if InCombatLockdown() then return end
	if (show ~= nil) then Healme.ShowFocusFrame = show end

	if Healme.ShowFocusFrame then
		FocusFrame:Show()
	else
		FocusFrame:Hide()
	end

	Healme_UpdateShowFocusFrame()
end

function Healme_ShowHideGroupFrame(group, show)
	if InCombatLockdown() then return end
	if (show ~= nil) then Healme.ShowGroupFrames[group] = show end

	if Healme.ShowGroupFrames[group] then
		GroupFrames[group]:Show()
	else
		GroupFrames[group]:Hide()
	end
end

function Healme_HideAllRaidFrames()
	if InCombatLockdown() then return end
--	TanksFrame:Hide()
	for i,j in ipairs(GroupFrames) do
		j:Hide()
	end
end

function Healme_ShowAllRaidFramesWithMembers()
end

function Healme_Show10ManRaidFrames()
	if InCombatLockdown() then return end
	GroupFrames[1]:Show()
	GroupFrames[2]:Show()
end

function Healme_Show25ManRaidFrames()
	if InCombatLockdown() then return end
	for i=1, 5, 1 do
		GroupFrames[i]:Show()
	end
end

function Healme_Show40ManRaidFrames()
	if InCombatLockdown() then return end
	for i=1, 8, 1 do
		GroupFrames[i]:Show()
	end
end

function Healme_CreateUnitFrames()
	PartyFrame = CreatePartyUnitFrame("HealmePartyFrame", "Party")
	PetsFrame = CreatePetUnitFrame("HealmePetFrame", "Pets")
	MeFrame = CreateMeUnitFrame("HealmeMeFrame", "Me")
	FriendsFrame = CreateFriendsUnitFrame("HealmeFriendsFrame", "Friends")
	DamagersFrame = CreateDamagersUnitFrame("HealmeDamagersFrame", "Damagers")
	HealersFrame = CreateHealersUnitFrame("HealmeHealersFrame", "Healers")
	TanksFrame = CreateTanksUnitFrame("HealmeTanksFrame", "Tanks")
	TargetFrame = CreateTargetUnitFrame("HealmeTargetFrame", "Target")

	if not IsClassic then
		FocusFrame = CreateFocusUnitFrame("HealmeFocusFrame", "Focus")
	end

	for i=1, 8, 1 do
		GroupFrames[i] = CreateGroupUnitFrame("HealmeGroup" .. i .. "Frame", "Group " .. i, tostring(i))
		GroupFramesWasShown[i]  = false
	end

end


function Healme_SetScale()
	local Scale = Healme.Scale

	PartyFrame:SetScale(Scale)
	PetsFrame:SetScale(Scale)
	MeFrame:SetScale(Scale)
	FriendsFrame:SetScale(Scale)
	DamagersFrame:SetScale(Scale)
	HealersFrame:SetScale(Scale)
	TanksFrame:SetScale(Scale)
	TargetFrame:SetScale(Scale)

	if not IsClassic then
		FocusFrame:SetScale(Scale)
	end

	for i,j in ipairs(GroupFrames) do
		j:SetScale(Scale)
	end
end

function Healme_MakeRankedSpellName(spellName, spellSubtext)
	local rankedSpellName

	if spellSubtext == "" then
		spellSubtext = nil
	end

	if spellSubtext then
		rankedSpellName = spellName .. "(" .. spellSubtext .. ")"
	else
		rankedSpellName = spellName
	end

	return rankedSpellName
end

function Healme_UpdateUnitBuffs(unit, frame)

	local buffIndex = 1
	local Profile = Healme_GetProfile()

	if Healme.ShowBuffs then
		for i=1, 100, 1 do
			local name, icon, count, debuffType, duration, expirationTime, source, isStealable = UnitBuff(unit, i)
			if name then
				if (source == "player") then

					local armed = false

					for j=1, Profile.ButtonCount, 1 do
						if Profile.SpellNames[j] == name or name == RejuvenationGermination or name == EternalFlame or name == Atonement or name == GlimmerOfLight or name == Tranquility then
							armed = true
							break
						end
					end

					if armed == true then
						local buffFrame = frame.buffs[buffIndex]

						buffFrame:SetID(i)
						buffFrame.icon:SetTexture(icon)

						if count > 1 then
							buffFrame.count:SetText(count)
							buffFrame.count:Show()
						else
							buffFrame.count:Hide()
						end

						if duration and duration > 0 then
							local startTime = expirationTime - duration
							buffFrame.cooldown:SetCooldown(startTime, duration)
							buffFrame.cooldown:Show()
						else
							buffFrame.cooldown:Hide()
						end

						buffFrame:Show()
						buffIndex = buffIndex + 1
						if buffIndex > MaxBuffs then
							break
						end

					end
				end
			else
				break
			end
		end
	end

	-- hide remainder frames
	for i = buffIndex, MaxBuffs, 1 do
		frame.buffs[i]:Hide()
	end

	-- Handle affliction notification
	if Healme.EnableDebufs then

		local foundDebuff = false
		local debuffTypes = { }

		for i = 1, 40, 1 do
			local name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = UnitDebuff(unit, i)

			if name == nil then
				break
			end

			if debuffType ~= nil then
				if Healme_CanCureDebuff(debuffType) then
					foundDebuff = true
					debuffTypes[debuffType] = true
					local debuffColor = DebuffTypeColor[debuffType] or DebuffTypeColor["none"];
					frame.hasDebuf = true
					frame.debuffColor = debuffColor

					if Healme.EnableDebufHealthbarHighlighting then
						frame.CurseBar:SetBackdropBorderColor(debuffColor.r, debuffColor.g, debuffColor.b)
						frame.CurseBar:SetAlpha(1)
					end

					if Healme.EnableDebufAudio then
						local now = GetTime()
						if unit == "player" or UnitInRange(unit) then -- UnitInRange will return false for "player"
							if now > (LastDebuffSoundTime + 7) then
								Healme_PlayDebuffSound()
								LastDebuffSoundTime = now
							end
						end
					end
				end
			end
		end

		if (not foundDebuff) and frame.hasDebuf then
			frame.CurseBar:SetAlpha(0)
			frame.hasDebuf = nil
		end

		if Healme.EnableDebufButtonHighlighting then
			Healme_ShowDebuffButtons(Profile, frame, debuffTypes)
		end

		Healme_UpdateUnitHealth(unit, frame)
	end
end

function Healme_UpdateEnableDebuffs()
	for _,j in pairs(UnitFrames) do
		if j.hasDebuf then
			frame.CurseBar:SetAlpha(0)
			frame.hasDebuf = nil

			for i=1, Healme_MaxButtons, 1 do
				local button = frame.button[i]
				if button then
					button.curseBar:SetAlpha(0)
					button.curseBar.hasDebuf = nil
				end
			end
		end
	end
end

function Healme_ManaStatusBar_OnLoad(frame)
	frame:SetRotatesTexture(true)
	frame:SetOrientation("VERTICAL")
end

function Healme_UpdateEnableClique()
	for _,k in ipairs(Healme_Frames) do
		if Healme.EnableClique then
			ClickCastFrames[k] = true
		else
			ClickCastFrames[k] = nil
			k:SetAttribute("type1", "target")
		end
	end
end

function Healme_ResetAllFramePositions()
	for _,k in ipairs(UnitFrames) do
		k:SetUserPlaced(false)
		k:ClearAllPoints()
		k:SetPoint("Center", UIParent, 0,0)
	end
	Healme_Print("Reset frame positions complete.")
end

function Healme_UpdateFriends()
	local names = ""
	for k, v in pairs(HealmeGlobal.Friends) do
		if names:len() > 0 then
			names = names .. "," .. v
		else
			names = v
		end
	end
	Healme_DebugPrint("namesList: " ..names)
	FriendsFrame.hdr:SetAttribute("nameList", names)
--	Healme_DebugPrint("Friends header is shown: " .. FriendsFrame.hdr:IsShown())
end

function Healme_UpdateTargetFrame()
	HealmeUnitFrames_Button_OnAttributeChanged(TargetFrame.hdr, "unit")
end

function Healme_UpdateFocusFrame()
	if IsClassic then return end
	HealmeUnitFrames_Button_OnAttributeChanged(FocusFrame.hdr, "unit")
end
