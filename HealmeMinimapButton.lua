local MiniMapTexture = "Interface\\AddOns\\Healme\\images\\heartx64.tga"  -- Heart
local _, Healme = ...

function Healme_CreateMiniMapButton()

  Healme = LibStub("AceAddon-3.0"):NewAddon(Healme, "Healme", "AceConsole-3.0", "AceEvent-3.0")
  LibRealmInfo = LibStub("LibRealmInfo")

  -- Set up DataBroker for minimap button
  SimcLDB = LibStub("LibDataBroker-1.1"):NewDataObject("Healme", {
    type = "data source",
    text = "Healme",
    label = "Healme",
    icon = "Interface\\AddOns\\Healme\\images\\heartx64.tga",
    OnClick = function()
      if SimcFrame and SimcFrame:IsShown() then
        SimcFrame:Hide()
      else
        Healme:PrintSimcProfile(false, false)
      end
    end,
    OnTooltipShow = function(tt)
      tt:AddLine("Healme")
      tt:AddLine(" ")
      tt:AddLine("Click to show Healme input")
      tt:AddLine("To toggle minimap button, type '/healme minimap'")
    end
  })

  LibDBIcon = LibStub("LibDBIcon-1.0")
end
