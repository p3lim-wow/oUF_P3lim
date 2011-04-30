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

		self:Tag(self.HealthValue, '[p3lim:status][p3lim:player]')
		self:SetWidth(230)
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
		self:Tag(self.HealthValue, '[p3lim:status][p3lim:hostile][p3lim:friendly]')
		self:SetWidth(230)
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

		self:Tag(self.HealthValue, '[p3lim:status][p3lim:friendly]')
		self:SetWidth(130)
	end,
	party = function(self)
		local name = self.Health:CreateFontString(nil, 'OVERLAY')
		name:SetPoint('LEFT', 3, 0)
		name:SetFont(FONT, 8, 'OUTLINEMONOCHROME')
		name:SetJustifyH('LEFT')
		self:Tag(name, '[p3lim:unbuffed< ][p3lim:leader][raidcolor][name]')

		local phase = self.Health:CreateFontString(nil, 'OVERLAY')
		phase:SetPoint('CENTER')
		phase:SetFont([=[Fonts\ARIALN.TTF]=], 12, 'OUTLINEMONOCHROME')
		self:Tag(phase, '|cff6000ff[p3lim:phase]|r')

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
		power.colorPower = unit == 'pet'

		local powerBG = power:CreateTexture(nil, 'BORDER')
		powerBG:SetAllPoints()
		powerBG:SetTexture(TEXTURE)
		powerBG.multiplier = 1/3
		power.bg = powerBG

		if(unit ~= 'target') then
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

			local powerValue = health:CreateFontString(nil, 'OVERLAY')
			powerValue:SetPoint('LEFT', health, 2, 0)
			powerValue:SetPoint('RIGHT', healthValue, 'LEFT', -3)
			powerValue:SetFont(FONT, 8, 'OUTLINEMONOCHROME')
			powerValue:SetJustifyH('LEFT')
			powerValue.frequentUpdates = 0.1
			self:Tag(powerValue, '[p3lim:power][ >p3lim:druid][ | >p3lim:spell]')
		end

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

	if(unit == 'focus' or unit:find('target')) then
		local name = health:CreateFontString(nil, 'OVERLAY')
		name:SetPoint('LEFT', health, 2, 0)
		name:SetPoint('RIGHT', healthValue, 'LEFT')
		name:SetFont(FONT, 8, 'OUTLINEMONOCHROME')
		name:SetJustifyH('LEFT')
		self:Tag(name, '[p3lim:color][name][ |cff0090ff>rare<|r]')

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
			self:SetSize(161, 19)
			self:Tag(healthValue, '[p3lim:status][p3lim:hostile][p3lim:friendly]')
		end

		if(unit == 'focus') then
			debuffs:SetPoint('TOPLEFT', self, 'TOPRIGHT', 4, 0)
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

oUF:RegisterStyle('P3lim', Shared)
oUF:Factory(function(self)
	self:SetActiveStyle('P3lim')
	self:Spawn('player'):SetPoint('CENTER', -300, -250)
	self:Spawn('pet'):SetPoint('CENTER', -490, -250)
	self:Spawn('focus'):SetPoint('CENTER', -335, -225)
	self:Spawn('target'):SetPoint('CENTER', 300, -250)
	self:Spawn('targettarget'):SetPoint('CENTER', 334, -225)

	self:SpawnHeader(nil, nil, 'party',
		'showParty', true, 'showPlayer', true, 'yOffset', -6,
		'oUF-initialConfigFunction', [[
			self:SetHeight(16)
			self:SetWidth(126)
		]]
	):SetPoint('TOP', Minimap, 'BOTTOM', 0, -10)
end)
