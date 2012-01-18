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
	ToggleDropDownMenu(1, nil, _G[string.gsub(self.unit, '^.', string.upper)..'FrameDropDown'], 'cursor')
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

local CLEU, PostUpdateDebuff
do
	local stack = 0
	function PostUpdateDebuff(element, unit, button, index)
		local _, _, _, count, type, _, _, owner, _, _, id = UnitAura(unit, index, button.filter)
		local color = DebuffTypeColor[type or 'none']

		if(owner == 'player') then
			button:SetBackdropColor(color.r * 3/5, color.g * 3/5, color.b * 3/5)
			button.icon:SetDesaturated(false)
		else
			button:SetBackdropColor(0, 0, 0)
			button.icon:SetDesaturated(true)
		end

		if(id == 1079 and owner == 'player') then
			if(stack) then
				button.count:SetText(stack > 0 and stack or '')
			end
		elseif(not count or count < 2) then
			button.count:SetText()
		end
	end

	local player, glyphed
	function CLEU(self, ...)
		if(not glyphed) then return end
		if(not player) then
			player = UnitGUID('player')
		end

		local _, _, event, _, source, _, _, _, _, _, _, _, spell = ...
		if(source ~= player) then return end

		if(spell == 1079) then
			if(event == 'SPELL_AURA_APPLIED' or event == 'SPELL_AURA_REFRESH' or event == 'SPELL_AURA_REMOVED') then
				stack = 0
				self.Debuffs:ForceUpdate()
			end
		end

		if(event == 'SPELL_DAMAGE') then
			if(spell == 5221 and stack < 3) then
				stack = stack + 1
				self.Debuffs:ForceUpdate()
			elseif(spell == 22568) then
				if(UnitHealth('target') / UnitHealthMax('target') <= 0.25) then
					stack = 0
					self.Debuffs:ForceUpdate()
				end
			end
		end
	end

	local talentGroup
	local talents = CreateFrame('Frame')
	talents:RegisterEvent('PLAYER_TALENT_UPDATE')
	talents:RegisterEvent('GLYPH_UPDATED')
	talents:SetScript('OnEvent', function(self, event)
		for index = 1, NUM_GLYPH_SLOTS do
			local _, _, _, glyph = GetGlyphSocketInfo(index)
			if(glyph == 54815) then
				glyphed = true
				return
			end
		end
		glyphed = false
	end)
end

local FilterPlayerBuffs
do
	local spells = {
		[5217] = true, -- Tiger's Fury
		[50334] = true, -- Berserk
		[52610] = true, -- Savage Roar

		[5171] = true, -- Slice and Dice
		[13750] = true, -- Adrenaline Rush
		[13877] = true, -- Blade Flurry
		[84745] = true, -- Shallow Insight
		[84746] = true, -- Moderate Insight
		[84747] = true, -- Deep Insight

		[32182] = true, -- Heroism
		[80353] = true, -- Time Warp
		[79633] = true, -- Tol'vir Potion
	}

	function FilterPlayerBuffs(...)
		local _, _, _, _, _, _, _, _, _, _, _, _, _, id = ...
		return spells[id]
	end
end

local FilterTargetDebuffs
do
	local spells = {
		[770] = true, -- Faerie Fire
		[7386] = true, -- Sunder Armor
		[16511] = true, -- Hemorrhage
		[16857] = true, -- Faerie Fire (Feral)
		[33876] = true, -- Mangle (Cat)
		[33878] = true, -- Mangle (Bear)
		[46857] = true, -- Trauma
	}

	function FilterTargetDebuffs(...)
		local _, unit, _, _, _, _, _, _, _, _, owner, _, _, id = ...
		return owner == 'player' or owner == 'vehicle' or UnitIsFriend('player', unit) or spells[id]
	end
end

