oUF.colors.power[0] = { r = 0.0, g = 0.8, b = 1.0 }

local function menu(self)
	local unit = self.unit:sub(1, -2)
	local cunit = self.unit:gsub('(.)', string.upper, 1)

	if(unit == 'party' or unit == 'partypet') then
		ToggleDropDownMenu(1, nil, _G['PartyMemberFrame'..self.id..'DropDown'], 'cursor', 0, 0)
	elseif(_G[cunit..'FrameDropDown']) then
		ToggleDropDownMenu(1, nil, _G[cunit..'FrameDropDown'], 'cursor', 0, 0)
	end
end

local classification = {
	worldboss = 'B',
	rareelite = '%s R',
	elite = '%s+',
	rare = '%s r',
	normal = '%s',
	trivial = '%s',
}

local function updateColor(self, element, unit, func)
	local color
	if(UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) or not UnitIsConnected(unit)) then
		color = self.colors.health[1]
	elseif(unit == 'pet') then
		color = self.colors.happiness[GetPetHappiness()]
	elseif(UnitIsPlayer(unit)) then
		color = RAID_CLASS_COLORS[select(2, UnitClass(unit))]
	else
		color = UnitReactionColor[UnitReaction(unit, 'player')] or self.colors.health[1]
	end

	if(color) then
		if(func == 'SetVertexColor') then
			element[func](element, color.r * 0.3, color.g * 0.3, color.b * 0.3)
		else
			element[func](element, color.r, color.g, color.b)
		end
	end
end

local function updateName(self, event, unit)
	if(self.unit ~= unit) then return end
	if(unit == 'target') then
		local level = UnitLevel(unit) < 0 and '??' or UnitLevel(unit)

		if(UnitIsPlayer(unit)) then
			self.Name:SetTextColor(1, 1, 1)
			self.Name:SetFormattedText('%s |cff0090ff%s|r', UnitName(unit), level)
		else
			updateColor(self, self.Name, unit, 'SetTextColor')
			self.Name:SetFormattedText('%s |cff0090ff%s|r', UnitName(unit), format(classification[UnitClassification(unit)], level))
		end
	else
		self.Name:SetText(UnitName(unit))
	end
end

local function updateHappiness(self, event, unit)
	if(unit == self.unit) then
		updateColor(self, self.Power, unit, 'SetStatusBarColor')
	end
end

local function updateHealth(self, event, bar, unit, min, max)
	if(UnitIsDead(unit)) then
		bar.value:SetText('Dead')
	elseif(UnitIsGhost(unit)) then
		bar.value:SetText('Ghost')
	elseif(not UnitIsConnected(unit)) then
		bar.value:SetText('Offline')
	else
		if(unit == 'target' and UnitClassification('target') == 'worldboss') then
			bar.value:SetFormattedText("%d (%d|cff0090ff%%|r)", min, floor(min/max*100)) -- show percentages on raid bosses
		else
			if(min ~= max) then
				if(unit == 'player') then
					bar.value:SetFormattedText('|cffff8080%d|r |cff0090ff/|r %d|cff0090ff%%|r', min-max, floor(min/max*100))
				else
					bar.value:SetFormattedText('%d |cff0090ff/|r %d', min, max)
				end
			else
				bar.value:SetText(max)
			end
		end
	end

	if(UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) or not UnitIsConnected(unit)) then
		self.Power:SetStatusBarColor(0.6, 0.6, 0.6)
	else
		self:UNIT_NAME_UPDATE(event, unit)
	end
end

local function updatePower(self, event, bar, unit, min, max)
	updateColor(self, bar, unit, 'SetStatusBarColor')
	updateColor(self, bar.bg, unit, 'SetVertexColor')

	if(not bar.value) then return end
	if(not UnitIsPlayer(unit)) then
		bar.value:SetText()
	else
		if(min == 0) then
			bar.value:SetText()
		elseif(UnitIsDead(unit) or UnitIsGhost(unit)) then
			bar:SetValue(0)
		elseif(not UnitIsConnected(unit)) then
			bar.value:SetText()
		else
			if(unit ~= 'player') then
				if(min ~= max) then
					bar.value:SetFormattedText('%d|cff0090ff - |r', max-(max-min))
				else
					bar.value:SetFormattedText('%d|cff0090ff - |r', min)
				end
			else
				if(min ~= max) then
					bar.value:SetText(max-(max-min))
				else
					bar.value:SetText(min)
				end
			end
		end
	end
end

local function auraIcon(self, button, icons, index, debuff)
	button.cd:SetReverse()
--	button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
end

