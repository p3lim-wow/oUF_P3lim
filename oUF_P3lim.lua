--[[

  Adrian L Lange grants anyone the right to use this work for any purpose,
  without any conditions, unless such conditions are required by law.

--]]

local _, ns = ...
local oUF = ns.oUF

local FONT = [=[Interface\AddOns\oUF_P3lim\semplice.ttf]=]
local TEXTURE = [=[Interface\ChatFrame\ChatFrameBackground]=]
local BACKDROP = {
	bgFile = TEXTURE, insets = {top = -1, bottom = -1, left = -1, right = -1}
}

local function PostUpdatePower(element, unit, min, max)
	element:GetParent().Health:SetHeight(max ~= 0 and 20 or 22)
end

local function PostUpdateCast(element, unit)
	local Spark = element.Spark
	if(not element.interrupt and UnitCanAttack('player', unit)) then
		Spark:SetTexture(1, 0, 0)
	else
		Spark:SetTexture(1, 1, 1)
	end
end

local function UpdateRuneState(self)
	local opacity
	if(UnitHasVehicleUI('player') or UnitIsDeadOrGhost('player')) then
		opacity = 0
	elseif(UnitAffectingCombat('player')) then
		opacity = 1
	elseif(UnitExists('target') and UnitCanAttack('player', 'target')) then
		opacity = 0.8
	else
		opacity = 0

		for index = 1, 6 do
			local _, _, ready = GetRuneCooldown(index)
			if(not ready) then
				opacity = 0.5
				break
			end
		end
	end

	local current = self:GetAlpha()
	if(opacity > current) then
		UIFrameFadeIn(self, 1/4, current, opacity)
	elseif(opacity < current) then
		UIFrameFadeOut(self, 1/4, current, opacity)
	end
end

local function UpdateRunes(self, elapsed)
	local duration = self.duration + elapsed
	if(duration >= 1) then
		self:SetScript('OnUpdate', nil)
	else
		self.duration = duration
		self:SetValue(math.max(duration, 0))
	end

	local Background = self.Background
	if(Background:GetHeight() <= 2.1) then
		Background:Hide()
	else
		Background:Show()
	end
end

local function PostUpdateRune(element, Rune, id, start, duration, ready)
	local Overlay = Rune.Overlay
	if(ready) then
		Overlay:SetValue(1)
		Overlay:SetScript('OnUpdate', nil)
		Overlay.Background:Show()
	else
		Overlay.duration = GetTime() - (start + duration - 1)
		Overlay:SetScript('OnUpdate', UpdateRunes)
	end
end

local function PostUpdateRuneType(element, Rune)
	local r, g, b = Rune:GetStatusBarColor()
	Rune:SetStatusBarColor(r * 0.7, g * 0.7, b * 0.7)
	Rune.Overlay:SetStatusBarColor(r, g, b)
end

local function UpdateEmbers(self, event, unit, powerType)
	if(not self:IsShown()) then return end
	if(powerType ~= 'BURNING_EMBERS') then return end

	local cur = UnitPower(unit, SPELL_POWER_BURNING_EMBERS, true)
	local max = UnitPowerMax(unit, SPELL_POWER_BURNING_EMBERS, true)

	for index = 1, 4 do
		local Ember = self[index]
		Ember:SetMinMaxValues(0, 10)
		Ember:SetValue(cur)

		cur = cur - 10
	end
end

local function UpdateEmbersVisibility(self)
	if(GetSpecialization() == SPEC_WARLOCK_DESTRUCTION and UnitLevel('player') >= 42 and not (UnitHasVehicleUI('player') or UnitIsDeadOrGhost('player'))) then
		self.BurningEmbers:Show()

		UpdateEmbers(self.BurningEmbers, nil, 'player', 'BURNING_EMBERS')
	else
		self.BurningEmbers:Hide()
	end
end