local UnitSpecific = {
	player = function(self)
		local powerValue = self.Health:CreateFontString(nil, 'OVERLAY')
		powerValue:SetPoint('LEFT', self.Health, 2, 0)
		powerValue:SetPoint('RIGHT', self.HealthValue, 'LEFT', -3)
		powerValue:SetFont(FONT, 8, 'OUTLINEMONOCHROME')
		powerValue:SetJustifyH('LEFT')
		powerValue.frequentUpdates = 0.1
		self:Tag(powerValue, '[p3lim:power][ >p3lim:druid][ | >p3lim:spell]')

		self.Debuffs.size = 22
		self.Debuffs:SetSize(230, 20)
		self.Buffs.CustomFilter = FilterPlayerBuffs

		self:Tag(self.HealthValue, '[p3lim:status][p3lim:player]')
		self:SetWidth(230)
	end,
	target = function(self)
		local cpoints = self:CreateFontString(nil, 'OVERLAY', 'SubZoneTextFont')
		cpoints:SetPoint('RIGHT', self, 'LEFT', -9, 0)
		cpoints:SetJustifyH('RIGHT')
		self:Tag(cpoints, '|cffffffff[cpoints]|r')

		self.Castbar.PostCastStart = PostUpdateCast
		self.Castbar.PostCastInterruptible = PostUpdateCast
		self.Castbar.PostCastNotInterruptible = PostUpdateCast
		self.Castbar.PostChannelStart = PostUpdateCast

		self.Debuffs.num = 20
		self.Debuffs.size = 19.4
		self.Debuffs['growth-y'] = 'DOWN'
		self.Debuffs:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -4)
		self.Debuffs:SetSize(230, 19.4)
		self.Debuffs.CustomFilter = FilterTargetDebuffs
		self.Debuffs.PostUpdateIcon = PostUpdateDebuff

		if(select(2, UnitClass('player')) == 'DRUID') then
			self:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED', CLEU)
		end

		self.Power.PostUpdate = PostUpdatePower
		self:Tag(self.HealthValue, '[p3lim:status][p3lim:hostile][p3lim:friendly]')
		self:SetWidth(230)
	end,
	party = function(self)
		local name = self.Health:CreateFontString(nil, 'OVERLAY')
		name:SetPoint('LEFT', 3, 0)
		name:SetFont(FONT, 8, 'OUTLINEMONOCHROME')
		name:SetJustifyH('LEFT')
		self:Tag(name, '[p3lim:unbuffed< ][p3lim:leader][raidcolor][name]')

		local roleicon = self:CreateTexture(nil, 'ARTWORK')
		roleicon:SetPoint('LEFT', self, 'RIGHT', 3, 0)
		roleicon:SetSize(14, 14)
		roleicon:SetAlpha(0)
		self.LFDRole = roleicon

		self:HookScript('OnEnter', function() roleicon:SetAlpha(1) end)
		self:HookScript('OnLeave', function() roleicon:SetAlpha(0) end)

		self.Health:SetAllPoints()
		self:Tag(self.HealthValue, '[p3lim:status][p3lim:percent]')
	end
}
UnitSpecific.raid = UnitSpecific.party

