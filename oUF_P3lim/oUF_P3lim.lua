oUF.colors.power[0] = {0, 144/255, 1}

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
	worldboss = 'Boss',
	rareelite = '%s+ Rare',
	elite = '%s+',
	rare = '%s Rare',
	normal = '%s',
	trivial = '%s',
}

local function updateColor(self, element, unit, func)
	local color
	if(UnitIsPlayer(unit)) then
		return element[func](element, 1, 1, 1)
	elseif(UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit)) then
		color = self.colors.tapped
	elseif(not UnitIsConnected(unit)) then
		color = self.colors.disconnected
	else
		color = self.colors.reaction[UnitReaction(unit, 'player')]
	end

	if(color) then
		element[func](element, color[1], color[2], color[3])
	end
end

local function updateName(self, event, unit)
	if(self.unit == unit) then
		updateColor(self, self.Name, unit, 'SetTextColor')

		if(unit == 'player' or unit == 'pet') then
			self.Name:Hide()
		elseif(unit == 'target') then
			local level = UnitLevel(unit) < 0 and '??' or UnitLevel(unit)
			self.Name:SetFormattedText('%s |cff0090ff%s|r', UnitName(unit), format(classification[UnitClassification(unit)], level))
		else
			self.Name:SetText(UnitName(unit))
		end
	end
end

local function updateHealth(self, event, unit, bar, min, max)
	if(UnitIsDead(unit)) then
		bar.value:SetText('Dead')
	elseif(UnitIsGhost(unit)) then
		bar.value:SetText('Ghost')
	elseif(not UnitIsConnected(unit)) then
		bar.value:SetText('Offline')
	else
		if(unit == 'target' and UnitClassification('target') == 'worldboss') then
			bar.value:SetFormattedText('%d (%d|cff0090ff%%|r)', min, floor(min/max*100)) -- show percentages on raid bosses
		else
			if(min ~= max) then
				if(unit == 'player' or unit:match('^party')) then
					bar.value:SetFormattedText('|cffff8080%d|r |cff0090ff/|r %d|cff0090ff%%|r', min-max, floor(min/max*100))
				else
					bar.value:SetFormattedText('%d |cff0090ff/|r %d', min, max)
				end
			else
				bar.value:SetText(max)
			end
		end
	end

	self:UNIT_NAME_UPDATE(self, event, unit)
end

local function updatePower(self, event, unit, bar, min, max)
	if(unit ~= 'player' and unit ~= 'pet') then
		bar.value:Hide()
	else
		local color = self.colors.power[UnitPowerType(unit)]
		if(min == 0) then
			bar.value:SetText()
		elseif(UnitIsDead(unit) or UnitIsGhost(unit)) then
			bar:SetValue(0)
		elseif(not UnitIsConnected(unit)) then
			bar.value:SetText()
		elseif(not UnitIsPlayer(unit)) then
			bar.value:SetText()
		else
			bar.value:SetTextColor(color[1], color[2], color[3])
			if(min ~= max) then
				bar.value:SetText(max-(max-min))
			else
				bar.value:SetText(min)
			end
		end
	end

	self.UNIT_NAME_UPDATE(self, event, unit)
end

local function auraIcon(self, button, icons, index, debuff)
	icons.showDebuffType = true
	button.cd:SetReverse()
	button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	button.overlay:SetTexture([[Interface\AddOns\oUF_P3lim\border]])
	button.overlay:SetTexCoord(0.0, 1.0, 0.0, 1.0)
	button.overlay.Hide = function(self) self:SetVertexColor(0.25, 0.25, 0.25) end
end

