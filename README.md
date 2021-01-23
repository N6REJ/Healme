# Healme
Wow shadowlands healer addon


Dev note:

19-21 
```
local _, HealmeClass = UnitClass("player")
local _, HealmeRace = UnitRace("player")
local _, HealmeSpec = GetSpecialization()
```
189 "OnLoad" event
207 	HealmeFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
975 "init variables"

1367-1372
```
	-- spec change event
	if (event == "PLAYER_SPECIALIZATION_CHANGED") then
	-- OK ITS CHANGED, NOW WHAT?
		-- message("spec changed")
		return
	end
  ```
  
  These may change but seems to be the important places.
