local MiniMapTexture = "Interface\\AddOns\\Healme\\images\\heartx64.tga"  -- Heart
local _, Healme = ...

function Healme_CreateMiniMapButton()

  Healme = LibStub("AceAddon-3.0"):NewAddon(Healme, "Healme", "AceConsole-3.0", "AceEvent-3.0")
  LibRealmInfo = LibStub("LibRealmInfo")

  -- Set up DataBroker for minimap button
 HealmeLDB = LibStub("LibDataBroker-1.1"):NewDataObject("Healme", {
    type = "data source",
    text = "Healme",
    label = "Healme",
    icon = "Interface\\AddOns\\Healme\\images\\heartx64.tga",
    OnClick = function()
      if HealmeFrame and HealmeFrame:IsShown() then
       HealmeFrame:Hide()
      else
        Healme:PrintHealmeProfile(false, false)
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
  Healme_button = LibDBIcon
  LibDBIcon:Register("Healme", HealmeLDB, self.db.profile.minimap)
  LibDBIcon:Show("Healme")
end