local function styleFunc(self, unit)
	local _, class = UnitClass('player')

	self.menu = menu
	self:RegisterForClicks('AnyUp')
	self:SetAttribute('*type2', 'menu')
	self:SetScript('OnEnter', UnitFrame_OnEnter)
	self:SetScript('OnLeave', UnitFrame_OnLeave)

	self:SetBackdrop({bgFile = [[Interface\ChatFrame\ChatFrameBackground]], insets = {top = -1, left = -1, bottom = -1, right = -1}})
	self:SetBackdropColor(0.0, 0.0, 0.0, 1.0)

	self.Health = CreateFrame('StatusBar', nil, self)
	self.Health:SetStatusBarTexture([[Interface\AddOns\oUF_P3lim\minimalist]])
	self.Health:SetStatusBarColor(0.25, 0.25, 0.35)
	self.Health:SetHeight(unit and 22 or 18)
	self.Health:SetPoint('TOPLEFT', self)
	self.Health:SetPoint('TOPRIGHT', self)

	self.Health.bg = self.Health:CreateTexture(nil, 'BORDER')
	self.Health.bg:SetAllPoints(self.Health)
	self.Health.bg:SetTexture(0.3, 0.3, 0.3)

	self.Health.value = self.Health:CreateFontString(nil, 'OVERLAY')
	self.Health.value:SetFontObject(GameFontNormalSmall)
	self.Health.value:SetPoint('RIGHT', self.Health, -2, -1)
	self.Health.value:SetTextColor(1, 1, 1)
	self.Health.value:SetJustifyH('RIGHT')

	self.Power = CreateFrame('StatusBar', nil, self)
	self.Power:SetStatusBarTexture([[Interface\AddOns\oUF_P3lim\minimalist]])
	self.Power:SetHeight(unit and 4 or 2)
	self.Power:SetPoint('TOPLEFT', self.Health, 'BOTTOMLEFT', 0, -1)
	self.Power:SetPoint('TOPRIGHT', self.Health, 'BOTTOMRIGHT', 0, -1)
	self.Power.colorTapping = true
	self.Power.colorDisconnected = true
	self.Power.colorClass = true
	self.Power.colorReaction = true

	self.Power.bg = self.Power:CreateTexture(nil, 'BACKGROUND')
	self.Power.bg:SetAllPoints(self.Power)
	self.Power.bg:SetTexture([[Interface\ChatFrame\ChatFrameBackground]])
	self.Power.bg:SetAlpha(0.3)

	self.Power.value = self.Power:CreateFontString(nil, 'OVERLAY')
	self.Power.value:SetFontObject(GameFontNormalSmall)
	self.Power.value:SetPoint('LEFT', self.Health, 2, -1)
	self.Power.value:SetTextColor(1, 1, 1)

	self.Leader = self.Health:CreateTexture(nil, 'OVERLAY')
	self.Leader:SetHeight(16)
	self.Leader:SetWidth(16)
	self.Leader:SetPoint('TOPLEFT', self, 0, 8)
	self.Leader:SetTexture([[Interface\GroupFrame\UI-Group-LeaderIcon]])

	self.RaidIcon = self.Health:CreateTexture(nil, 'OVERLAY')
	self.RaidIcon:SetHeight(16)
	self.RaidIcon:SetWidth(16)
	self.RaidIcon:SetPoint('TOP', self, 0, 8)
	self.RaidIcon:SetTexture([[Interface\TargetingFrame\UI-RaidTargetingIcons]])

	self.Name = self.Health:CreateFontString(nil, 'OVERLAY')
	self.Name:SetFontObject(GameFontNormalSmall)
	self.Name:SetPoint('LEFT', self.Health, 2, -1)
	self.Name:SetTextColor(1, 1, 1)

	if(unit == 'player') then
		self.Spark = self.Power:CreateTexture(nil, 'OVERLAY')
		self.Spark:SetTexture([[Interface\CastingBar\UI-CastingBar-Spark]])
		self.Spark:SetBlendMode('ADD')
		self.Spark:SetHeight(8)
		self.Spark:SetWidth(8)
		self.Spark.manatick = true

		if(class == 'DRUID') then
			self.DruidManaBar = CreateFrame('StatusBar', nil, self)
			self.DruidManaBar:SetHeight(1)
			self.DruidManaBar:SetStatusBarTexture([[Interface\AddOns\oUF_P3lim\minimalist]])
			self.DruidManaBar:SetPoint('BOTTOMRIGHT', self.Power, 'TOPRIGHT')
			self.DruidManaBar:SetPoint('BOTTOMLEFT', self.Power, 'TOPLEFT')

			self.DruidManaText = self.DruidManaBar:CreateFontString(nil, 'OVERLAY')
			self.DruidManaText:SetFontObject(GameFontNormalSmall)
			self.DruidManaText:SetPoint('CENTER', self.DruidManaBar)
		end
	end

	if(unit == 'target') then
		if(class == 'ROGUE' or class == 'DRUID') then
			self.CPoints = self:CreateFontString(nil, 'OVERLAY')
			self.CPoints:SetPoint('RIGHT', self, 'LEFT', -9, 0)
			self.CPoints:SetFontObject(SubZoneTextFont)
			self.CPoints:SetTextColor(1, 1, 1)
			self.CPoints:SetJustifyH('RIGHT')
		end

		self.Buffs = CreateFrame('Frame', nil, self)
		self.Buffs:SetPoint('TOPLEFT', self, 'TOPRIGHT', 2, 1)
		self.Buffs:SetHeight(24 * 2)
		self.Buffs:SetWidth(270)
		self.Buffs.num = 20
		self.Buffs.size = 24
		self.Buffs.spacing = 2
		self.Buffs.initialAnchor = 'TOPLEFT'
		self.Buffs['growth-y'] = 'DOWN'

		self.Debuffs = CreateFrame('Frame', nil, self)
		self.Debuffs:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', -1, -2)
		self.Debuffs:SetHeight(22 * 0.97)
		self.Debuffs:SetWidth(230)
		self.Debuffs.size = 22 * 0.97
		self.Debuffs.spacing = 2
		self.Debuffs.initialAnchor = 'TOPLEFT'
		self.Debuffs.showDebuffType = true
		self.Debuffs['growth-y'] = 'DOWN'
	end

	if(unit == 'pet') then
		if(class == 'HUNTER') then
			self.Power.colorHappiness = true
			self:RegisterEvent('UNIT_HAPPINESS')
			self.UNIT_HAPPINESS = self.UNIT_MANA
		end

		self:SetAttribute('initial-height', 27)
		self:SetAttribute('initial-width', 130)
	end

	if(unit == 'focus' or unit == 'targettarget') then
		self.Power:Hide()
		self.Health:SetHeight(20)

		self.Debuffs = CreateFrame('Frame', nil, self)
		self.Debuffs:SetHeight(23)
		self.Debuffs:SetWidth(180)
		self.Debuffs.size = 23
		self.Debuffs.spacing = 2
		self.Debuffs.showDebuffType = true
		self.Debuffs.num = 2

		if(unit == 'focus') then
			self.Debuffs:SetPoint('TOPLEFT', self, 'TOPRIGHT', 2, 1)
			self.Debuffs.initialAnchor = 'TOPLEFT'
		elseif(unit == 'targettarget') then
			self.Debuffs:SetPoint('TOPRIGHT', self, 'TOPLEFT', -2, 1)
			self.Debuffs.initialAnchor = 'TOPRIGHT'
			self.Debuffs['growth-x'] = 'LEFT'
		end

		self:SetAttribute('initial-height', 21)
		self:SetAttribute('initial-width', 181)
	end

	if(unit == 'player' or unit == 'target') then
		self.CombatFeedbackText = self.Health:CreateFontString(nil, 'OVERLAY')
		self.CombatFeedbackText:SetPoint('CENTER', self)
		self.CombatFeedbackText:SetFontObject(GameFontNormal)

		self.Castbar = CreateFrame('StatusBar', nil, self)
		self.Castbar:SetPoint('TOP', self, 'BOTTOM', 0, -100)
		self.Castbar:SetWidth(230)
		self.Castbar:SetHeight(22)
		self.Castbar:SetStatusBarTexture([[Interface\AddOns\oUF_P3lim\minimalist]])
		self.Castbar:SetStatusBarColor(0.25, 0.25, 0.35)
		self.Castbar:SetBackdrop({bgFile = [[Interface\ChatFrame\ChatFrameBackground]], insets = {top = -1, left = -1, bottom = -1, right = -1}})
		self.Castbar:SetBackdropColor(0.0, 0.0, 0.0, 1.0)

		self.Castbar.bg = self.Castbar:CreateTexture(nil, 'BACKGROUND')
		self.Castbar.bg:SetAllPoints(self.Castbar)
		self.Castbar.bg:SetTexture(0.3, 0.3, 0.3)

		self.Castbar.text = self.Castbar:CreateFontString(nil, 'OVERLAY')
		self.Castbar.text:SetPoint('LEFT', self.Castbar, 2, -1)
		self.Castbar.text:SetFontObject(GameFontNormalSmall)
		self.Castbar.text:SetTextColor(1, 1, 1)
		self.Castbar.text:SetJustifyH('LEFT')

		self.Castbar.casttime = self.Castbar:CreateFontString(nil, 'OVERLAY')
		self.Castbar.casttime:SetPoint('RIGHT', self.Castbar, -2, -1)
		self.Castbar.casttime:SetFontObject(GameFontNormalSmall)
		self.Castbar.casttime:SetTextColor(1, 1, 1)
		self.Castbar.casttime:SetJustifyH('RIGHT')

		self:SetAttribute('initial-height', 27)
		self:SetAttribute('initial-width', 230)
	end

	if(not unit) then
		self.outsideRangeAlpha = 0.4
		self.inRangeAlpha = 1.0
		self.Range = true

		self.ReadyCheck = self.Health:CreateTexture(nil, 'OVERLAY')
		self.ReadyCheck:SetPoint('TOPRIGHT', self, 0, 8)
		self.ReadyCheck:SetHeight(16)
		self.ReadyCheck:SetWidth(16)

		self:SetAttribute('initial-height', 21)
		self:SetAttribute('initial-width', 181)
	end

	self.DebuffHighlightBackdrop = true
	self.DebuffHighlightFilter = true
	self.Banzai = function(self, unit, aggro)
		if(aggro == 1) then
			self.Health:SetStatusBarColor(1, 0, 0)
		else
			self.Health:SetStatusBarColor(0.25, 0.25, 0.35)
		end
	end

	self.UNIT_NAME_UPDATE = updateName
	self.PostCreateAuraIcon = auraIcon
	self.PostUpdateHealth = updateHealth
	self.PostUpdatePower = updatePower

	return self