local function Shared(self, unit)
	self.colors.power.MANA = {0, 144/255, 1}

	self:RegisterForClicks('AnyUp')
	self:SetScript('OnEnter', UnitFrame_OnEnter)
	self:SetScript('OnLeave', UnitFrame_OnLeave)

	self:SetBackdrop(BACKDROP)
	self:SetBackdropColor(0, 0, 0)

	local health = CreateFrame('StatusBar', nil, self)
	health:SetStatusBarTexture(TEXTURE)
	health:SetStatusBarColor(1/6, 1/6, 2/7)
	health.frequentUpdates = true
	self.Health = health

	local healthBG = health:CreateTexture(nil, 'BORDER')
	healthBG:SetAllPoints()
	healthBG:SetTexture(1/3, 1/3, 1/3)

	local healthValue = health:CreateFontString(nil, 'OVERLAY')
	healthValue:SetPoint('RIGHT', health, -2, 0)
	healthValue:SetFont(FONT, 8, 'OUTLINEMONOCHROME')
	healthValue:SetJustifyH('RIGHT')
	healthValue.frequentUpdates = 1/4
	self.HealthValue = healthValue

	if(unit == 'player' or unit == 'target') then
		local power = CreateFrame('StatusBar', nil, self)
		power:SetPoint('BOTTOMRIGHT')
		power:SetPoint('BOTTOMLEFT')
		power:SetPoint('TOP', health, 'BOTTOM', 0, -1)
		power:SetStatusBarTexture(TEXTURE)
		power.frequentUpdates = true
		self.Power = power

		power.colorClass = true
		power.colorTapping = true
		power.colorDisconnected = true
		power.colorReaction = true

		local powerBG = power:CreateTexture(nil, 'BORDER')
		powerBG:SetAllPoints()
		powerBG:SetTexture(TEXTURE)
		powerBG.multiplier = 1/3
		power.bg = powerBG

		local buffs = CreateFrame('Frame', nil, self)
		buffs:SetPoint('TOPLEFT', self, 'TOPRIGHT', 4, 0)
		buffs:SetSize(236, 44)
		buffs.num = 20
		buffs.size = 22
		buffs.spacing = 4
		buffs.initialAnchor = 'TOPLEFT'
		buffs['growth-y'] = 'DOWN'
		buffs.PostCreateIcon = PostCreateAura
		self.Buffs = buffs

		local castbar = CreateFrame('StatusBar', nil, self)
		castbar:SetAllPoints(health)
		castbar:SetStatusBarTexture(TEXTURE)
		castbar:SetStatusBarColor(0, 0, 0, 0)
		castbar:SetToplevel(true)
		self.Castbar = castbar

		local spark = castbar:CreateTexture(nil, 'OVERLAY')
		spark:SetSize(2, 20)
		spark:SetTexture(1, 1, 1)
		castbar.Spark = spark

		local raidicon = health:CreateTexture(nil, 'OVERLAY')
		raidicon:SetPoint('TOP', self, 0, 8)
		raidicon:SetSize(16, 16)
		self.RaidIcon = raidicon

		health:SetHeight(20)
		health:SetPoint('TOPRIGHT')
		health:SetPoint('TOPLEFT')

		self.menu = SpawnMenu
		self:SetHeight(22)
	end

	if(unit ~= 'player' and unit ~= 'party' and unit ~= 'raid') then
		local name = health:CreateFontString(nil, 'OVERLAY')
		name:SetPoint('LEFT', health, 2, 0)
		name:SetPoint('RIGHT', healthValue, 'LEFT')
		name:SetFont(FONT, 8, 'OUTLINEMONOCHROME')
		name:SetJustifyH('LEFT')
		self:Tag(name, '[p3lim:color][name][ |cff0090ff>rare<|r]')
	end

	if(unit ~= 'party' and unit ~= 'raid') then
		local debuffs = CreateFrame('Frame', nil, self)
		debuffs.spacing = 4
		debuffs.initialAnchor = 'TOPLEFT'
		debuffs.PostCreateIcon = PostCreateAura
		self.Debuffs = debuffs

		if(unit == 'focus' or unit == 'targettarget') then
			debuffs.num = 3
			debuffs.size = 19
			debuffs:SetSize(230, 19)

			health:SetAllPoints()
			self:SetSize(161, 19)
		end

		if(unit == 'focus') then
			debuffs:SetPoint('TOPLEFT', self, 'TOPRIGHT', 4, 0)
			debuffs.onlyShowPlayer = true
		elseif(unit == 'player' or unit == 'targettarget') then
			debuffs:SetPoint('TOPRIGHT', self, 'TOPLEFT', -4, 0)
			debuffs.initialAnchor = 'TOPRIGHT'
			debuffs['growth-x'] = 'LEFT'
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

	if(select(2, UnitClass'player') == 'SHAMAN') then return end
	self:SpawnHeader(nil, nil, 'party,raid10',
		'showParty', true, 'showRaid', true, 'showPlayer', true, 'yOffset', -6,
		'oUF-initialConfigFunction', [[
			self:SetHeight(16)
			self:SetWidth(126)
		]]
	):SetPoint('TOP', Minimap, 'BOTTOM', 0, -10)
end)
