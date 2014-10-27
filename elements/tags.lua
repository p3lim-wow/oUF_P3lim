local tags = select(2, ...).oUF.Tags

local gsub = string.gsub
local format = string.format
local floor = math.floor

local DEAD_TEXTURE = [[|TInterface\RaidFrame\Raid-Icon-DebuffDisease:26|t]]

local function Short(value)
	if(value >= 1e6) then
		return gsub(format('%.2fm', value / 1e6), '%.?0+([km])$', '%1')
	elseif(value >= 1e4) then
		return gsub(format('%.1fk', value / 1e3), '%.?0+([km])$', '%1')
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

local function GetAuraCount(unit, id)
	local index = 1
	repeat
		local _, _, _, count, _, _, _, _, _, _, spellID = UnitAura(unit, index, 'HELPFUL')
		if(spellID == id) then
			return count
		end

		index = index + 1
	until(not spellID)
end

local events = {
	curhp = 'UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH',
	defhp = 'UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH',
	maxhp = 'UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH',
	perhp = 'UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH',
	pethp = 'UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH',
	targethp = 'UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH',
	curpp = 'UNIT_POWER_FREQUENT UNIT_MAXPOWER',
	altpp = 'UNIT_POWER_FREQUENT UNIT_MAXPOWER UNIT_DISPLAYPOWER',
	ptype = 'UNIT_DISPLAYPOWER',
	leader = 'PARTY_LEADER_CHANGED',
	combo = 'UNIT_COMBO_POINTS PLAYER_TARGET_CHANGED',
	anticipation = 'UNIT_AURA',
	maelstrom = 'UNIT_AURA',
	spell = 'UNIT_SPELLCAST_START UNIT_SPELLCAST_STOP UNIT_SPELLCAST_CHANNEL_START UNIT_SPELLCAST_CHANNEL_STOP',
	color = 'UNIT_REACTION UNIT_FACTION',
	status = 'UNIT_CONNECTION UNIT_HEALTH'
}

for tag, func in next, {
	curhp = function(unit)
		if(Status(unit)) then return end
		return Short(UnitHealth(unit))
	end,
	defhp = function(unit)
		if(Status(unit)) then return end

		local cur = UnitHealth(unit)
		local max = UnitHealthMax(unit)
		if(cur ~= max) then
			return Short(max - cur)
		end
	end,
	maxhp = function(unit)
		if(Status(unit)) then return end

		local max = UnitHealthMax(unit)
		if(max == UnitHealth(unit)) then
			return Short(max)
		end
	end,
	perhp = function(unit)
		if(Status(unit)) then return end

		local cur = UnitHealth(unit)
		local max = UnitHealthMax(unit)
		if(cur ~= max) then
			return floor(cur / max * 100)
		end
	end,
	pethp = function()
		if(UnitIsUnit('pet', 'vehicle')) then return end

		local cur = UnitHealth('pet')
		local max = UnitHealthMax('pet')
		if(cur > 0) then
			return format('%s%d%%|r', Hex(ColorGradient(cur, max, 1, 0, 0, 1, 1, 0, 1, 1, 1)), cur / max * 100)
		elseif(UnitIsDead('pet')) then
			return DEAD_TEXTURE
		end
	end,
	targethp = function(unit)
		if(Status(unit)) then return end

		local cur = UnitHealth(unit)
		local max = UnitHealthMax(unit)
		if(UnitCanAttack('player', unit)) then
			return format('(%d|cff0090ff%%|r)', cur / max * 100)
		elseif(cur ~= max) then
			return format('|cff0090ff/|r %s', Short(max))
		end
	end,
	curpp = function(unit)
		if(Status(unit)) then return end

		local cur = UnitPower(unit)
		if(cur > 0) then
			return Short(cur)
		end
	end,
	altpp = function(unit)
		local cur = UnitPower(unit, 0)
		local max = UnitPowerMax(unit, 0)
		if(UnitPowerType(unit) ~= 0 and cur ~= max) then
			return floor(cur / max * 100)
		end
	end,
	ptype = function(unit)
		local _, type = UnitPowerType(unit)
		return Hex(_COLORS.power[type] or _COLORS.power.MANA)
	end,
	leader = function(unit)
		return UnitIsGroupLeader(unit) and '|cffffff00!|r'
	end,
	spell = function(unit)
		return UnitCastingInfo(unit) or UnitChannelInfo(unit)
	end,
	combo = function(unit)
		if(not UnitExists('target')) then return end

		local points = GetComboPoints(unit, 'target')
		if(points == 5) then
			return format('|cffcc3333%d|r', points)
		elseif(points == 4) then
			return format('|cffff6600%d|r', points)
		elseif(points > 0) then
			return format('|cffffcc00%d|r', points)
		end
	end,
	anticipation = function(unit)
		return UnitExists('target') and GetAuraCount(unit, 115189)
	end,
	maelstrom = function(unit)
		return UnitExists('target') and GetAuraCount(unit, 53817)
	end,
	color = function(unit)
		local reaction = UnitReaction(unit, 'player')
		if((UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit)) or not UnitIsConnected(unit)) then
			return '|cff999999'
		elseif(not UnitIsPlayer(unit) and reaction) then
			return Hex(_COLORS.reaction[reaction])
		elseif(UnitFactionGroup(unit) and UnitIsEnemy(unit, 'player') and UnitIsPVP(unit)) then
			return '|cffff0000'
		end
	end,
	status = Status
} do
	tags.Methods['p3lim:' .. tag] = func
	tags.Events['p3lim:' .. tag] = events[tag]
end
