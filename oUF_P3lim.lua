local _, ns = ...
local oUF = ns.oUF

local _, playerClass = UnitClass('player')

local TEXTURE = [[Interface\ChatFrame\ChatFrameBackground]]
local BACKDROP = {
	bgFile = TEXTURE,
	insets = {top = -1, bottom = -1, left = -1, right = -1}
}

local GLOW = {
	edgeFile = [[Interface\AddOns\oUF_P3lim\assets\glow]], edgeSize = 3
}

local function PostUpdatePower(element, unit, cur, max)
	local parent = element.__owner
	local height = max ~= 0 and 20 or 22
	parent.Health:SetHeight(height)
	parent.Portrait.scrollFrame:SetHeight(height)
	parent.Portrait.scrollChild:SetHeight(height)
end

local function PostUpdateHealth(element, unit, cur, max)
	local ScrollFrame = element.__owner.Portrait.scrollFrame

	if(element.disconnected) then
		cur, max = 0, 1
	end

	-- XXX: this is broken in legion beta
	local offset = -(element:GetWidth() * (1 - cur / max))
	ScrollFrame:SetPoint('LEFT', offset, 0)
	ScrollFrame:SetHorizontalScroll(offset)
end

local function PostUpdatePortrait(element, unit)
	element:SetModelAlpha(0.1)
	element:SetDesaturation(1)
end

local function PostUpdateCast(element, unit)
	local Spark = element.Spark
	if(not element.interrupt and UnitCanAttack('player', unit)) then
		Spark:SetColorTexture(1, 0, 0)
	else
		Spark:SetColorTexture(1, 1, 1)
	end
end

