local IsClassic = _G.WOW_PROJECT_ID == _G.WOW_PROJECT_CLASSIC

local function CreateDropDownMenu(name,parent,x,y)
  local f = CreateFrame("Frame", name, parent, "Lib_UIDropDownMenuTemplate") 
  f:SetPoint("TOPLEFT", parent, "TOPLEFT",x,y)
  Lib_UIDropDownMenu_SetWidth(f, 180)  
  
  f.Text = f:CreateFontString(nil, "OVERLAY","GameFontNormal")
  f.Text:SetPoint("TOPLEFT",f,"TOPLEFT",-50,-5)
  
  return f
end

local function DropDownMenuItem_OnClick(dropdownbutton)
	Lib_UIDropDownMenu_SetSelectedValue(dropdownbutton.owner, dropdownbutton.value) 

	local Profile = Healme_GetProfile()
	
	if (dropdownbutton.value == nil) then
--		Healme_SetProfileSpell(Profile, i, nil, nil, nil)
	end

	for i=1, Healme_MaxClassSpells, 1 do
		if (dropdownbutton.owner == HealmeDropDown[i]) then
			for j=0, Healme_MaxClassSpells - 1, 1 do
				if (dropdownbutton.value == j) then
					Healme_SetProfileSpell(Profile, i, Healme_Spell.Name[j+1], Healme_Spell.ID[j+1], Healme_Spell.Icon[j+1], nil)
				end
			end
		end
	end
	
	Healme_UpdateButtonIcons()
	Healme_UpdateButtonAttributes()
end

-- Function called when the menu is opened, responsible for adding menu buttons
local function DropDownMenu_Init(frame,level)

	level = level or 1  
	local info = Lib_UIDropDownMenu_CreateInfo() 
	
	local DropDown = frame
	local spell = Lib_UIDropDownMenu_GetText(DropDown)
	
	for k, v in ipairs (Healme_Spell.Name) do
		info.text = Healme_Spell.Name[k]
		info.value = k-1
		info.func = DropDownMenuItem_OnClick
		info.owner = DropDown
		info.checked = nil 
		info.icon = Healme_Spell.Icon[k]
		if (info.icon) then
			Lib_UIDropDownMenu_AddButton(info, level) 
			if Healme_Spell.Name[k] == spell then
				Lib_UIDropDownMenu_SetSelectedValue(DropDown , k-1)	
			end
		end
	end
	
	-- Add No Spell
	info.text = "No Spell"
	info.value = #Healme_Spell.Name
	info.func = DropDownMenuItem_OnClick
	info.ownder = DropDown
	info.checked = (spell == nil) or (spell == "No Spell")
	info.icon = nil
  
	Lib_UIDropDownMenu_AddButton(info, level)   
end

local function SoundDropDownMenuItem_OnClick(dropdownbutton)
	Lib_UIDropDownMenu_SetSelectedValue(dropdownbutton.owner, dropdownbutton.value) 
	Healme.DebufAudioFile = dropdownbutton.value
	Healme_InitDebuffSound()
	Healme_PlayDebuffSound()
end

local function SoundDropDownMenu_Init(frame, level)
	level = level or 1  
	local info = Lib_UIDropDownMenu_CreateInfo() 
	local sound = Lib_UIDropDownMenu_GetText(frame)
	
	for k, v in ipairs (Healme_Sounds) do
		local this_sound = next(v, nil)
		if not IsClassic or not v[this_sound].retail then 
			info.text = this_sound
			info.value = this_sound
			info.func = SoundDropDownMenuItem_OnClick
			info.owner = frame
			info.checked = nil 
			Lib_UIDropDownMenu_AddButton(info, level) 
			if this_sound == sound then
				Lib_UIDropDownMenu_SetSelectedValue(frame, this_sound)	
			end
		end
	end
end


local function UpdateRangeCheckSliderText(frame)
    frame.Text:SetText("Range Check Frequency: |cFFFFFFFF".. format("%.1f",frame:GetValue()) .. " Hz")
end

function Healme_SetButtonCount(count)
  HealmeMaxButtonSlider.Text:SetText("Show |cFFFFFFFF"..count.. "|r Buttons")
  Healme_GetProfile().ButtonCount = count
  Healme_UpdateButtonVisibility()
end

local function MaxButtonSlider_Update(frame)
-- work around lame Blizzard slider bug in 5.4.0 and still in 5.4.1
	local step = frame:GetValueStep()
	local fixed_value = floor(frame:GetValue() / step + 0.5) * step;
	Healme_SetButtonCount(fixed_value)
end

local function TooltipsCheck_OnClick(frame)
	Healme.ShowToolTips = frame:GetChecked() or false
end

local function PercentageCheck_OnClick(frame)
	Healme.ShowPercentage = frame:GetChecked() or false
	Healme_UpdatePercentageVisibility()
end

local function ClassColorCheck_OnClick(frame)
	Healme.UseClassColors = frame:GetChecked() or false
	Healme_UpdateClassColors()
end

local function ShowBuffsCheck_OnClick(frame)
	Healme.ShowBuffs = frame:GetChecked() or false
	Healme_UpdateShowBuffs()
end

local function RangeCheckCheck_OnClick(frame)
	Healme.DoRangeChecks = frame:GetChecked() or false
end

local function EnableCooldownsCheck_OnClick(frame)
	Healme.EnableCooldowns = frame:GetChecked() or false
end

local function HideCloseButtonCheck_OnClick(frame)
	Healme.HideCloseButton = frame:GetChecked() or false
	Healme_UpdateCloseButtons()
end

local function HideCaptionsCheck_OnClick(frame)
	Healme.HideCaptions = frame:GetChecked() or false
	Healme_UpdateHideCaptions()
end

local function LockFramePositionsCheck_OnClick(frame)
	Healme.LockFrames = frame:GetChecked() or false
end

local function EnableCliqueCheck_OnClick(frame)
	Healme.EnableClique = frame:GetChecked() or false
	Healme_UpdateEnableClique()
end

local function ShowManaCheck_OnClick(frame)
	Healme.ShowMana = frame:GetChecked() or false
	Healme_UpdateShowMana()
end

local function ShowThreatCheck_OnClick(frame)
	Healme.ShowThreat = frame:GetChecked() or false
	Healme_UpdateShowThreat()
end

local function ShowRoleCheck_OnClick(frame)
	Healme.ShowRole = frame:GetChecked() or false
	Healme_UpdateShowRole()
end

local function ShowIncomingHealsCheck_OnClick(frame)
	Healme.ShowIncomingHeals = frame:GetChecked() or false
	Healme_UpdateShowIncomingHeals()
end

local function ShowRaidIconsCheck_OnClick(frame)
	Healme.ShowRaidIcons = frame:GetChecked() or false
	Healme_UpdateShowRaidIcons()
