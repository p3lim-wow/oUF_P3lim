local WoD = select(4, GetBuildInfo()) >= 6e4

local _, ns = ...
local oUF = ns.oUF

local FONT = [[Interface\AddOns\oUF_P3lim\semplice.ttf]]
local TEXTURE = [[Interface\ChatFrame\ChatFrameBackground]]
local BACKDROP = {
	bgFile = TEXTURE,
	insets = {top = -1, bottom = -1, left = -1, right = -1}
}

local GLOW = {
	edgeFile = [[Interface\AddOns\oUF_P3lim\glow]], edgeSize = 3
}

local function PostUpdatePower(element, unit, cur, max)
	local parent = element.__owner
	local height = max ~= 0 and 20 or 22
	parent.Health:SetHeight(height)
	parent.Portrait.scrollFrame:SetHeight(height)
	parent.Portrait.scrollFrame:GetScrollChild():SetHeight(height)
end

local function PostUpdateHealth(element, unit, cur, max)
	local ScrollFrame = element.__owner.Portrait.scrollFrame

	if(element.disconnected) then
		cur = 0
	end

	local offset = -(230 * (1 - cur / max))
	ScrollFrame:SetPoint('LEFT', offset, 0)
	ScrollFrame:SetHorizontalScroll(offset)
end

local function PostUpdateCast(element, unit)
	local Spark = element.Spark
	if(not element.interrupt and UnitCanAttack('player', unit)) then
		Spark:SetTexture(1, 0, 0)
	else
		Spark:SetTexture(1, 1, 1)
	end
end

local function PostUpdateClassIcon(element, cur, max, diff)
	if(diff) then
		for index = 1, max do
			local ClassIcon = element[index]
			if(max == 3) then
				ClassIcon:SetWidth(74)
			elseif(max == 4) then
				ClassIcon:SetWidth(index > 2 and 55 or 54)
			elseif(max == 5) then
				ClassIcon:SetWidth(index == 5 and 42 or 43)
			end
		end
	end
end

local function PostUpdateResurrect(element)
	if(not element.__owner) then
		element = element.ResurrectIcon
	end

	local unit = element.__owner.unit

	local hasResurrectDebuff
	for index = 1, 40 do
		local _, _, _, _, _, _, _, _, _, _, spellID = UnitAura(unit, index, 'HARMFUL')
		if(spellID and spellID == 160029) then
			hasResurrectDebuff = true
			break
		elseif(not spellID) then
			break
		end
	end

	if(hasResurrectDebuff) then
		element:Show()
		element:SetVertexColor(1, 0, 0)
	elseif(not UnitHasIncomingResurrection(unit)) then
		element:Hide()
		element:SetVertexColor(1, 1, 1)
	else
		element:SetVertexColor(1, 1, 1)
	end
end

local function UpdateEclipse(self, event, unit, powerType)
	if(self.unit ~= unit or (event == 'UNIT_POWER_FREQUENT' and powerType ~= 'ECLIPSE')) then return end
	local lunar = self.Eclipse.LunarBar

	local max = UnitPowerMax('player', SPELL_POWER_ECLIPSE)
	lunar:SetMinMaxValues(-max, max)
	lunar:SetValue(UnitPower('player', SPELL_POWER_ECLIPSE))
end

local function UpdateEclipseVisibility(self)
	local element = self.Eclipse

	local showBar
	local form = GetShapeshiftFormID()
	if(not form) then
		local specialization = GetSpecialization()
		if(specialization and specialization == 1) then
			showBar = true
		end
	elseif(form == MOONKIN_FORM) then
		showBar = true
	end

	if(UnitHasVehicleUI('player')) then
		showBar = false
	end

	if(showBar) then
		element:Show()
	else
		element:Hide()
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

local function UpdateAura(self, elapsed)
	if(self.expiration) then
		if(self.expiration < 60) then
			self.remaining:SetFormattedText('%d', self.expiration)
		else
			self.remaining:SetText()
		end

		self.expiration = self.expiration - elapsed
	end
end

