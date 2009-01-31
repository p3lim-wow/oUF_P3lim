local _, class = UnitClass('player')
local texture = [=[Interface\AddOns\oUF_P3lim\minimalist]=]
local backdrop = {
	bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
	insets = {top = -1, left = -1, bottom = -1, right = -1},
}

local runeloadcolors = {
	[1] = {0.77, 0.12, 0.23},
	[2] = {0.77, 0.12, 0.23},
	[3] = {0.4, 0.8, 0.1},
	[4] = {0.4, 0.8, 0.1},
	[5] = {0, 0.4, 0.7},
	[6] = {0, 0.4, 0.7},
}

local colors = setmetatable({
	power = setmetatable({
		['MANA'] = {0, 144/255, 1},
	}, {__index = oUF.colors.power}),
	runes = setmetatable({
		[1] = {0.77, 0.12, 0.23},
		[2] = {0.3, 0.8, 0.1},
		[3] = {0, 0.4, 0.7},
		[4] = {0.8, 0.8, 0.8},
	}, {__index = oUF.colors.runes}),
}, {__index = oUF.colors})

local function menu(self)
	local unit = string.gsub(self.unit, '(.)', string.upper, 1)
	if(_G[unit..'FrameDropDown']) then
		ToggleDropDownMenu(1, nil, _G[unit..'FrameDropDown'], 'cursor')
	end
end

local function truncate(value)
	if(value >= 1e6) then
		return string.format('%dm', value / 1e6)
	elseif(value >= 1e4) then
		return string.format('%dk', value / 1e3)
	else
		return value
	end
end

local function UpdateInfoColor(self, unit)
	if(UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit)) then
		self:SetTextColor(unpack(colors.tapped))
	elseif(not UnitIsConnected(unit)) then
		self:SetTextColor(unpack(colors.disconnected))
	elseif(not UnitIsPlayer(unit)) then
		self:SetTextColor(unpack({UnitSelectionColor(unit)} or colors.health))
	else
		self:SetTextColor(1, 1, 1)
	end
end

local function UpdateMasterLooter(self)
	self.MasterLooter:ClearAllPoints()
	if((UnitInParty(self.unit) or UnitInRaid(self.unit)) and UnitIsPartyLeader(self.unit)) then
		self.MasterLooter:SetPoint('LEFT', self.Leader, 'RIGHT')
	else
		self.MasterLooter:SetPoint('TOPLEFT', self, 0, 8)
	end
end

local function UpdateRuneBar(self, elapsed)
	local start, duration, ready = GetRuneCooldown(self:GetID())

	if(ready) then
		self:SetValue(1)
		self:SetScript('OnUpdate', nil)
	else
		self:SetValue((GetTime() - start) / duration)
	end
end

local function UpdateRunePower(self, event, rune, usable)
	for i = 1, 6 do
		if(rune == i and not usable and GetRuneType(rune)) then
			self.RuneBar[i]:SetScript('OnUpdate', UpdateRuneBar)
		end
	end
end

local function UpdateRuneType(self, event, rune)
	if(rune) then
		local runetype = GetRuneType(rune)
		if(runetype) then
			self.RuneBar[rune]:SetStatusBarColor(unpack(colors.runes[runetype]))
		end
	else
		for i = 1, 6 do
			local runetype = GetRuneType(i)
			if(runetype) then
				self.RuneBar[i]:SetStatusBarColor(unpack(colors.runes[runetype]))
			end
		end
	end
end

local function UpdateDruidPower(self)
	local bar = self.DruidPower
	local num, str = UnitPowerType('player')
	local min = UnitPower('player', (num ~= 0) and 0 or 3)
	local max = UnitPowerMax('player', (num ~= 0) and 0 or 3)

	bar:SetMinMaxValues(0, max)

	if(min ~= max) then
		bar:SetValue(min)
		bar:SetAlpha(1)

		if(num ~= 0) then
			bar:SetStatusBarColor(unpack(colors.power['MANA']))
			bar.Text:SetFormattedText('%d - %d%%', min, math.floor(min / max * 100))
		else
			bar:SetStatusBarColor(unpack(colors.power['ENERGY']))
			bar.Text:SetText()
		end
	else
		bar:SetAlpha(0)
		bar.Text:SetText()
	end
end

local function PostUpdateReputation(self, event, unit, bar)
	local name, id = GetWatchedFactionInfo()
	bar:SetStatusBarColor(FACTION_BAR_COLORS[id].r, FACTION_BAR_COLORS[id].g, FACTION_BAR_COLORS[id].b)