end

local function UppercaseNamesCheck_OnClick(frame)
	Healme.UppercaseNames = frame:GetChecked() or false
	Healme_UpdateUnitNames()
end

local function UpdateEnableDebuffsControls(frame)
	local color 
	if frame:GetChecked() then
		color = NORMAL_FONT_COLOR
	else
		color = GRAY_FONT_COLOR
	end
	
	for _,j in ipairs(frame.children) do
		j:SetTextColor(color.r, color.g, color.b)
	end
end

local function EnableDebuffsCheck_OnClick(frame)
	UpdateEnableDebuffsControls(frame)
	Healme.EnableDebufs = frame:GetChecked() or false
	Healme_UpdateEnableDebuffs()
end

local function EnableDebuffAudioCheck_OnClick(frame)
	Healme.EnableDebufAudio = frame:GetChecked() or false
end

local function EnableDebuffHealthbarHighlightingCheck_OnClick(frame)
	Healme.EnableDebufHealthbarHighlighting = frame:GetChecked() or false
	Healme_UpdateEnableDebuffs()
end

local function EnableDebuffButtonHighlightingCheck_OnClick(frame)
	Healme.EnableDebufButtonHighlighting = frame:GetChecked() or false
	Healme_UpdateEnableDebuffs()
end

local function EnableDebuffHealthbarColoringCheck_OnClick(frame)
	Healme.EnableDebufHealthbarColoring = frame:GetChecked() or false
	Healme_UpdateEnableDebuffs()
end

local function ScaleSlider_OnValueChanged(frame)
	Healme.Scale = frame:GetValue()
	Healme_SetScale()
	frame.Text:SetText("Scale: |cFFFFFFFF".. format("%.1f",Healme.Scale))
end

local function RangeCheckSlider_OnValueChanged(frame)
	Healme.RangeCheckPeriod = 1.0 / frame:GetValue()
	UpdateRangeCheckSliderText(frame)
end

function Healme_ShowConfigPanel()
    if (InterfaceOptionsFrame:IsVisible()) then
      InterfaceOptionsFrame:Hide()
     else
	  -- called twice to overcome new bug after a patch, per suggestion at http://www.wowpedia.org/Patch_5.3.0/API_changes
	  InterfaceOptionsFrame_OpenToCategory(Healme_AddonName)
	  InterfaceOptionsFrame_OpenToCategory(Healme_AddonName)
    end
end


local function CreateCheck(checkName, scrollchild, parent, tip, text)
	local check = CreateFrame("CheckButton", checkName,  scrollchild, "OptionsCheckButtonTemplate")
	check:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 0, 0)
	check.tooltipText = tip
	check.Text = check:CreateFontString(nil, "BACKGROUND","GameFontNormal")
	check.Text:SetPoint("LEFT", check, "RIGHT", 0)
	check.Text:SetText(text)
	return check
end

-- Used to update the config panel controls when the profile changes
function Healme_Update_ConfigPanel()
	local Profile = Healme_GetProfile()
	
	HealmeMaxButtonSlider:SetValue(Healme_GetProfile().ButtonCount)
	
	if not IsClassic then 
		for i=1, Healme_MaxButtons, 1 do
			local name
			if Profile.SpellTypes[i] == Healme_Type_Macro then
				name =  "Macro: " .. Profile.SpellNames[i]
			elseif Profile.SpellTypes[i] == Healme_Type_Item then
				name = "Item: " .. Profile.SpellNames[i]
			else
				name = Profile.SpellNames[i]
				if name == nil then
					name = "No Spell"
				end
			end
		
			Lib_UIDropDownMenu_SetText(HealmeDropDown[i], name)
		end
	end
end

