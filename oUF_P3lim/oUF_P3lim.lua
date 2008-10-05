local wotlk = select(4, GetBuildInfo()) >= 3e4
local _, class = UnitClass('player')
local texture = [=[Interface\AddOns\oUF_P3lim\minimalist]=]

local colors = setmetatable({
	power = setmetatable({
		['MANA'] = {0, 144/255, 1},
	}, {__index = oUF.colors.power}),
}, {__index = oUF.colors})
colors.power[0] = colors.power.MANA

oUF.Tags['[smartlevel]'] = function(u) return UnitClassification(u) == "worldboss" and "Boss" or oUF.Tags['[level]'](u) .. oUF.Tags["[plus]"](u) end

local function menu(self)
	local unit = self.unit:gsub('(.)', string.upper, 1)
	if(_G[unit..'FrameDropDown']) then
		ToggleDropDownMenu(1, nil, _G[unit..'FrameDropDown'], 'cursor')
	end
end

local function UpdateInfoColor(self, unit)
	if(self.Info) then
		local color = {1, 1, 1}
		if(UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit)) then
			color = self.colors.tapped
		elseif(UnitIsDead(unit) or UnitIsGhost(unit) or not UnitIsConnected(unit)) then
			color = self.colors.disconnected
		elseif(not UnitIsPlayer(unit)) then
			if(wotlk) then
				local r, g, b = UnitSelectionColor(unit)
				color = {r, g, b}
			else
				color = self.colors.reaction[UnitReaction(unit, 'player')] or self.colors.health
			end
		end

		self.Info:SetTextColor(unpack(color))
	end
end

local function PostUpdateHealth(self, event, unit, bar, min, max)
	if(not UnitIsConnected(unit)) then
		bar.text:SetText('Offline')
	elseif(UnitIsDead(unit)) then
		bar.text:SetText('Dead')
	elseif(UnitIsGhost(unit)) then
		bar.text:SetText('Ghost')
	else
		if(unit == 'target' and UnitClassification('target') == 'worldboss') then
			bar.text:SetFormattedText('%d (%d|cff0090ff%%|r)', min, floor(min/max*100))
		else
			if(min ~= max) then
				if(unit == 'player') then
					bar.text:SetFormattedText('|cffff8080%d|r %d|cff0090ff%%|r', min-max, floor(min/max*100))
				else
					bar.text:SetFormattedText('%d |cff0090ff/|r %d', min, max)
				end
			else
				bar.text:SetText(max)
			end
		end
	end

	bar:SetStatusBarColor(0.25, 0.25, 0.35)
	UpdateInfoColor(self, unit)
end

local function PostUpdatePower(self, event, unit, bar, min, max)
	if(bar.text) then
		if(min == 0) then
			bar.text:SetText()
		elseif(not UnitIsPlayer(unit) or not UnitIsConnected(unit)) then
			bar.text:SetText()
		else
			if(min ~= max) then
				bar.text:SetText(max-(max-min))
			else
				bar.text:SetText(min)
			end
		end

		local num, str = UnitPowerType(unit)
		local color = self.colors.power[wotlk and str or num]
		bar.text:SetTextColor(color[1], color[2], color[3])
	end

	UpdateInfoColor(self, unit)
end

local function PostCreateAuraIcon(self, button, icons, index, debuff)
	button.cd:SetReverse()
	button.overlay:SetTexture([=[Interface\AddOns\oUF_P3lim\border]=])
	button.overlay:SetTexCoord(0, 1, 0, 1)
	button.overlay.Hide = function(self) self:SetVertexColor(0.25, 0.25, 0.25) end
end

