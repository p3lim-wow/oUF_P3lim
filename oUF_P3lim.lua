--[[

  Adrian L Lange grants anyone the right to use this work for any purpose,
  without any conditions, unless such conditions are required by law.

--]]

local FONT = [=[Interface\AddOns\oUF_P3lim\semplice.ttf]=]
local TEXTURE = [=[Interface\ChatFrame\ChatFrameBackground]=]
local BACKDROP = {
	bgFile = TEXTURE, insets = {top = -1, bottom = -1, left = -1, right = -1}
}

local function SpawnMenu(self)
	local dropdown = _G[string.gsub(self.unit, '^.', string.upper)..'FrameDropDown']
	if(dropdown) then
		ToggleDropDownMenu(1, nil, dropdown, 'cursor')
	end
end

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

local function PostCreateAura(element, button)
	button:SetBackdrop(BACKDROP)
	button:SetBackdropColor(0, 0, 0)
	button.cd:SetReverse()
	button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	button.icon:SetDrawLayer('ARTWORK')
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
end

local FilterPlayerBuffs
do
	local spells = {
		-- Druid
		[5217] = true, -- Tiger's Fury
		[52610] = true, -- Savage Roar
		[106951] = true, -- Berserk
		[127538] = true, -- Savage Roar (glyphed)
		[124974] = true, -- Nature's Vigil

		-- Shared
		[32182] = true, -- Heroism
		[57933] = true, -- Tricks of the Trade
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
		[81326] = true, -- Physical Vulnerability
		[113746] = true, -- Weakened Armor
	}

	function FilterTargetDebuffs(...)
		local _, unit, _, _, _, _, _, _, _, _, owner, _, _, id = ...
		return owner == 'player' or owner == 'vehicle' or UnitIsFriend('player', unit) or spells[id]
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
		self:Tag(PowerValue, '[|cffffff00>holypower<|r ][p3lim:power][ >p3lim:druid][ | >p3lim:spell]')

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

		self.Debuffs.size = 22
		self.Debuffs:SetSize(230, 22)
		self.Buffs.CustomFilter = FilterPlayerBuffs

		self:Tag(self.HealthValue, '[p3lim:status][p3lim:player]')
		self:SetWidth(230)
	end,
	target = function(self)
		local ComboPoints = self:CreateFontString(nil, 'OVERLAY', 'SubZoneTextFont')
		ComboPoints:SetPoint('RIGHT', self, 'LEFT', -9, 0)
		ComboPoints:SetJustifyH('RIGHT')
		self:Tag(ComboPoints, '|cffffffff[cpoints]|r')

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

		self:HookScript('OnEnter', function() RoleIcon:SetAlpha(1) end)
		self:HookScript('OnLeave', function() RoleIcon:SetAlpha(0) end)

		self.Health:SetAllPoints()
		self:Tag(self.HealthValue, '[p3lim:status][p3lim:percent]')
	end,
	boss = function(self)
		self:SetSize(126, 19)
		self.Health:SetAllPoints()
		self:Tag(self.HealthValue, '[p3lim:percent]')
	end
}
UnitSpecific.raid = UnitSpecific.party

local function Shared(self, unit)
	unit = unit:match('(boss)%d?$') or unit

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

	if(unit == 'player' or unit == 'target') then
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

		local Castbar = CreateFrame('StatusBar', nil, self)
		Castbar:SetAllPoints(Health)
		Castbar:SetStatusBarTexture(TEXTURE)
		Castbar:SetStatusBarColor(0, 0, 0, 0)
		Castbar:SetToplevel(true)
		self.Castbar = Castbar

		local Spark = Castbar:CreateTexture(nil, 'OVERLAY')
		Spark:SetSize(2, 20)
		Spark:SetTexture(1, 1, 1)
		Castbar.Spark = Spark

		local RaidIcon = Health:CreateTexture(nil, 'OVERLAY')
		RaidIcon:SetPoint('TOP', self, 0, 8)
		RaidIcon:SetSize(16, 16)
		self.RaidIcon = RaidIcon

		Health:SetHeight(20)
		Health:SetPoint('TOPRIGHT')
		Health:SetPoint('TOPLEFT')

		self.menu = SpawnMenu
		self:SetHeight(22)
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

	for index = 1, MAX_BOSS_FRAMES do
		local boss = self:Spawn('boss' .. index)
		if(index == 1) then
			boss:SetPoint('TOP', oUF_P3limRaid or Minimap, 'BOTTOM', 0, -20)
		else
			boss:SetPoint('TOP', _G['oUF_P3limBoss' .. index - 1], 'BOTTOM', 0, -6)
		end

		local blizz = _G['Boss' .. index .. 'TargetFrame']
		blizz:UnregisterAllEvents()
		blizz:Hide()
	end
end)