function Healme_CreateConfigPanel(Class, Version)
	local Profile = Healme_GetProfile()
	
	local panel = CreateFrame("Frame", nil, UIParent)
	panel.name = Healme_AddonName
	panel.okay = function (frame)frame.originalValue = MY_VARIABLE end    -- [[ When the player clicks okay, set the original value to the current setting ]] --
	panel.cancel = function (frame) MY_VARIABLE = frame.originalValue end    -- [[ When the player clicks cancel, set the current setting to the original value ]] --
	InterfaceOptions_AddCategory(panel)

	local scrollframe = CreateFrame("ScrollFrame", "HealmePanelScrollFrame", panel, "UIPanelScrollFrameTemplate")
	local framewidth = InterfaceOptionsFramePanelContainer:GetWidth()
	local frameheight = InterfaceOptionsFramePanelContainer:GetHeight() 
	scrollframe:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -25)
	scrollframe:SetWidth(framewidth-45)
	scrollframe:SetHeight(frameheight-45)
	scrollframe:Show()
	
    scrollframe.scrollbar = _G["HealmePanelScrollFrameScrollBar"]
	
	if (BackdropTemplateMixin) then 
		Mixin(scrollframe.scrollbar, BackdropTemplateMixin)
	end

    scrollframe.scrollbar:SetBackdrop({   
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",   
        edgeSize = 8,   
        tileSize = 32,   
        insets = { left = 0, right =0, top =5, bottom = 5 }})   
	
	
	local scrollchild = CreateFrame("Frame", "$parentScrollChild", scrollframe)
	scrollframe:SetScrollChild(scrollchild)	

	-- The Height and Width here are important.  The Width will control placement of the class icon since it attaches to TOPRIGHT of scrollchild.
	scrollchild:SetHeight(frameheight - 45)	
	scrollchild:SetWidth(framewidth - 45)
	scrollchild:Show()
	
	-- Title text
	local TitleText = scrollchild:CreateFontString(nil, "OVERLAY","GameFontNormalLarge")
	TitleText:SetJustifyH("LEFT")
	TitleText:SetPoint("TOPLEFT", 10, -10)
	TitleText:SetText(Healme_AddonColoredName .. Version)
	-- Title subtext
	local TitleSubText = scrollchild:CreateFontString(nil, "OVERLAY","GameFontNormalSmall")
	TitleSubText:SetJustifyH("LEFT")
	TitleSubText:SetPoint("TOPLEFT", 10, -30)
	TitleSubText:SetText("Welcome to the " .. Healme_AddonColoredName .. " options screen.|nUse the scrollbar to access more options.")
	TitleSubText:SetTextColor(1,1,1,1) 
  
	-- Create the Class Icon 
  	local HealmeClassIcon = CreateFrame("Frame", "HealmeClassIcon" ,scrollchild)
	HealmeClassIcon:SetPoint("TOPRIGHT",-20,0)
	HealmeClassIconTexture = HealmeClassIcon:CreateTexture(nil, "BACKGROUND")
	HealmeClassIconTexture:SetAllPoints()
	HealmeClassIconTexture:SetTexture("Interface/Glues/CHARACTERCREATE/UI-CHARACTERCREATE-CLASSES")
	local coords = CLASS_ICON_TCOORDS[Class];
	HealmeClassIconTexture:SetTexCoord(coords[1], coords[2], coords[3], coords[4]);
	HealmeClassIcon:SetHeight(60)
	HealmeClassIcon:SetWidth(60)
	HealmeClassIcon.Text = HealmeClassIcon:CreateFontString(nil, "OVERLAY","GameFontNormalLarge")
	HealmeClassIcon.Text:SetText(strupper(Class))
	HealmeClassIcon.Text:SetPoint("CENTER",0,-38)
	HealmeClassIcon.Text:SetTextColor(1,1,0.2,1)

 	
	-- ToolTips Check Button
    local TooltipsCheck = CreateFrame("CheckButton","$parentShowTooltipCheckButton",scrollchild,"OptionsCheckButtonTemplate")
	TooltipsCheck:SetPoint("TOPLEFT",5,-70)	
    
    TooltipsCheck.Text = TooltipsCheck:CreateFontString(nil, "BACKGROUND","GameFontNormal")
	TooltipsCheck.Text:SetPoint("LEFT", TooltipsCheck, "RIGHT", 0)
    TooltipsCheck.Text:SetText("Show Button ToolTips")
	
    TooltipsCheck:SetScript("OnClick", TooltipsCheck_OnClick)
	TooltipsCheck.tooltipText = "Shows spell tooltips when hovering the mouse over the " .. Healme_AddonColoredName .. " buttons."

	-- ShowMana Check Button
	local ShowManaCheck = CreateCheck("$parentShowManaCheckButton",scrollchild,TooltipsCheck, "Shows the unit's mana.", "Show Mana")
	ShowManaCheck:SetScript("OnClick", ShowManaCheck_OnClick)
	
	-- Percentage Check button
	local PercentageCheck = CreateCheck("$parentShowPercentageCheckButton",scrollchild,ShowManaCheck, "Shows the unit's health as a percentage on the right side of the health bar.", "Show Health Percentage")
	PercentageCheck:SetScript("OnClick", PercentageCheck_OnClick)
	
	-- ClassColor Check button
	local ClassColorCheck = CreateCheck("$parentClassColorCheckButton",scrollchild,PercentageCheck, 
	"Colors the healthbar based on the unit's class instead of green/yellow/red based on it's current health.", "Use Class Colors")
    ClassColorCheck:SetScript("OnClick", ClassColorCheck_OnClick)
	
	-- Hide Close Check button
	local HideCloseButtonCheck = CreateCheck("$parentHideCloseCheckButton",scrollchild,ClassColorCheck,
		"Hides the X (close) button on the upper-right of the " .. Healme_AddonColoredName ..	" caption bar.", "Hide Close Buttons")
	HideCloseButtonCheck:SetScript("OnClick", HideCloseButtonCheck_OnClick)	

	-- Hide Captions Check button
	local HideCaptionsCheck = CreateCheck("$parentHideCaptionsCheckButton",scrollchild,HideCloseButtonCheck,
		"Automatically hides the caption bar of " .. Healme_AddonColoredName .. " frames when the mouse leaves the caption.", "Hide Captions")
	HideCaptionsCheck:SetScript("OnClick", HideCaptionsCheck_OnClick)	
	
	-- Lock Frame Positions Check button
	local LockFramePositionsCheck = CreateCheck("$parentLockFramePositionsCheckButton",scrollchild,HideCaptionsCheck, "Prevents dragging of any " .. Healme_AddonColoredName .. " frames.", "Lock Frame Positions")
	LockFramePositionsCheck:SetScript("OnClick", LockFramePositionsCheck_OnClick)	
	
	-- Enable Clique check button
	local EnableCliqueCheck = CreateCheck("$parentEnableCliqueCheckButton",scrollchild,LockFramePositionsCheck,
		"Allows use of the Clique addon on the healthbar.  Clique will override the ability to LeftClick to target the unit unless you configure Clique to do that, which it can.", "Enable Clique Support")		
	EnableCliqueCheck:SetScript("OnClick", EnableCliqueCheck_OnClick)	
	
	local ShowThreatCheck
	local ShowRoleCheck
	local ShowIncomingHealsCheck
	
	if not IsClassic then
		-- Show Threat check button
		ShowThreatCheck = CreateCheck("$parentShowRoleCheckButton",scrollchild,EnableCliqueCheck,	"Shows a threat indicator that displays if the unit has threat on any mob.", "Show Threat")	
		ShowThreatCheck:SetScript("OnClick", ShowThreatCheck_OnClick)	

		-- Show Role check button
		ShowRoleCheck = CreateCheck("$parentShowRoleCheckButton",scrollchild,ShowThreatCheck,
			"Shows unit's role icon (healer, tank, damage) when in random dungeons.  Will override Health Percentage text when unit is assigned a role.", "Show Role Icons")
		ShowRoleCheck:SetScript("OnClick", ShowRoleCheck_OnClick)	

		-- Show Incoming Heals check button
		ShowIncomingHealsCheck = CreateCheck("$parentShowIncomingHealsCheckButton",scrollchild,ShowRoleCheck,
			"Shows incoming heals from all units as a dark green bar extending beyond the unit's current health.", "Show Incoming Heals")
		ShowIncomingHealsCheck:SetScript("OnClick", ShowIncomingHealsCheck_OnClick)	
	end
	
	-- Show Raid Icons check button
	local ShowRaidParent
	if IsClassic then 
		ShowRaidParent = EnableCliqueCheck
	else
		ShowRaidParent = ShowIncomingHealsCheck
	end
	
	local ShowRaidIconsCheck = CreateCheck("$parentShowRaidIconsCheckButton",scrollchild,ShowRaidParent, "Shows the raid icon assigned to this unit.", "Show Raid Icons")
	ShowRaidIconsCheck:SetScript("OnClick", ShowRaidIconsCheck_OnClick)	
	
	-- Uppercase names check button
	local UppercaseNamesCheck = CreateCheck("$parentShowUppercaseNamesCheckButton",scrollchild,ShowRaidIconsCheck, "Shows names in UPPERCASE text.", "UPPERCASE names")
	UppercaseNamesCheck:SetScript("OnClick", UppercaseNamesCheck_OnClick)
	local ClassicConfigButtonsText
	
	if not IsClassic then		
		-- Dropdown menus
		local ButtonConfigTitleText = scrollchild:CreateFontString(nil, "OVERLAY","GameFontNormalLarge")
		ButtonConfigTitleText:SetJustifyH("LEFT")
		ButtonConfigTitleText:SetPoint("TOPLEFT", UppercaseNamesCheck, "BOTTOMLEFT", 0, -20)
		ButtonConfigTitleText:SetText("Button Configuration")	
		
		local ButtonConfigTitleSubText = scrollchild:CreateFontString(nil, "OVERLAY","GameFontNormalSmall")
		ButtonConfigTitleSubText:SetJustifyH("LEFT")
		ButtonConfigTitleSubText:SetPoint("TOPLEFT", ButtonConfigTitleText, "BOTTOMLEFT", 0, 0)
		ButtonConfigTitleSubText:SetText("Click the dropdowns to configure each button.|nYou may now drag and drop directly from the spellbook|nonto buttons to configure them, including buffs!")
		ButtonConfigTitleSubText:SetTextColor(1,1,1,1) 	

		local y = -480
		local y_inc = 20
		
		for i=1, Healme_MaxButtons, 1 do
			HealmeDropDown[i] = CreateDropDownMenu("HealmeDropDown[" .. i .. "]",scrollchild,60,y)
			y = y - y_inc
			HealmeDropDown[i].Text:SetText("Button " .. i)
	--		HealmeDropDown[i].tooltipText = Healme_AddonColoredName .. " button"
		end
	else
		ClassicConfigButtonsText = scrollchild:CreateFontString(nil, "OVERLAY","GameFontNormalSmall")
		ClassicConfigButtonsText:SetJustifyH("LEFT")
		ClassicConfigButtonsText:SetPoint("TOPLEFT", UppercaseNamesCheck, "BOTTOMLEFT", 0, -30)
		ClassicConfigButtonsText:SetText("In Classic, to configure buttons, drag and drop directly from the spellbook onto buttons.")
		ClassicConfigButtonsText:SetTextColor(1,1,1,1) 	
	end

	-- Slider for controlling how many buttons to show
    HealmeMaxButtonSlider = CreateFrame("Slider","$parentMaxButtonSlider",scrollchild,"OptionsSliderTemplate")
    HealmeMaxButtonSlider:SetWidth(128)
    HealmeMaxButtonSlider:SetHeight(16)
          
    HealmeMaxButtonSlider:SetPoint("TOPLEFT", 220, -110)
      
    HealmeMaxButtonSlider:SetMinMaxValues(0,Healme_MaxButtons)