end

oUF:RegisterSubTypeMapping('UNIT_LEVEL')
oUF:RegisterStyle('P3lim', styleFunc)

oUF:SetActiveStyle('P3lim')

oUF:Spawn('player'):SetPoint('CENTER', UIParent, -220, -250)
oUF:Spawn('target'):SetPoint('CENTER', UIParent, 220, -250)
oUF:Spawn('pet'):SetPoint('RIGHT', oUF.units.player, 'LEFT', -25, 0)
oUF:Spawn('focus'):SetPoint('BOTTOMLEFT', oUF.units.player, 'TOPLEFT', 0, 5)
oUF:Spawn('targettarget'):SetPoint('BOTTOMRIGHT', oUF.units.target, 'TOPRIGHT', 0, 5)

local party = oUF:Spawn('header', 'oUF_Party')
party:SetPoint('TOPLEFT', UIParent, 15, -15)
party:SetManyAttributes('yOffset', -5, 'showParty', true)

local partyToggle = CreateFrame('Frame')
partyToggle:RegisterEvent('PLAYER_LOGIN')
partyToggle:RegisterEvent('RAID_ROSTER_UPDATE')
partyToggle:RegisterEvent('PARTY_LEADER_CHANGED')
partyToggle:RegisterEvent('PARTY_MEMBER_CHANGED')
partyToggle:SetScript('OnEvent', function(self)
	if(InCombatLockdown()) then
		self:RegisterEvent('PLAYER_REGEN_ENABLED')
	else
		self:UnregisterEvent('PLAYER_REGEN_ENABLED')
		if(GetNumRaidMembers() > 0) then
			party:Hide()
		else
			party:Show()
		end
	end
end)