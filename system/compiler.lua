local _, NeP = ...

NeP.Compiler = {}

local spellTokens = {
	{'actions', '^%%'},
	{'lib', '^@'},
	{'macro', '^/'},
  {'item', '^#'}
}

-- Takes a string a produces a table in its place
function NeP.Compiler:Spell(eval)
	local ref = {
		spell = eval[1]
	}
	if ref.spell:find('^!') then
		ref.interrupts = true
    ref.bypass = true
		ref.spell = ref.spell:sub(2)
	end
  if ref.spell:find('^&') then
    ref.bypass = true
    ref.spell = ref.spell:sub(2)
  end
	for i=1, #spellTokens do
		local kind, patern = unpack(spellTokens[i])
		if ref.spell:find(patern) then
      ref.token = ref.spell:sub(1,1)
			ref.spell = ref.spell:sub(2)
		end
	end
  local arg1, args = ref.spell:match('(.+)%((.+)%)')
  if args then ref.spell = arg1 end
  ref.args = args
	ref.spell = NeP.Spells:Convert(ref.spell)
	eval[1] = ref
end

function NeP.Compiler:Target(eval)
	local ref = {
		target = ref
	}
	if ref.target:find('.ground') then
		ref.target = ref.target:sub(0,-8)
		ref.ground = true
	end
	eval[3] = ref
end

function NeP.Compiler:Iterate(eval)
	local spell, cond, target = unpack(eval)
	-- Take care of target
  if type(target) == 'string' then
    self:Target(eval)
  end
  -- Take care of spell
	if type(spell) == 'table' then
		self:Iterate(spell)
	elseif type(spell) == 'string' then
		self:Spell(eval)
	elseif type(spell) == 'function' then
		eval[1] = {
      spell = 'fake'
      func = spell,
			token = 'func'
		}
	end
end