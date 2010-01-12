--[[

  Adrian L Lange grants anyone the right to use this work for any purpose,
  without any conditions, unless such conditions are required by law.

--]]

local max = math.max
local floor = math.floor

local minimalist = [=[Interface\AddOns\oUF_P3lim\media\minimalist]=]
local backdrop = {
	bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
	insets = {top = -1, bottom = -1, left = -1, right = -1}
}

local playerUnits = {
	player = true,
	pet = true,
	vehicle = true,
}

local colors = setmetatable({
	power = setmetatable({
		MANA = {0, 144/255, 1}
	}, {__index = oUF.colors.power}),
	reaction = setmetatable({
		[2] = {1, 0, 0},
		[4] = {1, 1, 0},
		[5] = {0, 1, 0}
	}, {__index = oUF.colors.reaction}),
}, {__index = oUF.colors})

local buffFilter = {
	[52610] = true, -- Druid: Savage Roar
	[22812] = true, -- Druid: Barkskin
	[16870] = true, -- Druid: Clearcast
	[50213] = true, -- Druid: Tiger's Fury
	[48517] = true, -- Druid: Eclipse (Solar)
	[48518] = true, -- Druid: Eclipse (Lunar)
	[57960] = true, -- Shaman: Water Shield
	[53390] = true, -- Shaman: Tidal Waves (Talent)
	[32182] = true, -- Shaman: Heroism
	[49016] = true, -- Death Knight: Hysteria
	[50334] = true, -- Enchant: Berserk
}

local debuffFilter = {
	[770] = true, -- Faerie Fire
	[16857] = true, -- Faerie Fire (Feral)
	[48564] = true, -- Mangle (Bear)
	[48566] = true, -- Mangle (Cat)
	[46857] = true, -- Trauma
}

local function menu(self)
	if(self.unit == 'player') then
		ToggleDropDownMenu(1, nil, oUF_P3lim_DropDown, 'cursor')
	elseif(_G[string.gsub(self.unit, '(.)', string.upper, 1) .. 'FrameDropDown']) then
		ToggleDropDownMenu(1, nil, _G[string.gsub(self.unit, '(.)', string.upper, 1) .. 'FrameDropDown'], 'cursor')
	end
end

local function updateCombo(self, event, unit)
	if(unit == PlayerFrame.unit and unit ~= self.CPoints.unit) then
		self.CPoints.unit = unit
	end
end

local function updatePower(self, event, unit, bar, minVal, maxVal)
	if(maxVal ~= 0) then
		self.Health:SetHeight(20)
		bar:Show()
	else
		self.Health:SetHeight(22)
		bar:Hide()
	end
end

local function castIcon(self, event, unit)
	local castbar = self.Castbar
	if(castbar.interrupt) then
		castbar.Icon:SetVertexColor(1, 0, 0)
	else
		castbar.Icon:SetVertexColor(1, 1, 1)
	end
end

local function castTime(self, duration)
	if(self.channeling) then
		self.Time:SetFormattedText('%.1f ', duration)
	elseif(self.casting) then
		self.Time:SetFormattedText('%.1f ', self.max - duration)
	end
end

local function updateDebuff(self, icons, unit, icon, index)
	local name, _, _, _, dtype, _, _, owner, _, _, spellid = UnitAura(unit, index, icon.filter)

	if(icon.debuff) then
		if(UnitIsFriend('player', unit) or debuffFilter[spellid] or playerUnits[owner]) then
			local color = DebuffTypeColor[dtype] or DebuffTypeColor.none
			icon:SetBackdropColor(color.r * 0.6, color.g * 0.6, color.b * 0.6)
			icon.icon:SetDesaturated(false)
		else
			icon:SetBackdropColor(0, 0, 0)
			icon.icon:SetDesaturated(true)
		end
	end
end

local function createAura(self, button, icons)
	button.cd:SetReverse()
	button:SetBackdrop(backdrop)
	button:SetBackdropColor(0, 0, 0)
	button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	button.icon:SetDrawLayer('ARTWORK')
