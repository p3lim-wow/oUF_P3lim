--[[

  Adrian L Lange grants anyone the right to use this work for any purpose,
  without any conditions, unless such conditions are required by law.

--]]

local match, format, gsub = string.match, string.format, string.gsub

local localized, class = UnitClass('player')
local texture = [=[Interface\AddOns\oUF_P3lim\media\minimalist]=]
local backdrop = {
	bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
	insets = {top = -1, left = -1, bottom = -1, right = -1},
}

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

local buffFilter = {
	[GetSpellInfo(61336)] = true,
	[GetSpellInfo(22842)] = true,
	[GetSpellInfo(52610)] = true,
	[GetSpellInfo(22812)] = true,
	[GetSpellInfo(16870)] = true,
	[GetSpellInfo(62600)] = true,
}

local function menu(self)
	local unit = gsub(self.unit, '(.)', string.upper, 1)
	if(_G[unit..'FrameDropDown']) then
		ToggleDropDownMenu(1, nil, _G[unit..'FrameDropDown'], 'cursor')
	end
end

local function updateCombo(self, event, unit)
	if(unit == PlayerFrame.unit and unit ~= self.CPoints.unit) then
		self.CPoints.unit = unit
	end
end

local function updateDruidPower(self, event, unit)
	if(unit and unit ~= self.unit) then return end
	local bar = self.DruidPower

	local mana = UnitPowerType('player') == 0
	local min, max = UnitPower('player', mana and 3 or 0), UnitPowerMax('player', mana and 3 or 0)

	bar:SetStatusBarColor(unpack(colors.power[mana and 'ENERGY' or 'MANA']))
	bar:SetMinMaxValues(0, max)
	bar:SetValue(min)
	bar:SetAlpha(min ~= max and 1 or 0)
end

local function updatePower(self, event, unit, bar, min, max)
	if(unit ~= 'target') then return end

	if(max ~= 0) then
		self.Health:SetHeight(22)
		bar:Show()
	else
		self.Health:SetHeight(27)
		bar:Hide()
	end
end

local function updateReputationColor(self, event, unit, bar)
	local name, id = GetWatchedFactionInfo()
	bar:SetStatusBarColor(FACTION_BAR_COLORS[id].r, FACTION_BAR_COLORS[id].g, FACTION_BAR_COLORS[id].b)
end

local function castbarIcon(self, event, unit)
	local castbar, locked = self.Castbar

	if(castbar.channeling) then
		local _, _, _, _, _, _, _, notInterruptible = UnitChannelInfo(unit)
		locked = notInterruptible
	elseif(castbar.casting) then
		local _, _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo(unit)
		locked = notInterruptible
	end

	if(locked) then
		castbar.Icon.overlay:SetVertexColor(0, 0.9, 1)
	else
		castbar.Icon.overlay:SetVertexColor(0.25, 0.25, 0.25)
	end
end

local function castbarTime(self, duration)
	if(self.channeling) then
		self.Time:SetFormattedText('%.1f ', duration)
	elseif(self.casting) then
		self.Time:SetFormattedText('%.1f ', self.max - duration)
	end
end

local function createAura(self, button, icons)
	icons.showDebuffType = true
	button.cd:SetReverse()
	button.overlay:SetTexture([=[Interface\AddOns\oUF_P3lim\media\border]=])
	button.overlay:SetTexCoord(0, 1, 0, 1)
	button.overlay.Hide = function(self) self:SetVertexColor(0.25, 0.25, 0.25) end

	if(self.unit == 'player') then
		icons.disableCooldown = true
		button.time = button:CreateFontString(nil, 'OVERLAY', 'NumberFontNormal')
		button.time:SetPoint('TOPLEFT', button)
	end
end

local function updateTime(self, elapsed)
	self.timeLeft = max(self.timeLeft - elapsed, 0)
	self.time:SetText(self.timeLeft < 90 and floor(self.timeLeft) or '')
	
	if(GameTooltip:IsOwned(self)) then
		GameTooltip:SetUnitAura(self.frame.unit, self:GetID(), self.filter)
	end
end

