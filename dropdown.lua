local menu = CreateFrame('Frame', 'oUF_P3lim_DropDown')
menu:RegisterEvent('PARTY_LOOT_METHOD_CHANGED')
menu.displayMode = 'MENU'
menu.info = {}

local loot = {
	master = '|cff0070dd|rMaster Loot',
	group = '|cff1eff00Group Loot|r',
	freeforall = '|cffffffffFree For All|r'
}

local lootone = { -- find a localized alternative to the following tables, preferably with all options?
	freeforall = 'Loot: %sFree|r',
	group = 'Loot: %sGroup|r',
	master = 'Loot: %sMaster|r',
	ignore = 'Loot: %sIgnore|r'
}

local party = {
	'5 [N]',
	'5 [|cffff5050H|r]'
}

local raid = {
	'10 [N]',
	'25 [N]',
	'10 [|cffff5050H|r]',
	'25 [|cffff5050H|r]'
}

local function InGroup()
	return GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0
end

local function GroupLeader()
	return InGroup() and (IsRaidLeader() or IsPartyLeader()) or not InGroup()
end

local function onEvent()
	if(GroupLeader()) then
		SetLootThreshold(GetLootMethod() == 'master' and 3 or 2)
	end
end

local function initialize(self, level)
	local info = self.info

	if(level == 1) then
		if(InGroup()) then
			wipe(info)
			info.text = string.format(lootone[GetOptOutOfLoot() and 'ignore' or GetLootMethod()], select(4, GetItemQualityColor(GetLootThreshold())))
			info.value = 'loot'
			info.notCheckable = 1
			info.hasArrow = 1
			UIDropDownMenu_AddButton(info, level)
		end

		wipe(info)
		info.text = string.format('Difficulty: %s', UnitInRaid('player') and raid[GetRaidDifficulty()] or party[GetDungeonDifficulty()])
		info.value = 'difficulty'
		info.notCheckable = 1
		info.hasArrow = 1
		UIDropDownMenu_AddButton(info, level)

		if(GroupLeader()) then
			wipe(info)
			info.text = RESET_INSTANCES
			info.notCheckable = 1
			info.func = function() ResetInstances() end
			UIDropDownMenu_AddButton(info, level)
		end

		if(InGroup()) then
			wipe(info)
			info.text = PARTY_LEAVE
			info.notCheckable = 1
			info.func = function() LeaveParty() end
			UIDropDownMenu_AddButton(info, level)
		end
	elseif(level == 2) then
		if(UIDROPDOWNMENU_MENU_VALUE == 'loot') then
			wipe(info)

			for k, v in next, loot do
				info.text = v
				info.func = function() SetLootMethod(k, UnitName('player')) end
				UIDropDownMenu_AddButton(info, level)
			end

			info.text = '|cff9d9d9dIgnore Loot|r'
			info.func = function() SetOptOutOfLoot(not GetOptOutOfLoot()) end
			UIDropDownMenu_AddButton(info, level)
		elseif(UIDROPDOWNMENU_MENU_VALUE == 'difficulty') then
			wipe(info)

			if(UnitInRaid('player')) then
				for k, v in next, raid do
					info.text = v
					info.func = function() SetRaidDifficulty(k) end
					UIDropDownMenu_AddButton(info, level)
				end
			else
				for k, v in next, party do
					info.text = v
					info.func = function() SetDungeonDifficulty(k) end
					UIDropDownMenu_AddButton(info, level)
				end
			end
		end
	end
end

menu:SetScript('OnEvent', onEvent)
menu.initialize = initialize
