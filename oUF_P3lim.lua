--[[

  Adrian L Lange grants anyone the right to use this work for any purpose,
  without any conditions, unless such conditions are required by law.

--]]

local _, ns = ...
ns.colors = setmetatable({
	power = setmetatable({
		MANA = {0, 144/255, 1}
	}, {__index = oUF.colors.power}),
	reaction = setmetatable({
		[2] = {1, 0, 0},
		[4] = {1, 1, 0},
		[5] = {0, 1, 0}
	}, {__index = oUF.colors.reaction}),
}, {__index = oUF.colors})


local FONT = [=[Interface\AddOns\oUF_P3lim\media\semplice.ttf]=]
local TEXTURE = [=[Interface\AddOns\oUF_P3lim\media\minimalist]=]
local BACKDROP = {
	bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
	insets = {top = -1, bottom = -1, left = -1, right = -1}
}

local function SpawnMenu(self)
	ToggleDropDownMenu(1, nil, _G[string.gsub(self.unit, '^.', string.upper)..'FrameDropDown'], 'cursor')
end

local function CustomCastText(element, duration)
	element.Time:SetFormattedText('%.1f', element.channeling and duration or (element.max - duration))
end

local function PostCastStart(element)
	local text = element.Text
	if(element.interrupt) then
		text:SetTextColor(1, 0, 0)
	else
		text:SetTextColor(1, 1, 1)
	end
end

local function PostUpdatePower(element, unit, min, max)
	element:GetParent().Health:SetHeight(max ~= 0 and 20 or 22)
end

local function PostCreateAura(element, button)
	button:SetBackdrop(BACKDROP)
	button:SetBackdropColor(0, 0, 0)
	button.cd:SetReverse()
	button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	button.icon:SetDrawLayer('ARTWORK')
end

local PostUpdateDebuff
do
	local units = {
		vehicle = true,
		player = true,
	}

	local spells = {
		[770] = true, -- Faerie Fire
		[16857] = true, -- Faerie Fire (Feral)
		[48564] = true, -- Mangle (Bear)
		[48566] = true, -- Mangle (Cat)
		[46857] = true, -- Trauma
	}

	function PostUpdateDebuff(element, unit, button, index)
		local _, _, _, _, type, _, _, owner, _, _, spell = UnitAura(unit, index, button.filter)

		if(UnitIsFriend('player', unit) or spells[spell] or units[owner]) then
			local color = DebuffTypeColor[type] or DebuffTypeColor.none
			button:SetBackdropColor(color.r * 3/5, color.g * 3/5, color.b * 3/5)
			button.icon:SetDesaturated(false)
		else
			button:SetBackdropColor(0, 0, 0)
			button.icon:SetDesaturated(true)
		end
	end
end

local CustomBuffFilter
do
	local spells = {
		[52610] = true, -- Druid: Savage Roar
		[16870] = true, -- Druid: Clearcast
		[50213] = true, -- Druid: Tiger's Fury
		[50334] = true, -- Druid: Berserk
		[57960] = true, -- Shaman: Water Shield
		[70806] = true, -- Shaman: T10 2pc Bonus
		[32182] = true, -- Buff: Heroism
		[49016] = true, -- Buff: Hysteria
	}

	function CustomBuffFilter(element, ...)
		local _, _, _, _, _, _, _, _, _, owner, _, _, spell = ...
		return spells[spell] and owner == 'player'
	end
end