local function PostUpdateEclipse(element)
	local direction = GetEclipseDirection()
	if(direction == 'sun') then
		element.SolarBar:SetStatusBarColor(1/4, 2/5, 5/6)
		element.LunarBar:SetStatusBarColor(1/3, 1/3, 1/3)
	elseif(direction == 'moon') then
		element.LunarBar:SetStatusBarColor(4/5, 3/5, 0)
		element.SolarBar:SetStatusBarColor(1/3, 1/3, 1/3)
	else
		element.LunarBar:SetStatusBarColor(4/5, 3/5, 0)
		element.SolarBar:SetStatusBarColor(1/4, 2/5, 5/6)
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
		PowerValue.frequentUpdates = 0.1
		self:Tag(PowerValue, '[p3lim:power][ |cff00ff96>chi][ |cfffff568>holypower][ |cff7b68ee>shadoworbs][ |cffba55d3>p3lim:shards][ |cff997fcc>p3lim:fury<|r][ |cff0090ff>p3lim:mana<|r][ | >p3lim:spell]')

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
		if(playerClass == 'DEATHKNIGHT') then
			local Parent = CreateFrame('Frame', nil, UIParent)
			Parent:SetPoint('CENTER', 0, -230)
			Parent:SetSize(82, 40)

			Parent:RegisterEvent('UNIT_EXITED_VEHICLE')
			Parent:RegisterEvent('UNIT_ENTERED_VEHICLE')
			Parent:RegisterEvent('PLAYER_ENTERING_WORLD')
			Parent:RegisterEvent('PLAYER_TARGET_CHANGED')
			Parent:RegisterEvent('PLAYER_REGEN_DISABLED')
			Parent:RegisterEvent('PLAYER_REGEN_ENABLED')
			Parent:RegisterEvent('RUNE_POWER_UPDATE')
			Parent:SetScript('OnEvent', UpdateRuneState)

			local Runes = {}
			for index = 1, 6 do
				local Rune = CreateFrame('StatusBar', nil, Parent)
				Rune:SetPoint('BOTTOMLEFT', 3 + (index - 1) * 13, 0)
				Rune:SetSize(10, 38)
				Rune:SetOrientation('VERTICAL')
				Rune:SetStatusBarTexture(TEXTURE)
				Rune:SetAlpha(0.7)

				local Overlay = CreateFrame('StatusBar', nil, Parent)
				Overlay:SetAllPoints(Rune)
				Overlay:SetOrientation('VERTICAL')
				Overlay:SetStatusBarTexture(TEXTURE)
				Overlay:SetMinMaxValues(0, 1)
				Overlay:SetFrameLevel(3)
				Rune.Overlay = Overlay

				local RuneBG = Parent:CreateTexture(nil, 'BORDER')
				RuneBG:SetPoint('BOTTOM', Rune, 0, -1)
				RuneBG:SetPoint('TOP', Rune:GetStatusBarTexture(), 0, 1)
				RuneBG:SetSize(12, 40)
				RuneBG:SetTexture(0, 0, 0)
				Overlay.Background = RuneBG

				Runes[index] = Rune
			end

			Runes.PostUpdateRune = PostUpdateRune
			Runes.PostUpdateType = PostUpdateRuneType

			self.Runes = Runes

			self.colors.runes[1] = {0.9, 0.15, 0.15}
			self.colors.runes[2] = {0.4, 0.9, 0.3}
			self.colors.runes[3] = {0, 0.7, 0.9}
			self.colors.runes[4] = {0.5, 0.27, 0.68}
		elseif(playerClass == 'DRUID') then
			local EclipseBar = CreateFrame('Frame', nil, self)
			EclipseBar:SetPoint('BOTTOM', 0, -10)
			EclipseBar:SetSize(230, 6)
			EclipseBar:SetBackdrop(BACKDROP)
			EclipseBar:SetBackdropColor(0, 0, 0)
			EclipseBar.PostDirectionChange = PostUpdateEclipse
			self.EclipseBar = EclipseBar

			local LunarBar = CreateFrame('StatusBar', nil, EclipseBar)
			LunarBar:SetPoint('LEFT')
			LunarBar:SetSize(230, 6)
			LunarBar:SetStatusBarTexture(TEXTURE)
			EclipseBar.LunarBar = LunarBar

			local SolarBar = CreateFrame('StatusBar', nil, EclipseBar)
			SolarBar:SetPoint('LEFT', LunarBar:GetStatusBarTexture(), 'RIGHT')
			SolarBar:SetSize(230, 6)
			SolarBar:SetStatusBarTexture(TEXTURE)
			EclipseBar.SolarBar = SolarBar
		elseif(playerClass == 'WARLOCK') then
			local BurningEmbers = CreateFrame('Frame', nil, self)
			BurningEmbers:SetPoint('BOTTOM', 0, -10)
			BurningEmbers:SetSize(230, 6)
			BurningEmbers:SetBackdrop(BACKDROP)
			BurningEmbers:SetBackdropColor(0, 0, 0)
			BurningEmbers:RegisterUnitEvent('UNIT_POWER_FREQUENT', 'player')
			BurningEmbers:RegisterUnitEvent('UNIT_DISPLAYPOWER', 'player')
			BurningEmbers:SetScript('OnEvent', UpdateEmbers)
			self.BurningEmbers = BurningEmbers

			for index = 1, 4 do
				local Ember = CreateFrame('StatusBar', nil, BurningEmbers)
				Ember:SetPoint('BOTTOMLEFT', (index - 1) * 58, 0)
				Ember:SetSize(index == 4 and 56 or 57, 6)
				Ember:SetStatusBarTexture(TEXTURE)
				BurningEmbers[index] = Ember

				local EmberBG = Ember:CreateTexture(nil, 'BORDER')
				EmberBG:SetAllPoints()

				if(IsSpellKnown(101508)) then
					Ember:SetStatusBarColor(1/2, 3/4, 0.1)
					EmberBG:SetTexture(1/5, 1/4, 0)
				else
					Ember:SetStatusBarColor(2/3, 1/5, 0)
					EmberBG:SetTexture(1/7, 0.1, 0.1)
				end
			end

			self:RegisterEvent('UNIT_EXITED_VEHICLE', UpdateEmbersVisibility)
			self:RegisterEvent('UNIT_ENTERED_VEHICLE', UpdateEmbersVisibility)
			self:RegisterEvent('SPELLS_CHANGED', UpdateEmbersVisibility)
		end

		self.Debuffs.size = 22
		self.Debuffs:SetSize(230, 22)
		self.Debuffs.PostUpdateIcon = PostUpdateBuff
		self.Buffs.PostUpdateIcon = PostUpdateBuff
		self.Buffs.CustomFilter = FilterPlayerBuffs

		self:Tag(self.HealthValue, '[p3lim:pet< : ][p3lim:status][p3lim:player]')
		self:SetWidth(230)
	end,
	target = function(self)
		local ComboPoints = self:CreateFontString(nil, 'OVERLAY', 'SubZoneTextFont')
		ComboPoints:SetPoint('RIGHT', self, 'LEFT', -9, -2)
		ComboPoints:SetJustifyH('RIGHT')
		ComboPoints:SetTextColor(1, 1, 1)
		self:Tag(ComboPoints, '[cpoints]')

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
		self:Tag(self.HealthValue, '[p3lim:status][p3lim:hostile][p3lim:friendly]')
		self:SetWidth(230)
	end,
	party = function(self)
		local Name = self.Health:CreateFontString(nil, 'OVERLAY')
		Name:SetPoint('LEFT', 3, 0)
		Name:SetPoint('RIGHT', self.HealthValue, 'LEFT')
		Name:SetFont(FONT, 8, 'OUTLINEMONOCHROME')
		Name:SetJustifyH('LEFT')
		self:Tag(Name, '[p3lim:unbuffed< ][p3lim:leader][raidcolor][name]')

		local RoleIcon = self:CreateTexture(nil, 'ARTWORK')
		RoleIcon:SetPoint('LEFT', self, 'RIGHT', 3, 0)
		RoleIcon:SetSize(14, 14)
		RoleIcon:SetAlpha(0)
		self.LFDRole = RoleIcon

		local ReadyCheck = self:CreateTexture(nil, 'OVERLAY')
		ReadyCheck:SetPoint('LEFT', self, 'RIGHT', 3, 0)
		ReadyCheck:SetSize(14, 14)
		self.ReadyCheck = ReadyCheck

		self:HookScript('OnEnter', function() RoleIcon:SetAlpha(1) end)
		self:HookScript('OnLeave', function() RoleIcon:SetAlpha(0) end)

		self.Health:SetAllPoints()
		self:Tag(self.HealthValue, '[p3lim:status][p3lim:percent]')
	end,
	boss = function(self)
		self:SetSize(126, 19)
		self.Health:SetAllPoints()
		self:Tag(self.HealthValue, '[p3lim:percent]')
	end,
	arena = function(self)
		self:SetSize(126, 19)
		self:Tag(self.HealthValue, '[p3lim:percent]')
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
	HealthValue.frequentUpdates = 1/4
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

			self:SetHeight(22)
			Health:SetHeight(20)
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

	if(unit ~= 'player' and unit ~= 'party' and unit ~= 'raid') then
		local Name = Health:CreateFontString(nil, 'OVERLAY')
		Name:SetPoint('LEFT', 2, 0)
		Name:SetPoint('RIGHT', HealthValue, 'LEFT')
		Name:SetFont(FONT, 8, 'OUTLINEMONOCHROME')
		Name:SetJustifyH('LEFT')
		self:Tag(Name, '[p3lim:color][name][ |cff0090ff>rare<|r]')
	end

	if(unit ~= 'party' and unit ~= 'raid' and unit ~= 'boss') then
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

