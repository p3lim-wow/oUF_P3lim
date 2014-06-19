local _, ns = ...
local tags = ns.oUF.Tags

local function ShortValue(value)
	if(value >= 1e6) then
		return ('%.2fm'):format(value / 1e6):gsub('%.?0+([km])$', '%1')
	elseif(value >= 1e4) then
		return ('%.1fk'):format(value / 1e3):gsub('%.?0+([km])$', '%1')
	else
		return value
	end
end

local function Status(unit)
	if(not UnitIsConnected(unit)) then
		return 'Offline'
	elseif(UnitIsGhost(unit)) then
		return 'Ghost'
	elseif(UnitIsDead(unit)) then
		return 'Dead'
	end
end

tags.Methods['p3lim:status'] = Status

tags.Methods['p3lim:health'] = function(unit)
	local max = UnitHealthMax(unit)
	if(UnitHealth(unit) == max) then
		return max
	end
end

tags.Methods['p3lim:deficit'] = function(unit)
	if(Status(unit)) then return end

	local cur, max = UnitHealth(unit), UnitHealthMax(unit)
	if(cur ~= max) then
		return ('|cffff8080%d|r'):format(cur - max)
	end
end

tags.Methods['p3lim:percent'] = function(unit)
	if(Status(unit)) then return end

	return ('%d|cff0090ff%%|r'):format(UnitHealth(unit) / UnitHealthMax(unit) * 100)
end

tags.Methods['p3lim:player'] = function(unit)
	if(Status(unit)) then return end

	local maxHealth = _TAGS['p3lim:health'](unit)
	if(maxHealth) then
		return maxHealth
	else
		return ('%s %s'):format(_TAGS['p3lim:deficit'](unit), _TAGS['p3lim:percent'](unit))
	end
end

tags.Methods['p3lim:hostile'] = function(unit)
	if(Status(unit)) then return end

	if(UnitCanAttack('player', unit)) then
		return ('%s (%s)'):format(ShortValue(UnitHealth(unit)), _TAGS['p3lim:percent'](unit))
	end
end

tags.Methods['p3lim:friendly'] = function(unit)
	if(Status(unit)) then return end

	if(not UnitCanAttack('player', unit)) then
		local maxHealth = _TAGS['p3lim:health'](unit)
		if(maxHealth) then
			return maxHealth
		else
			return ('%s |cff0090ff/|r %s'):format(ShortValue(UnitHealth(unit)), ShortValue(UnitHealthMax(unit)))
		end
	end
end

tags.Methods['p3lim:power'] = function(unit)
	local cur = UnitPower(unit)
	if(cur > 0 and not UnitIsDeadOrGhost(unit)) then
		local _, type = UnitPowerType(unit)
		local colors = _COLORS.power
		return ('%s%d|r'):format(Hex(colors[type] or colors['RUNES']), cur)
	end
end

tags.Methods['p3lim:mana'] = function(unit)
	local cur, max = UnitPower(unit, 0), UnitPowerMax(unit, 0)
	if(UnitPowerType(unit) ~= 0 and cur ~= max) then
		return ('%d%%'):format(cur / max * 100)
	end
end

tags.Events['p3lim:color'] = 'UNIT_REACTION UNIT_FACTION'
tags.Methods['p3lim:color'] = function(unit)
	local reaction = UnitReaction(unit, 'player')
	if((UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit)) or not UnitIsConnected(unit)) then
		return Hex(3/5, 3/5, 3/5)
	elseif(not UnitIsPlayer(unit) and reaction) then
		return Hex(_COLORS.reaction[reaction])
	elseif(UnitFactionGroup(unit) and UnitIsEnemy(unit, 'player') and UnitIsPVP(unit)) then
		return Hex(1, 0, 0)
	else
		return Hex(1, 1, 1)
	end
end

tags.Events['p3lim:leader'] = 'PARTY_LEADER_CHANGED'
tags.Methods['p3lim:leader'] = function(unit)
	if(UnitIsGroupLeader(unit)) then
		return '|cffffff00!|r'
	end
end

tags.Events['p3lim:unbuffed'] = 'UNIT_AURA'
tags.Methods['p3lim:unbuffed'] = function(unit, real)
	if(not UnitAura(real or unit, 'Mark of the Wild') and not UnitAura(real or unit, 'Blessing of Kings') and not UnitAura(real or unit, 'Legacy of the Emperor')) then
		return '|cffff00ff!|r'
	end
end

tags.Methods['p3lim:spell'] = function(unit)
	return UnitCastingInfo(unit) or UnitChannelInfo(unit)
end

tags.Events['p3lim:shards'] = 'UNIT_POWER SPELLS_CHANGED'
tags.Methods['p3lim:shards'] = function(unit)
	if(GetSpecialization() ~= SPEC_WARLOCK_AFFLICTION) then return end

	local cur = UnitPower(unit, SPELL_POWER_SOUL_SHARDS)
	if(cur > 0) then
		return cur
	end
end