local function Style(self, unit)
	self.colors = ns.colors

	self:RegisterForClicks('AnyUp')
	self:SetScript('OnEnter', UnitFrame_OnEnter)
	self:SetScript('OnLeave', UnitFrame_OnLeave)

	self:SetBackdrop(BACKDROP)
	self:SetBackdropColor(0, 0, 0)

	local petUnit = unit == 'pet'
	local slimUnit = (unit == 'focus' or unit == 'targettarget')

	local health = CreateFrame('StatusBar', nil, self)
	health:SetStatusBarTexture(TEXTURE)
	health:SetStatusBarColor(1/4, 1/4, 2/5)
	health:SetHeight(slimUnit and 19 or 20)
	health.frequentUpdates = true

	local healthBG = health:CreateTexture(nil, 'BORDER')
	healthBG:SetAllPoints(health)
	healthBG:SetTexture(1/3, 1/3, 1/3)

	local healthValue = health:CreateFontString(nil, 'OVERLAY')
	healthValue:SetPoint('RIGHT', health, -2, 0)
	healthValue:SetFont(FONT, 8, 'OUTLINE')
	healthValue:SetJustifyH('RIGHT')
	healthValue.frequentUpdates = 1/4

	self.Health = health
	self:Tag(healthValue, '[p3limhealth]')

	if(slimUnit) then
		local debuffs = CreateFrame('Frame', nil, self)
		debuffs:SetHeight(20)
		debuffs:SetWidth(44)
		debuffs.num = 2
		debuffs.size = 20
		debuffs.spacing = 4
		debuffs.PostCreateIcon = PostCreateAura

		if(unit == 'focus') then
			debuffs:SetPoint('TOPLEFT', self, 'TOPRIGHT', 4, 0)
			debuffs.initialAnchor = 'TOPLEFT'
			debuffs.onlyShowPlayer = true
		else
			debuffs:SetPoint('TOPRIGHT', self, 'TOPLEFT', -4, 0)
			debuffs.initialAnchor = 'TOPRIGHT'
			debuffs['growth-x'] = 'LEFT'
		end

		health:SetAllPoints(self)

		self.Debuffs = debuffs
		self:SetAttribute('initial-height', 19)
		self:SetAttribute('initial-width', 182)
	else
		local power = CreateFrame('StatusBar', nil, self)
		power:SetPoint('BOTTOMRIGHT')
		power:SetPoint('BOTTOMLEFT')
		power:SetPoint('TOP', health, 'BOTTOM', 0, -1)
		power:SetStatusBarTexture(TEXTURE)
		power.frequentUpdates = true

		power.colorClass = true
		power.colorTapping = true
		power.colorDisconnected = true
		power.colorReaction = not petUnit
		power.colorHappiness = petUnit
		power.colorPower = petUnit

		local powerBG = power:CreateTexture(nil, 'BORDER')
		powerBG:SetAllPoints(power)
		powerBG:SetTexture([=[Interface\ChatFrame\ChatFrameBackground]=])
		powerBG.multiplier = 1/3
		power.bg = powerBG

		local castbar = CreateFrame('StatusBar', nil, self)
		castbar:SetWidth(petUnit and 105 or 205)
		castbar:SetHeight(16)
		castbar:SetStatusBarTexture(TEXTURE)
		castbar:SetStatusBarColor(1/4, 1/4, 2/5)
		castbar:SetBackdrop(BACKDROP)
		castbar:SetBackdropColor(0, 0, 0)
		castbar.CustomTimeText = CustomCastTime

		local castbarBG = castbar:CreateTexture(nil, 'BORDER')
		castbarBG:SetAllPoints(castbar)
		castbarBG:SetTexture(1/3, 1/3, 1/3)

		local castbarTime = castbar:CreateFontString(nil, 'OVERLAY')
		castbarTime:SetPoint('RIGHT', -2, 0)
		castbarTime:SetFont(FONT, 8, 'OUTLINE')
		castbarTime:SetJustifyH('RIGHT')
		castbar.Time = castbarTime

		local castbarText = castbar:CreateFontString(nil, 'OVERLAY')
		castbarText:SetPoint('LEFT', 2, 0)
		castbarText:SetPoint('RIGHT', castbarTime)
		castbarText:SetFont(FONT, 8, 'OUTLINE')
		castbarText:SetJustifyH('LEFT')
		castbar.Text = castbarText

		local castbarDummy = CreateFrame('Frame', nil, castbar)
		castbarDummy:SetHeight(21)
		castbarDummy:SetWidth(21)
		castbarDummy:SetBackdrop(BACKDROP)
		castbarDummy:SetBackdropColor(0, 0, 0)

		local castbarIcon = castbarDummy:CreateTexture(nil, 'ARTWORK')
		castbarIcon:SetAllPoints(castbarDummy)
		castbarIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		castbar.Icon = castbarIcon

		if(unit == 'target') then
			castbar.PostCastStart = PostCastStart
			castbar.PostChannelStart = PostCastStart
			castbar:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -60)
			castbarDummy:SetPoint('BOTTOMLEFT', castbar, 'BOTTOMRIGHT', 4, 0)
		else
			castbar:SetPoint('TOPRIGHT', self, 'BOTTOMRIGHT', 0, -60)
			castbarDummy:SetPoint('BOTTOMRIGHT', castbar, 'BOTTOMLEFT', -4, 0)
		end

		local raidicon = health:CreateTexture(nil, 'OVERLAY')
		raidicon:SetPoint('TOP', self, 0, 8)
		raidicon:SetHeight(16)
		raidicon:SetWidth(16)

		health:SetPoint('TOPRIGHT')
		health:SetPoint('TOPLEFT')
		health:SetHeight(20)

		self.Power = power
		self.Castbar = castbar
		self.RaidIcon = raidicon

		self.menu = SpawnMenu
		self:SetAttribute('type2', 'menu')
		self:SetAttribute('initial-height', 22)
	end

	if(petUnit or unit == 'player') then
		local powerValue = health:CreateFontString(nil, 'OVERLAY')
		powerValue:SetPoint('LEFT', health, 2, 0)
		powerValue:SetFont(FONT, 8, 'OUTLINE')
		powerValue:SetJustifyH('LEFT')
		powerValue.frequentUpdates = 0.1
		self:Tag(powerValue, '[p3limpower][( )p3limdruid]')
	else
		local name = health:CreateFontString(nil, 'OVERLAY')
		name:SetPoint('LEFT', health, 2, 0)
		name:SetPoint('RIGHT', healthValue, 'LEFT')
		name:SetFont(FONT, 8, 'OUTLINE')
		name:SetJustifyH('LEFT')
		self:Tag(name, '[p3limname]|cff0090ff[( )rare]|r')
	end

	if(unit == 'player' or unit == 'target') then
		local buffs = CreateFrame('Frame', nil, self)
		buffs:SetPoint('TOPLEFT', self, 'TOPRIGHT', 4, 0)
		buffs:SetHeight(44)
		buffs:SetWidth(236)
		buffs.num = 20
		buffs.size = 20
		buffs.spacing = 4
		buffs.initialAnchor = 'TOPLEFT'
		buffs['growth-y'] = 'DOWN'
		buffs.PostCreateIcon = PostCreateAura

		if(unit == 'target') then
			local debuffs = CreateFrame('Frame', nil, self)
			debuffs:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -4)
			debuffs:SetHeight(20 * 0.97)
			debuffs:SetWidth(230)
			debuffs.num = 20
			debuffs.size = 20 * 0.97
			debuffs.spacing = 4
			debuffs.initialAnchor = 'TOPLEFT'
			debuffs['growth-y'] = 'DOWN'
			debuffs.PostCreateIcon = PostCreateAura
			debuffs.PostUpdateIcon = PostUpdateDebuff

			local cpoints = self:CreateFontString(nil, 'OVERLAY', 'SubZoneTextFont')
			cpoints:SetPoint('RIGHT', self, 'LEFT', -9, 0)
			cpoints:SetTextColor(1, 1, 1)
			cpoints:SetJustifyH('RIGHT')

			self.Debuffs = debuffs
			self.CPoints = cpoints
			self.Power.PostUpdate = PostUpdatePower
		else
			local leader = health:CreateTexture(nil, 'OVERLAY')
			leader:SetPoint('TOPLEFT', self, 0, 8)
			leader:SetHeight(16)
			leader:SetWidth(16)

			local assistant = health:CreateTexture(nil, 'OVERLAY')
			assistant:SetPoint('TOPLEFT', self, 0, 8)
			assistant:SetHeight(16)
			assistant:SetWidth(16)

			local info = health:CreateFontString(nil, 'OVERLAY')
			info:SetPoint('CENTER')
			info:SetFont(FONT, 8, 'OUTLINE')
			info.frequentUpdates = 1/4
			self:Tag(info, '[p3limthreat][( )p3limpvp]')

			buffs.CustomFilter = CustomBuffFilter

			self.Leader = leader
			self.Assistant = assistant
		end

		self.Buffs = buffs
		self:SetAttribute('initial-width', 230)
	end

	if(petUnit) then
		local auras = CreateFrame('Frame', nil, self)
		auras:SetPoint('TOPRIGHT', self, 'TOPLEFT', -4, 0)
		auras:SetHeight(44)
		auras:SetWidth(256)
		auras.size = 22
		auras.spacing = 4
		auras.initialAnchor = 'TOPRIGHT'
		auras['growth-x'] = 'LEFT'
		auras.PostCreateIcon = PostCreateAura

		self.Auras = auras
		self:SetAttribute('initial-width', 130)
	end
end

oUF:RegisterStyle('P3lim', Style)
oUF:SetActiveStyle('P3lim')

oUF:Spawn('player'):SetPoint('CENTER', -220, -250)
oUF:Spawn('pet'):SetPoint('CENTER', -410, -250)
oUF:Spawn('focus'):SetPoint('CENTER', -244, -225)
oUF:Spawn('target'):SetPoint('CENTER', 220, -250)
oUF:Spawn('targettarget'):SetPoint('CENTER', 244, -225)
