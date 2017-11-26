local _, gbl = ...
local _G = _G
gbl.Tooltip = {}
local frame = CreateFrame("GameTooltip", "gbl_ScanningTooltip", UIParent, "GameTooltipTemplate")

local function pPattern(text, pattern)
	local pattern_tp = type(pattern)
	if pattern_tp == "string" then
		local match = text:lower():match(pattern)
		if match then return true end
	elseif pattern_tp == "table" then
		for i=1, #pattern do
			local match = text:lower():match(pattern[i])
			if match then return true end
		end
	end
end

function gbl.Tooltip.Scan_Buff(_, target, pattern)
	for i = 1, 40 do
		frame:SetOwner(UIParent, "ANCHOR_NONE")
		frame:SetUnitBuff(target, i)
		local tooltipText = _G["gbl_ScanningTooltipTextLeft2"]:GetText()
		if tooltipText and pPattern(tooltipText, pattern) then return true end
	end
	return false
end

function gbl.Tooltip.Scan_Debuff(_, target, pattern)
	for i = 1, 40 do
		frame:SetOwner(UIParent, "ANCHOR_NONE")
		frame:SetUnitDebuff(target, i)
		local tooltipText = _G["gbl_ScanningTooltipTextLeft2"]:GetText()
		if tooltipText and pPattern(tooltipText, pattern) then return true end
	end
	return false
end

function gbl.Tooltip.Unit(_, target, pattern)
	frame:SetOwner(UIParent, "ANCHOR_NONE")
	frame:SetUnit(target)
	local tooltipText = _G["gbl_ScanningTooltipTextLeft2"]:GetText()
	if pPattern(UnitName(target):lower(), pattern) then return true end
	return tooltipText and pPattern(tooltipText, pattern)
end

function gbl.Tooltip.Tick_Time(_, target)
	frame:SetOwner(UIParent, "ANCHOR_NONE")
	frame:SetUnitBuff(target)
	local tooltipText = _G["gbl_ScanningTooltipTextLeft2"]:GetText()
	local match = tooltipText:lower():match("[0-9]+%.?[0-9]*")
	return tonumber(match)
end
