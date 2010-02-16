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

for name, func in pairs({
	['pvp'] = function(unit)
		local running = IsPVPTimerRunning()
		if(UnitIsPVP(unit) and not running) then
			return '|cffff0000+|r'
		elseif(running) then
			local timer = GetPVPTimer() / 1e3
			return ('|cffff0000%d:%02d|r'):format(timer / 60, timer % 60)
		end
	end,
	['threat'] = function(unit)
		local tanking, status, percent = UnitDetailedThreatSituation('player', 'target')
		if(percent and percent > 0) then
			return ('%s%d%%|r'):format(Hex(GetThreatStatusColor(status)), percent)
		end
	end,
	['health'] = function(unit)
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
	end,
	['power'] = function(unit)
		local _, type = UnitPowerType(unit)
		return ('%s%d|r'):format(Hex(oUF.colors.power[type or 'RUNES']), UnitPower(unit))
	end,
	['druid'] = function(unit)
		local min, max = UnitPower(unit, 0), UnitPowerMax(unit, 0)
		if(UnitPowerType(unit) ~= 0 and min ~= max) then
			return ('|cff0090ff%d%%|r'):format(min / max * 100)
		end
	end,
	['name'] = function(unit)
		local reaction = UnitReaction(unit, 'player')

		local r, g, b = 1, 1, 1
		if((UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit)) or not UnitIsConnected(unit)) then
			r, g, b = 3/5, 3/5, 3/5
		elseif(not UnitIsPlayer(unit) and reaction) then
			r, g, b = unpack(oUF.colors.reaction[reaction])
		elseif(UnitFactionGroup(unit) and UnitIsEnemy(unit, 'player') and UnitIsPVP(unit)) then
			r, g, b = 1, 0, 0
		end

		return ('%s%s|r'):format(Hex(r, g, b), UnitName(unit))
	end
}) do
	oUF.Tags['p3lim:'..name] = func
end

oUF.TagEvents['p3lim:name'] = 'UNIT_NAME_UPDATE UNIT_REACTION UNIT_FACTION'
oUF.TagEvents['p3lim:threat'] = 'UNIT_THREAT_LIST_UPDATE'
