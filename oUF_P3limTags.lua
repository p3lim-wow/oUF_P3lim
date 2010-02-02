local _, ns = ...

local unpack = unpack
local format = string.format
local gsub = string.gsub

local function ShortenValue(value)
	if(value >= 1e6) then
		return ('%.2fm'):format(value / 1e6):gsub('%.?0+([km])$', '%1')
	elseif(value >= 1e4) then
		return ('%.1fk'):format(value / 1e3):gsub('%.?0+([km])$', '%1')
	else
		return value
	end
end

oUF.Tags['[p3limpvp]'] = function(unit)
	local running = IsPVPTimerRunning()
	if(UnitIsPVP(unit) and not running) then
		return '|cffff0000+|r'
	elseif(running) then
		local timer = GetPVPTimer()
		return ('|cffff0000%d:%02d'):format((timer / 1000) / 60, (timer / 1000) % 60)
	end
end

oUF.TagEvents['[p3limthreat]'] = 'UNIT_THREAT_LIST_UPDATE'
oUF.Tags['[p3limthreat]'] = function()
	local _, _, perc = UnitDetailedThreatSituation('player', 'target')
	local r, g, b = GetThreatStatusColor(UnitThreatSituation('player', 'target'))
	return perc and perc > 0 and ('|cff%02x%02x%02x%d%%|r'):format(r * 255, g * 255, b * 255, perc)
end

oUF.Tags['[p3limhealth]'] = function(unit)
	local min, max = UnitHealth(unit), UnitHealthMax(unit)

	local status = not UnitIsConnected(unit) and 'Offline' or UnitIsGhost(unit) and 'Ghost' or UnitIsDead(unit) and 'Dead'
	if(status) then
		return status
	elseif(unit == 'target' and UnitCanAttack('player', unit)) then
		return ('%s (%d|cff0090ff%%|r)'):format(ShortenValue(min), min / max * 100)
	elseif(unit == 'player' and min ~= max) then
		return ('|cffff8080%d|r %d|cff0090ff%%|r'):format(min - max, min / max * 100)
	elseif(min ~= max) then
		return ('%s |cff0090ff/|r %s'):format(ShortenValue(min), ShortenValue(max))
	else
		return max
	end
end

oUF.Tags['[p3limpower]'] = function(unit)
	local _, str = UnitPowerType(unit)
	local r, g, b = unpack(ns.colors.power[str] or {1, 1, 1})
	return ('|cff%02x%02x%02x%d|r'):format(r * 255, g * 255, b * 255, UnitPower(unit))
end

oUF.Tags['[p3limdruid]'] = function(unit)
	local min, max = UnitPower(unit, 0), UnitPowerMax(unit, 0)
	return UnitPowerType(unit) ~= 0 and min ~= max and ('|cff0090ff%d%%|r'):format(min / max * 100)
end

oUF.TagEvents['[p3limname]'] = 'UNIT_NAME_UPDATE UNIT_REACTION UNIT_FACTION'
oUF.Tags['[p3limname]'] = function(unit)
	local reaction = UnitReaction(unit, 'player')

	local r, g, b = 1, 1, 1
	if((UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit)) or not UnitIsConnected(unit)) then
		r, g, b = 3/5, 3/5, 3/5
	elseif(not UnitIsPlayer(unit) and reaction) then
		r, g, b = unpack(ns.colors.reaction[reaction])
	elseif(UnitFactionGroup(unit) and UnitIsEnemy(unit, 'player') and UnitIsPVP(unit)) then
		r, g, b = 1, 0, 0
	end

	return ('|cff%02x%02x%02x%s|r'):format(r * 255, g * 255, b * 255, UnitName(unit))
end
