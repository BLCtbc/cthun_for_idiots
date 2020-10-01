-- local Idiot_Orientation = 'vertical';
-- local Idiot_Labels = false;

local events = {};
local dotLookup = nil;
local letterLookup = nil;
local raid_info = nil;

function get_best_for_slot(party, priority, blacklist)
	if priority == nil then
		-- return first non-blacklisted party member
		for p, partyMember in ipairs(party) do
			if array_contains(blacklist, partyMember['NAME']) == false then
				blacklist[#blacklist+1] = partyMember['NAME'];
				return partyMember;
			end
		end

		return;
	end

	-- return first non-blacklisted party member based on class priority
	for i, class in ipairs(priority) do
		for p, partyMember in ipairs(party) do
			if array_contains(blacklist, partyMember['NAME']) == false then
				if partyMember['CLASS'] == class then
					blacklist[#blacklist+1] = partyMember['NAME'];
					return partyMember;
				end
			end
		end
	end
	return nil;
end

-- update all dots with current raid composition
function update_all_dots(test_mode)
	local slot_a_priority = {'Rogue', 'Warrior'};
	local slot_b_priority = {'Shaman', 'Priest', 'Druid'};
	local slot_c_priority = {'Warrior', 'Rogue', 'Druid', 'Hunter'};

	local ranged_priority = {'Mage', 'Warlock', 'Hunter', 'Paladin', 'Shaman', 'Priest', 'Druid'};
	local whocares_priority = {'Mage', 'Warlock', 'Hunter', 'Paladin', 'Shaman', 'Priest', 'Druid', 'Warrior', 'Rogue'};

	if test_mode then
		raid_info = get_test_raid();
	else
		raid_info = get_raid_info();
	end

	local localPlayer = GetUnitName("player");
	for group=1,8 do
		local blacklist = {};
		local partyMembers = raid_info[group];
		-- sort table by name for consistency
		table.sort(partyMembers, function(a, b) return a['NAME']:lower() < b['NAME']:lower() end);

		-- get best melee for eye.  rogue > warrior
		local slotA = get_best_for_slot(partyMembers, slot_a_priority, blacklist);

		-- get healyboi for slot B.  shaman > priest
		local slotB = get_best_for_slot(partyMembers, slot_b_priority, blacklist);

		-- get best melee for tentacles warrior > rogue > hunter
		local slotC = get_best_for_slot(partyMembers, slot_c_priority, blacklist);

		-- fill slot A/B/C if no prioritized classes could be assigned
		if slotA == nil then
			slotA = get_best_for_slot(partyMembers, ranged_priority, blacklist);
		end

		if slotB == nil then
			slotB = get_best_for_slot(partyMembers, ranged_priority, blacklist);
		end

		if slotC == nil then
			slotC = get_best_for_slot(partyMembers, ranged_priority, blacklist);
		end

		-- fill D/E with whatever is left
		local slotD = get_best_for_slot(partyMembers, nil, blacklist);
		local slotE = get_best_for_slot(partyMembers, nil, blacklist);

		local slots = {
			[1] = slotA,
			[2] = slotB,
			[3] = slotC,
			[4] = slotD,
			[5] = slotE
		};

		-- update dots
		for slot=1,5 do
			update_dot(group, slot, slots[slot]);
		end
	end

	-- dump to positioning to chat if player is in AQ40
	local currentZone = GetRealZoneText();
	if currentZone == 'Ahn\'Qiraj' then
		-- dump_group_info();
	end
end

-- update dot and tooltip for group/slot with player info
function update_dot(group, slot, playerInfo)
	local dots = dotLookup['Group'..group..'_Slot'..letterLookup[slot]];
	for i, dot in ipairs(dots) do
		dot:SetFrameLevel(dot:GetFrameLevel()+3);
		dot:EnableMouse(true);

		local toolstrip_text = nil;
		local backdrop = dot:GetBackdrop();
		if playerInfo == nil then
			-- default texture for unassigned slots
			backdrop.bgFile = "Interface\\AddOns\\CthunForIdiots\\Images\\Unassigned.tga";
			toolstrip_text = 'No player assigned\nGroup '..group..' Slot '..letterLookup[slot];
			dot:SetSize(20, 20);
		else
			-- class texture for assigned slots
			backdrop.bgFile = "Interface\\AddOns\\CthunForIdiots\\Images\\"..playerInfo['CLASS'].."Icon.tga";
			toolstrip_text = playerInfo['NAME']..' - '..playerInfo['CLASS']..'\nGroup '..group..' Slot '..letterLookup[slot];

			-- make player's dot larger than others
			local localPlayer = GetUnitName("player");
			if localPlayer == playerInfo['NAME'] then
				dot:SetSize(32, 32);
			else 
				dot:SetSize(20, 20);
			end
		end

		-- set new backdrop
		dot:SetBackdrop(backdrop);

		-- bind events for tooltips
		dot:SetScript("OnEvent", function()
			dot:Hide();
			CthunFrame:Hide();
		end);

		dot:SetScript("OnEnter", function()
			GameTooltip:SetOwner(dot, "ANCHOR_TOP");
			GameTooltip:SetText(toolstrip_text);
			GameTooltip:Show();
		end);

		dot:SetScript("OnLeave", function() GameTooltip:Hide(); end);
	end
end

-- build actual raid composition
function get_raid_info()
	local ret = {
		[1] = {},
		[2] = {},
		[3] = {},
		[4] = {},
		[5] = {},
		[6] = {},
		[7] = {},
		[8] = {}
	};

	for raidIndex=1,GetNumGroupMembers() do
		local name, rank, subgroup, level, class = GetRaidRosterInfo(raidIndex);
		if name ~= nil then
			ret[subgroup][#ret[subgroup]+1] = {
				['NAME'] = name,
				['CLASS'] = class,
				['GROUP'] = subgroup
			};
		end
	end
	return ret;
end

-- build test raid composition
function get_test_raid()
	local ret = {
		[1] = {},
		[2] = {},
		[3] = {},
		[4] = {},
		[5] = {},
		[6] = {},
		[7] = {},
		[8] = {}
	};

	for group=1,8 do
		ret[group][#ret[group]+1] = {
			['NAME'] = 'Nir',
			['CLASS'] = 'Rogue',
			['GROUP'] = group
		};

		ret[group][#ret[group]+1] = {
			['NAME'] = 'Sweepy',
			['CLASS'] = 'Warrior',
			['GROUP'] = group
		};

		ret[group][#ret[group]+1] = {
			['NAME'] = 'Sofakingcool',
			['CLASS'] = 'Shaman',
			['GROUP'] = group
		};

		ret[group][#ret[group]+1] = {
			['NAME'] = 'Jolt',
			['CLASS'] = 'Hunter',
			['GROUP'] = group
		};

		ret[group][#ret[group]+1] = {
			['NAME'] = 'Squiggies',
			['CLASS'] = 'Mage',
			['GROUP'] = group
		};
	end
	return ret;
end

-- dump the player's group positioning to chat
function dump_group_info()
	function find_player_group()
		for group=1,8 do
			for p, partyMember in ipairs(raid_info[group]) do
				if localPlayer == partyMember['NAME'] then
					return group;
				end
			end
		end
		return nil;
	end

	local player_group = find_player_group();
	if player_group == nil then
		print('Player group not found.');
		return;
	end

	-- build print string
	local dump_str = 'You are in Group '..group;
	for p, partyMember in ipairs(raid_info[player_group]) do
		if localPlayer == partyMember['NAME'] then
			for slot=1,5 do
				if slots[slot] ~= nil then
					dump_str = dump_str..'\nSlot '..letterLookup[slot]..': '..slots[slot]['NAME'];
				end
			end
		end
	end
	print(dump_str);
end

-- ADDON_LOADED event handler
function events:ADDON_LOADED(addon, ...)
	if addon == 'CthunForIdiots' then
		if Idiot_Orientation == nil then
			Idiot_Orientation = 'vertical';
		end
		if Idiot_Labels == nil then
			Idiot_Labels = false;
		end
		if Idiot_Scale == nil then
			Idiot_Scale = 100;
		end
	end
end

-- GROUP_ROSTER_UPDATE event handler
function events:GROUP_ROSTER_UPDATE(...)
	update_all_dots();
end

function setup_frames()
	-- setup map orientation
	if Idiot_Orientation == 'vertical' then
		VerticalFrame:SetAlpha(1);
		AngledFrame:SetAlpha(0);
	else
		VerticalFrame:SetAlpha(0);
		AngledFrame:SetAlpha(1);
	end

	-- setup retard labels
	if Idiot_Labels then
		GongString:SetAlpha(1);
		StairString:SetAlpha(1);
		Angled_GongString:SetAlpha(1);
		Angled_StairString:SetAlpha(1);
	else
		GongString:SetAlpha(0);
		StairString:SetAlpha(0);
		Angled_GongString:SetAlpha(0);
		Angled_StairString:SetAlpha(0);
	end
	
end

-- OnLoad event handler
function init_cthun()
	-- name -> frame lookup
	dotLookup = {
		['Group1_SlotA'] = {
			Group1_SlotA,
			Angled_Group1_SlotA
		},
		['Group1_SlotB'] = {
			Group1_SlotB,
			Angled_Group1_SlotB
		},
		['Group1_SlotC'] = {
			Group1_SlotC,
			Angled_Group1_SlotC
		},
		['Group1_SlotD'] = {
			Group1_SlotD,
			Angled_Group1_SlotD
		},
		['Group1_SlotE'] = {
			Group1_SlotE,
			Angled_Group1_SlotE
		},

		['Group2_SlotA'] = {
			Group2_SlotA,
			Angled_Group2_SlotA
		},
		['Group2_SlotB'] = {
			Group2_SlotB,
			Angled_Group2_SlotB
		},
		['Group2_SlotC'] = {
			Group2_SlotC,
			Angled_Group2_SlotC
		},
		['Group2_SlotD'] = {
			Group2_SlotD,
			Angled_Group2_SlotD
		},
		['Group2_SlotE'] = {
			Group2_SlotE,
			Angled_Group2_SlotE
		},

		['Group3_SlotA'] = {
			Group3_SlotA,
			Angled_Group3_SlotA
		},
		['Group3_SlotB'] = {
			Group3_SlotB,
			Angled_Group3_SlotB
		},
		['Group3_SlotC'] = {
			Group3_SlotC,
			Angled_Group3_SlotC
		},
		['Group3_SlotD'] = {
			Group3_SlotD,
			Angled_Group3_SlotD
		},
		['Group3_SlotE'] = {
			Group3_SlotE,
			Angled_Group3_SlotE
		},

		['Group4_SlotA'] = {
			Group4_SlotA,
			Angled_Group4_SlotA
		},
		['Group4_SlotB'] = {
			Group4_SlotB,
			Angled_Group4_SlotB
		},
		['Group4_SlotC'] = {
			Group4_SlotC,
			Angled_Group4_SlotC
		},
		['Group4_SlotD'] = {
			Group4_SlotD,
			Angled_Group4_SlotD
		},
		['Group4_SlotE'] = {
			Group4_SlotE,
			Angled_Group4_SlotE
		},

		['Group5_SlotA'] = {
			Group5_SlotA,
			Angled_Group5_SlotA
		},
		['Group5_SlotB'] = {
			Group5_SlotB,
			Angled_Group5_SlotB
		},
		['Group5_SlotC'] = {
			Group5_SlotC,
			Angled_Group5_SlotC
		},
		['Group5_SlotD'] = {
			Group5_SlotD,
			Angled_Group5_SlotD
		},
		['Group5_SlotE'] = {
			Group5_SlotE,
			Angled_Group5_SlotE
		},

		['Group6_SlotA'] = {
			Group6_SlotA,
			Angled_Group6_SlotA
		},
		['Group6_SlotB'] = {
			Group6_SlotB,
			Angled_Group6_SlotB
		},
		['Group6_SlotC'] = {
			Group6_SlotC,
			Angled_Group6_SlotC
		},
		['Group6_SlotD'] = {
			Group6_SlotD,
			Angled_Group6_SlotD
		},
		['Group6_SlotE'] = {
			Group6_SlotE,
			Angled_Group6_SlotE
		},

		['Group7_SlotA'] = {
			Group7_SlotA,
			Angled_Group7_SlotA
		},
		['Group7_SlotB'] = {
			Group7_SlotB,
			Angled_Group7_SlotB
		},
		['Group7_SlotC'] = {
			Group7_SlotC,
			Angled_Group7_SlotC
		},
		['Group7_SlotD'] = {
			Group7_SlotD,
			Angled_Group7_SlotD
		},
		['Group7_SlotE'] = {
			Group7_SlotE,
			Angled_Group7_SlotE
		},

		['Group8_SlotA'] = {
			Group8_SlotA,
			Angled_Group8_SlotA
		},
		['Group8_SlotB'] = {
			Group8_SlotB,
			Angled_Group8_SlotB
		},
		['Group8_SlotC'] = {
			Group8_SlotC,
			Angled_Group8_SlotC
		},
		['Group8_SlotD'] = {
			Group8_SlotD,
			Angled_Group8_SlotD
		},
		['Group8_SlotE'] = {
			Group8_SlotE,
			Angled_Group8_SlotE
		}
	};

	-- integer -> letter lookup
	letterLookup = {
		[1] = 'A',
		[2] = 'B',
		[3] = 'C',
		[4] = 'D',
		[5] = 'E',
	};

	-- init opacity slider
	getglobal(AlphaSlider:GetName() .. 'Low'):SetText('5%')
	getglobal(AlphaSlider:GetName() .. 'High'):SetText('100%')
	getglobal(AlphaSlider:GetName() .. 'Text'):SetText('Opacity')
	AlphaSlider:SetScript("OnValueChanged", function(self)
		local value = AlphaSlider:GetValue();
		CthunFrame:SetAlpha(value/100);
	end);

	-- setup hide button
	HideBtn:SetScript("OnClick", function(self)
		CthunFrame:Hide();
	end);

	-- setup rotate button
	RotateBtn:SetScript("OnClick", function(self)
		if Idiot_Orientation == 'vertical' then
			Idiot_Orientation = 'retard';
			setup_frames();
		else
			Idiot_Orientation = 'vertical';
			setup_frames();
		end
	end);

	-- event handling
	CthunFrame:SetScript("OnEvent", function(self, event, ...)
		events[event](self, ...);
	end);

	-- register events
	for k, v in pairs(events) do
		-- print("Registering Event: " .. k);
		CthunFrame:RegisterEvent(k);
	end

	setup_frames();
	update_all_dots();
	CthunFrame:Hide();
	print('CthunForIdiots Initialized');
end

function table.clone(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[table.clone(orig_key)] = table.clone(orig_value)
        end
        setmetatable(copy, table.clone(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

string.starts_with = function(self, str) 
    return self:find('^' .. str) ~= nil
end

function array_contains(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

local function string_isempty(s)
	return s == nil or s == '';
end

local function to_integer(number)
    return math.floor(tonumber(number) or error("Could not cast '" .. tostring(number) .. "' to number.'"))
end

local function split_string(inputstr, sep)
    if sep == nil then
		sep = "%s";
    end

    local t = {};
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		table.insert(t, str);
    end
    return t;
end

local cTip = CreateFrame("GameTooltip","SbTooltip",nil,"GameTooltipTemplate")
function is_soulbound(bag, slot)
    cTip:SetOwner(UIParent, "ANCHOR_NONE")
    cTip:SetBagItem(bag, slot)
    cTip:Show()
    for i = 1,cTip:NumLines() do
        if(_G["SbTooltipTextLeft"..i]:GetText()==ITEM_SOULBOUND) then
            return true
        end
    end
    cTip:Hide()
    return false
end

-- register /cthun chat command
SLASH_CTHUN1, SLASH_CTHUN2, SLASH_CTHUN3 = '/cthun', '/idiot', '/fatidiot';
SlashCmdList["CTHUN"] = function(msg, editbox)
	msg = msg:lower();

	-- toggle main frame
	if string_isempty(msg) then
		if (CthunFrame:IsVisible()) then
			CthunFrame:Hide();
		else
			if CthunFrame:GetScale()*100 ~= Idiot_Scale then
				CthunFrame:SetScale(Idiot_Scale/100);
			end
			update_all_dots(false);
			CthunFrame:Show();
		end

	-- toggle map orientation
	elseif msg == 'rotate' then
		if Idiot_Orientation == 'vertical' then
			Idiot_Orientation = 'retard';
		else
			Idiot_Orientation = 'vertical';
		end
		setup_frames();

	-- toggle retard labels
	elseif msg == 'labels' then
		if Idiot_Labels then
			Idiot_Labels = false;
		else
			Idiot_Labels = true;
		end
		setup_frames();

	-- dump player's group positioning to chat
	elseif msg == 'group' then
		dump_group_info();

	-- test mode
	elseif msg == 'test' then
		update_all_dots(true);
		CthunFrame:Show();

	-- show main frame
	elseif msg == 'show' then
		if CthunFrame:GetScale()*100 ~= Idiot_Scale then
			CthunFrame:SetScale(Idiot_Scale/100);
		end
		update_all_dots(false);
		CthunFrame:Show();

	-- hide main frame
	elseif msg == 'hide' then
		CthunFrame:Hide();

	-- adjust main frame scale
	elseif msg:starts_with('scale') then
		split = split_string(msg, " ");
		if #split < 2 then
			print("Missing scale size.  Example usage:  /cthun scale 100");
			return;
		end

		scale = to_integer(split[2]);
		print("Adjust Frame Scale to : "..scale.."%");
		Idiot_Scale = scale;
		CthunFrame:SetScale(scale/100);

	-- reset window position/opacity
	elseif msg == 'reset' then
		mainFrame:SetAlpha(1);
		mainFrame:SetScale(1);
		mainFrame:SetPoint("TOPLEFT", UIParent, 0, 0);

	-- command list
	elseif msg == 'help' then
		print('CthunForIdiots Commands');
		print('/idiot     -- Toggle Window');
		print('/idiot test     -- Test Mode');
		print('/idiot show     -- Show Window');
		print('/idiot hide     -- Hide Window');
		print('/idiot group     -- Print player\'s group positioning to chat.');
		print('/idiot scale 100     -- Adjust window scale');
		print('/idiot rotate      -- Toggle map orientation');
		print('/idiot labels     -- Toggle retard labels');
		print('/idiot reset    -- Reset Position/Opacity');
	end
end