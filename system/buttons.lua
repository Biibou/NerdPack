local _, NeP = ...

-- Locals
local GetActionInfo = _G.GetActionInfo
local ActionButton_CalculateAction = _G.ActionButton_CalculateAction
local GetSpellInfo = _G.GetSpellInfo
local wipe = _G.wipe

NeP.Buttons = {}

local nBars = {
	"ActionButton",
	"MultiBarBottomRightButton",
	"MultiBarBottomLeftButton",
	"MultiBarRightButton",
	"MultiBarLeftButton"
}

local function UpdateButtons()
	wipe(NeP.Buttons)
	for _, group in ipairs(nBars) do
		for i =1, 12 do
			local button = _G[group .. i]
			if button then
				local actionType, id = GetActionInfo(ActionButton_CalculateAction(button, "LeftButton"))
				if actionType == 'spell' then
					local spell = GetSpellInfo(id)
					if spell then
						NeP.Buttons[spell] = button
					end
				end
			end
		end
	end
end

NeP.Listener:Add('NeP_Buttons','PLAYER_ENTERING_WORLD', function ()
	UpdateButtons()
end)

NeP.Listener:Add('NeP_Buttons','ACTIONBAR_SLOT_CHANGED', function ()
	UpdateButtons()
end)