local function style(settings, self, unit)
	self.menu = menu
	self:RegisterForClicks('AnyUp')
	self:SetAttribute('*type2', 'menu')
	self:SetScript('OnEnter', UnitFrame_OnEnter)
	self:SetScript('OnLeave', UnitFrame_OnLeave)

	self:SetBackdrop({bgFile = 'Interface\\ChatFrame\\ChatFrameBackground', insets = {top = -1, left = -1, bottom = -1, right = -1}})
	self:SetBackdropColor(0, 0, 0, 1)

	self.Health = CreateFrame('StatusBar', nil, self)
	self.Health:SetStatusBarTexture('Interface\\AddOns\\oUF_P3lim\\minimalist')
	self.Health:SetStatusBarColor(0.25, 0.25, 0.35)
	self.Health:SetHeight(unit and 22 or 16)
	self.Health:SetPoint('TOPLEFT')
	self.Health:SetPoint('TOPRIGHT')

	self.Health.bg = self.Health:CreateTexture(nil, 'BORDER')
	self.Health.bg:SetAllPoints(self.Health)
	self.Health.bg:SetTexture(0.25 * 1.2, 0.25 * 1.2, 0.35 * 0.8)

	self.Health.value = self.Health:CreateFontString(nil, 'OVERLAY')
	self.Health.value:SetFontObject(GameFontNormalSmall)
	self.Health.value:SetPoint('RIGHT', -2, -1)
	self.Health.value:SetTextColor(1, 1, 1)
	self.Health.value:SetJustifyH('RIGHT')

	self.Power = CreateFrame('StatusBar', nil, self)
	self.Power:SetStatusBarTexture('Interface\\AddOns\\oUF_P3lim\\minimalist')
	self.Power:SetHeight(4)
	self.Power:SetPoint('TOPLEFT', self.Health, 'BOTTOMLEFT', 0, -1)
	self.Power:SetPoint('TOPRIGHT', self.Health, 'BOTTOMRIGHT', 0, -1)

	self.Power.bg = self.Power:CreateTexture(nil, 'BACKGROUND')
	self.Power.bg:SetAllPoints(self.Power)
	self.Power.bg:SetTexture('Interface\\ChatFrame\\ChatFrameBackground')

	self.Power.value = self.Health:CreateFontString(nil, 'OVERLAY')
	self.Power.value:SetFontObject(GameFontNormalSmall)
	self.Power.value:SetPoint('LEFT', 2, -1)
	self.Power.value:SetTextColor(1, 1, 1)

	self.Leader = self.Health:CreateTexture(nil, 'OVERLAY')
	self.Leader:SetHeight(16)
	self.Leader:SetWidth(16)
	self.Leader:SetPoint('TOPLEFT', self, 0, 8)
	self.Leader:SetTexture('Interface\\GroupFrame\\UI-Group-LeaderIcon')

	self.RaidIcon = self.Health:CreateTexture(nil, 'OVERLAY')
	self.RaidIcon:SetHeight(16)
	self.RaidIcon:SetWidth(16)
	self.RaidIcon:SetPoint('TOP', self, 0, 8)
	self.RaidIcon:SetTexture('Interface\\TargetingFrame\\UI-RaidTargetingIcons')

	self.Name = self.Health:CreateFontString(nil, 'OVERLAY')
	self.Name:SetFontObject(GameFontNormalSmall)
	self.Name:SetPoint('LEFT', 2, -1)
	self.Name:SetTextColor(1, 1, 1)

	if(unit == 'player') then
		self.Spark = self.Power:CreateTexture(nil, 'OVERLAY')
		self.Spark:SetTexture('Interface\\CastingBar\\UI-CastingBar-Spark')
		self.Spark:SetBlendMode('ADD')
		self.Spark:SetHeight(8)
		self.Spark:SetWidth(8)
		self.Spark.manatick = true

		self.Name:Hide()
	end

	if(unit == 'target') then
		if(select(2, UnitClass('player')) == 'ROGUE' or select(2, UnitClass('player')) == 'DRUID') then
			self.CPoints = self:CreateFontString(nil, 'OVERLAY')
			self.CPoints:SetPoint('RIGHT', self, 'LEFT', -9, 0)
			self.CPoints:SetFontObject(SubZoneTextFont)
			self.CPoints:SetTextColor(1, 1, 1)
			self.CPoints:SetJustifyH('RIGHT')
		end

		self.Power.value:Hide()

		self.Buffs = CreateFrame('Frame', nil, self)
		self.Buffs:SetPoint('TOPLEFT', self, 'TOPRIGHT', 2, 0)
		self.Buffs:SetHeight(22 * 2)
		self.Buffs:SetWidth(230)
		self.Buffs.size = 22
		self.Buffs.spacing = 2
		self.Buffs.initialAnchor = 'TOPLEFT'
		self.Buffs['growth-y'] = 'DOWN'

		self.Debuffs = CreateFrame('Frame', nil, self)
		self.Debuffs:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -2)
		self.Debuffs:SetHeight(22)
		self.Debuffs:SetWidth(230)
		self.Debuffs.size = 22
		self.Debuffs.spacing = 2
		self.Debuffs.initialAnchor = 'TOPLEFT'
		self.Debuffs.showDebuffType = true
		self.Debuffs['growth-y'] = 'DOWN'
	end

	if(unit == 'pet') then
		self.UNIT_HAPPINESS = updateHappiness
	end

	if(settings.units == 'fotot') then
		self.Health:SetHeight(20)
		self.Health.value:SetPoint('RIGHT', -2, -1)
		self.Power.value:Hide()
		self.Power:Hide()

		self.Debuffs = CreateFrame('Frame', nil, self)
		self.Debuffs:SetHeight(20)
		self.Debuffs:SetWidth(180)
		self.Debuffs.size = 22
		self.Debuffs.spacing = 2
		self.Debuffs.showDebuffType = true
		self.Debuffs.num = 2

		if(unit == 'focus') then
			self.Debuffs:SetPoint('TOPLEFT', self, 'TOPRIGHT', 2, 0)
			self.Debuffs.initialAnchor = 'TOPLEFT'
		elseif(unit == 'targettarget') then
			self.Debuffs:SetPoint('TOPRIGHT', self, 'TOPLEFT', -2, 0)
			self.Debuffs.initialAnchor = 'TOPRIGHT'
			self.Debuffs['growth-x'] = 'LEFT'
		end
	end

	if(settings.units == 'party') then
		self.Power.value:Hide()
		self.outsideRangeAlpha = 0.4
		self.inRangeAlpha = 1.0
		self.Range = true
	end

	self.UNIT_NAME_UPDATE = updateName
	self.PostCreateAuraIcon = auraIcon
	self.OverrideUpdatePower = updatePower
	self.OverrideUpdateHealth = updateHealth

	return self