--	HealmeMaxButtonSlider:SetStepsPerPage(1)
    HealmeMaxButtonSlider:SetValueStep(1)
    HealmeMaxButtonSlider:SetValue(Healme_GetProfile().ButtonCount)
	HealmeMaxButtonSlider.tooltipText = "How many " .. Healme_AddonColoredName .. " buttons to show."
      
    HealmeMaxButtonSlider.Text = HealmeMaxButtonSlider:CreateFontString(nil, "BACKGROUND","GameFontNormalLarge")
    HealmeMaxButtonSlider.Text:SetPoint("CENTER", 0, 17)
    HealmeMaxButtonSlider.Text:SetText("Show |cFFFFFFFF"..HealmeMaxButtonSlider:GetValue().. "|r Buttons")
      
    _G[HealmeMaxButtonSlider:GetName().."Low"]:SetText("0")
    _G[HealmeMaxButtonSlider:GetName().."High"]:SetText(Healme_MaxButtons)
      
    HealmeMaxButtonSlider:SetScript("OnValueChanged",MaxButtonSlider_Update)
    HealmeMaxButtonSlider:Show()
  
    -- Slider for Scaling
    local ScaleSlider = CreateFrame("Slider","HealmeScaleSlider",scrollchild,"OptionsSliderTemplate")
    ScaleSlider:SetWidth(100)
    ScaleSlider:SetHeight(16)
    
    _G[ScaleSlider:GetName().."Low"]:SetText("Small")
    _G[ScaleSlider:GetName().."High"]:SetText("Large")
    
    ScaleSlider:SetMinMaxValues(0.6,1.5)
    ScaleSlider:SetValueStep(0.1)
    ScaleSlider:SetValue(Healme.Scale)
    
    ScaleSlider:SetPoint("TOPLEFT", HealmeMaxButtonSlider, "BOTTOMLEFT", 0, -30)
    
    ScaleSlider.Text = ScaleSlider:CreateFontString(nil, "BACKGROUND","GameFontNormalLarge")
    ScaleSlider.Text:SetPoint("CENTER", -5, 17)
    ScaleSlider.Text:SetText("Scale: |cFFFFFFFF".. format("%.1f",ScaleSlider:GetValue()))
 
    ScaleSlider:SetScript("OnValueChanged", ScaleSlider_OnValueChanged)
	ScaleSlider.tooltipText = "Sets the scale of all " .. Healme_AddonColoredName .. " frames."

	-- Show Frames Settings
	local ShowFramesTitleText = scrollchild:CreateFontString(nil, "OVERLAY","GameFontNormalLarge")
	ShowFramesTitleText:SetJustifyH("LEFT")
	local ShowFramesParent
	if IsClassic then 
		ShowFramesTitleText:SetPoint("TOPLEFT", ClassicConfigButtonsText, "BOTTOMLEFT", 0, -30)
	else
		ShowFramesTitleText:SetPoint("TOPLEFT", HealmeDropDown[Healme_MaxButtons].Text, "BOTTOMLEFT", 0, -30)
	end
	ShowFramesTitleText:SetText("Show Frames")	
	
	local ShowFramesTitleSubText = scrollchild:CreateFontString(nil, "OVERLAY","GameFontNormalSmall")
	ShowFramesTitleSubText:SetJustifyH("LEFT")
	ShowFramesTitleSubText:SetPoint("TOPLEFT", ShowFramesTitleText, "BOTTOMLEFT", 0, 0)
	ShowFramesTitleSubText:SetText("Check each frame to show.")
	ShowFramesTitleSubText:SetTextColor(1,1,1,1) 
	
	-- Show Party Check
    Healme_ShowPartyCheck = CreateFrame("CheckButton","$parentShowPartyCheckButton",scrollchild,"OptionsCheckButtonTemplate")
    Healme_ShowPartyCheck:SetPoint("TOPLEFT",ShowFramesTitleSubText, "BOTTOMLEFT", 0, -10)
	Healme_ShowPartyCheck.tooltipText = "Shows the Party " .. Healme_AddonColoredName .. " frame."
    Healme_ShowPartyCheck.Text = Healme_ShowPartyCheck:CreateFontString(nil, "BACKGROUND","GameFontNormal")
    Healme_ShowPartyCheck.Text:SetPoint("LEFT", Healme_ShowPartyCheck, "RIGHT", 0)
    Healme_ShowPartyCheck.Text:SetText("Party")
    
    Healme_ShowPartyCheck:SetScript("OnClick",function()
        Healme.ShowPartyFrame = Healme_ShowPartyCheck:GetChecked() or false
		Healme_ShowHidePartyFrame()
    end)

	-- Show Pets Check
	Healme_ShowPetsCheck = CreateCheck("$parentShowPetsCheckButton",scrollchild,Healme_ShowPartyCheck, "Shows the Pets " .. Healme_AddonColoredName .. " frame.", "Pets")
    
    Healme_ShowPetsCheck:SetScript("OnClick",function()
        Healme.ShowPetsFrame = Healme_ShowPetsCheck:GetChecked() or false
		Healme_ShowHidePetsFrame()
    end)

	-- Show Me Check
	Healme_ShowMeCheck = CreateCheck("$parentShowMeCheckButton",scrollchild,Healme_ShowPetsCheck, "Shows the Me " .. Healme_AddonColoredName .. " frame.", "Me")
    
    Healme_ShowMeCheck:SetScript("OnClick",function()
        Healme.ShowMeFrame = Healme_ShowMeCheck:GetChecked() or false
		Healme_ShowHideMeFrame()
    end)
	
	-- Show Friends Check
	Healme_ShowFriendsCheck = CreateCheck("$parentShowFriendsCheckButton",scrollchild,Healme_ShowMeCheck, "Shows the Friends " .. Healme_AddonColoredName .. " frame.", "Friends")
    
    Healme_ShowFriendsCheck:SetScript("OnClick",function()
        Healme.ShowFriendsFrame = Healme_ShowFriendsCheck:GetChecked() or false
		Healme_ShowHideFriendsFrame()
    end)	
	
	-- Show Target Check
	Healme_ShowTargetCheck = CreateCheck("$parentShowTargetCheckButton",scrollchild,Healme_ShowFriendsCheck, "Shows the Target " .. Healme_AddonColoredName .. " frame.", "Target")
    
    Healme_ShowTargetCheck:SetScript("OnClick",function()
        Healme.ShowTargetFrame = Healme_ShowTargetCheck:GetChecked() or false
		Healme_ShowHideTargetFrame()
    end)		
	
	-- Show Focus Check
	if not IsClassic then 
		Healme_ShowFocusCheck = CreateCheck("$parentShowFocusCheckButton",scrollchild,Healme_ShowTargetCheck, "Shows the Focus " .. Healme_AddonColoredName .. " frame.", "Focus")
		
		Healme_ShowFocusCheck:SetScript("OnClick",function()
			Healme.ShowFocusFrame = Healme_ShowFocusCheck:GetChecked() or false
			Healme_ShowHideFocusFrame()
		end)		
	end
	
	-- Show Group 1 Check
	local Group1Parent
	if IsClassic then 
		Group1Parent = Healme_ShowTargetCheck
	else
		Group1Parent = Healme_ShowFocusCheck
	end
	
	Healme_ShowGroup1Check = CreateCheck("$parentShowGroup1CheckButton",scrollchild,Group1Parent, "Shows the Group 1 " .. Healme_AddonColoredName .. " frame.", "Group 1")
    
    Healme_ShowGroup1Check:SetScript("OnClick",function()
        Healme.ShowGroupFrames[1] = Healme_ShowGroup1Check:GetChecked() or false
		Healme_ShowHideGroupFrame(1)
    end)	
	
	-- Show Group 2 Check
	Healme_ShowGroup2Check = CreateCheck("$parentShowGroup2CheckButton",scrollchild,Healme_ShowGroup1Check, "Shows the Group 2 " .. Healme_AddonColoredName .. " frame.", "Group 2")
    
    Healme_ShowGroup2Check:SetScript("OnClick",function()
        Healme.ShowGroupFrames[2] = Healme_ShowGroup2Check:GetChecked() or false
		Healme_ShowHideGroupFrame(2)
    end)		
	
	-- Show Group 3 Check
	Healme_ShowGroup3Check = CreateCheck("$parentShowGroup3CheckButton",scrollchild,Healme_ShowGroup2Check, "Shows the Group 3 " .. Healme_AddonColoredName .. " frame.", "Group 3")
    
    Healme_ShowGroup3Check:SetScript("OnClick",function()
        Healme.ShowGroupFrames[3] = Healme_ShowGroup3Check:GetChecked() or false
		Healme_ShowHideGroupFrame(3)
    end)		

	-- Show Group 4 Check
	Healme_ShowGroup4Check = CreateCheck("$parentShowGroup4CheckButton",scrollchild,Healme_ShowGroup3Check, "Shows the Group 4 " .. Healme_AddonColoredName .. " frame.", "Group 4")
    
    Healme_ShowGroup4Check:SetScript("OnClick",function()
        Healme.ShowGroupFrames[4]= Healme_ShowGroup4Check:GetChecked() or false
		Healme_ShowHideGroupFrame(4)
    end)			
	
	-- Show Group 5 Check
    Healme_ShowGroup5Check = CreateCheck("$parentShowGroup5CheckButton",scrollchild,Healme_ShowGroup4Check, "Shows the Group 5 " .. Healme_AddonColoredName .. " frame.", "Group 5")
    
    Healme_ShowGroup5Check:SetScript("OnClick",function()
        Healme.ShowGroupFrames[5] = Healme_ShowGroup5Check:GetChecked() or false
		Healme_ShowHideGroupFrame(5)
    end)		

	-- Show Group 6 Check
    Healme_ShowGroup6Check = CreateCheck("$parentShowGroup6CheckButton",scrollchild,Healme_ShowGroup5Check, "Shows the Group 6 " .. Healme_AddonColoredName .. " frame.", "Group 6")
    
    Healme_ShowGroup6Check:SetScript("OnClick",function()
        Healme.ShowGroupFrames[6] = Healme_ShowGroup6Check:GetChecked() or false
		Healme_ShowHideGroupFrame(6)
    end)	
	
	-- Show Group 7 Check
    Healme_ShowGroup7Check = CreateCheck("$parentShowGroup7CheckButton",scrollchild,Healme_ShowGroup6Check, "Shows the Group 7 " .. Healme_AddonColoredName .. " frame.", "Group 7")
    
    Healme_ShowGroup7Check:SetScript("OnClick",function()
        Healme.ShowGroupFrames[7] = Healme_ShowGroup7Check:GetChecked() or false
		Healme_ShowHideGroupFrame(7)
    end)	
	
	-- Show Group 8 Check
    Healme_ShowGroup8Check = CreateCheck("$parentShowGroup8CheckButton",scrollchild,Healme_ShowGroup7Check, "Shows the Group 8 " .. Healme_AddonColoredName .. " frame.", "Group 8")
    
    Healme_ShowGroup8Check:SetScript("OnClick",function()
        Healme.ShowGroupFrames[8] = Healme_ShowGroup8Check:GetChecked() or false
		Healme_ShowHideGroupFrame(8)
    end)		