local function CreateStyle(self, unit)
	self.colors = colors
	self.menu = menu
	self:RegisterForClicks('AnyUp')
	self:SetAttribute('*type2', 'menu')
	self:SetScript('OnEnter', UnitFrame_OnEnter)
	self:SetScript('OnLeave', UnitFrame_OnLeave)

	self:SetBackdrop({bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=], insets = {top = -1, left = -1, bottom = -1, right = -1}})
	self:SetBackdropColor(0, 0, 0)

	self.Health = CreateFrame('StatusBar', nil, self)
	self.Health:SetPoint('TOPRIGHT', self)
	self.Health:SetPoint('TOPLEFT', self)
	self.Health:SetStatusBarTexture(texture)
	self.Health:SetHeight(22)

	self.Health.bg = self.Health:CreateTexture(nil, 'BORDER')
	self.Health.bg:SetAllPoints(self.Health)
	self.Health.bg:SetTexture(0.3, 0.3, 0.3)

	self.Health.text = self.Health:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
	self.Health.text:SetPoint('RIGHT', self.Health, -2, -1)
	self.Health.text:SetJustifyH('RIGHT')

	self.Power = CreateFrame('StatusBar', nil, self)
	self.Power:SetPoint('TOPRIGHT', self.Health, 'BOTTOMRIGHT', 0, -1)
	self.Power:SetPoint('TOPLEFT', self.Health, 'BOTTOMLEFT', 0, -1)
	self.Power:SetStatusBarTexture(texture)
	self.Power:SetHeight(4)

	self.Power.colorTapping = true
	self.Power.colorDisconnected = true
	self.Power.colorClass = true
	self.Power.colorReaction = true

	self.Power.bg = self.Power:CreateTexture(nil, 'BORDER')
	self.Power.bg:SetAllPoints(self.Power)
	self.Power.bg:SetTexture([=[Interface\ChatFrame\ChatFrameBackground]=])
	self.Power.bg.multiplier = 0.3

	self.Leader = self.Health:CreateTexture(nil, 'OVERLAY')
	self.Leader:SetPoint('TOPLEFT', self, 0, 8)
	self.Leader:SetHeight(16)
	self.Leader:SetWidth(16)

	self.RaidIcon = self.Health:CreateTexture(nil, 'OVERLAY')
	self.RaidIcon:SetPoint('TOP', self, 0, 8)
	self.RaidIcon:SetHeight(16)
	self.RaidIcon:SetWidth(16)

	if(wotlk) then
		self.Threat = self:CreateTexture(nil, 'OVERLAY')
		self.Threat:SetPoint('TOPRIGHT', self, 0, -8)
		self.Threat:SetHeight(20)
		self.Threat:SetWidth(20)
	end

	if(unit == 'player' or unit == 'pet') then
		self.Power.text = self.Power:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
		self.Power.text:SetPoint('LEFT', self.Health, 2, -1)

		self.barFade = true

		if(IsAddOnLoaded('oUF_Experience')) then
			self.Experience = CreateFrame('StatusBar', nil, self)
			self.Experience:SetPoint('TOP', self, 'BOTTOM', 0, -10)
			self.Experience:SetStatusBarTexture(texture)
			self.Experience:SetHeight(11)
			self.Experience:SetWidth((unit == 'pet') and 130 or 230)
			self.Experience:SetBackdrop({bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=], insets = {top = -1, left = -1, bottom = -1, right = -1}})
			self.Experience:SetBackdropColor(0, 0, 0)

			self.Experience.Tooltip = true

			self.Experience.Text = self.Experience:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
			self.Experience.Text:SetPoint('CENTER', self.Experience)

			self.Experience.bg = self.Experience:CreateTexture(nil, 'BORDER')
			self.Experience.bg:SetAllPoints(self.Experience)
			self.Experience.bg:SetTexture(0.3, 0.3, 0.3)
		end

		if(unit == 'player') then
			self.Spark = self.Power:CreateTexture(nil, 'OVERLAY')
			self.Spark:SetTexture([=[Interface\CastingBar\UI-CastingBar-Spark]=])
			self.Spark:SetBlendMode('ADD')
			self.Spark:SetHeight(8)
			self.Spark:SetWidth(8)
			self.Spark.manatick = true

			if(IsAddOnLoaded('oUF_DruidMana') and class == 'DRUID') then
				self.DruidMana = CreateFrame('StatusBar', nil, self)
				self.DruidMana:SetPoint('BOTTOM', self.Power, 'TOP')
				self.DruidMana:SetStatusBarTexture(texture)
				self.DruidMana:SetStatusBarColor(unpack(self.colors.power[0]))
				self.DruidMana:SetHeight(1)
				self.DruidMana:SetWidth(230)

				self.DruidManaText = self.DruidMana:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
				self.DruidManaText:SetPoint('CENTER', self.DruidMana)
				self.DruidManaText:SetTextColor(unpack(self.colors.power[0]))
			end
		elseif(unit == 'pet') then
			self.Power.colorPower = true
			self.Power.colorHappiness = true
			self.Power.colorReaction = false

			self.Buffs = CreateFrame('Frame', nil, self)
			self.Buffs:SetPoint('TOPRIGHT', self, 'TOPLEFT', -2, 1)
			self.Buffs:SetHeight(24 * 2)
			self.Buffs:SetWidth(270)
			self.Buffs.size = 24
			self.Buffs.spacing = 2
			self.Buffs.initialAnchor = 'TOPRIGHT'
			self.Buffs['growth-x'] = 'LEFT'

			self:SetAttribute('initial-height', 27)
			self:SetAttribute('initial-width', 130)
		end
	else
		self.Info = self.Health:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
		self.Info:SetPoint('LEFT', self.Health, 2, -1)
		self.Info:SetPoint('RIGHT', self.Health.text, 'LEFT')
		self.Info:SetJustifyH('LEFT')
		self.Info:SetText(unit == 'target' and '[name] |cff0090ff[smartlevel] [rare]|r' or '[name]')
		self.TaggedStrings = {self.Info}
	end

	if(unit == 'focus' or unit == 'targettarget') then
		self.Power:Hide()
		self.Health:SetHeight(20)

		self.Debuffs = CreateFrame('Frame', nil, self)
		self.Debuffs:SetPoint('TOPLEFT', self, 'TOPRIGHT', 2, 1)
		self.Debuffs:SetHeight(23)
		self.Debuffs:SetWidth(180)
		self.Debuffs.num = 2
		self.Debuffs.size = 23
		self.Debuffs.spacing = 2
		self.Debuffs.initialAnchor = 'TOPLEFT'
		self.Debuffs.showDebuffType = true

		if(unit == 'targettarget') then
			self.Debuffs:SetPoint('TOPRIGHT', self, 'TOPLEFT', -2, 1)
			self.Debuffs.initialAnchor = 'TOPRIGHT'
			self.Debuffs['growth-x'] = 'LEFT'
		else
			self.Debuffs.onlyShowDuration = true
		end

		self:SetAttribute('initial-height', 21)
		self:SetAttribute('initial-width', 181)
	end

	if(unit == 'player' or unit == 'target') then
		self.CombatFeedbackText = self.Health:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
		self.CombatFeedbackText:SetPoint('CENTER', self)

		self.Castbar = CreateFrame('StatusBar', nil, self)
		self.Castbar:SetPoint('TOPRIGHT', self, 'BOTTOMRIGHT', 0, -100)
		self.Castbar:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -100)
		self.Castbar:SetStatusBarTexture(texture)
		self.Castbar:SetStatusBarColor(0.25, 0.25, 0.35)
		self.Castbar:SetBackdrop({bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=], insets = {top = -1, left = -1, bottom = -1, right = -1}})
		self.Castbar:SetBackdropColor(0, 0, 0)
		self.Castbar:SetHeight(22)

		self.Castbar.bg = self.Castbar:CreateTexture(nil, 'BORDER')
		self.Castbar.bg:SetAllPoints(self.Castbar)
		self.Castbar.bg:SetTexture(0.3, 0.3, 0.3)

		self.Castbar.Text = self.Castbar:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
		self.Castbar.Text:SetPoint('LEFT', self.Castbar, 2, -1)
		self.Castbar.Text:SetJustifyH('LEFT')

		self.Castbar.Time = self.Castbar:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
		self.Castbar.Time:SetPoint('RIGHT', self.Castbar, -2, -1)
		self.Castbar.Time:SetJustifyH('RIGHT')

		self:SetAttribute('initial-height', 27)
		self:SetAttribute('initial-width', 230)

		if(unit == 'target') then
			self.CPoints = self:CreateFontString(nil, 'OVERLAY', 'SubZoneTextFont')
			self.CPoints:SetPoint('RIGHT', self, 'LEFT', -9, 0)
			self.CPoints:SetTextColor(1, 1, 1)
			self.CPoints:SetJustifyH('RIGHT')

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
	end

	self.DebuffHighlightBackdrop = true
	self.DebuffHighlightFilter = true

	self.PostCreateAuraIcon = PostCreateAuraIcon
	self.PostUpdateHealth = PostUpdateHealth
	self.PostUpdatePower = PostUpdatePower

	return self
end

oUF:RegisterStyle('P3lim', CreateStyle)
oUF:SetActiveStyle('P3lim')

oUF:Spawn('player'):SetPoint('CENTER', UIParent, -220, -250)
oUF:Spawn('target'):SetPoint('CENTER', UIParent, 220, -250)
oUF:Spawn('targettarget'):SetPoint('BOTTOMRIGHT', oUF.units.target, 'TOPRIGHT', 0, 5)
oUF:Spawn('focus'):SetPoint('BOTTOMLEFT', oUF.units.player, 'TOPLEFT', 0, 5)
oUF:Spawn('pet'):SetPoint('RIGHT', oUF.units.player, 'LEFT', -25, 0)