local function PostCreateAura(element, button)
	button:SetBackdrop(BACKDROP)
	button:SetBackdropColor(0, 0, 0)
	button.cd:SetReverse()
	button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	button.icon:SetDrawLayer('ARTWORK')

	if(WoD) then
		button.cd:SetHideCountdownNumbers(true)
	end

	button.count:SetPoint('BOTTOMRIGHT', 2, 1)
	button.count:SetFont(FONT, 8, 'OUTLINEMONOCHROME')

	local remaining = button:CreateFontString(nil, 'OVERLAY')
	remaining:SetPoint('TOPLEFT', 0, -1)
	remaining:SetFont(FONT, 8, 'OUTLINEMONOCROME')
	button.remaining = remaining

	button:HookScript('OnUpdate', UpdateAura)
end

local function PostUpdateBuff(element, unit, button, index)
	local _, _, _, _, _, duration, expiration = UnitAura(unit, index, button.filter)

	if(duration and duration > 0) then
		button.expiration = expiration - GetTime()
	else
		button.expiration = math.huge
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

local FilterPlayerBuffs
do
	local spells = {
		-- Shared
		[32182] = true, -- Heroism
		[80353] = true, -- Time Warp
	}

	function FilterPlayerBuffs(...)
		local _, _, _, _, _, _, _, _, _, _, _, _, _, id = ...
		return spells[id]
	end
end

local FilterTargetDebuffs
do
	local spells = {
		[1490] = true, -- Curse of Elements (Magic Vulnerability)
		[58410] = true, -- Master Poisoner (Magic Vulnerability)
		[81326] = true, -- Physical Vulnerability (Shared)
		[113746] = true, -- Weakened Armor (Shared)
	}

	function FilterTargetDebuffs(...)
		local _, unit, _, _, _, _, _, _, _, _, owner, _, _, id = ...

		if(owner == 'player' or owner == 'vehicle' or UnitIsFriend('player', unit) or spells[id] or not owner) then
			return true
		end
	end
end