end

local function PostUpdateHealth(self, event, unit, bar, min, max)
	bar:SetStatusBarColor(0.25, 0.25, 0.35)
	if(not UnitIsConnected(unit)) then
		bar.Text:SetText('Offline')
	elseif(UnitIsDead(unit)) then
		bar.Text:SetText('Dead')
	elseif(UnitIsGhost(unit)) then
		bar.Text:SetText('Ghost')
	else
		if(unit == 'target' and UnitCanAttack('player', 'target')) then
			bar.Text:SetFormattedText('%s (%d|cff0090ff%%|r)', truncate(min), floor(min/max*100))
		else
			if(min ~= max) then
				if(unit == 'player') then
					bar.Text:SetFormattedText('|cffff8080%d|r %d|cff0090ff%%|r', min-max, floor(min/max*100))
				else
					bar.Text:SetFormattedText('%d |cff0090ff/|r %d', min, max)
				end
			else
				bar.Text:SetText(max)
			end
		end
	end

	if(self.Info) then UpdateInfoColor(self.Info, unit) end
end

local function PostUpdatePower(self, event, unit, bar, min, max)
	if(bar.Text) then
		if(min == 0 or not UnitIsPlayer(unit) or not UnitIsConnected(unit)) then
			bar.Text:SetText()
		else
			if(min ~= max) then
				bar.Text:SetText(max-(max-min))
			else
				bar.Text:SetText(min)
			end
		end

		local num, str = UnitPowerType(unit)
		local color = colors.power[str] or colors.health
		if(color) then bar.Text:SetTextColor(color[1], color[2], color[3]) end
	end

	if(self.Info) then UpdateInfoColor(self.Info, unit) end
end

local function OverrideCastbarTime(self, duration)
	if(self.channeling) then
		self.Time:SetFormattedText('%.1f ', duration)
	elseif(self.casting) then
		self.Time:SetFormattedText('%.1f ', self.max - duration)
	end
end

local function PostCreateAuraIcon(self, button, icons)
	icons.showDebuffType = true
	button.cd:SetReverse()
	button.overlay:SetTexture([=[Interface\AddOns\oUF_P3lim\border]=])
	button.overlay:SetTexCoord(0, 1, 0, 1)
	button.overlay.Hide = function(self) self:SetVertexColor(0.25, 0.25, 0.25) end
end

local function PostUpdateAuraIcon(self, icons, unit, icon, index, offset, filter, debuff)
	if(debuff and UnitIsEnemy('player', unit)) then
		local _, _, _, _, _, duration, _, isPlayer = UnitAura(unit, index, filter)
		if(duration and duration > 0 and not isPlayer) then
			icon.cd:Hide()
		end
	end
end

