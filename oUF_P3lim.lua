--[[

  Adrian L Lange grants anyone the right to use this work for any purpose,
  without any conditions, unless such conditions are required by law.

--]]

local FONT = [=[Interface\AddOns\oUF_P3lim\semplice.ttf]=]
local TEXTURE = [=[Interface\ChatFrame\ChatFrameBackground]=]
local BACKDROP = {
	bgFile = TEXTURE, insets = {top = -1, bottom = -1, left = -1, right = -1}
}

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
		local power = UnitPower(unit)
		if(power > 0) then
			local _, type = UnitPowerType(unit)
			local colors = _COLORS.power
			return ('%s%d|r'):format(Hex(colors[type] or colors['RUNES']), power)
		end
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
			r, g, b = unpack(_COLORS.reaction[reaction])
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

local function SpawnMenu(self)
	ToggleDropDownMenu(1, nil, _G[string.gsub(self.unit, '^.', string.upper)..'FrameDropDown'], 'cursor')
end

local function PostUpdatePower(element, unit, min, max)
	element:GetParent().Health:SetHeight(max ~= 0 and 20 or 22)
end

local function PostCreateAura(element, button)
	button:SetBackdrop(BACKDROP)
	button:SetBackdropColor(0, 0, 0)
	button.cd:SetReverse()
	button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	button.icon:SetDrawLayer('ARTWORK')
end

local function PostUpdateDebuff(element, unit, button, index)
	if(UnitIsFriend('player', unit) or button.isPlayer) then
		local _, _, _, _, type = UnitAura(unit, index, button.filter)
		local color = DebuffTypeColor[type] or DebuffTypeColor.none

		button:SetBackdropColor(color.r * 3/5, color.g * 3/5, color.b * 3/5)
		button.icon:SetDesaturated(false)
	else
		button:SetBackdropColor(0, 0, 0)
		button.icon:SetDesaturated(true)
	end
end

local UnitSpecific = {
	player = function(self)
		local leader = self.Health:CreateTexture(nil, 'OVERLAY')
		leader:SetPoint('TOPLEFT', self, 0, 8)
		leader:SetSize(16, 16)
		self.Leader = leader

		local assistant = self.Health:CreateTexture(nil, 'OVERLAY')
		assistant:SetPoint('TOPLEFT', self, 0, 8)
		assistant:SetSize(16, 16)
		self.Assistant = assistant

		local info = self.Health:CreateFontString(nil, 'OVERLAY')
		info:SetPoint('CENTER')
		info:SetFont(FONT, 8, 'OUTLINE')
		self:Tag(info, '[p3lim:threat]')

		self:SetAttribute('initial-width', 230)
	end,
	target = function(self)
		local buffs = CreateFrame('Frame', nil, self)
		buffs:SetPoint('TOPLEFT', self, 'TOPRIGHT', 4, 0)
		buffs:SetSize(236, 44)
		buffs.num = 20
		buffs.size = 20
		buffs.spacing = 4
		buffs.initialAnchor = 'TOPLEFT'
		buffs['growth-y'] = 'DOWN'
		buffs.PostCreateIcon = PostCreateAura
		self.Buffs = buffs

		local cpoints = self:CreateFontString(nil, 'OVERLAY', 'SubZoneTextFont')
		cpoints:SetPoint('RIGHT', self, 'LEFT', -9, 0)
		cpoints:SetJustifyH('RIGHT')
		self:Tag(cpoints, '|cffffffff[cpoints]|r')

		self.Power.PostUpdate = PostUpdatePower
		self:SetAttribute('initial-width', 230)
	end,
	pet = function(self)
		local auras = CreateFrame('Frame', nil, self)
		auras:SetPoint('TOPRIGHT', self, 'TOPLEFT', -4, 0)
		auras:SetSize(236, 44)
		auras.size = 20
		auras.spacing = 4
		auras.initialAnchor = 'TOPRIGHT'
		auras['growth-x'] = 'LEFT'
		auras.PostCreateIcon = PostCreateAura
		self.Auras = auras

		self:SetAttribute('initial-width', 130)
	end,
}