local function PostUpdateTotem(element)
	local shown = {}
	for index = 1, MAX_TOTEMS do
		local Totem = element[index]
		if(Totem:IsShown()) then
			local prevShown = shown[#shown]

			Totem:ClearAllPoints()
			Totem:SetPoint('TOPLEFT', shown[#shown] or element.__owner, 'TOPRIGHT', 4, 0)
			table.insert(shown, Totem)
		end
	end
end

local function PostUpdateClassIcon(element, cur, max, diff, powerType, event)
	if(diff or event == 'ClassPowerEnable') then
		element:UpdateTexture()

		for index = 1, max do
			local ClassIcon = element[index]
			if(max == 3) then
				ClassIcon:SetWidth(74)
			elseif(max == 4) then
				ClassIcon:SetWidth(index > 2 and 55 or 54)
			elseif(max == 5 or max == 8) then
				ClassIcon:SetWidth(index == 5 and 42 or 43)
			elseif(max == 6) then
				ClassIcon:SetWidth(35)
			end

			if(max == 8) then
				-- Rogue anticipation
				if(index == 6) then
					ClassIcon:ClearAllPoints()
					ClassIcon:SetPoint('LEFT', element[index - 5])
				end

				if(index > 5) then
					ClassIcon.Texture:SetColorTexture(1, 0, 0)
				end
			else
				if(index > 1) then
					ClassIcon:ClearAllPoints()
					ClassIcon:SetPoint('LEFT', element[index - 1], 'RIGHT', 4, 0)
				end
			end
		end
	end
end

local function UpdateClassIconTexture(element)
	local r, g, b = 1, 1, 2/5
	if(not UnitHasVehicleUI('player')) then
		if(playerClass == 'MONK') then
			r, g, b = 0, 4/5, 3/5
		elseif(playerClass == 'WARLOCK') then
			r, g, b = 2/3, 1/3, 2/3
		elseif(playerClass == 'PRIEST') then -- WoD only
			r, g, b = 2/3, 1/4, 2/3
		elseif(playerClass == 'PALADIN') then
			r, g, b = 1, 1, 2/5
		elseif(playerClass == 'MAGE') then
			r, g, b = 5/6, 1/2, 5/6
		end
	end

	for index = 1, 8 do
		local ClassIcon = element[index]
		ClassIcon.Texture:SetColorTexture(r, g, b)
	end
end

local function UpdateThreat(self, event, unit)
	if(unit ~= self.unit) then
		return
	end

	local situation = UnitThreatSituation(unit)
	if(situation and situation > 0) then
		local r, g, b = GetThreatStatusColor(situation)
		self.Threat:SetBackdropBorderColor(r, g, b, 1)
	else
		self.Threat:SetBackdropBorderColor(0, 0, 0, 0)
	end
end

local function UpdateExperienceTooltip(self)
	if(not (UnitLevel('player') == MAX_PLAYER_LEVEL and IsWatchingHonorAsXP())) then
		local cur = UnitXP('player')
		local max = UnitXPMax('player')
		local per = math.floor(cur / max * 100 + 0.5)
		local rested = math.floor((GetXPExhaustion() or 0) / max * 100 + 0.5)

		GameTooltip:SetOwner(self, 'ANCHOR_NONE')
		GameTooltip:SetPoint('BOTTOMLEFT', self, 'TOPLEFT')
		GameTooltip:SetText(string.format('%s / %s (%s%%)', BreakUpLargeNumbers(cur), BreakUpLargeNumbers(max), per))
		GameTooltip:AddLine(string.format('%.1f bars, %s%% rested', cur / max * 20, rested))
		GameTooltip:Show()
	end
end

local function UpdateAura(self, elapsed)
	if(self.expiration) then
		self.expiration = math.max(self.expiration - elapsed, 0)

		if(self.expiration > 0 and self.expiration < 60) then
			self.Duration:SetFormattedText('%d', self.expiration)
		else
			self.Duration:SetText()
		end
	end
end

local function PostCreateAura(element, button)
	button:SetBackdrop(BACKDROP)
	button:SetBackdropColor(0, 0, 0)
	button.cd:SetReverse(true)
	button.cd:SetHideCountdownNumbers(true)
	button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	button.icon:SetDrawLayer('ARTWORK')

	local StringParent = CreateFrame('Frame', nil, button)
	StringParent:SetFrameLevel(20)

	button.count:SetParent(StringParent)
	button.count:ClearAllPoints()
	button.count:SetPoint('BOTTOMRIGHT', button, 2, 1)
	button.count:SetFontObject('SempliceNormal')

	local Duration = StringParent:CreateFontString(nil, 'OVERLAY', 'SempliceNormal')
	Duration:SetPoint('TOPLEFT', button, 0, -1)
	button.Duration = Duration

	button:HookScript('OnUpdate', UpdateAura)
end

local function PostUpdateBuff(element, unit, button, index)
	local _, _, _, _, _, duration, expiration, owner, canStealOrPurge = UnitAura(unit, index, button.filter)

	if(duration and duration > 0) then
		button.expiration = expiration - GetTime()
	else
		button.expiration = math.huge
	end

	if(unit == 'target' and canStealOrPurge) then
		button:SetBackdropColor(0, 1/2, 1/2)
	elseif(owner ~= 'player') then
		button:SetBackdropColor(0, 0, 0)
	end
end

local function PostUpdateDebuff(element, unit, button, index)
	local _, _, _, _, type, _, _, owner = UnitAura(unit, index, button.filter)

	if(owner == 'player') then
		local color = DebuffTypeColor[type or 'none']
		button:SetBackdropColor(color.r * 3/5, color.g * 3/5, color.b * 3/5)
		button.icon:SetDesaturated(false)
	else
		button:SetBackdropColor(0, 0, 0)
		button.icon:SetDesaturated(true)
	end

	PostUpdateBuff(element, unit, button, index)
end

local function FilterTargetDebuffs(...)
	local _, unit, _, _, _, _, _, _, _, _, owner, _, _, id = ...
	return owner == 'player' or owner == 'vehicle' or UnitIsFriend('player', unit) or not owner
end

local function FilterGroupDebuffs(...)
	local _, _, _, _, _, _, _, _, _, _, _, _, _, id = ...
	return id == 160029
end

local UnitSpecific = {
	player = function(self)
		local PetHealth = self.StringParent:CreateFontString(nil, 'OVERLAY', 'SempliceRight')
		PetHealth:SetPoint('RIGHT', self.HealthValue, 'LEFT', -2, 0)
		PetHealth.overrideUnit = 'pet'
		self:CustomTag(PetHealth, '[p3lim:pethp< :]')

		local PowerValue = self.StringParent:CreateFontString(nil, 'OVERLAY', 'SempliceLeft')
		PowerValue:SetPoint('LEFT', self.Health, 2, 0)
		PowerValue:SetPoint('RIGHT', PetHealth, 'LEFT', -2, 0)
		PowerValue:SetWordWrap(false)

		self:Tag(PowerValue, '[p3lim:ptype][p3lim:curpp]|r[ |cff0090ff>p3lim:altpp<%|r][ : >p3lim:cast]')

		local PowerPrediction = CreateFrame('StatusBar', nil, self.Power)
		PowerPrediction:SetPoint('RIGHT', self.Power:GetStatusBarTexture())
		PowerPrediction:SetPoint('BOTTOM')
		PowerPrediction:SetPoint('TOP')
		PowerPrediction:SetWidth(230)
		PowerPrediction:SetStatusBarTexture(TEXTURE)
		PowerPrediction:SetStatusBarColor(1, 0, 0)
		PowerPrediction:SetReverseFill(true)
		self.PowerPrediction = {
			mainBar = PowerPrediction
		}

		local Experience = CreateFrame('StatusBar', nil, self, 'AnimatedStatusBarTemplate')
		Experience:SetPoint('BOTTOM', 0, -20)
		Experience:SetSize(230, 6)
		Experience:SetStatusBarTexture(TEXTURE)
		Experience:SetScript('OnEnter', UpdateExperienceTooltip)
		Experience:SetScript('OnLeave', GameTooltip_Hide)
		self.Experience = Experience

		local Rested = CreateFrame('StatusBar', nil, Experience)
		Rested:SetAllPoints()
		Rested:SetStatusBarTexture(TEXTURE)
		Rested:SetBackdrop(BACKDROP)
		Rested:SetBackdropColor(0, 0, 0)
		Experience.Rested = Rested

		local ExperienceBG = Rested:CreateTexture(nil, 'BORDER')
		ExperienceBG:SetAllPoints()
		ExperienceBG:SetColorTexture(1/3, 1/3, 1/3)

		local ClassIcons = {}
		ClassIcons.UpdateTexture = UpdateClassIconTexture
		ClassIcons.PostUpdate = PostUpdateClassIcon

		for index = 1, 8 do
			local ClassIcon = CreateFrame('Frame', nil, self)
			ClassIcon:SetHeight(6)
			ClassIcon:SetBackdrop(BACKDROP)
			ClassIcon:SetBackdropColor(0, 0, 0)

			if(index > 1) then
				ClassIcon:SetPoint('LEFT', ClassIcons[index - 1], 'RIGHT', 4, 0)
			else
				ClassIcon:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -4)
			end

			local Texture = ClassIcon:CreateTexture(nil, 'BORDER', nil, index > 5 and 1 or 0)
			Texture:SetAllPoints()
			ClassIcon.Texture = Texture

			ClassIcons[index] = ClassIcon
		end
		self.ClassIcons = ClassIcons

		local Totems = {}
		Totems.PostUpdate = PostUpdateTotem

		for index = 1, MAX_TOTEMS do
			local Totem = CreateFrame('Button', nil, self)
			Totem:SetSize(22, 22)

			local Icon = Totem:CreateTexture(nil, 'OVERLAY')
			Icon:SetAllPoints()
			Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
			Totem.Icon = Icon

			local Background = Totem:CreateTexture(nil, 'BORDER')
			Background:SetPoint('TOPLEFT', -1, 1)
			Background:SetPoint('BOTTOMRIGHT', 1, -1)
			Background:SetColorTexture(0, 0, 0)

			local Cooldown = CreateFrame('Cooldown', nil, Totem, 'CooldownFrameTemplate')
			Cooldown:SetAllPoints()
			Cooldown:SetReverse(true)
			Totem.Cooldown = Cooldown

			Totems[index] = Totem
		end
		self.Totems = Totems

		if(playerClass == 'DEATHKNIGHT') then
			local Runes = {}
			for index = 1, 6 do
				local Rune = CreateFrame('StatusBar', nil, self)
				Rune:SetSize(35, 6)
				Rune:SetStatusBarTexture(TEXTURE)
				Rune:SetStatusBarColor(1/2, 1/3, 2/3)
				Rune:SetBackdrop(BACKDROP)
				Rune:SetBackdropColor(0, 0, 0)

				if(index == 1) then
					Rune:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -4)
				else
					Rune:SetPoint('LEFT', Runes[index - 1], 'RIGHT', 4, 0)
				end

				local RuneBG = Rune:CreateTexture(nil, 'BORDER')
				RuneBG:SetAllPoints()
				RuneBG:SetColorTexture(1/6, 1/9, 1/3)

				Runes[index] = Rune
			end
			self.Runes = Runes
		end

		self.Debuffs.size = 22
		self.Debuffs:SetSize(230, 22)
		self.Debuffs.PostUpdateIcon = PostUpdateBuff

		self:Tag(self.HealthValue, '[p3lim:status][p3lim:maxhp][|cffff8080->p3lim:defhp<|r][ >p3lim:perhp<|cff0090ff%|r]')
		self:SetWidth(230)
	end,
	target = function(self)
		local Name = self.StringParent:CreateFontString(nil, 'OVERLAY', 'SempliceLeft')
		Name:SetPoint('LEFT', self.Health, 2, 0)
		Name:SetPoint('RIGHT', self.HealthValue, 'LEFT')
		Name:SetWordWrap(false)
		self:Tag(Name, '[p3lim:name]')

		local Buffs = CreateFrame('Frame', nil, self)
		Buffs:SetPoint('TOPLEFT', self, 'TOPRIGHT', 4, 0)
		Buffs:SetSize(236, 44)
		Buffs.num = 27
		Buffs.size = 22
		Buffs.spacing = 4
		Buffs.initialAnchor = 'TOPLEFT'
		Buffs['growth-y'] = 'DOWN'
		Buffs.PostCreateIcon = PostCreateAura
		Buffs.PostUpdateIcon = PostUpdateBuff
		self.Buffs = Buffs

		self.Castbar.PostCastStart = PostUpdateCast
		self.Castbar.PostCastInterruptible = PostUpdateCast
		self.Castbar.PostCastNotInterruptible = PostUpdateCast
		self.Castbar.PostChannelStart = PostUpdateCast

		self.Debuffs.size = 19.4
		self.Debuffs['growth-y'] = 'DOWN'
		self.Debuffs:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -4)
		self.Debuffs:SetSize(230, 19.4)
		self.Debuffs.CustomFilter = FilterTargetDebuffs
		self.Debuffs.PostUpdateIcon = PostUpdateDebuff

		self.Power.PostUpdate = PostUpdatePower
		self:Tag(self.HealthValue, '[p3lim:status][p3lim:curhp][ >p3lim:targethp]')
		self:SetWidth(230)
	end,
	party = function(self)
		local ReadyCheck = self:CreateTexture()
		ReadyCheck:SetPoint('LEFT', self, 'RIGHT', 3, 0)
		ReadyCheck:SetSize(14, 14)
		self.ReadyCheck = ReadyCheck

		local RoleIcon = self:CreateTexture(nil, 'OVERLAY')
		RoleIcon:SetPoint('LEFT', self, 'RIGHT', 3, 0)
		RoleIcon:SetSize(14, 14)
		RoleIcon:SetAlpha(0)
		self.LFDRole = RoleIcon

		self:HookScript('OnEnter', function() RoleIcon:SetAlpha(1) end)
		self:HookScript('OnLeave', function() RoleIcon:SetAlpha(0) end)

		self.Debuffs.size = 16
		self.Debuffs:SetSize(100, 16)
		self.Debuffs.CustomFilter = FilterGroupDebuffs

		self.Health:SetAllPoints()
		self:Tag(self.Name, '[p3lim:leader][raidcolor][name]')
		self:Tag(self.HealthValue, '[p3lim:status][p3lim:perhp<|cff0090ff%|r]')
	end,
	boss = function(self)
		self:SetSize(126, 19)
		self.Health:SetAllPoints()
		self:Tag(self.HealthValue, '[p3lim:perhp<|cff0090ff%|r]')
	end,
	arena = function(self)
		self:SetSize(126, 19)
		self:Tag(self.Name, '[raidcolor][arenaspec]')
		self:Tag(self.HealthValue, '[p3lim:perhp<|cff0090ff%|r]')
		self.Health:SetHeight(17)
	end
}
UnitSpecific.raid = UnitSpecific.party