-- TODO DAMAGERS/HEALERS frame

	-- Show Damagers Check
    Healme_ShowDamagersCheck = CreateCheck("$parentShowDamagersCheckButton",scrollchild,Healme_ShowGroup8Check, "Shows the Damagers " .. Healme_AddonColoredName .. " frame.", "Damagers")
	
    Healme_ShowDamagersCheck:SetScript("OnClick",function()
        Healme.ShowDamagersFrame = Healme_ShowDamagersCheck:GetChecked() or false
		Healme_ShowHideDamagersFrame()
    end)			

	-- Show Healers Check
    Healme_ShowHealersCheck = CreateCheck("$parentShowHealersCheckButton",scrollchild,Healme_ShowDamagersCheck, "Shows the Healers " .. Healme_AddonColoredName .. " frame.", "Healers")
	
    Healme_ShowHealersCheck:SetScript("OnClick",function()
        Healme.ShowHealersFrame = Healme_ShowHealersCheck:GetChecked() or false
		Healme_ShowHideHealersFrame()
    end)				

	-- Show Tanks Check
    Healme_ShowTanksCheck = CreateCheck("$parentShowTanksCheckButton",scrollchild,Healme_ShowHealersCheck, "Shows the Tanks " .. Healme_AddonColoredName .. " frame.", "Tanks")
    
    Healme_ShowTanksCheck:SetScript("OnClick",function()
        Healme.ShowTanksFrame = Healme_ShowTanksCheck:GetChecked() or false
		Healme_ShowHideTanksFrame()
    end)			

	
	-- Debuff Warnings
	local DebuffWarningsTitleText = scrollchild:CreateFontString(nil, "OVERLAY","GameFontNormalLarge")
	DebuffWarningsTitleText:SetJustifyH("LEFT")
	DebuffWarningsTitleText:SetPoint("TOPLEFT", Healme_ShowTanksCheck, "BOTTOMLEFT", 0, -30)
	DebuffWarningsTitleText:SetText("Debuff Warnings")
	
	local DebuffWarningsSubText = scrollchild:CreateFontString(nil, "OVERLAY","GameFontNormalSmall")
	DebuffWarningsSubText:SetJustifyH("LEFT")
	DebuffWarningsSubText:SetPoint("TOPLEFT", DebuffWarningsTitleText, "BOTTOMLEFT", 0, 0)
	DebuffWarningsSubText:SetText("Debuff warnings are audible and visual indicators that|nnotify you when you can cure a debuff on a player.")
	DebuffWarningsSubText:SetTextColor(1,1,1,1) 

	
	-- Enable Debuffs check button
    local EnableDebuffsCheck = CreateFrame("CheckButton","$parentEnableDebuffsCheckButton",scrollchild,"OptionsCheckButtonTemplate")
	EnableDebuffsCheck.children = { }
    EnableDebuffsCheck:SetPoint("TOPLEFT", DebuffWarningsSubText, "BOTTOMLEFT", 0, -10)
    
    EnableDebuffsCheck.Text = EnableDebuffsCheck:CreateFontString(nil, "BACKGROUND","GameFontNormal")
	EnableDebuffsCheck.Text:SetPoint("LEFT", EnableDebuffsCheck, "RIGHT", 0)
    EnableDebuffsCheck.Text:SetText("Enable Debuff Warnings")

	EnableDebuffsCheck:SetScript("OnClick", EnableDebuffsCheck_OnClick)	
	EnableDebuffsCheck.tooltipText = "Enables debuff warnings"

	-- Enable Debuff Healthbar coloring check button 
	local EnableDebufHealthbarColoringCheck	= CreateFrame("CheckButton","$parentEnableDebuffHealthbarColoringCheckButton",scrollchild,"OptionsCheckButtonTemplate")
    EnableDebufHealthbarColoringCheck:SetPoint("TOPLEFT", EnableDebuffsCheck, "BOTTOMLEFT", 20, 0)
    
    EnableDebufHealthbarColoringCheck.Text = EnableDebufHealthbarColoringCheck:CreateFontString(nil, "BACKGROUND","GameFontNormal")
	EnableDebufHealthbarColoringCheck.Text:SetPoint("LEFT", EnableDebufHealthbarColoringCheck, "RIGHT", 0)
    EnableDebufHealthbarColoringCheck.Text:SetText("Healthbar Coloring")
	table.insert(EnableDebuffsCheck.children, EnableDebufHealthbarColoringCheck.Text)
	
	EnableDebufHealthbarColoringCheck:SetScript("OnClick", EnableDebuffHealthbarColoringCheck_OnClick)	
	EnableDebufHealthbarColoringCheck.tooltipText = "Enables coloring of the healthbar of a player that has a debuff which you can cure"
	
	
	-- Enable Debuff Healthbar highlighting check button
    local EnableDebuffHealthbarHighlightingCheck = CreateFrame("CheckButton","$parentEnableDebuffHealthbarHighlightingCheck",scrollchild,"OptionsCheckButtonTemplate")
    EnableDebuffHealthbarHighlightingCheck:SetPoint("TOPLEFT", EnableDebufHealthbarColoringCheck, "BOTTOMLEFT", 0, 0)
    
    EnableDebuffHealthbarHighlightingCheck.Text = EnableDebuffHealthbarHighlightingCheck:CreateFontString(nil, "BACKGROUND","GameFontNormal")
	EnableDebuffHealthbarHighlightingCheck.Text:SetPoint("LEFT", EnableDebuffHealthbarHighlightingCheck, "RIGHT", 0)
    EnableDebuffHealthbarHighlightingCheck.Text:SetText("Healthbar Highlight Warning")
	table.insert(EnableDebuffsCheck.children, EnableDebuffHealthbarHighlightingCheck.Text)
	
	EnableDebuffHealthbarHighlightingCheck:SetScript("OnClick", EnableDebuffHealthbarHighlightingCheck_OnClick)	
	EnableDebuffHealthbarHighlightingCheck.tooltipText = "Enables highlighting of the healthbar of a player that has a debuff which you can cure"


	-- Enable Debuff Button highlighting check button
    local EnableDebuffButtonHighlightingCheck = CreateFrame("CheckButton","$parentEnableDebuffButtonHighlightingCheck",scrollchild,"OptionsCheckButtonTemplate")
    EnableDebuffButtonHighlightingCheck:SetPoint("TOPLEFT", EnableDebuffHealthbarHighlightingCheck, "BOTTOMLEFT", 0, 0)
    
    EnableDebuffButtonHighlightingCheck.Text = EnableDebuffButtonHighlightingCheck:CreateFontString(nil, "BACKGROUND","GameFontNormal")
	EnableDebuffButtonHighlightingCheck.Text:SetPoint("LEFT", EnableDebuffButtonHighlightingCheck, "RIGHT", 0)
    EnableDebuffButtonHighlightingCheck.Text:SetText("Button Highlight Warning")
	table.insert(EnableDebuffsCheck.children, EnableDebuffButtonHighlightingCheck.Text)
	
	EnableDebuffButtonHighlightingCheck:SetScript("OnClick", EnableDebuffButtonHighlightingCheck_OnClick)	
	EnableDebuffButtonHighlightingCheck.tooltipText = "Enables highlighting of buttons which have been assigned a spell that can cure a debuff on a player"

	-- Enable Debuff Audio check button
    local EnableDebuffAudioCheck = CreateFrame("CheckButton","$parentEnableDebuffAudioCheckButton",scrollchild,"OptionsCheckButtonTemplate")
    EnableDebuffAudioCheck:SetPoint("TOPLEFT", EnableDebuffButtonHighlightingCheck, "BOTTOMLEFT", 0, 0)
    
    EnableDebuffAudioCheck.Text = EnableDebuffAudioCheck:CreateFontString(nil, "BACKGROUND","GameFontNormal")
	EnableDebuffAudioCheck.Text:SetPoint("LEFT", EnableDebuffAudioCheck, "RIGHT", 0)
    EnableDebuffAudioCheck.Text:SetText("Audio Warning")
	table.insert(EnableDebuffsCheck.children, EnableDebuffAudioCheck.Text)
	
	EnableDebuffAudioCheck:SetScript("OnClick", EnableDebuffAudioCheck_OnClick)	
	EnableDebuffAudioCheck.tooltipText = "Enables an audio warning when a player has a debuff which you can cure, and is within 40yds"
	
	-- Sound drop down
	local SoundDropDown = CreateFrame("Frame", "$parentSoundDropDown", scrollchild, "Lib_UIDropDownMenuTemplate") 
	SoundDropDown:SetPoint("TOPLEFT", EnableDebuffAudioCheck, "BOTTOMLEFT",65, 0)
	SoundDropDown.Text = SoundDropDown:CreateFontString(nil, "OVERLAY","GameFontNormal")
	SoundDropDown.Text:SetText("Audio File")
	SoundDropDown.Text:SetPoint("TOPLEFT",SoundDropDown,"TOPLEFT",-60,-5)
	Lib_UIDropDownMenu_Initialize(SoundDropDown, SoundDropDownMenu_Init)
	table.insert(EnableDebuffsCheck.children, SoundDropDown.Text)	
	
	-- Play sound button
	local PlayButton = CreateFrame("Button", "$parentPlaySoundButton", scrollchild, "UIPanelButtonTemplate")
	PlayButton:SetText("Play")
	PlayButton:SetWidth(54)
	PlayButton:SetHeight(22)
	PlayButton:SetPoint("LEFT", SoundDropDown, "RIGHT", 120, 0)
	PlayButton:SetScript("OnClick", Healme_PlayDebuffSound)
	
	-- CPU Intensive Settings text
	local UpdatingTitleText = scrollchild:CreateFontString(nil, "OVERLAY","GameFontNormalLarge")
	UpdatingTitleText:SetJustifyH("LEFT")
	UpdatingTitleText:SetPoint("TOPLEFT", EnableDebuffAudioCheck, "BOTTOMLEFT", -20, -60)
	UpdatingTitleText:SetText("CPU Intensive Settings")

	local UpdatingTitleSubText = scrollchild:CreateFontString(nil, "OVERLAY","GameFontNormalSmall")
	UpdatingTitleSubText:SetJustifyH("LEFT")
	UpdatingTitleSubText:SetPoint("TOPLEFT", UpdatingTitleText, "BOTTOMLEFT", 0, 0)
	UpdatingTitleSubText:SetText("Enabling these settings may cause extra lag.")
	UpdatingTitleSubText:SetTextColor(1,1,1,1) 
	
    -- EnableColldowns Check Button
    local EnableCooldownsCheck = CreateFrame("CheckButton","$parentEnableCooldownsCheckButton",scrollchild,"OptionsCheckButtonTemplate")
    EnableCooldownsCheck:SetPoint("TOPLEFT", UpdatingTitleSubText, "BOTTOMLEFT", 0, -10)
    EnableCooldownsCheck.tooltipText = "Enables cooldown animations on the " .. Healme_AddonColoredName .. " buttons."
	
    EnableCooldownsCheck.Text = EnableCooldownsCheck:CreateFontString(nil, "BACKGROUND","GameFontNormal")
    EnableCooldownsCheck.Text:SetPoint("LEFT", EnableCooldownsCheck, "RIGHT", 0)
    EnableCooldownsCheck.Text:SetText("Enable Cooldowns")
    EnableCooldownsCheck:SetScript("OnClick", EnableCooldownsCheck_OnClick)
	

	-- RangeCheck Check Button
    local RangeCheckCheck = CreateFrame("CheckButton","$parentRangeCheckButton",scrollchild,"OptionsCheckButtonTemplate")
    RangeCheckCheck:SetPoint("TOPLEFT",EnableCooldownsCheck, "BOTTOMLEFT", 0, 0)
    RangeCheckCheck.tooltipText = "Enables range checks on the " .. Healme_AddonColoredName .. " buttons."
	
    RangeCheckCheck.Text = RangeCheckCheck:CreateFontString(nil, "BACKGROUND","GameFontNormal")
    RangeCheckCheck.Text:SetPoint("LEFT", RangeCheckCheck, "RIGHT", 0)
    RangeCheckCheck.Text:SetText("Enable Range Checks")
    RangeCheckCheck:SetScript("OnClick",RangeCheckCheck_OnClick)
	
	-- RangeCheck Slider
	local RangeCheckSlider = CreateFrame("Slider","$parentRangeCheckSlider",scrollchild,"OptionsSliderTemplate")
    RangeCheckSlider:SetWidth(180)
    RangeCheckSlider:SetHeight(16)
    
    _G[RangeCheckSlider:GetName().."Low"]:SetText("Slower\n(Less CPU)")
    _G[RangeCheckSlider:GetName().."High"]:SetText("Faster\n(More CPU)")
    
    RangeCheckSlider:SetMinMaxValues(.5,5.0)
    RangeCheckSlider:SetValueStep(0.1)
    RangeCheckSlider:SetValue(1.0/Healme.RangeCheckPeriod)
    
    RangeCheckSlider:SetPoint("TOPLEFT", RangeCheckCheck.Text, "TOPRIGHT", 15, 0)
    RangeCheckSlider.tooltipText = "Controls how often to do range checks.  The further to the right, the more often range checks are performed and the more CPU it will use."
	
    RangeCheckSlider.Text = RangeCheckSlider:CreateFontString(nil, "BACKGROUND","GameFontNormalSmall")
    RangeCheckSlider.Text:SetPoint("CENTER", -5, 17)
    UpdateRangeCheckSliderText(RangeCheckSlider)
    
    RangeCheckSlider:SetScript("OnValueChanged", RangeCheckSlider_OnValueChanged)
	
	-- ShowBuffs check
	local ShowBuffsCheck = CreateFrame("CheckButton","$parentShowBuffsCheckButton",scrollchild,"OptionsCheckButtonTemplate")
    ShowBuffsCheck:SetPoint("TOPLEFT",RangeCheckCheck, "BOTTOMLEFT", 0, 0)
    ShowBuffsCheck.tooltipText = "Shows the buffs and HOTs you have personally cast on the player to the left of the healthbar.  It will only show spells that are configured in " .. Healme_AddonColoredName .. "."
	
    ShowBuffsCheck.Text = ShowBuffsCheck:CreateFontString(nil, "BACKGROUND","GameFontNormal")
    ShowBuffsCheck.Text:SetPoint("LEFT", ShowBuffsCheck, "RIGHT", 0)
    ShowBuffsCheck.Text:SetText("Show Buffs")
	ShowBuffsCheck:SetScript("OnClick", ShowBuffsCheck_OnClick);

    -- About Frame
    local AboutTitle = CreateFrame("Frame","",scrollchild)
