local parent, ns = ...
local oUF = ns.oUF

oUF.Tags.Events['demonicfury'] = 'UNIT_POWER SPELLS_CHANGED'
oUF.Tags.Methods['demonicfury'] = function(unit)
	if(not IsPlayerSpell(WARLOCK_METAMORPHOSIS)) then return end

	local cur = UnitPower(unit, SPELL_POWER_DEMONIC_FURY)
	if(cur > 0) then
		return cur
	end
end

local function UNIT_POWER(self, event, unit, powerType)
	if(self.unit ~= unit or (event == 'UNIT_POWER_FREQUENT' and powerType ~= 'DEMONIC_FURY')) then
		return
	end

	local element = self.DemonicFury

	local cur = UnitPower('player', SPELL_POWER_DEMONIC_FURY)
	local max = UnitPowerMax('player', SPELL_POWER_DEMONIC_FURY)

	element:SetMinMaxValues(0, max)
	element:SetValue(cur)

	if(element.PostUpdatePower) then
		return element:PostUpdatePower(unit, cur, max)
	end
end

local function UPDATE_VISIBILITY(self)
	local element = self.DemonicFury

	local showElement
	if(IsPlayerSpell(WARLOCK_METAMORPHOSIS)) then
		showElement = true
	end

	if(UnitHasVehicleUI('player')) then
		showElement = false
	end

	if(showElement) then
		element:Show()
	else
		element:Hide()
	end

	if(element.PostUpdateVisibility) then
		return element:PostUpdateVisibility(self.unit)
	end
end

local function Update(self, ...)
	UPDATE_VISIBILITY(self, ...)
	UNIT_POWER(self, ...)
end

local function ForceUpdate(element)
	return Update(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self, unit)
	local element = self.DemonicFury
	if(element and unit == 'player') then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent('SPELLS_CHANGED', UPDATE_VISIBILITY, true)
		self:RegisterEvent('UNIT_POWER_FREQUENT', UNIT_POWER)

		if(element:GetObjectType() == 'StatusBar' and not element:GetStatusBarTexture()) then
			element:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
		end

		return true
	end
end

local function Disable(self)
	if(self.BurningEmbers) then
		self:UnregisterEvent('SPELLS_CHANGED', UPDATE_VISIBILITY)
		self:UnregisterEvent('UNIT_POWER_FREQUENT', UNIT_POWER)
	end
end

oUF:AddElement('DemonicFury', Update, Enable, Disable)