local function Shared(self, unit)
	unit = unit:match('(boss)%d?$') or unit:match('(arena)%d?$') or unit

	self.colors.power.MANA = {0, 144/255, 1}
	self.colors.power.INSANITY = {4/5, 2/5, 1}

	self:RegisterForClicks('AnyUp')
	self:SetScript('OnEnter', UnitFrame_OnEnter)
	self:SetScript('OnLeave', UnitFrame_OnLeave)

	self:SetBackdrop(BACKDROP)
	self:SetBackdropColor(0, 0, 0)

	local Health = CreateFrame('StatusBar', nil, self)
	Health:SetStatusBarTexture(TEXTURE)
	Health:SetStatusBarColor(1/6, 1/6, 2/7)
	Health.frequentUpdates = true
	self.Health = Health

	local HealthBG = Health:CreateTexture(nil, 'BORDER')
	HealthBG:SetAllPoints()
	HealthBG:SetColorTexture(1/3, 1/3, 1/3)

	local StringParent = CreateFrame('Frame', nil, self)
	StringParent:SetFrameLevel(20)
	self.StringParent = StringParent

	local HealthValue = StringParent:CreateFontString(nil, 'OVERLAY', 'SempliceRight')
	HealthValue:SetPoint('RIGHT', Health, -2, 0)
	self.HealthValue = HealthValue

	if(unit == 'player' or unit == 'target' or unit == 'arena') then
		local Power = CreateFrame('StatusBar', nil, self)
		Power:SetPoint('BOTTOMRIGHT')
		Power:SetPoint('BOTTOMLEFT')
		Power:SetHeight(1)
		Power:SetStatusBarTexture(TEXTURE)
		Power.frequentUpdates = true
		self.Power = Power

		Power.colorClass = true
		Power.colorTapping = true
		Power.colorDisconnected = true
		Power.colorReaction = true

		local PowerBG = Power:CreateTexture(nil, 'BORDER')
		PowerBG:SetAllPoints()
		PowerBG:SetTexture(TEXTURE)
		PowerBG.multiplier = 1/3
		Power.bg = PowerBG

		if(unit ~= 'arena') then
			local ScrollFrame = CreateFrame('ScrollFrame', nil, Health)
			ScrollFrame:SetPoint('LEFT')
			ScrollFrame:SetSize(230, 20)

			local ScrollChild = CreateFrame('Frame')
			ScrollChild:SetSize(ScrollFrame:GetSize())
			ScrollFrame:SetScrollChild(ScrollChild)

			local Portrait = CreateFrame('PlayerModel', nil, ScrollChild)
			Portrait:SetAllPoints()
			Portrait.scrollChild = ScrollChild
			Portrait.scrollFrame = ScrollFrame
			Portrait.PostUpdate = PostUpdatePortrait
			self.Portrait = Portrait

			Health.PostUpdate = PostUpdateHealth
			Health:SetHeight(20)
			self:SetHeight(22)
		end

		local Castbar = CreateFrame('StatusBar', nil, self)
		Castbar:SetAllPoints(Health)
		Castbar:SetStatusBarTexture(TEXTURE)
		Castbar:SetStatusBarColor(0, 0, 0, 0)
		Castbar:SetFrameStrata('HIGH')
		self.Castbar = Castbar

		local Spark = Castbar:CreateTexture(nil, 'OVERLAY')
		Spark:SetSize(2, 20)
		Spark:SetColorTexture(1, 1, 1)
		Castbar.Spark = Spark

		local RaidIcon = Health:CreateTexture(nil, 'OVERLAY')
		RaidIcon:SetPoint('TOP', self, 0, 8)
		RaidIcon:SetSize(16, 16)
		self.RaidIcon = RaidIcon

		Health:SetPoint('TOPRIGHT')
		Health:SetPoint('TOPLEFT')
	end

	if(unit == 'focus' or unit == 'targettarget' or unit == 'boss') then
		local Name = Health:CreateFontString(nil, 'OVERLAY', 'SempliceLeft')
		Name:SetPoint('LEFT', 2, 0)
		Name:SetPoint('RIGHT', HealthValue, 'LEFT')
		Name:SetWordWrap(false)
		self:Tag(Name, '[p3lim:color][name]')
	elseif(unit ~= 'arena') then
		local Threat = CreateFrame('Frame', nil, self)
		Threat:SetPoint('TOPRIGHT', 3, 3)
		Threat:SetPoint('BOTTOMLEFT', -3, -3)
		Threat:SetFrameStrata('LOW')
		Threat:SetBackdrop(GLOW)
		Threat.Override = UpdateThreat
		self.Threat = Threat
	end

	if(unit == 'party' or unit == 'raid' or unit == 'arena') then
		local Name = self.Health:CreateFontString(nil, 'OVERLAY', 'SempliceLeft')
		Name:SetPoint('LEFT', 3, 0)
		Name:SetPoint('RIGHT', HealthValue, 'LEFT')
		Name:SetWordWrap(false)
		self.Name = Name

		local Resurrect = Health:CreateTexture(nil, 'OVERLAY')
		Resurrect:SetPoint('CENTER', 0, -1)
		Resurrect:SetSize(16, 16)
		self.ResurrectIcon = Resurrect
	end

	if(unit ~= 'boss' and unit ~= 'arena') then
		local Debuffs = CreateFrame('Frame', nil, self)
		Debuffs.spacing = 4
		Debuffs.initialAnchor = 'TOPLEFT'
		Debuffs.PostCreateIcon = PostCreateAura
		self.Debuffs = Debuffs

		if(unit == 'focus') then
			Debuffs:SetPoint('TOPLEFT', self, 'TOPRIGHT', 4, 0)
			Debuffs.onlyShowPlayer = true
		elseif(unit ~= 'target') then
			Debuffs:SetPoint('TOPRIGHT', self, 'TOPLEFT', -4, 0)
			Debuffs.initialAnchor = 'TOPRIGHT'
			Debuffs['growth-x'] = 'LEFT'
		end

		if(unit == 'focus' or unit == 'targettarget') then
			Debuffs.num = 3
			Debuffs.size = 19
			Debuffs:SetSize(230, 19)

			Health:SetAllPoints()
			self:SetSize(161, 19)
		end
	end

	if(UnitSpecific[unit]) then
		return UnitSpecific[unit](self)
	end
