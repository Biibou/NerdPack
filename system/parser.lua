local _, NeP = ...
NeP.Parser   = {}
local _G = _G
local c = NeP.CR

--This is used by the ticker
--Its used to determin if we should iterate or not
--Returns true if we're not mounted or in a castable mount
local function IsMountedCheck()
	--Figure out if we're mounted on a castable mount
	for i = 1, 40 do
		local mountID = select(11, _G.UnitBuff('player', i))
		if mountID and NeP.ByPassMounts(mountID) then
			return true
		end
	end
	--return boolean (true if not mounted)
	return (_G.SecureCmdOptionParse("[overridebar][vehicleui][possessbar,@vehicle,exists][mounted]true")) ~= "true"
end

--This is used by the parser.spell
--Returns if we're casting/channeling anything, its remaning time and name
--Also used by the parser for (!spell) if order to figure out if we should clip
local function castingTime()
	local time = _G.GetTime()
	local name, _,_,_,_, endTime = _G.UnitCastingInfo("player")
	if not name then name, _,_,_,_, endTime = _G.UnitChannelInfo("player") end
	return (name and (endTime/1000)-time) or 0, name
end

local function _interrupt(eval)
	if eval[1].interrupts then
		if eval.master.cname == eval.spell then
			return false
		else
			NeP.Protected.SpellStopCasting()
		end
	end
	return true
end

local function tst(_type, unit)
	local tbl = c.CR.blacklist[_type]
	if not tbl then return end
	for i=1, #tbl do
		local _count = tbl[i].count
		if _count then
			if NeP.DSL:Get(_type..'.count.any')(unit, tbl[i].name) >= _count then return true end
		else
			if NeP.DSL:Get(_type..'.any')(unit, tbl[i]) then return true end
		end
	end
end

function NeP.Parser.Unit_Blacklist(_, unit)
	return c.CR.blacklist.units[NeP.Core:UnitID(unit)] or tst("buff", unit) or tst("debuff", unit)
end

--This works on the current parser target.
--This function takes care of psudo units (fakeunits).
--Returns boolean (true if the target is valid).
function NeP.Parser:Target(eval)
	-- This is to alow casting at the cursor location where no unit exists
	if eval[3].cursor then return true end
	-- Eval if the unit is valid
	return eval.target
	and _G.UnitExists(eval.target)
	and _G.UnitIsVisible(eval.target)
	and NeP.Protected.LineOfSight('player', eval.target)
	and not self:Unit_Blacklist(eval.target)
end

local function noob_target() return _G.UnitExists('target') and 'target' or 'player' end

function NeP.Parser:Parse2(eval, func, nest_unit)
	local res;
	--target is target, nest target or fallback
	local tmp_target = eval[3].target or nest_unit or noob_target
	tmp_target = NeP.FakeUnits:Filter(tmp_target)
	--tmp_target = NeP.FakeUnits:Filter(tmp_target)
	for i=1, #tmp_target do
		--print("TARGET ===", i)
		eval.target = tmp_target[i]
		nest_unit = eval.target
		res = func(self, eval, nest_unit)
		if res then break end
	end
	return res
end

function NeP.Parser:Parse3(eval, nest_unit)
	local res;
	if NeP.DSL.Parse(eval[2], eval[1].spell, eval.target) then
		for i=1, #eval[1] do
			--print("NEST ===============", i)
			res = self:Parse(eval[1][i], nest_unit)
			if res then return res end
		end
	end
end

function NeP.Parser:Parse4(eval)
	if not self:Target(eval) then return end
	eval.spell = eval.spell or eval[1].spell
	-- dont for spells that failed Conditions
	--eval.master.halt = eval.master.halt and dsl_res
	--if not eval.master.halt
	if NeP.DSL.Parse(eval[2], eval.spell, eval.target)
	and NeP.Helpers:Check(eval.spell, eval.target)
	and _interrupt(eval) then
		NeP.ActionLog:Add(eval[1].token, eval.spell or "", eval[1].icon, eval.target)
		NeP.Interface:UpdateIcon('mastertoggle', eval[1].icon)
		return eval.exe(eval)
	end
end

--This is the actual Parser...
--Reads and figures out what it should execute from the CR
--The CR when it reaches this point must be already compiled and be ready to run.
function NeP.Parser:Parse(eval, nest_unit)
	-- a spell is waiting for mana
	--if eval.master.halt then
		--print(">>>>>> waiting for", eval.master.halt_spell)
		--return
	--end
	--print(eval[1].spell)
	-- Its a table
	if eval[1].is_table then
		return self:Parse2(eval, self.Parse3, nest_unit)
	-- Normal
	elseif (eval[1].bypass or eval.master.endtime == 0)
	and NeP.Actions:Eval(eval[1].token)(eval) then
		return self:Parse2(eval, self.Parse4, nest_unit)
	end
end

local function ParseStart()
	NeP.Faceroll:Hide()
	NeP:Wipe_Cache()
	if NeP.DSL:Get('toggle')(nil, 'mastertoggle')
	and not _G.UnitIsDeadOrGhost('player')
	and IsMountedCheck()
	and not _G.LootFrame:IsShown() then
		if NeP.Queuer:Execute() then return end
		local table = c.CR and c.CR[_G.InCombatLockdown()]
		if not table then return end
		table.master.endtime, table.master.cname = castingTime()
		table.master.time = _G.GetTime()
		table.master.halt = false
		for i=1, #table do
			--print("TABLE ============================", i)
			if NeP.Parser:Parse(table[i]) then break end
		end
	end
end

-- Delay until everything is ready
NeP.Core:WhenInGame(function()
_G.C_Timer.NewTicker(0.1, ParseStart)
end, -99)

NeP.Debug:Add("Parser", ParseStart, true)
