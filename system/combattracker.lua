local _, NeP = ...
local _G = _G

NeP.CombatTracker = {}
local Data = {}

-- Thse are Mixed Damage types (magic and pysichal)
local Doubles = {
	[3]   = 'Holy + Physical',
	[5]   = 'Fire + Physical',
	[9]   = 'Nature + Physical',
	[17]  = 'Frost + Physical',
	[33]  = 'Shadow + Physical',
	[65]  = 'Arcane + Physical',
	[127] = 'Arcane + Shadow + Frost + Nature + Fire + Holy + Physical',
}

local function addToData(GUID)
	if not Data[GUID] then
		Data[GUID] = {
			dmgTaken   = 0,
			dmgTaken_P = 0,
			dmgTaken_M = 0,
			Hits       = 0,
			firstHit   = _G.GetTime(),
			lastHit    = 0
		}
	end
end

--[[ This Logs the damage done for every unit ]]
local logDamage = function(...)
	local _,_,_,_,_,_,_, GUID, _,_,_,_,_, school, Amount = ...
	-- Mixed
	if Doubles[school] then
		Data[GUID].dmgTaken_P = Data[GUID].dmgTaken_P + Amount
		Data[GUID].dmgTaken_M = Data[GUID].dmgTaken_M + Amount
	-- Pysichal
	elseif school == 1  then
		Data[GUID].dmgTaken_P = Data[GUID].dmgTaken_P + Amount
	-- Magic
	else
		Data[GUID].dmgTaken_M = Data[GUID].dmgTaken_M + Amount
	end
	-- Totals
	Data[GUID].dmgTaken = Data[GUID].dmgTaken + Amount
	Data[GUID].Hits     = Data[GUID].Hits + 1
end

--[[ This Logs the swings (damage) done for every unit ]]
local logSwing = function(...)
	local _,_,_,_,_,_,_, GUID, _,_,_, Amount = ...
	Data[GUID].dmgTaken_P = Data[GUID].dmgTaken_P + Amount
	Data[GUID].dmgTaken   = Data[GUID].dmgTaken + Amount
	Data[GUID].Hits       = Data[GUID].Hits + 1
end

--[[ This Logs the healing done for every unit
		 !!~counting selfhealing only for now~!!]]
local logHealing = function(...)
	local _,_,_, sourceGUID, _,_,_, GUID, _,_,_,_,_,_, Amount = ...
	local playerGUID = _G.UnitGUID('player')
	if sourceGUID == playerGUID then
		Data[GUID].dmgTaken_P = Data[GUID].dmgTaken_P - Amount
		Data[GUID].dmgTaken_M = Data[GUID].dmgTaken_M - Amount
		Data[GUID].dmgTaken   = Data[GUID].dmgTaken - Amount
	end
end

--[[ This Logs the last action done for every unit ]]
local addAction = function(...)
	local _,_,_, sourceGUID, _,_,_,_, destName, _,_,_, spellName = ...
	if not spellName then return end
	addToData(sourceGUID)
	-- Add to action Log, only for self for now
	if sourceGUID == _G.UnitGUID('player') then
		local icon = select(3, _G.GetSpellInfo(spellName))
		NeP.ActionLog:Add('Spell Cast Succeed', spellName, icon, destName)
	end
	Data[sourceGUID].lastcast = spellName
end

--[[ These are the events we're looking for and its respective action ]]
local EVENTS = {
	['SPELL_DAMAGE'] 					= function(...) logDamage(...) 							end,
	['DAMAGE_SHIELD'] 				= function(...) logDamage(...) 							end,
	['SPELL_PERIODIC_DAMAGE']	= function(...) logDamage(...) 							end,
	['SPELL_BUILDING_DAMAGE']	= function(...) logDamage(...) 							end,
	['RANGE_DAMAGE'] 					= function(...) logDamage(...) 							end,
	['SWING_DAMAGE'] 					= function(...) logSwing(...) 							end,
	['SPELL_HEAL'] 						= function(...) logHealing(...) 						end,
	['SPELL_PERIODIC_HEAL'] 	= function(...) logHealing(...) 						end,
	['UNIT_DIED'] 						= function(...) Data[select(8, ...)] = nil 	end,
	['SPELL_CAST_SUCCESS'] 		= function(...) addAction(...) 							end
}

--[[ Returns the total ammount of time a unit is in-combat for ]]
function NeP.CombatTracker.CombatTime(_, UNIT)
	local GUID = _G.UnitGUID(UNIT)
	if Data[GUID] and _G.InCombatLockdown() then
		local combatTime = (_G.GetTime()-Data[GUID].firstHit)
		return combatTime
	end
	return 0
end

function NeP.CombatTracker:getDMG(UNIT)
	local total, Hits, phys, magic = 0, 0, 0, 0
	local GUID = _G.UnitGUID(UNIT)
	if Data[GUID] then
		local time = _G.GetTime()
		-- Remove a unit if it hasnt recived dmg for more then 5 sec
		if (time-Data[GUID].lastHit) > 5 then
			Data[GUID] = nil
		else
			local combatTime = self:CombatTime(UNIT)
			total            = Data[GUID].dmgTaken / combatTime
			phys             = Data[GUID].dmgTaken_P / combatTime
			magic            = Data[GUID].dmgTaken_M / combatTime
			Hits             = Data[GUID].Hits
		end
	end
	return total, Hits, phys, magic
end

function NeP.CombatTracker:TimeToDie(unit)
	local ttd = 0
	local DMG, Hits = self:getDMG(unit)
	if DMG >= 1 and Hits > 1 then
		ttd = _G.UnitHealth(unit) / DMG
	end
	return ttd or 8675309
end

function NeP.CombatTracker.LastCast(_, unit)
  local GUID = _G.UnitGUID(unit)
  if Data[GUID] then
    return Data[GUID].lastcast
  end
end

NeP.Listener:Add('NeP_CombatTracker', 'COMBAT_LOG_EVENT_UNFILTERED', function(...)
	local _, EVENT, _,_,_,_,_, GUID = ...
	-- Add the unit to our data if we dont have it
	addToData(GUID)
	-- Update last  hit time
	Data[GUID].lastHit = _G.GetTime()
	-- Add the amount of dmg/heak
	if EVENTS[EVENT] then EVENTS[EVENT](...) end
end)

NeP.Listener:Add('NeP_CombatTracker', 'PLAYER_REGEN_ENABLED', function()
	_G.wipe(Data)
end)

NeP.Listener:Add('NeP_CombatTracker', 'PLAYER_REGEN_DISABLED', function()
	_G.wipe(Data)
end)
