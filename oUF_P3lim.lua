--[[

  Adrian L Lange grants anyone the right to use this work for any purpose,
  without any conditions, unless such conditions are required by law.

--]]

local FONT = [=[Interface\AddOns\oUF_P3lim\media\semplice.ttf]=]
local TEXTURE = [=[Interface\AddOns\oUF_P3lim\media\minimalist]=]
local BACKDROP = {
	bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
	insets = {top = -1, bottom = -1, left = -1, right = -1}
}

local function SpawnMenu(self)
	ToggleDropDownMenu(1, nil, _G[string.gsub(self.unit, '^.', string.upper)..'FrameDropDown'], 'cursor')
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

local function PostUpdateDebuff(element, unit, button, index)
	if(UnitIsFriend('player', unit) or button.isPlayer) then
		local _, _, _, _, type = UnitAura(unit, index, button.filter)
		local color = DebuffTypeColor[type] or DebuffTypeColor.none

		button:SetBackdropColor(color.r * 3/5, color.g * 3/5, color.b * 3/5)
		button.icon:SetDesaturated(false)
	else
		button:SetBackdropColor(0, 0, 0)
		button.icon:SetDesaturated(true)
	end
end

local UnitSpecific = {
	player = function(self)
		local leader = self.Health:CreateTexture(nil, 'OVERLAY')
		leader:SetPoint('TOPLEFT', self, 0, 8)
		leader:SetSize(16, 16)
		self.Leader = leader

		local assistant = self.Health:CreateTexture(nil, 'OVERLAY')
		assistant:SetPoint('TOPLEFT', self, 0, 8)
		assistant:SetSize(16, 16)
		self.Assistant = assistant

		local info = self.Health:CreateFontString(nil, 'OVERLAY')
		info:SetPoint('CENTER')
		info:SetFont(FONT, 8, 'OUTLINE')
		self:Tag(info, '[p3lim:threat]')

		self:SetAttribute('initial-width', 230)
	end,
	target = function(self)
		local buffs = CreateFrame('Frame', nil, self)
		buffs:SetPoint('TOPLEFT', self, 'TOPRIGHT', 4, 0)
		buffs:SetSize(236, 44)
		buffs.num = 20
		buffs.size = 20
		buffs.spacing = 4
		buffs.initialAnchor = 'TOPLEFT'
		buffs['growth-y'] = 'DOWN'
		buffs.PostCreateIcon = PostCreateAura
		self.Buffs = buffs

		local cpoints = self:CreateFontString(nil, 'OVERLAY', 'SubZoneTextFont')
		cpoints:SetPoint('RIGHT', self, 'LEFT', -9, 0)
		cpoints:SetJustifyH('RIGHT')
		self:Tag(cpoints, '|cffffffff[cpoints]|r')

		self.Power.PostUpdate = PostUpdatePower
		self:SetAttribute('initial-width', 230)
	end,
	pet = function(self)
		local auras = CreateFrame('Frame', nil, self)
		auras:SetPoint('TOPRIGHT', self, 'TOPLEFT', -4, 0)
		auras:SetSize(236, 44)
		auras.size = 20
		auras.spacing = 4
		auras.initialAnchor = 'TOPRIGHT'
		auras['growth-x'] = 'LEFT'
		auras.PostCreateIcon = PostCreateAura
		self.Auras = auras

		self:SetAttribute('initial-width', 130)
	end,
}