local UnitSpecific = {
	player = function(self)
		local PowerValue = self.Health:CreateFontString(nil, 'OVERLAY')
		PowerValue:SetPoint('LEFT', 2, 0)
		PowerValue:SetPoint('RIGHT', self.HealthValue, 'LEFT', -3)
		PowerValue:SetFont(FONT, 8, 'OUTLINEMONOCHROME')
		PowerValue:SetJustifyH('LEFT')
		self:Tag(PowerValue, '[p3lim:ptype][p3lim:curpp]|r[ |cff997fcc>demonicfury<|r][ |cff0090ff>p3lim:altpp<%|r][ | >p3lim:spell]')

		local Experience = CreateFrame('StatusBar', nil, self)
		Experience:SetPoint('BOTTOM', 0, -20)
		Experience:SetSize(230, 6)
		Experience:SetStatusBarTexture(TEXTURE)
		Experience:SetStatusBarColor(0.15, 0.7, 0.1)
		self.Experience = Experience

		local Rested = CreateFrame('StatusBar', nil, Experience)
		Rested:SetAllPoints()
		Rested:SetStatusBarTexture(TEXTURE)
		Rested:SetStatusBarColor(0, 0.4, 1, 0.6)
		Rested:SetBackdrop(BACKDROP)
		Rested:SetBackdropColor(0, 0, 0)
		Experience.Rested = Rested

		local ExperienceBG = Rested:CreateTexture(nil, 'BORDER')
		ExperienceBG:SetAllPoints()
		ExperienceBG:SetTexture(1/3, 1/3, 1/3)

		local _, playerClass = UnitClass('player')

		local ComboPoints = self:CreateFontString(nil, 'OVERLAY', 'SubZoneTextFont')
		ComboPoints:SetPoint('RIGHT', self, 'LEFT', 590, -2)
		ComboPoints:SetJustifyH('RIGHT')
		ComboPoints:SetTextColor(1, 1, 1)

		if(playerClass == 'ROGUE') then
			self:Tag(ComboPoints, '[p3lim:anticipation< ][p3lim:combo]')
		else
			self:Tag(ComboPoints, '[p3lim:combo]')
		end

		local ClassIcons = {}
		ClassIcons.UpdateTexture = function() end
		ClassIcons.PostUpdate = PostUpdateClassIcon

		local r, g, b
		if(playerClass == 'MONK') then
			r, g, b = 0, 4/5, 3/5
		elseif(playerClass == 'WARLOCK') then
			r, g, b = 2/3, 1/3, 2/3
		elseif(playerClass == 'PRIEST') then
			r, g, b = 2/3, 1/4, 2/3
		elseif(playerClass == 'PALADIN') then
			r, g, b = 1, 1, 2/5
		end

		for index = 1, 5 do
			local ClassIcon = CreateFrame('Frame', nil, self)
			ClassIcon:SetHeight(6)
			ClassIcon:SetBackdrop(BACKDROP)
			ClassIcon:SetBackdropColor(0, 0, 0)

			if(index == 1) then
				ClassIcon:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -4)
			else
				ClassIcon:SetPoint('LEFT', ClassIcons[index - 1], 'RIGHT', 4, 0)
			end

			local Texture = ClassIcon:CreateTexture(nil, 'BORDER')
			Texture:SetAllPoints()
			Texture:SetTexture(r, g, b)

			ClassIcons[index] = ClassIcon
		end
		self.ClassIcons = ClassIcons

		if(playerClass == 'DEATHKNIGHT') then
			local Runes = {}
			for index = 1, 6 do
				local Rune = CreateFrame('StatusBar', nil, self)
				Rune:SetSize(35, 6)
				Rune:SetStatusBarTexture(TEXTURE)
				Rune:SetBackdrop(BACKDROP)
				Rune:SetBackdropColor(0, 0, 0)

				if(index == 1) then
					Rune:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -4)
				else
					Rune:SetPoint('LEFT', Runes[index - 1], 'RIGHT', 4, 0)
				end

				local RuneBG = Rune:CreateTexture(nil, 'BACKGROUND')
				RuneBG:SetAllPoints()
				RuneBG:SetTexture(TEXTURE)
				RuneBG.multiplier = 1/3
				Rune.bg = RuneBG

				Runes[index] = Rune
			end
			self.Runes = Runes

			self.colors.runes[1] = {0.9, 0.15, 0.15}
			self.colors.runes[2] = {0.4, 0.9, 0.3}
			self.colors.runes[3] = {0, 0.7, 0.9}
			self.colors.runes[4] = {0.5, 0.27, 0.68}
		elseif(playerClass == 'DRUID') then
			local EclipseBar = CreateFrame('Frame', nil, self)
			EclipseBar:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -4)
			EclipseBar:SetSize(230, 6)
			EclipseBar:SetBackdrop(BACKDROP)
			EclipseBar:SetBackdropColor(0, 0, 0)

			local LunarBar = CreateFrame('StatusBar', nil, EclipseBar)
			LunarBar:SetPoint('LEFT')
			LunarBar:SetSize(230, 6)
			LunarBar:SetStatusBarTexture(TEXTURE)
			LunarBar:SetStatusBarColor(4/5, 3/5, 0)
			EclipseBar.LunarBar = LunarBar

			local SolarBar = EclipseBar:CreateTexture(nil, 'BORDER')
			SolarBar:SetAllPoints()
			SolarBar:SetTexture(1/4, 2/5, 5/6)

			if(WoD) then
				self.Eclipse = EclipseBar
				self:RegisterEvent('PLAYER_TALENT_UPDATE', UpdateEclipseVisibility, true)
				self:RegisterEvent('UPDATE_SHAPESHIFT_FORM', UpdateEclipseVisibility, true)
				self:RegisterEvent('UNIT_POWER_FREQUENT', UpdateEclipse)
				UpdateEclipseVisibility(self)
				UpdateEclipse(self, nil, 'player')
			else
				self.EclipseBar = EclipseBar
			end
		elseif(playerClass == 'WARLOCK') then
			local BurningEmbers = {}
			for index = 1, 4 do
				local Ember = CreateFrame('StatusBar', nil, self)
				Ember:SetSize(index > 2 and 55 or 54, 6)
				Ember:SetStatusBarTexture(TEXTURE)
				Ember:SetBackdrop(BACKDROP)
				Ember:SetBackdropColor(0, 0, 0)

				if(index == 1) then
					Ember:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -4)
				else
					Ember:SetPoint('LEFT', BurningEmbers[index - 1], 'RIGHT', 4, 0)
				end

				local EmberBG = Ember:CreateTexture(nil, 'BORDER')
				EmberBG:SetAllPoints()

				if(IsSpellKnown(WARLOCK_GREEN_FIRE)) then
					Ember:SetStatusBarColor(1/2, 3/4, 0.1)
					EmberBG:SetTexture(1/5, 1/4, 0)
				else
					Ember:SetStatusBarColor(2/3, 1/5, 0)
					EmberBG:SetTexture(1/7, 0.1, 0.1)
				end

				BurningEmbers[index] = Ember
			end
			self.BurningEmbers = BurningEmbers

			local DemonicFury = CreateFrame('StatusBar', nil, self)
			DemonicFury:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -4)
			DemonicFury:SetSize(230, 6)
			DemonicFury:SetStatusBarTexture(TEXTURE)
			DemonicFury:SetStatusBarColor(3/5, 1/2, 4/5)
			DemonicFury:SetBackdrop(BACKDROP)
			DemonicFury:SetBackdropColor(0, 0, 0)
			self.DemonicFury = DemonicFury

			local DemonicFuryBG = DemonicFury:CreateTexture(nil, 'BORDER')
			DemonicFuryBG:SetAllPoints()
			DemonicFuryBG:SetTexture(1/5, 1/6, 1/4)
		end

		self.Debuffs.size = 22
		self.Debuffs:SetSize(230, 22)
		self.Debuffs.PostUpdateIcon = PostUpdateBuff
		self.Buffs.PostUpdateIcon = PostUpdateBuff
		self.Buffs.CustomFilter = FilterPlayerBuffs

		self:Tag(self.HealthValue, '[p3lim:pethp< : ][p3lim:status][p3lim:maxhp][|cffff8080->p3lim:defhp<|r][ >p3lim:perhp<|cff0090ff%|r]')
		self:SetWidth(230)
	end,
	target = function(self)
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
		self:Tag(self.Name, '[raidcolor][name]')
		self:Tag(self.HealthValue, '[p3lim:perhp<|cff0090ff%|r]')
		self.Health:SetHeight(17)
	end
}
UnitSpecific.raid = UnitSpecific.party