local function CreateStyle(self, unit)
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
	self.Health:SetHeight(22)
	self.Health.frequentUpdates = true

	self.Health.Text = self.Health:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmallRight')
	self.Health.Text:SetPoint('RIGHT', self.Health, -2, -1)

	self.Health.bg = self.Health:CreateTexture(nil, 'BORDER')
	self.Health.bg:SetAllPoints(self.Health)
	self.Health.bg:SetTexture(0.3, 0.3, 0.3)

	self.Power = CreateFrame('StatusBar', nil, self)
	self.Power:SetPoint('TOPRIGHT', self.Health, 'BOTTOMRIGHT', 0, -1)
	self.Power:SetPoint('TOPLEFT', self.Health, 'BOTTOMLEFT', 0, -1)
	self.Power:SetStatusBarTexture(texture)
	self.Power:SetHeight(4)
	self.Power.frequentUpdates = true

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

	self.MasterLooter = self.Health:CreateTexture(nil, 'OVERLAY')
	self.MasterLooter:SetPoint('LEFT', self.Leader, 'RIGHT')
	self.MasterLooter:SetHeight(16)
	self.MasterLooter:SetWidth(16)

	table.insert(self.__elements, UpdateMasterLooter)
	self:RegisterEvent('PARTY_LOOT_METHOD_CHANGED', UpdateMasterLooter)
	self:RegisterEvent('PARTY_MEMBERS_CHANGED', UpdateMasterLooter)
	self:RegisterEvent('PARTY_LEADER_CHANGED', UpdateMasterLooter)

	if(unit == 'player' or unit == 'pet') then
		self.Power.Text = self.Power:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
		self.Power.Text:SetPoint('LEFT', self.Health, 2, -1)

		self.BarFade = true

		if(IsAddOnLoaded('oUF_Experience')) then
			self.Experience = CreateFrame('StatusBar', nil, self)
			self.Experience:SetPoint('TOP', self, 'BOTTOM', 0, -10)
			self.Experience:SetStatusBarTexture(texture)
			self.Experience:SetStatusBarColor(unpack(colors.health))
			self.Experience:SetHeight(11)
			self.Experience:SetWidth((unit == 'pet') and 130 or 230)
			self.Experience:SetBackdrop(backdrop)
			self.Experience:SetBackdropColor(0, 0, 0)

			self.Experience.Tooltip = true

			self.Experience.Text = self.Experience:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
			self.Experience.Text:SetPoint('CENTER', self.Experience)

			self.Experience.bg = self.Experience:CreateTexture(nil, 'BORDER')
			self.Experience.bg:SetAllPoints(self.Experience)
			self.Experience.bg:SetTexture(0.3, 0.3, 0.3)
		end
	else
		self.Info = self.Health:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmallLeft')
		self.Info:SetPoint('LEFT', self.Health, 2, -1)
		self.Info:SetPoint('RIGHT', self.Health.Text, 'LEFT')
		self:Tag(self.Info, unit == 'target' and '[name] |cff0090ff[smartlevel] [rare]|r' or '[name]')
	end

	if(unit == 'player') then
		if(IsAddOnLoaded('oUF_AutoShot') and class == 'HUNTER') then
			self.AutoShot = CreateFrame('StatusBar', nil, self)
			self.AutoShot:SetPoint('TOP', self, 'BOTTOM', 0, -80)
			self.AutoShot:SetStatusBarTexture(texture)
			self.AutoShot:SetStatusBarColor(1, 0.7, 0)
			self.AutoShot:SetHeight(6)
			self.AutoShot:SetWidth(230)
			self.AutoShot:SetBackdrop(backdrop)
			self.AutoShot:SetBackdropColor(0, 0, 0)

			self.AutoShot.Text = self.AutoShot:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
			self.AutoShot.Text:SetPoint('CENTER', self.AutoShot)

			self.AutoShot.bg = self.AutoShot:CreateTexture(nil, 'BORDER')
			self.AutoShot.bg:SetAllPoints(self.AutoShot)
			self.AutoShot.bg:SetTexture(0.3, 0.3, 0.3)				
		end

		if(IsAddOnLoaded'oUF_Reputation' and UnitLevel(unit) == MAX_PLAYER_LEVEL) then
			self.Reputation = CreateFrame('StatusBar', nil, self)
			self.Reputation:SetPoint('TOP', self, 'BOTTOM', 0, -10)
			self.Reputation:SetStatusBarTexture(texture)
			self.Reputation:SetHeight(11)
			self.Reputation:SetWidth(230)
			self.Reputation:SetBackdrop(backdrop)
			self.Reputation:SetBackdropColor(0, 0, 0)

			self.Reputation.PostUpdate = PostUpdateReputation
			self.Reputation.Tooltip = true

			self.Reputation.Text = self.Reputation:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
			self.Reputation.Text:SetPoint('CENTER', self.Reputation)

			self.Reputation.bg = self.Reputation:CreateTexture(nil, 'BORDER')
			self.Reputation.bg:SetAllPoints(self.Reputation)
			self.Reputation.bg:SetTexture(0.3, 0.3, 0.3)
		end

		if(class == 'DRUID') then
			self.DruidPower = CreateFrame('StatusBar', nil, self)
			self.DruidPower:SetPoint('BOTTOM', self.Power, 'TOP')
			self.DruidPower:SetStatusBarTexture(texture)
			self.DruidPower:SetHeight(1)
			self.DruidPower:SetWidth(230)
			self.DruidPower:SetAlpha(0)

			self.DruidPower.Text = self.DruidPower:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
			self.DruidPower.Text:SetPoint('CENTER', self.DruidPower)
			self.DruidPower.Text:SetTextColor(unpack(colors.power['MANA']))

			self:RegisterEvent('UNIT_MANA', UpdateDruidPower)
			self:RegisterEvent('UNIT_ENERGY', UpdateDruidPower)
			self:RegisterEvent('PLAYER_LOGIN', UpdateDruidPower)
		end

		if(class == 'DEATHKNIGHT') then
			self.RuneBar = {}
			for i = 1, 6 do
				self.RuneBar[i] = CreateFrame('StatusBar', nil, self)
				if(i == 1) then
					self.RuneBar[i]:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -1)
				else
					self.RuneBar[i]:SetPoint('TOPLEFT', self.RuneBar[i-1], 'TOPRIGHT', 1, 0)
				end
				self.RuneBar[i]:SetStatusBarTexture(texture)
				self.RuneBar[i]:SetStatusBarColor(unpack(runeloadcolors[i]))
				self.RuneBar[i]:SetHeight(4)
				self.RuneBar[i]:SetWidth(230/6 - 0.85)
				self.RuneBar[i]:SetBackdrop(backdrop)
				self.RuneBar[i]:SetBackdropColor(0, 0, 0)
				self.RuneBar[i]:SetMinMaxValues(0, 1)
				self.RuneBar[i]:SetID(i)

				self.RuneBar[i].bg = self.RuneBar[i]:CreateTexture(nil, 'BORDER')
				self.RuneBar[i].bg:SetAllPoints(self.RuneBar[i])
				self.RuneBar[i].bg:SetTexture(0.3, 0.3, 0.3)			
			end

			RuneFrame:Hide()

			self:RegisterEvent('RUNE_TYPE_UPDATE', UpdateRuneType)
			self:RegisterEvent('RUNE_REGEN_UPDATE', UpdateRuneType)
			self:RegisterEvent('RUNE_POWER_UPDATE', UpdateRunePower)
		end
	end

	if(unit == 'pet') then
		self.Power.colorPower = true
		self.Power.colorHappiness = true
		self.Power.colorReaction = false

		self.Auras = CreateFrame('Frame', nil, self)
		self.Auras:SetPoint('TOPRIGHT', self, 'TOPLEFT', -2, 1)
		self.Auras:SetHeight(24 * 2)
		self.Auras:SetWidth(270)
		self.Auras.size = 24
		self.Auras.spacing = 2
		self.Auras.initialAnchor = 'TOPRIGHT'
		self.Auras['growth-x'] = 'LEFT'

		local cpoints = self.Health:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
		cpoints:SetPoint('LEFT', self.Health, 2, 0)
		cpoints:SetJustifyH('LEFT')
		self:Tag(cpoints, '[cpoints( CP)]')

		self:SetAttribute('initial-height', 27)
		self:SetAttribute('initial-width', 130)
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

		if(unit == 'targettarget') then
			self.Debuffs:SetPoint('TOPRIGHT', self, 'TOPLEFT', -2, 1)
			self.Debuffs.initialAnchor = 'TOPRIGHT'
			self.Debuffs['growth-x'] = 'LEFT'
		else
			self.BarFade = true
			self.Debuffs.onlyShowPlayer = true
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
		self.Castbar:SetBackdrop(backdrop)
		self.Castbar:SetBackdropColor(0, 0, 0)
		self.Castbar:SetHeight(22)

		self.Castbar.Text = self.Castbar:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmallLeft')
		self.Castbar.Text:SetPoint('LEFT', self.Castbar, 2, -1)

		self.Castbar.Time = self.Castbar:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmallRight')
		self.Castbar.Time:SetPoint('RIGHT', self.Castbar, -2, -1)
		self.Castbar.CustomTimeText = OverrideCastbarTime

		self.Castbar.bg = self.Castbar:CreateTexture(nil, 'BORDER')
		self.Castbar.bg:SetAllPoints(self.Castbar)
		self.Castbar.bg:SetTexture(0.3, 0.3, 0.3)

		self:SetAttribute('initial-height', 27)
		self:SetAttribute('initial-width', 230)
	end

	if(unit == 'target') then
		self.CPoints = self:CreateFontString(nil, 'OVERLAY', 'SubZoneTextFont')
		self.CPoints:SetPoint('RIGHT', self, 'LEFT', -9, 0)
		self.CPoints:SetTextColor(1, 1, 1)
		self.CPoints:SetJustifyH('RIGHT')
		self.CPoints.unit = 'player'

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
		self.Debuffs['growth-y'] = 'DOWN'
	end

	self.disallowVehicleSwap = true

	self.DebuffHighlightBackdrop = true
	self.DebuffHighlightFilter = true

	self.PostUpdateAuraIcon = PostUpdateAuraIcon
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