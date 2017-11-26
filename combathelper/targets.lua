local _, gbl = ...

gbl.Interface:AddToggle({
		key = "AutoTarget",
		name = "Auto Target",
		text = "Automatically target the nearest enemy when target dies or does not exist",
		icon = "Interface\\Icons\\ability_hunter_snipershot",
		nohide = true
})

local gbl_forceTarget = {
	-- WOD DUNGEONS/RAIDS
	[75966] = 100,	-- Defiled Spirit (Shadowmoon Burial Grounds)
	[76220] = 100,	-- Blazing Trickster (Auchindoun Normal)
	[76222] = 100,	-- Rallying Banner (UBRS Black Iron Grunt)
	[76267] = 100,	-- Solar Zealot (Skyreach)
	[76518] = 100,	-- Ritual of Bones (Shadowmoon Burial Grounds)
	[77252] = 100,	-- Ore Crate (BRF Oregorger)
	[77665] = 100,	-- Iron Bomber (BRF Blackhand)
	[77891] = 100,	-- Grasping Earth (BRF Kromog)
	[77893] = 100,	-- Grasping Earth (BRF Kromog)
	[86752] = 100,	-- Stone Pillars (BRF Mythic Kromog)
	[78583] = 100,	-- Dominator Turret (BRF Iron Maidens)
	[78584] = 100,	-- Dominator Turret (BRF Iron Maidens)
	[79504] = 100,	-- Ore Crate (BRF Oregorger)
	[79511] = 100,	-- Blazing Trickster (Auchindoun Heroic)
	[81638] = 100,	-- Aqueous Globule (The Everbloom)
	[86644] = 100,	-- Ore Crate (BRF Oregorger)
	[94873] = 100,	-- Felfire Flamebelcher (HFC)
	[90432] = 100,	-- Felfire Flamebelcher (HFC)
	[95586] = 100,	-- Felfire Demolisher (HFC)
	[93851] = 100,	-- Felfire Crusher (HFC)
	[90410] = 100,	-- Felfire Crusher (HFC)
	[94840] = 100,	-- Felfire Artillery (HFC)
	[90485] = 100,	-- Felfire Artillery (HFC)
	[93435] = 100,	-- Felfire Transporter (HFC)
	[93717] = 100,	-- Volatile Firebomb (HFC)
	[188293] = 100,	-- Reinforced Firebomb (HFC)
	[94865] = 100,	-- Grasping Hand (HFC)
	[93838] = 100,	-- Grasping Hand (HFC)
	[93839] = 100,	-- Dragging Hand (HFC)
	[91368] = 100,	-- Crushing Hand (HFC)
	[94455] = 100,	-- Blademaster Jubei"thos (HFC)
	[90387] = 100,	-- Shadowy Construct (HFC)
	[90508] = 100,	-- Gorebound Construct (HFC)
	[90568] = 100,	-- Gorebound Essence (HFC)
	[94996] = 100,	-- Fragment of the Crone (HFC)
	[95656] = 100,	-- Carrion Swarm (HFC)
	[91540] = 100,	-- Illusionary Outcast (HFC)
}

local function getTargetPrio(Obj)
	local id = tonumber(select(6, strsplit("-", UnitGUID(Obj))) or 0)
	local prio = 1
	-- Elite
	if gbl.Condition.Get("elite")(Obj) then
		prio = prio + 30
	end
	-- If its forced
	if gbl_forceTarget[tonumber(Obj)] then
		prio = prio + gbl_forceTarget[id]
	end
	return prio
end

function gbl.CombatHelper.Target()
	-- If dont have a target, target is friendly or dead
  if not UnitExists("target")
	or UnitReaction("player", "target") > 4
	or UnitIsDeadOrGhost("target") then
		local setPrio = {}
		for _, Obj in pairs(gbl.OM:Get("Enemy")) do
			if UnitExists(Obj.key)
			and Obj.distance <= 40 then
				if (UnitAffectingCombat(Obj.key)
				or gbl.Condition.Get("isdummy")(Obj.key))
				and gbl.Condition.Get("infront")(Obj.key) then
					setPrio[#setPrio+1] = {
						key = Obj.key,
						bonus = getTargetPrio(Obj.key),
						name = Obj.name
					}
				end
			end
		end
		table.sort(setPrio, function(a,b) return a.bonus > b.bonus end)
		if setPrio[1] then
			gbl.Protected.TargetUnit(setPrio[1].key)
		end
	end
end

local function Start()
	if UnitAffectingCombat("player")
	and gbl.Condition.Get("toggle")(nil, "mastertoggle")
	and gbl.Condition.Get("toggle")(nil, "AutoTarget") then
			gbl.CombatHelper:Target()
	end
end

-- Ticker
C_Timer.NewTicker(0.1, Start)
gbl.Debug.Add("FACING", Start, true)