local function Shared(self, unit)
	self:RegisterForClicks('AnyUp')
	self:SetScript('OnEnter', UnitFrame_OnEnter)
	self:SetScript('OnLeave', UnitFrame_OnLeave)

	self:SetBackdrop(BACKDROP)
	self:SetBackdropColor(0, 0, 0)

	local health = CreateFrame('StatusBar', nil, self)
	health:SetStatusBarTexture(TEXTURE)
	health:SetStatusBarColor(1/6, 1/6, 2/7)
	health.frequentUpdates = true
	self.Health = health

	local healthBG = health:CreateTexture(nil, 'BORDER')
	healthBG:SetAllPoints()
	healthBG:SetTexture(1/3, 1/3, 1/3)

	local healthValue = health:CreateFontString(nil, 'OVERLAY')
	healthValue:SetPoint('RIGHT', health, -2, 0)
	healthValue:SetFont(FONT, 8, 'OUTLINE')
	healthValue:SetJustifyH('RIGHT')
	healthValue.frequentUpdates = 1/4
	self:Tag(healthValue, '[p3lim:health]')

	if(unit == 'player' or unit == 'target' or unit == 'pet') then
		local power = CreateFrame('StatusBar', nil, self)
		power:SetPoint('BOTTOMRIGHT')
		power:SetPoint('BOTTOMLEFT')
		power:SetPoint('TOP', health, 'BOTTOM', 0, -1)
		power:SetStatusBarTexture(TEXTURE)
		power.frequentUpdates = true
		self.Power = power

		power.colorClass = true
		power.colorTapping = true
		power.colorDisconnected = true
		power.colorReaction = unit ~= 'pet'
		power.colorHappiness = unit == 'pet'
		power.colorPower = unit == 'pet'

		local powerBG = power:CreateTexture(nil, 'BORDER')
		powerBG:SetAllPoints()
		powerBG:SetTexture(TEXTURE)
		powerBG.multiplier = 1/3
		power.bg = powerBG

		if(unit ~= 'target') then
			local powerValue = health:CreateFontString(nil, 'OVERLAY')
			powerValue:SetPoint('LEFT', health, 2, 0)
			powerValue:SetFont(FONT, 8, 'OUTLINE')
			powerValue:SetJustifyH('LEFT')
			powerValue.frequentUpdates = 0.1
			self:Tag(powerValue, '[p3lim:power< ][p3lim:druid]')
		end

		local raidicon = health:CreateTexture(nil, 'OVERLAY')
		raidicon:SetPoint('TOP', self, 0, 8)
		raidicon:SetSize(16, 16)
		self.RaidIcon = raidicon

		health:SetHeight(20)
		health:SetPoint('TOPRIGHT')
		health:SetPoint('TOPLEFT')

		self.menu = SpawnMenu
		self:SetAttribute('type2', 'menu')
		self:SetAttribute('initial-height', 22)
	end

	if(unit == 'focus' or unit:find('target')) then
		local name = health:CreateFontString(nil, 'OVERLAY')
		name:SetPoint('LEFT', health, 2, 0)
		name:SetPoint('RIGHT', healthValue, 'LEFT')
		name:SetFont(FONT, 8, 'OUTLINE')
		name:SetJustifyH('LEFT')
		self:Tag(name, '[p3lim:name< ][|cff0090ff>rare<|r]')

		local debuffs = CreateFrame('Frame', nil, self)
		debuffs.spacing = 4
		debuffs.initialAnchor = 'TOPLEFT'
		debuffs.PostCreateIcon = PostCreateAura
		self.Debuffs = debuffs

		if(unit == 'target') then
			debuffs.num = 20
			debuffs.size = 19.4
			debuffs['growth-y'] = 'DOWN'
			debuffs.PostUpdateIcon = PostUpdateDebuff
			debuffs:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -4)
		else
			debuffs.num = 3
			debuffs.size = 19

			health:SetAllPoints()
			self:SetAttribute('initial-height', 19)
			self:SetAttribute('initial-width', 161)
		end

		if(unit == 'focus') then
			debuffs:SetPoint('TOPLEFT', self, 'TOPRIGHT')
			debuffs.onlyShowPlayer = true
		elseif(unit ~= 'target') then
			debuffs:SetPoint('TOPRIGHT', self, 'TOPLEFT', -4, 0)
			debuffs.initialAnchor = 'TOPRIGHT'
			debuffs['growth-x'] = 'LEFT'
		end

		debuffs:SetSize(230, debuffs.size)
	end

	if(UnitSpecific[unit]) then
		return UnitSpecific[unit](self)
	end
end

oUF.colors.power.MANA = {0, 144/255, 1}

oUF:RegisterStyle('P3lim', Shared)
oUF:Factory(function(self)
	self:SetActiveStyle('P3lim')
	self:Spawn('player'):SetPoint('CENTER', -300, -250)
	self:Spawn('pet'):SetPoint('CENTER', -490, -250)
	self:Spawn('focus'):SetPoint('CENTER', -335, -225)
	self:Spawn('target'):SetPoint('CENTER', 300, -250)
	self:Spawn('targettarget'):SetPoint('CENTER', 334, -225)
end)