--    AboutTitle:SetFrameStrata("TOOLTIP")
    AboutTitle:SetWidth(160)
    AboutTitle:SetHeight(20)
    
    AboutTitle.Text = AboutTitle:CreateFontString(nil, "BACKGROUND","GameFontNormalLarge")
    AboutTitle.Text:SetPoint("TOPLEFT",ShowBuffsCheck, "BOTTOMLEFT", 0, -30)
    AboutTitle.Text:SetText("About " .. Healme_AddonColoredName)
    
    local AboutFrame = CreateFrame("Frame","AboutHealme",scrollchild,BackdropTemplateMixin and "BackdropTemplate")
    AboutFrame:SetWidth(340)
    AboutFrame:SetHeight(80)
    AboutFrame:SetPoint("TOPLEFT", AboutTitle.Text, "BOTTOMLEFT", 0, 0)

    AboutFrame:SetBackdrop({bgFile = "",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }})

    AboutFrame.Text = AboutFrame:CreateFontString(nil, "BACKGROUND","GameFontNormal")
    AboutFrame.Text:SetWidth(330)
    AboutFrame.Text:SetJustifyH("LEFT")
    AboutFrame.Text:SetPoint("TOPLEFT", 7,-10)
    AboutFrame.Text:SetText(Healme_AddonColoredName .. Version .. " |cFFFFFFFFCreated by Bearesquishy of Dalaran.|n|n|cFFFFFFFFOriginally based on Healium, which was created by Dourd of Argent Dawn EU.")

	-- Init Config Panel controls
	if not IsClassic then 
		for i=1, Healme_MaxButtons, 1 do
			Lib_UIDropDownMenu_Initialize(HealmeDropDown[i], DropDownMenu_Init)
		end
	end
	
	Healme_Update_ConfigPanel()
	
	TooltipsCheck:SetChecked(Healme.ShowToolTips)
	ShowManaCheck:SetChecked(Healme.ShowMana)
	PercentageCheck:SetChecked(Healme.ShowPercentage)
	ClassColorCheck:SetChecked(Healme.UseClassColors)
	ShowBuffsCheck:SetChecked(Healme.ShowBuffs)
	RangeCheckCheck:SetChecked(Healme.DoRangeChecks)
	EnableCooldownsCheck:SetChecked(Healme.EnableCooldowns)
	HideCloseButtonCheck:SetChecked(Healme.HideCloseButton)
	HideCaptionsCheck:SetChecked(Healme.HideCaptions)
	LockFramePositionsCheck:SetChecked(Healme.LockFrames)
	EnableDebuffsCheck:SetChecked(Healme.EnableDebufs)
	EnableCliqueCheck:SetChecked(Healme.EnableClique)
			
			
	if not IsClassic then 
		ShowThreatCheck:SetChecked(Healme.ShowThreat)
		ShowRoleCheck:SetChecked(Healme.ShowRole)
		ShowIncomingHealsCheck:SetChecked(Healme.ShowIncomingHeals)
		Healme_ShowFocusCheck:SetChecked(Healme.ShowFocusFrame)
	end
	
	ShowRaidIconsCheck:SetChecked(Healme.ShowRaidIcons)
	UppercaseNamesCheck:SetChecked(Healme.UppercaseNames)
	EnableDebuffAudioCheck:SetChecked(Healme.EnableDebufAudio)
	EnableDebuffHealthbarHighlightingCheck:SetChecked(Healme.EnableDebufHealthbarHighlighting)
	EnableDebuffButtonHighlightingCheck:SetChecked(Healme.EnableDebufButtonHighlighting)
	EnableDebufHealthbarColoringCheck:SetChecked(Healme.EnableDebufHealthbarColoring)
	
	Lib_UIDropDownMenu_SetText(SoundDropDown, Healme.DebufAudioFile)
	
	Healme_ShowPartyCheck:SetChecked(Healme.ShowPartyFrame)
	Healme_ShowPetsCheck:SetChecked(Healme.ShowPetsFrame)
	Healme_ShowMeCheck:SetChecked(Healme.ShowMeFrame)
	Healme_ShowFriendsCheck:SetChecked(Healme.ShowFriendsFrame)