end

oUF:RegisterStyle('P3lim', Shared)
oUF:Factory(function(self)
	self:SetActiveStyle('P3lim')
	self:Spawn('player'):SetPoint('CENTER', -300, -250)
	self:Spawn('focus'):SetPoint('TOPLEFT', oUF_P3limPlayer, 0, 26)
	self:Spawn('target'):SetPoint('CENTER', 300, -250)
	self:Spawn('targettarget'):SetPoint('TOPRIGHT', oUF_P3limTarget, 0, 26)

	self:SpawnHeader(nil, nil, 'custom [group:party] show; [@raid3,exists] show; [@raid26,exists] hide; hide',
		'showParty', true,
		'showRaid', true,
		'showPlayer', true,
		'yOffset', -6,
		'groupBy', 'ASSIGNEDROLE',
		'groupingOrder', 'TANK,HEALER,DAMAGER',
		'oUF-initialConfigFunction', [[
			self:SetHeight(16)
			self:SetWidth(126)
		]]
	):SetPoint('TOP', Minimap, 'BOTTOM', 0, -10)

	for index = 1, 5 do
		local boss = self:Spawn('boss' .. index)
		local arena = self:Spawn('arena' .. index)

		if(index == 1) then
			boss:SetPoint('TOP', oUF_P3limRaid or Minimap, 'BOTTOM', 0, -20)
			arena:SetPoint('TOP', oUF_P3limRaid or Minimap, 'BOTTOM', 0, -20)
		else
			boss:SetPoint('TOP', _G['oUF_P3limBoss' .. index - 1], 'BOTTOM', 0, -6)
			arena:SetPoint('TOP', _G['oUF_P3limArena' .. index - 1], 'BOTTOM', 0, -6)
		end
	end
end)
