local MiniMapTexture = "Interface\\AddOns\\Healme\\images\\heartx64.tga"  -- Heart

-- Register icon api
local HealmeMiniMapicon = LibStub("LibDBIcon-1.0")
-- HealmeMiniMapicon:Register("HealmeMinimap", HealmeMiniMap, Minimap)


function Healme_CreateMiniMapButton()
  local button = CreateFrame("Button", "HealmeMiniMap", Minimap)
  --button:SetFrameStrata("MEDIUM") -- needed or else appears underneath

  button.icon = button:CreateTexture("icon","BACKGROUND")
  button.overlay = button:CreateTexture("icon","OVERLAY")
  button.icon:SetAllPoints()
  button.overlay:SetAllPoints()

  local highlight = button:CreateTexture(nil, "HIGHLIGHT")
  highlight:SetBlendMode("ADD")
  highlight:SetPoint("CENTER", button, "CENTER")
  highlight:SetWidth(32)
  highlight:SetHeight(32)

  button:SetPushedTexture("Interface/Buttons/UI-Quickslot-Depress")

  highlight:SetTexture("Interface/Minimap/UI-Minimap-ZoomButton-Highlight")

  local tex = button:CreateTexture("MinimapButtonOverlay", "OVERLAY")
  tex:SetTexture("Interface/Minimap/MiniMap-TrackingBorder")
  tex:SetPoint("CENTER", button, "CENTER", 11, -11)
  tex:SetWidth(54)
  tex:SetHeight(54)

  button.icon:SetTexture(MiniMapTexture)

  button:EnableMouse(1)
  button:RegisterForDrag("RightButton")
  button:RegisterForClicks("LeftButtonUp")
  button:SetHeight(18)
  button:SetWidth(18)

  button:SetPoint("TOPLEFT","Minimap","TOPLEFT",62-(80*cos(5)),(80*sin(5))-62)

  button:SetScript("OnEnter", function(frame)
    GameTooltip:SetOwner(frame, "ANCHOR_LEFT")
    GameTooltip:SetText(Healme_AddonColor .. Healme_AddonName .. "|r |n|cFF55FF55Left Mouse |cFFFFFFFF" .. Healme_AddonName .. " Menu|n|cFF55FF55Right Mouse |cFFFFFFFFMove Button|n|cFF55FF55Shift & Left Mouse |cFFFFFFFF Toggle Frames")
    GameTooltip:Show()
  end)

   button:SetScript("OnLeave", function(frame)
    GameTooltip:Hide()
  end)

  -- [ Lua Only Approach For Making Dragable Frames (With Right Mouse Only) ]
  button:SetMovable(true)
  button:EnableMouse(true)
  local OnMouseDown = function(frame) if(IsMouseButtonDown("RightButton")) then frame:StartMoving() end end
  button:SetScript("OnMouseDown", OnMouseDown)
  button:SetScript("OnMouseUp",function(frame) frame:StopMovingOrSizing() end)

  button:SetScript("OnClick",function(frame)  -------------------------

  if not (IsShiftKeyDown()) then
	Lib_ToggleDropDownMenu(1, nil, HealmeMenu, frame, 0, 0)
  end

  if (IsShiftKeyDown()) then
	Healme_ToggleAllFrames()
  end

  end) ------------------------------------------------------------------

  Healme_MMButton = button

end