local function updateBuff(self, icons, unit, icon, index)
	local _, _, _, _, _, duration, expiration = UnitAura(unit, index, icon.filter)

	if(duration > 0 and expiration) then
		icon.timeLeft = expiration - GetTime()
		icon:SetScript('OnUpdate', updateTime)
	else
		icon.timeLeft = nil
		icon.time:SetText()
		icon:SetScript('OnUpdate', nil)
	end
end

local function updateDebuff(self, icons, unit, icon, index)
	if(not icon.debuff or UnitIsFriend('player', unit)) then return end

	if(icon.owner ~= 'player' and icon.owner ~= 'vehicle') then
		icon.icon:SetDesaturated(true)
		icon.overlay:SetVertexColor(0.25, 0.25, 0.25)
	else
		icon.icon:SetDesaturated(false)
	end
end

local function customFilter(icons, unit, icon, name, rank, texture, count, dtype, duration, expiration, caster)
	if(buffFilter[name] and caster == 'player') then
		-- todo: set the buffs.visibleBuffs so it works with buffs.num
		return true
	end
end

local function styleFunction(self, unit)
	self.colors = colors
	self.menu = menu
	self:RegisterForClicks('AnyUp')
	self:SetAttribute('type2', 'menu')

	self:SetScript('OnEnter', UnitFrame_OnEnter)
	self:SetScript('OnLeave', UnitFrame_OnLeave)

	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0, 0, 0)

	self.Health = CreateFrame('StatusBar', nil, self)
	self.Health:SetPoint('TOPRIGHT', self)
	self.Health:SetPoint('TOPLEFT', self)
	self.Health:SetStatusBarTexture(texture)
	self.Health:SetStatusBarColor(0.25, 0.25, 0.35)
	self.Health:SetHeight((unit == 'focus' or unit == 'targettarget') and 20 or 22)
	self.Health.frequentUpdates = true

	self.Health.bg = self.Health:CreateTexture(nil, 'BORDER')
	self.Health.bg:SetAllPoints(self.Health)
	self.Health.bg:SetTexture(0.3, 0.3, 0.3)

	local hpvalue = self.Health:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmallRight')
	hpvalue:SetPoint('RIGHT', self.Health, -2, -1)
	hpvalue.frequentUpdates = 0.1
	self:Tag(hpvalue, '[phealth]')

	self.RaidIcon = self.Health:CreateTexture(nil, 'OVERLAY')
	self.RaidIcon:SetPoint('TOP', self, 0, 8)
	self.RaidIcon:SetHeight(16)
	self.RaidIcon:SetWidth(16)

	if(unit ~= 'targettarget' and unit ~= 'focus') then
		self.Power = CreateFrame('StatusBar', nil, self)
		self.Power:SetPoint('BOTTOMRIGHT', self)
		self.Power:SetPoint('BOTTOMLEFT', self)
		self.Power:SetStatusBarTexture(texture)
		self.Power:SetHeight(4)
		self.Power.frequentUpdates = true

		local pet = unit == 'pet'
		self.Power.bg = self.Power:CreateTexture(nil, 'BORDER')
		self.Power.bg:SetAllPoints(self.Power)
		self.Power.bg:SetTexture([=[Interface\ChatFrame\ChatFrameBackground]=])
		self.Power.bg.multiplier = 0.3

		self.Power.colorTapping = true
		self.Power.colorDisconnected = true
		self.Power.colorClass = true
		self.Power.colorPower = pet
		self.Power.colorHappiness = pet
		self.Power.colorReaction = not pet
		self.PostUpdatePower = updatePower

		self.Leader = self.Health:CreateTexture(nil, 'OVERLAY')
		self.Leader:SetPoint('TOPLEFT', self, 0, 8)
		self.Leader:SetHeight(16)
		self.Leader:SetWidth(16)

		self.Assistant = self.Health:CreateTexture(nil, 'OVERLAY')
		self.Assistant:SetPoint('TOPLEFT', self, 0, 8)
		self.Assistant:SetHeight(16)
		self.Assistant:SetWidth(16)
	else
		local focus = unit == 'focus'
		self.Debuffs = CreateFrame('Frame', nil, self)
		self.Debuffs:SetPoint(focus and 'TOPLEFT' or 'TOPRIGHT', self, focus and 'TOPRIGHT' or 'TOPLEFT', focus and 2 or -2, 1)
		self.Debuffs:SetHeight(23)
		self.Debuffs:SetWidth(180)
		self.Debuffs.num = 2
		self.Debuffs.size = 23
		self.Debuffs.spacing = 2
		self.Debuffs.onlyShowPlayer = focus
		self.Debuffs.initialAnchor = focus and 'TOPLEFT' or 'TOPRIGHT'
		self.Debuffs['growth-x'] = focus and 'RIGHT' or 'LEFT'
		self.PostCreateAuraIcon = createAura

		self:SetAttribute('initial-height', 21)
		self:SetAttribute('initial-width', 181)
	end

	if(unit == 'player' or unit == 'pet') then
		local power = self.Health:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmallLeft')
		power:SetPoint('LEFT', self.Health, 2, -1)
		power.frequentUpdates = 0.1
		self:Tag(power, unit == 'player' and '[ppower][( )druidpower]' or '[ppower]')

		if(IsAddOnLoaded('oUF_Experience')) then
			self.Experience = CreateFrame('StatusBar', nil, self)
			self.Experience:SetPoint('TOP', self, 'BOTTOM', 0, -10)
			self.Experience:SetStatusBarTexture(texture)
			self.Experience:SetStatusBarColor(unpack(colors.health))
			self.Experience:SetHeight(11)
			self.Experience:SetWidth(230)
			self.Experience.Tooltip = true

			self.Experience.Rested = CreateFrame('StatusBar', nil, self)
			self.Experience.Rested:SetAllPoints(self.Experience)
			self.Experience.Rested:SetStatusBarTexture(texture)
			self.Experience.Rested:SetStatusBarColor(0, 0.4, 1, 0.6)
			self.Experience.Rested:SetBackdrop(backdrop)
			self.Experience.Rested:SetBackdropColor(0, 0, 0)
			self.Experience.Rested:SetFrameLevel(1)

			self.Experience.Text = self.Experience:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
			self.Experience.Text:SetPoint('CENTER', self.Experience)

			self.Experience.bg = self.Experience.Rested:CreateTexture(nil, 'BORDER')
			self.Experience.bg:SetAllPoints(self.Experience)
			self.Experience.bg:SetTexture(0.3, 0.3, 0.3)
		end

		if(unit == 'player') then
			local info = self.Health:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
			info:SetPoint('CENTER', self.Health, 0, -1)
			info.frequentUpdates = 0.1
			self:Tag(info, '[pthreat]|cffff0000[pvptime]|r')
		end

		self.BarFade = true
	else
		local info = self.Health:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmallLeft')
		info:SetPoint('LEFT', self.Health, 2, -1)
		info:SetPoint('RIGHT', hpvalue, 'LEFT')
		self:Tag(info, unit == 'target' and '[pname]|cff0090ff[( )rare]|r' or '[pname]')
	end

	if(unit == 'pet') then
		self.Auras = CreateFrame('Frame', nil, self)
		self.Auras:SetPoint('TOPRIGHT', self, 'TOPLEFT', -2, 1)
		self.Auras:SetHeight(24 * 2)
		self.Auras:SetWidth(270)
		self.Auras.size = 24
		self.Auras.spacing = 2
		self.Auras.initialAnchor = 'TOPRIGHT'
		self.Auras['growth-x'] = 'LEFT'
		self.PostCreateAuraIcon = createAura

		self:SetAttribute('initial-height', 27)
		self:SetAttribute('initial-width', 130)
	end

	if(unit == 'target' or unit == 'player') then
		self.Buffs = CreateFrame('Frame', nil, self)
		self.Buffs:SetPoint('TOPLEFT', self, 'TOPRIGHT', 2, 1)
		self.Buffs:SetHeight(24 * 2)
		self.Buffs:SetWidth(270)
		self.Buffs.num = 20
		self.Buffs.size = 24
		self.Buffs.spacing = 2
		self.Buffs.initialAnchor = 'TOPLEFT'
		self.Buffs['growth-y'] = 'DOWN'
		self.PostCreateAuraIcon = createAura
		self.PostUpdateAuraIcon = unit == 'player' and updateBuff
		self.CustomAuraFilter = unit == 'player' and customFilter

		self.Castbar = CreateFrame('StatusBar', nil, self)
		self.Castbar:SetWidth(205)
		self.Castbar:SetHeight(16)
		self.Castbar:SetStatusBarTexture(texture)
		self.Castbar:SetStatusBarColor(0.25, 0.25, 0.35)
		self.Castbar:SetBackdrop(backdrop)
		self.Castbar:SetBackdropColor(0, 0, 0)
		self.PostCastStart = castbarIcon
		self.PostChannelStart = castbarIcon

		self.Castbar.Text = self.Castbar:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmallLeft')
		self.Castbar.Text:SetPoint('LEFT', self.Castbar, 'LEFT', 2, 1)

		self.Castbar.Time = self.Castbar:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmallRight')
		self.Castbar.Time:SetPoint('RIGHT', self.Castbar, 'RIGHT', -2, 1)
		self.Castbar.CustomTimeText = castbarTime

		self.Castbar.bg = self.Castbar:CreateTexture(nil, 'BORDER')
		self.Castbar.bg:SetAllPoints(self.Castbar)
		self.Castbar.bg:SetTexture(0.3, 0.3, 0.3)

		self.Castbar.Icon = self.Castbar:CreateTexture(nil, 'ARTWORK')
		self.Castbar.Icon:SetHeight(24)
		self.Castbar.Icon:SetWidth(24)

		self.Castbar.Icon.overlay = self.Castbar:CreateTexture(nil, 'OVERLAY')
		self.Castbar.Icon.overlay:SetAllPoints(self.Castbar.Icon)
		self.Castbar.Icon.overlay:SetTexture([=[Interface\AddOns\oUF_P3lim\media\border]=])
		self.Castbar.Icon.overlay:SetVertexColor(0.25, 0.25, 0.25)

		if(unit == 'target') then
			self.Castbar:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -20)
			self.Castbar.Icon:SetPoint('BOTTOMLEFT', self.Castbar, 'BOTTOMRIGHT', 2, -1)
		else
			self.Castbar:SetPoint('TOPRIGHT', self, 'BOTTOMRIGHT', 0, -20)
			self.Castbar.Icon:SetPoint('BOTTOMRIGHT', self.Castbar, 'BOTTOMLEFT', -2, -1)
		end

		self:SetAttribute('initial-height', 27)
		self:SetAttribute('initial-width', 230)
	end

	if(unit == 'target') then
		self.CPoints = self:CreateFontString(nil, 'OVERLAY', 'SubZoneTextFont')
		self.CPoints:SetPoint('RIGHT', self, 'LEFT', -9, 0)
		self.CPoints:SetTextColor(1, 1, 1)
		self.CPoints:SetJustifyH('RIGHT')
		self.CPoints.unit = PlayerFrame.unit
		self:RegisterEvent('UNIT_COMBO_POINTS', updateCombo)

		self.Debuffs = CreateFrame('Frame', nil, self)
		self.Debuffs:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', -1, -2)
		self.Debuffs:SetHeight(22 * 0.97)
		self.Debuffs:SetWidth(230)
		self.Debuffs.num = 20
		self.Debuffs.size = 22 * 0.97
		self.Debuffs.spacing = 2
		self.Debuffs.initialAnchor = 'TOPLEFT'
		self.Debuffs['growth-y'] = 'DOWN'
		self.PostCreateAuraIcon = createAura
		self.PostUpdateAuraIcon = updateDebuff
	end

	self.DebuffHighlightBackdrop = true
	self.DebuffHighlightFilter = true
end

oUF:RegisterStyle('P3lim', styleFunction)
oUF:SetActiveStyle('P3lim')

oUF:Spawn('player'):SetPoint('CENTER', UIParent, -220, -250)
oUF:Spawn('target'):SetPoint('CENTER', UIParent, 220, -250)
oUF:Spawn('targettarget'):SetPoint('BOTTOMRIGHT', oUF.units.target, 'TOPRIGHT', 0, 5)
oUF:Spawn('focus'):SetPoint('BOTTOMLEFT', oUF.units.player, 'TOPLEFT', 0, 5)
oUF:Spawn('pet'):SetPoint('RIGHT', oUF.units.player, 'LEFT', -25, 0)