end

local function customFilter(icons, unit, icon, ...)
	local _, _, _, _, _, _, _, owner, _, _, spellid = ...
	if(buffFilter[spellid] and owner == 'player') then
		return true
	end
end

local function style(self, unit)
	self.colors = colors
	self.menu = menu

	self:RegisterForClicks('AnyUp')
	self:SetAttribute('type2', 'menu')

	self:SetScript('OnEnter', UnitFrame_OnEnter)
	self:SetScript('OnLeave', UnitFrame_OnLeave)

	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0, 0, 0)

	self.Health = CreateFrame('StatusBar', nil, self)
	self.Health:SetPoint('TOPRIGHT')
	self.Health:SetPoint('TOPLEFT')
	self.Health:SetStatusBarTexture(minimalist)
	self.Health:SetStatusBarColor(0.25, 0.25, 0.35)
	self.Health:SetHeight((unit == 'focus' or unit == 'targettarget') and 19 or 20)
	self.Health.frequentUpdates = true

	self.Health.bg = self.Health:CreateTexture(nil, 'BORDER')
	self.Health.bg:SetAllPoints(self.Health)
	self.Health.bg:SetTexture(0.3, 0.3, 0.3)

	local health = self.Health:CreateFontString(nil, 'OVERLAY', 'pfontright')
	health:SetPoint('RIGHT', self.Health, -2, 0)
	health.frequentUpdates = 0.25
	self:Tag(health, '[phealth]')

	self.RaidIcon = self.Health:CreateTexture(nil, 'OVERLAY')
	self.RaidIcon:SetPoint('TOP', self, 0, 8)
	self.RaidIcon:SetHeight(16)
	self.RaidIcon:SetWidth(16)

	if(unit == 'focus' or unit == 'targettarget') then
		self:SetAttribute('initial-height', 19)
		self:SetAttribute('initial-width', 182)

		self.Debuffs = CreateFrame('Frame', nil, self)
		self.Debuffs:SetHeight(20)
		self.Debuffs:SetWidth(44)
		self.Debuffs.num = 2
		self.Debuffs.size = 20
		self.Debuffs.spacing = 4
		self.PostCreateAuraIcon = createAura

		if(unit == 'focus') then
			self.Debuffs:SetPoint('TOPLEFT', self, 'TOPRIGHT', 4, 0)
			self.Debuffs.onlyShowPlayer = true
			self.Debuffs.initialAnchor = 'TOPLEFT'
		else
			self.Debuffs:SetPoint('TOPRIGHT', self, 'TOPLEFT', -4, 0)
			self.Debuffs.initialAnchor = 'TOPRIGHT'
			self.Debuffs['growth-x'] = 'LEFT'
		end
	else
		self.Power = CreateFrame('StatusBar', nil, self)
		self.Power:SetPoint('BOTTOMRIGHT')
		self.Power:SetPoint('BOTTOMLEFT')
		self.Power:SetPoint('TOP', self.Health, 'BOTTOM', 0, -1)
		self.Power:SetStatusBarTexture(minimalist)
		self.Power.frequentUpdates = true

		self.Power.colorClass = true
		self.Power.colorTapping = true
		self.Power.colorDisconnected = true
		self.Power.colorReaction = unit ~= 'pet'
		self.Power.colorHappiness = unit == 'pet'
		self.Power.colorPower = unit == 'pet'

		self.Power.bg = self.Power:CreateTexture(nil, 'BORDER')
		self.Power.bg:SetAllPoints(self.Power)
		self.Power.bg:SetTexture([=[Interface\ChatFrame\ChatFrameBackground]=])
		self.Power.bg.multiplier = 0.3

		self.Castbar = CreateFrame('StatusBar', nil, self)
		self.Castbar:SetWidth(unit == 'pet' and 105 or 205)
		self.Castbar:SetHeight(16)
		self.Castbar:SetStatusBarTexture(minimalist)
		self.Castbar:SetStatusBarColor(0.25, 0.25, 0.35)
		self.Castbar:SetBackdrop(backdrop)
		self.Castbar:SetBackdropColor(0, 0, 0)

		self.Castbar.bg = self.Castbar:CreateTexture(nil, 'BORDER')
		self.Castbar.bg:SetAllPoints(self.Castbar)
		self.Castbar.bg:SetTexture(0.3, 0.3, 0.3)

		self.Castbar.Text = self.Castbar:CreateFontString(nil, 'OVERLAY', 'pfontleft')
		self.Castbar.Text:SetPoint('LEFT', 2, 0)
		self.Castbar.Text:SetPoint('RIGHT', self.Castbar.Time)

		self.Castbar.Time = self.Castbar:CreateFontString(nil, 'OVERLAY', 'pfontright')
		self.Castbar.Time:SetPoint('RIGHT', -2, 0)
		self.Castbar.CustomTimeText = castTime

		self.Castbar.Button = CreateFrame('Frame', nil, self.Castbar)
		self.Castbar.Button:SetHeight(21)
		self.Castbar.Button:SetWidth(21)
		self.Castbar.Button:SetBackdrop(backdrop)
		self.Castbar.Button:SetBackdropColor(0, 0, 0)

		self.Castbar.Icon = self.Castbar.Button:CreateTexture(nil, 'ARTWORK')
		self.Castbar.Icon:SetAllPoints(self.Castbar.Button)
		self.Castbar.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

		if(unit == 'target') then
			self.PostCastStart = castIcon
			self.PostChannelStart = castIcon
			self.Castbar:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -60)
			self.Castbar.Button:SetPoint('BOTTOMLEFT', self.Castbar, 'BOTTOMRIGHT', 4, 0)
		else
			self.Castbar:SetPoint('TOPRIGHT', self, 'BOTTOMRIGHT', 0, -60)
			self.Castbar.Button:SetPoint('BOTTOMRIGHT', self.Castbar, 'BOTTOMLEFT', -4, 0)
		end
	end

	if(unit == 'player' or unit == 'pet') then
		if(IsAddOnLoaded('oUF_Experience')) then
			self.Experience = CreateFrame('StatusBar', nil, self)
			self.Experience:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -10)
			self.Experience:SetPoint('TOPRIGHT', self, 'BOTTOMRIGHT', 0, -10)
			self.Experience:SetHeight(11)
			self.Experience:SetStatusBarTexture(minimalist)
			self.Experience:SetStatusBarColor(0.15, 0.7, 0.1)
			self.Experience.Tooltip = true

			self.Experience.Rested = CreateFrame('StatusBar', nil, self)
			self.Experience.Rested:SetAllPoints(self.Experience)
			self.Experience.Rested:SetStatusBarTexture(minimalist)
			self.Experience.Rested:SetStatusBarColor(0, 0.4, 1, 0.6)
			self.Experience.Rested:SetBackdrop(backdrop)
			self.Experience.Rested:SetBackdropColor(0, 0, 0)

			self.Experience.Text = self.Experience:CreateFontString(nil, 'OVERLAY', 'pfont')
			self.Experience.Text:SetPoint('CENTER', self.Experience)

			self.Experience.bg = self.Experience.Rested:CreateTexture(nil, 'BORDER')
			self.Experience.bg:SetAllPoints(self.Experience)
			self.Experience.bg:SetTexture(0.3, 0.3, 0.3)
		end

		local power = self.Health:CreateFontString(nil, 'OVERLAY', 'pfontleft')
		power:SetPoint('LEFT', self.Health, 2, 0)
		power.frequentUpdates = 0.1
		self:Tag(power, '[ppower][( )druidpower]')
	else
		local info = self.Health:CreateFontString(nil, 'OVERLAY', 'pfontleft')
		info:SetPoint('LEFT', self.Health, 2, 0)
		info:SetPoint('RIGHT', health, 'LEFT')
		self:Tag(info, '[pname]|cff0090ff[( )rare]|r')
	end

	if(unit == 'pet') then
		self:SetAttribute('initial-height', 22)
		self:SetAttribute('initial-width', 130)

		self.Auras = CreateFrame('Frame', nil, self)
		self.Auras:SetPoint('TOPRIGHT', self, 'TOPLEFT', -4, 0)
		self.Auras:SetHeight(4)
		self.Auras:SetWidth(256)
		self.Auras.size = 22
		self.Auras.spacing = 4
		self.Auras.initialAnchor = 'TOPRIGHT'
		self.Auras['growth-x'] = 'LEFT'
		self.PostCreateAuraIcon = createAura
	end

	if(unit == 'player' or unit == 'target') then
		self:SetAttribute('initial-height', 22)
		self:SetAttribute('initial-width', 230)

		self.Buffs = CreateFrame('Frame', nil, self)
		self.Buffs:SetPoint('TOPLEFT', self, 'TOPRIGHT', 4, 0)
		self.Buffs:SetHeight(44)
		self.Buffs:SetWidth(236)
		self.Buffs.num = 20
		self.Buffs.size = 20
		self.Buffs.spacing = 4
		self.Buffs.initialAnchor = 'TOPLEFT'
		self.Buffs['growth-y'] = 'DOWN'
		self.PostCreateAuraIcon = createAura
	end

	if(unit == 'target') then
		self.Debuffs = CreateFrame('Frame', nil, self)
		self.Debuffs:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -4)
		self.Debuffs:SetHeight(20 * 0.97)
		self.Debuffs:SetWidth(230)
		self.Debuffs.num = 20
		self.Debuffs.size = 20 * 0.97
		self.Debuffs.spacing = 4
		self.Debuffs.initialAnchor = 'TOPLEFT'
		self.Debuffs['growth-y'] = 'DOWN'
		self.PostCreateAuraIcon = createAura
		self.PostUpdateAuraIcon = updateDebuff

		self.CPoints = self:CreateFontString(nil, 'OVERLAY', 'SubZoneTextFont')
		self.CPoints:SetPoint('RIGHT', self, 'LEFT', -9, 0)
		self.CPoints:SetTextColor(1, 1, 1)
		self.CPoints:SetJustifyH('RIGHT')
		self.CPoints.unit = PlayerFrame.unit
		self:RegisterEvent('UNIT_COMBO_POINTS', updateCombo)

		self.PostUpdatePower = updatePower
	end

	if(unit == 'player') then
		self.Leader = self.Health:CreateTexture(nil, 'OVERLAY')
		self.Leader:SetPoint('TOPLEFT', self, 0, 8)
		self.Leader:SetHeight(16)
		self.Leader:SetWidth(16)

		self.Assistant = self.Health:CreateTexture(nil, 'OVERLAY')
		self.Assistant:SetPoint('TOPLEFT', self, 0, 8)
		self.Assistant:SetHeight(16)
		self.Assistant:SetWidth(16)

		local info = self.Health:CreateFontString(nil, 'OVERLAY', 'pfont')
		info:SetPoint('CENTER')
		info.frequentUpdates = 0.25
		self:Tag(info, '[pthreat]|cffff0000[( )pvptime]|r')

		self.CustomAuraFilter = customFilter
	end

	self.DebuffHighlightBackdrop = true
	self.DebuffHighlightFilter = true
end

oUF:RegisterStyle('P3lim', style)
oUF:SetActiveStyle('P3lim')

oUF:Spawn('player'):SetPoint('CENTER', -220, -250)
oUF:Spawn('target'):SetPoint('CENTER', 220, -250)
oUF:Spawn('targettarget'):SetPoint('CENTER', 244, -225)
oUF:Spawn('focus'):SetPoint('CENTER', -244, -225)
oUF:Spawn('pet'):SetPoint('CENTER', -410, -250)