end

oUF:RegisterSubTypeMapping('UNIT_LEVEL')
oUF:RegisterStyle('P3lim', setmetatable({
	['initial-width'] = 230,
	['initial-height'] = 27,
}, {__call = style }))
oUF:RegisterStyle('P3limPet', setmetatable({
	['initial-width'] = 130,
	['initial-height'] = 27,
}, {__call = style }))
oUF:RegisterStyle('P3limFoToT', setmetatable({
	['initial-width'] = 180,
	['initial-height'] = 21,
	['units'] = 'fotot',
}, {__call = style }))
oUF:RegisterStyle('P3limParty', setmetatable({
	['initial-width'] = 180,
	['initial-height'] = 21,
	['units'] = 'party',
}, {__call = style }))

oUF:SetActiveStyle('P3lim')
oUF:Spawn('player'):SetPoint('CENTER', UIParent, -220, -250)
oUF:Spawn('target'):SetPoint('CENTER', UIParent, 220, -250)

oUF:SetActiveStyle('P3limPet')
oUF:Spawn('pet'):SetPoint('RIGHT', oUF.units.player, 'LEFT', -25, 0)

oUF:SetActiveStyle('P3limFoToT')
oUF:Spawn('targettarget'):SetPoint('BOTTOMRIGHT', oUF.units.target, 'TOPRIGHT', 0, 5)
oUF:Spawn('focus'):SetPoint('BOTTOMLEFT', oUF.units.player, 'TOPLEFT', 0, 5)

oUF:SetActiveStyle('P3limParty')
local party = oUF:Spawn('header', 'oUF_Party')
party:SetPoint('TOPLEFT', UIParent, 15, -15)
party:SetManyAttributes('yOffset', -5, 'showParty', true, 'showPlayer', true)

local partyToggle = CreateFrame('Frame')
partyToggle:RegisterEvent('PLAYER_LOGIN')
partyToggle:RegisterEvent('RAID_ROSTER_UPDATE')
partyToggle:RegisterEvent('PARTY_LEADER_CHANGED')
partyToggle:RegisterEvent('PARTY_MEMBER_CHANGED')
partyToggle:SetScript('OnEvent', function(self)
	if(InCombatLockdown()) then
		self:RegisterEvent('PLAYER_REGEN_ENABLED')
	else
		self:UnregisterEvent('PLAYER_REGEN_DISABLED')
		if(HIDE_PARTY_INTERFACE == "1" and GetNumRaidMembers() > 0) then
			party:Hide()
		else
			party:Show()
		end
	end
end)