local function Shared(self, unit)
	unit = unit:match('(boss)%d?$') or unit:match('(arena)%d?$') or unit

	self.colors.power.MANA = {0, 144/255, 1}

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
	HealthBG:SetTexture(1/3, 1/3, 1/3)

	local HealthValue = Health:CreateFontString(nil, 'OVERLAY')
	HealthValue:SetPoint('RIGHT', -2, 0)
	HealthValue:SetFont(FONT, 8, 'OUTLINEMONOCHROME')
	HealthValue:SetJustifyH('RIGHT')
	self.HealthValue = HealthValue

	if(unit == 'player' or unit == 'target' or unit == 'arena') then
		local Power = CreateFrame('StatusBar', nil, self)
		Power:SetPoint('BOTTOMRIGHT')
		Power:SetPoint('BOTTOMLEFT')
		Power:SetPoint('TOP', Health, 'BOTTOM', 0, -1)
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
			local Buffs = CreateFrame('Frame', nil, self)
			Buffs:SetPoint('TOPLEFT', self, 'TOPRIGHT', 4, 0)
			Buffs:SetSize(236, 44)
			Buffs.num = 20
			Buffs.size = 22
			Buffs.spacing = 4
			Buffs.initialAnchor = 'TOPLEFT'
			Buffs['growth-y'] = 'DOWN'
			Buffs.PostCreateIcon = PostCreateAura
			self.Buffs = Buffs

			local ScrollFrame = CreateFrame('ScrollFrame', nil, Health)
			ScrollFrame:SetPoint('LEFT')
			ScrollFrame:SetSize(230, 20)

			local ScrollChild = CreateFrame('Frame')
			ScrollChild:SetSize(ScrollFrame:GetSize())
			ScrollFrame:SetScrollChild(ScrollChild)

			local Portrait = CreateFrame('PlayerModel', nil, ScrollChild)
			Portrait:SetAllPoints()
			Portrait:SetAlpha(0.1)
			Portrait.scrollFrame = ScrollFrame
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
		Spark:SetTexture(1, 1, 1)
		Castbar.Spark = Spark

		local RaidIcon = Health:CreateTexture(nil, 'OVERLAY')
		RaidIcon:SetPoint('TOP', self, 0, 8)
		RaidIcon:SetSize(16, 16)
		self.RaidIcon = RaidIcon

		Health:SetPoint('TOPRIGHT')
		Health:SetPoint('TOPLEFT')
	end

	if(unit == 'target' or unit == 'focus' or unit == 'targettarget' or unit == 'boss') then
		local Name = Health:CreateFontString(nil, 'OVERLAY')
		Name:SetPoint('LEFT', 2, 0)
		Name:SetPoint('RIGHT', HealthValue, 'LEFT')
		Name:SetFont(FONT, 8, 'OUTLINEMONOCHROME')
		Name:SetJustifyH('LEFT')
		self:Tag(Name, '[p3lim:color][name][ |cff0090ff>rare<|r]')
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
		local Name = self.Health:CreateFontString(nil, 'OVERLAY')
		Name:SetPoint('LEFT', 3, 0)
		Name:SetPoint('RIGHT', self.HealthValue, 'LEFT')
		Name:SetFont(FONT, 8, 'OUTLINEMONOCHROME')
		Name:SetJustifyH('LEFT')
		self.Name = Name

		local Resurrect = Health:CreateTexture(nil, 'OVERLAY')
		Resurrect:SetPoint('CENTER', 0, -1)
		Resurrect:SetSize(16, 16)
		Resurrect.PostUpdate = PostUpdateResurrect
		self.ResurrectIcon = Resurrect

		self:RegisterEvent('UNIT_AURA', PostUpdateResurrect)
	elseif(unit ~= 'boss') then
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
		'showParty', true, 'showRaid', true, 'showPlayer', true, 'yOffset', -6,
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

		local blizz = _G['Boss' .. index .. 'TargetFrame']
		blizz:UnregisterAllEvents()
		blizz:Hide()
	end