local function Shared(self, unit)
	self:RegisterForClicks('AnyUp')
	self:SetScript('OnEnter', UnitFrame_OnEnter)
	self:SetScript('OnLeave', UnitFrame_OnLeave)

	self:SetBackdrop(BACKDROP)
	self:SetBackdropColor(0, 0, 0)

	local health = CreateFrame('StatusBar', nil, self)
	health:SetStatusBarTexture(TEXTURE)
	health:SetStatusBarColor(1/4, 1/4, 2/5)
	health.frequentUpdates = true
	self.Health = health

	local healthBG = health:CreateTexture(nil, 'BORDER')
	healthBG:SetAllPoints()
	healthBG:SetTexture(1/3, 1/3, 1/3)

	local healthValue = health:CreateFontString(nil, 'OVERLAY')
	healthValue:SetPoint('RIGHT', health, -2, 0)
	healthValue:SetFont(FONT, 8, 'OUTLINE')
	healthValue:SetJustifyH('RIGHT')
	healthValue.frequentUpdates = 1/4
	self:Tag(healthValue, '[p3lim:health]')

	if(unit == 'player' or unit == 'target' or unit == 'pet') then
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
		power.colorReaction = unit ~= 'pet'
		power.colorHappiness = unit == 'pet'
		power.colorPower = unit == 'pet'

		local powerBG = power:CreateTexture(nil, 'BORDER')
		powerBG:SetAllPoints()
		powerBG:SetTexture([=[Interface\ChatFrame\ChatFrameBackground]=])
		powerBG.multiplier = 1/3
		power.bg = powerBG

		if(unit ~= 'target') then
			local powerValue = health:CreateFontString(nil, 'OVERLAY')
			powerValue:SetPoint('LEFT', health, 2, 0)
			powerValue:SetFont(FONT, 8, 'OUTLINE')
			powerValue:SetJustifyH('LEFT')
			powerValue.frequentUpdates = 0.1
			self:Tag(powerValue, '[p3lim:power< ][p3lim:druid]')
		end

		local raidicon = health:CreateTexture(nil, 'OVERLAY')
		raidicon:SetPoint('TOP', self, 0, 8)
		raidicon:SetSize(16, 16)
		self.RaidIcon = raidicon

		health:SetHeight(20)
		health:SetPoint('TOPRIGHT')
		health:SetPoint('TOPLEFT')

		self.menu = SpawnMenu
		self:SetAttribute('type2', 'menu')
		self:SetAttribute('initial-height', 22)
	end

	if(unit == 'focus' or unit:find('target')) then
		local name = health:CreateFontString(nil, 'OVERLAY')
		name:SetPoint('LEFT', health, 2, 0)
		name:SetPoint('RIGHT', healthValue, 'LEFT')
		name:SetFont(FONT, 8, 'OUTLINE')
		name:SetJustifyH('LEFT')
		self:Tag(name, '[p3lim:name< ][|cff0090ff>rare<|r]')

		local debuffs = CreateFrame('Frame', nil, self)
		debuffs.spacing = 4
		debuffs.initialAnchor = 'TOPLEFT'
		debuffs.PostCreateIcon = PostCreateAura
		self.Debuffs = debuffs

		if(unit == 'target') then
			debuffs.num = 20
			debuffs.size = 19.4
			debuffs['growth-y'] = 'DOWN'
			debuffs.PostUpdateIcon = PostUpdateDebuff
			debuffs:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -4)
		else
			debuffs.num = 3
			debuffs.size = 19

			health:SetAllPoints()
			self:SetAttribute('initial-height', 19)
			self:SetAttribute('initial-width', 161)
		end

		if(unit == 'focus') then
			debuffs:SetPoint('TOPLEFT', self, 'TOPRIGHT')
			debuffs.onlyShowPlayer = true
		elseif(unit ~= 'target') then
			debuffs:SetPoint('TOPRIGHT', self, 'TOPLEFT', -4, 0)
			debuffs.initialAnchor = 'TOPRIGHT'
			debuffs['growth-x'] = 'LEFT'
		end

		debuffs:SetSize(230, debuffs.size)
	end

	if(UnitSpecific[unit]) then
		return UnitSpecific[unit](self)
	end
end

oUF.colors.power.MANA = {0, 144/255, 1}

oUF:RegisterStyle('P3lim', Shared)
oUF:Factory(function(self)
	self:SetActiveStyle('P3lim')
	self:Spawn('player'):SetPoint('CENTER', -220, -250)
	self:Spawn('pet'):SetPoint('CENTER', -410, -250)
	self:Spawn('focus'):SetPoint('CENTER', -255, -225)
	self:Spawn('target'):SetPoint('CENTER', 220, -250)
	self:Spawn('targettarget'):SetPoint('CENTER', 254, -225)
end)