-- TODO DAMAGERS/HEALERS frame	
	Healme_ShowDamagersCheck:SetChecked(Healme.ShowDamagersFrame)
	Healme_ShowHealersCheck:SetChecked(Healme.ShowHealersFrame)
	Healme_ShowTanksCheck:SetChecked(Healme.ShowTanksFrame)
	Healme_ShowTargetCheck:SetChecked(Healme.ShowTargetFrame)
	Healme_ShowGroup1Check:SetChecked(Healme.ShowGroupFrames[1])
	Healme_ShowGroup2Check:SetChecked(Healme.ShowGroupFrames[2])
	Healme_ShowGroup3Check:SetChecked(Healme.ShowGroupFrames[3])
	Healme_ShowGroup4Check:SetChecked(Healme.ShowGroupFrames[4])
	Healme_ShowGroup5Check:SetChecked(Healme.ShowGroupFrames[5])
	Healme_ShowGroup6Check:SetChecked(Healme.ShowGroupFrames[6])
	Healme_ShowGroup7Check:SetChecked(Healme.ShowGroupFrames[7])
	Healme_ShowGroup8Check:SetChecked(Healme.ShowGroupFrames[8])
	
	ScaleSlider:SetValue(Healme.Scale)
	RangeCheckSlider:SetValue(1.0/Healme.RangeCheckPeriod)
	
	UpdateEnableDebuffsControls(EnableDebuffsCheck)

end