end)

local preparationFrames = {}
for index = 1, 5 do
	local Frame = CreateFrame('Frame', 'oUF_P3limArenaPreparation' .. index, UIParent)
	Frame:SetSize(126, 19)
	Frame:SetBackdrop(BACKDROP)
	Frame:SetBackdropColor(0, 0, 0)
	Frame:Hide()

	local Health = Frame:CreateTexture()
	Health:SetPoint('TOPRIGHT')
	Health:SetPoint('TOPLEFT')
	Health:SetHeight(17)
	Health:SetTexture(1/6, 1/6, 2/7)

	local Power = Frame:CreateTexture()
	Power:SetPoint('BOTTOMRIGHT')
	Power:SetPoint('BOTTOMLEFT')
	Power:SetPoint('TOP', Health, 'BOTTOM', 0, -1)
	Frame.Power = Power

	local Spec = Frame:CreateFontString(nil, 'OVERLAY')
	Spec:SetPoint('LEFT', Health, 2, 0)
	Spec:SetFont(FONT, 8, 'OUTLINEMONOCHROME')
	Spec:SetJustifyH('LEFT')
	Frame.Spec = Spec

	preparationFrames[index] = Frame
end

local PreparationHandler = CreateFrame('Frame')
PreparationHandler:RegisterEvent('PLAYER_LOGIN')
PreparationHandler:RegisterEvent('ARENA_OPPONENT_UPDATE')
PreparationHandler:RegisterEvent('ARENA_PREP_OPPONENT_SPECIALIZATIONS')
PreparationHandler:SetScript('OnEvent', function(self, event)
	if(event == 'PLAYER_LOGIN') then
		for index = 1, 5 do
			if(index == 1) then
				preparationFrames[index]:SetPoint('TOP', oUF_P3limRaid or Minimap, 'BOTTOM', 0, -20)
			else
				preparationFrames[index]:SetPoint('TOP', preparationFrames[index - 1], 'BOTTOM', 0, -6)
			end
		end
	elseif(event == 'ARENA_OPPONENT_UPDATE') then
		for index = 1, 5 do
			preparationFrames[index]:Hide()
		end

		return
	end

	for index = 1, GetNumArenaOpponentSpecs() do
		local Frame = preparationFrames[index]

		local specID, gender = GetArenaOpponentSpec(index)
		if(specID and specID > 0) then
			local _, name, _, _, _, _, class = GetSpecializationInfoByID(specID, gender)
			local color = RAID_CLASS_COLORS[class]

			Frame.Spec:SetFormattedText('|c%s%s|r', color.colorStr, name)
			Frame.Power:SetTexture(color.r, color.g, color.b)
		else
			Frame.Spec:SetText('Unknown')
			Frame.Power:SetTexture(1, 1, 1)
		end

		Frame:Show()
	end
end)