local preperationFrames = {}
for index = 1, 5 do
	local Frame = CreateFrame('Frame', 'oUF_P3limArenaPreperation' .. index, UIParent)
	Frame:SetSize(126, 19)
	Frame:SetBackdrop(BACKDROP)
	Frame:SetBackdropColor(0, 0, 0)
	Frame:Hide()

	local Health = Frame:CreateTexture(nil, 'BACKGROUND')
	Health:SetPoint('TOPRIGHT')
	Health:SetPoint('TOPLEFT')
	Health:SetHeight(17)
	Health:SetTexture(1/6, 1/6, 2/7)

	local Power = Frame:CreateTexture(nil, 'BACKGROUND')
	Power:SetPoint('BOTTOMRIGHT')
	Power:SetPoint('BOTTOMLEFT')
	Power:SetPoint('TOP', Health, 'BOTTOM', 0, -1)
	Frame.Power = Power

	local Spec = Frame:CreateFontString(nil, 'OVERLAY')
	Spec:SetPoint('LEFT', Health, 2, 0)
	Spec:SetFont(FONT, 8, 'OUTLINEMONOCHROME')
	Spec:SetJustifyH('LEFT')
	Frame.Spec = Spec

	preperationFrames[index] = Frame
end

local PreperationHandler = CreateFrame('Frame')
PreperationHandler:RegisterEvent('PLAYER_LOGIN')
PreperationHandler:RegisterEvent('ARENA_OPPONENT_UPDATE')
PreperationHandler:RegisterEvent('ARENA_PREP_OPPONENT_SPECIALIZATIONS')
PreperationHandler:SetScript('OnEvent', function(self, event)
	if(event == 'PLAYER_LOGIN') then
		for index = 1, 5 do
			if(index == 1) then
				preperationFrames[index]:SetPoint('TOP', oUF_P3limRaid or Minimap, 'BOTTOM', 0, -20)
			else
				preperationFrames[index]:SetPoint('TOP', preperationFrames[index - 1], 'BOTTOM', 0, -6)
			end
		end
	elseif(event == 'ARENA_OPPONENT_UPDATE') then
		for index = 1, 5 do
			preperationFrames[index]:Hide()
		end
	else
		for index = 1, GetNumArenaOpponentSpecs() do
			local Frame = preperationFrames[index]

			local specID = GetArenaOpponentSpec(index)
			if(specID and specID > 0) then
				local _, name, _, _, _, _, class = GetSpecializationInfoByID(specID)
				local r, g, b, colorStr = RAID_CLASS_COLORS[class]

				Frame.Spec:SetFormattedText('|c%s%s|r', colorStr, name)
				Frame.Power:SetTexture(r, g, b)
			else
				Frame.Spec:SetText('Unknown')
				Frame.Power:SetTexture(1, 1, 1)
			end

			Frame:Show()
		end
	end
end)
