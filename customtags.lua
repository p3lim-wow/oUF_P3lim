local format = string.format
local gsub = string.gsub

local colors = setmetatable({
	power = setmetatable({
		['MANA'] = {0, 144/255, 1}
	}, {__index = oUF.colors.power}),
	reaction = setmetatable({
		[2] = {1, 0, 0},
		[4] = {1, 1, 0},
		[5] = {0, 1, 0}
	}, {__index = oUF.colors.reaction}),
}, {__index = oUF.colors})

local function shortVal(value)
	if(value >= 1e6) then
		return ('%.2fm'):format(value / 1e6):gsub('%.?0+([km])$', '%1')
	elseif(value >= 1e4) then
		return ('%.1fk'):format(value / 1e3):gsub('%.?0+([km])$', '%1')
	else
		return value
	end
end

local function hex(r, g, b)
	if(type(r) == 'table') then
		if(r.r) then r, g, b = r.r, r.g, r.b else r, g, b = unpack(r) end
	end
	return ('|cff%02x%02x%02x'):format(r * 255, g * 255, b * 255)
end

oUF.Tags['[pvptime]'] = function(unit)
	return UnitIsPVP(unit) and not IsPVPTimerRunning() and '*' or IsPVPTimerRunning() and ('%d:%02d'):format((GetPVPTimer() / 1000) / 60, (GetPVPTimer() / 1000) % 60)
end

oUF.TagEvents['[pthreat]'] = 'UNIT_THREAT_LIST_UPDATE'
oUF.Tags['[pthreat]'] = function()
	local _, _, perc = UnitDetailedThreatSituation('player', 'target')
	return perc and ('%s%d%%|r'):format(hex(GetThreatStatusColor(UnitThreatSituation('player', 'target'))), perc)
end

oUF.Tags['[phealth]'] = function(unit)
	local min, max = UnitHealth(unit), UnitHealthMax(unit)
	
	local status = not UnitIsConnected(unit) and 'Offline' or UnitIsGhost(unit) and 'Ghost' or UnitIsDead(unit) and 'Dead'
	local target = unit == 'target' and UnitCanAttack('player', unit) and ('%s (%d|cff0090ff%%|r)'):format(shortVal(min), min / max * 100)
	local player = unit == 'player' and min ~= max and ('|cffff8080%d|r %d|cff0090ff%%|r'):format(min - max, min / max * 100)
	
	return status and status or target and target or player and player or min ~= max and ('%s |cff0090ff/|r %s'):format(shortVal(min), shortVal(max)) or max
end

oUF.Tags['[ppower]'] = function(unit)
	local _, str = UnitPowerType(unit)
	return ('%s%d|r'):format(hex(colors.power[str] or {1, 1, 1}), oUF.Tags['[curpp]'](unit) or '')
end

oUF.TagEvents['[pname]'] = 'UNIT_NAME_UPDATE UNIT_REACTION UNIT_FACTION'
oUF.Tags['[pname]'] = function(unit)
	local colorString = hex((UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit)) and colors.tapped or
		(not UnitIsConnected(unit)) and colors.disconnected or
		(not UnitIsPlayer(unit)) and colors.reaction[UnitReaction(unit, 'player')] or
		(UnitFactionGroup(unit) and UnitIsEnemy(unit, 'player') and UnitIsPVP(unit)) and {1, 0, 0} or {1, 1, 1})

	return ('%s%s|r'):format(colorString, UnitName(unit))
end

oUF.TagEvents['[druidpower]'] = 'UNIT_MANA UPDATE_SHAPESHIFT_FORM'
oUF.Tags['[druidpower]'] = function(unit)
	local value = UnitPower(unit, 0)
	return UnitPowerType(unit) ~= 0 and ('|cff0090ff%d - %d%%|r'):format(value, value / UnitPowerMax(unit, 0) * 100)
end
