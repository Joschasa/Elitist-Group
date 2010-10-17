local ElitistGroup = select(2, ...)
local Report = ElitistGroup:NewModule("Report", "AceEvent-3.0")
local L = ElitistGroup.L
local raidUnits, partyUnits = ElitistGroup.raidUnits, ElitistGroup.partyUnits

function Report:Show()
	self:CreateUI()
end

local function summaryUpdate(self)
	local time = GetTime()
	if( self.endTime < time ) then
		self.tooltip = L["Do not abuse this!\n\nAbuse will result in the feature being removed."]
		self:SetScript("OnUpdate", nil)
		self:SetText(L["Report"])
		self:Enable()
	else
		self:SetFormattedText("%d", self.endTime - time)
	end
end

local function reportSummary(self)
	-- Make sure the channel is valid obviously!
	if( not ElitistGroup.db.profile.report.channel ) then
		ElitistGroup:Print(L["You did not set a channel to report to."])
		return
	elseif( ElitistGroup.db.profile.report.channel == "RAID" and GetNumRaidMembers() == 0 ) then
		ElitistGroup:Print(L["You need to be in a raid to output to this channel."])
		return
	elseif( ElitistGroup.db.profile.report.channel == "PARTY" and GetNumPartyMembers() == 0 ) then
		ElitistGroup:Print(L["You need to be in a party to output to this channel."])
		return
	elseif( ( ElitistGroup.db.profile.report.channel == "GUILD" or ElitistGroup.db.profile.report.channel == "OFFICER" ) and not IsInGuild() ) then
		ElitistGroup:Print(L["You need to be in a guild to output to this channel."])
		return
	elseif( not GetChannelName(ElitistGroup.db.profile.report.channel) ) then
		ElitistGroup:Print(string.format(L["You are not inside chat channel #%d, can't send report."], ElitistGroup.db.profile.report.channel))
		return
	end
	
	-- Figure out how many valid matches will need, as well as if we listed any filters
	local itemLevel = ElitistGroup.db.profile.report.itemLevel
	local equipment = ElitistGroup.db.profile.report.equipment
	local enchants = ElitistGroup.db.profile.report.enchants
	local gems = ElitistGroup.db.profile.report.gems
	local requiredMatches = (itemLevel and 1 or 0) + (equipment and 1 or 0) + (enchants and 1 or 0) + (gems and 1 or 0)
	if( requiredMatches == 0 ) then
		ElitistGroup:Print(L["No filters setup, you need at least one to report."])
		return
	elseif( not ElitistGroup.db.profile.report.matchAll ) then
		requiredMatches = 1
	end

	-- Compile the list of datas
	local userList = {}
	for i=1, GetNumRaidMembers() do
		local playerID = ElitistGroup:GetPlayerID(raidUnits[i])
		local userData = playerID and ElitistGroup.userData[playerID]
		
		if( userData ) then
			table.insert(userList, userData)
		end
	end
		
	if( GetNumRaidMembers() == 0 ) then
		for i=1, GetNumPartyMembers() do
			local playerID = ElitistGroup:GetPlayerID(partyUnits[i])
			local userData = playerID and ElitistGroup.userData[playerID]
			
			if( userData ) then
				table.insert(userList, userData)
			end
		end
	end
		
	if( #(userList) == 0 ) then
		ElitistGroup:Print(L["No data found on group, you might need to wait a minute for it to load."])
		return
	end
			
	local queuedData = {}
	for _, userData in pairs(userList) do
		local averageLevel, percentGear, percentEnchants, percentGems = ElitistGroup:GetOptimizedSummary(userData)
		if( averageLevel and not ElitistGroup.db.profile.report[userData.classToken] ) then
			percentGear = 1 - percentGear
			percentEnchants = 1 - percentEnchants
			percentGems = 1 - percentGems
		
			-- Figure out how many matches we have
			local totalMatches = 0
			if( itemLevel and averageLevel <= itemLevel ) then
				totalMatches = totalMatches + 1
			end

			if( equipment and percentGear > equipment ) then
				totalMatches = totalMatches + 1
			end

			if( enchants and percentEnchants > enchants ) then
				totalMatches = totalMatches + 1
			end
			
			if( gems and percentGems > gems ) then
				totalMatches = totalMatches + 1
			end
						
			-- Do the base text then
			if( totalMatches >= requiredMatches ) then
				local text = ""
				if( itemLevel ) then
					text = text .. averageLevel .. ""
				end
				
				if( equipment ) then
					text = text .. "/" .. math.floor((percentGear * 100) + 0.5) .. "%"
				end

				if( enchants ) then
					text = text .. "/" .. math.floor((percentEnchants * 100) + 0.5) .. "%"
				end

				if( gems ) then
					text = text .. "/" .. math.floor((percentGems * 100) + 0.5) .. "%"
				end
				
				table.insert(queuedData, string.format("%s (%s)", userData.name, string.gsub(text, "^/", "")))
			end
		end
	end
	
	if( #(queuedData) == 0 ) then
		ElitistGroup:Print(L["Nobody in your group matched the entered filters."])
		return
	end
	
	-- Create the help text so people know what is what
	local outputHelp = ""
	if( itemLevel ) then
		outputHelp = outputHelp .. L["[average ilvl]"]
	end
	if( equipment ) then
		outputHelp = outputHelp .. "/" .. L["[bad equipment]"]
	end
	if( enchants ) then
		outputHelp = outputHelp .. "/" .. L["[bad enchants]"]
	end
	if( gems ) then
		outputHelp = outputHelp .. "/" .. L["[bad gems]"]
	end
	
	outputHelp = string.gsub(outputHelp, "^/", "")

	local target, channelID = ElitistGroup.db.profile.report.channel
	if( type(target) == "number" ) then
		channelID = target
		target = "CHANNEL"
	end
	
	ChatThrottleLib:SendChatMessage("BULK", "EG", string.format(L["Elitist Group (%s): showing %d players, check out http://elitistarmory.com for more info. Format is, [name] (%s)"], ElitistGroup.version, #(queuedData), outputHelp), target, nil, channelID)
	
	-- Now do all of the actual work
	local message = ""
	for _, summary in pairs(queuedData) do
		local testMessage = message .. ", " .. summary
		if( string.len(testMessage) >= 250 ) then
			ChatThrottleLib:SendChatMessage("BULK", "EG", string.gsub(message, "^, ", ""), target, nil, channelID)
			message = summary
		else
			message = testMessage
		end
	end
	
	if( message ~= "" ) then
		ChatThrottleLib:SendChatMessage("BULK", "EG", string.gsub(message, "^, ", ""), target, nil, channelID)
	end
	
	-- Disable it for 60 seconds
	self.tooltip = L["You can only send a report once every 60 seconds."]
	self.endTime = GetTime() + 60
	self:SetScript("OnUpdate", summaryUpdate)
	self:Disable()
end

function Report:CreateUI()
	if( self.frame ) then
		self.frame:Show()
		return
	end

	local OnEnter, OnLeave = ElitistGroup.Widgets.OnEnter, ElitistGroup.Widgets.OnLeave
	
	local function OnClick(self) PlaySound(self:GetChecked() and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff") end
	local function createToggle(parent)
	   local check = CreateFrame("CheckButton", nil, parent)
	   check:SetScript("OnClick", OnClick)
	   check:SetSize(20, 20)
	   check:SetHitRectInsets(0, -100, 0, 0)
	   check:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
	   check:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
	   check:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
	   check:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
	   check:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
	   check:SetScript("OnEnter", OnEnter)
	   check:SetScript("OnLeave", OnLeave)
	   
	   check.text = check:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	   check.text:SetPoint("LEFT", check, "RIGHT", 0, 1)
	   check.text:SetWidth(parent:GetWidth() - 26)
	   check.text:SetHeight(11)
	   check.text:SetJustifyH("LEFT")

	   return check 
	end
	
	-- Main container
	local frame = CreateFrame("Frame", "ElitistGroupReportFrame", UIParent)
	frame:SetClampedToScreen(true)
	frame:RegisterForDrag("LeftButton", "RightButton")
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetToplevel(true)
	frame:SetHeight(294)
	frame:SetWidth(351)
	frame:SetScript("OnDragStart", function(self, mouseButton)
		if( mouseButton == "RightButton" ) then
			frame:ClearAllPoints()
			frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
			ElitistGroup.db.profile.positions.notes = nil
			return
		end
		
		self:StartMoving()
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		
		local scale = self:GetEffectiveScale()
		ElitistGroup.db.profile.positions.notes = {x = self:GetLeft() * scale, y = self:GetTop() * scale}
	end)
	frame:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		edgeSize = 26,
		insets = {left = 9, right = 9, top = 9, bottom = 9},
	})
	frame:SetBackdropColor(0, 0, 0, 0.90)
	
	table.insert(UISpecialFrames, "ElitistGroupReportFrame")
		
	if( ElitistGroup.db.profile.positions.report ) then
		local scale = frame:GetEffectiveScale()
		frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", ElitistGroup.db.profile.positions.report.x / scale, ElitistGroup.db.profile.positions.report.y / scale)
	else
		frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end

	frame.titleBar = frame:CreateTexture(nil, "ARTWORK")
	frame.titleBar:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
	frame.titleBar:SetPoint("TOP", 0, 8)
	frame.titleBar:SetWidth(200)
	frame.titleBar:SetHeight(45)

	frame.title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	frame.title:SetPoint("TOP", 0, 0)
	frame.title:SetText("Elitist Group")

	-- Close button
	local button = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	button:SetPoint("TOPRIGHT", -3, -3)
	button:SetHeight(28)
	button:SetWidth(28)
	button:SetScript("OnClick", function() frame:Hide() end)

	-- General config frame
	local backdrop = {bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeSize = 1}
	local generalFrame = CreateFrame("Frame", nil, frame)   
	generalFrame:SetBackdrop(backdrop)
	generalFrame:SetBackdropBorderColor(0.60, 0.60, 0.60, 1)
	generalFrame:SetBackdropColor(0, 0, 0, 0)
	generalFrame:SetWidth(185)
	generalFrame:SetHeight(240)
	generalFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -42)
	self.generalFrame = generalFrame

	generalFrame.headerText = generalFrame:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
	generalFrame.headerText:SetPoint("BOTTOMLEFT", generalFrame, "TOPLEFT", 0, 5)
	generalFrame.headerText:SetText(L["General"])
	
	-- General dropdown
	local function dropdownSelected(self)
		local parent = UIDROPDOWNMENU_OPEN_MENU
		local value = self.value ~= "disabled" and self.value or nil
		ElitistGroup.db.profile.report[parent.configKey] = value
		UIDropDownMenu_SetSelectedValue(parent, self.value)

		if( not value ) then	
			UIDropDownMenu_SetText(parent, parent.disabledText)
		else
			local text = self.arg1
			local channel = type(self.arg1) == "number" and select(2, GetChannelName(self.arg1))
			if( channel ) then
				text = string.format("%d. %s", self.arg1, channel)
			end

			UIDropDownMenu_SetText(parent, string.format(parent.formatText, text))
		end
	end
	
	local function initDropdownMenu(self)
		for _, row in pairs(self.menu) do
			row.checked = nil

			if( row.isChannel ) then
				local text = select(2, GetChannelName(row.arg1)) 
				if( text ) then
					row.text = string.format("%d. %s", row.arg1, text)
					UIDropDownMenu_AddButton(row)
				end
			else
				UIDropDownMenu_AddButton(row)
			end
		end
	end
	
	local function initDropdown(self)
		UIDropDownMenu_Initialize(self, initDropdownMenu)
		UIDropDownMenu_SetWidth(self, 160)
		UIDropDownMenu_SetSelectedValue(self, ElitistGroup.db.profile.report[self.configKey])

		local value = ElitistGroup.db.profile.report[self.configKey]
		if( not value ) then	
			UIDropDownMenu_SetText(self, self.disabledText)
		else
			local text
			for _, row in pairs(self.menu) do
				if( row.value == value ) then
					text = row.arg1
					local channel = row.isChannel and select(2, GetChannelName(row.arg1))
					if( channel ) then
						text = string.format("%d. %s", row.arg1, channel)
					end
					
					row.checked = nil
					break
				end
			end
		
			UIDropDownMenu_SetText(self, string.format(self.formatText, text))
		end
	end
	
	-- Average item level
	local levelFilter = CreateFrame("Frame", "ElitistGroupReportItemLevel", generalFrame, "UIDropDownMenuTemplate")
	levelFilter:SetPoint("TOPLEFT", generalFrame, "TOPLEFT", -14, -2)
	levelFilter:SetScript("OnShow", initDropdown)
	levelFilter.disabledText = L["Don't include item level"]
	levelFilter.formatText = L["Item levels <= %d"]
	levelFilter.configKey = "itemLevel"
	levelFilter.menu = {
		{value = "disabled", text = L["Don't include"], func = dropdownSelected},
		{value = 300, arg1 = 300, text = string.format(L["<= %d"], 300), func = dropdownSelected},
		{value = 270, arg1 = 270, text = string.format(L["<= %d"], 270), func = dropdownSelected},
		{value = 260, arg1 = 260, text = string.format(L["<= %d"], 260), func = dropdownSelected},
		{value = 250, arg1 = 250, text = string.format(L["<= %d"], 250), func = dropdownSelected},
		{value = 240, arg1 = 240, text = string.format(L["<= %d"], 240), func = dropdownSelected},
		{value = 230, arg1 = 230, text = string.format(L["<= %d"], 230), func = dropdownSelected},
		{value = 220, arg1 = 220, text = string.format(L["<= %d"], 220), func = dropdownSelected},
		{value = 210, arg1 = 210, text = string.format(L["<= %d"], 210), func = dropdownSelected},
		{value = 200, arg1 = 200, text = string.format(L["<= %d"], 200), func = dropdownSelected},
	}
	initDropdown(levelFilter)
	ElitistGroupReportItemLevelButton:SetScript("OnEnter", OnEnter)
	ElitistGroupReportItemLevelButton:SetScript("OnLeave", OnLeave)
	ElitistGroupReportItemLevelButton.tooltip = L["Whether item level should be included in the report, or only show average item levels below the selected value."]
	generalFrame.levelFilter = levelFilter
	
	local SPACING = 0
	
	-- Equipment
	local equipmentFilter = CreateFrame("Frame", "ElitistGroupReportEquipment", generalFrame, "UIDropDownMenuTemplate")
	equipmentFilter:SetPoint("TOPLEFT", generalFrame.levelFilter, "BOTTOMLEFT", 0, SPACING)
	equipmentFilter:SetScript("OnShow", initDropdown)
	equipmentFilter.disabledText = L["Don't include gear"]
	equipmentFilter.formatText = L["> %d%% bad gear"]
	equipmentFilter.configKey = "equipment"
	equipmentFilter.menu = {
		{value = "disabled", text = L["Don't include"], func = dropdownSelected},
		{value = 0, arg1 = 0, text = string.format(L["> %d%%"], 0), func = dropdownSelected},
		{value = 0.2, arg1 = 20, text = string.format(L["> %d%%"], 20), func = dropdownSelected},
		{value = 0.4, arg1 = 40, text = string.format(L["> %d%%"], 40), func = dropdownSelected},
		{value = 0.6, arg1 = 60, text = string.format(L["> %d%%"], 60), func = dropdownSelected},
		{value = 0.8, arg1 = 80, text = string.format(L["> %d%%"], 80), func = dropdownSelected},
	}
	initDropdown(equipmentFilter)
	ElitistGroupReportEquipmentButton:SetScript("OnEnter", OnEnter)
	ElitistGroupReportEquipmentButton:SetScript("OnLeave", OnLeave)
	ElitistGroupReportEquipmentButton.tooltip = L["Whether equipment should be included in the report.\n\nWhen set, it will show people with a percentage of bad gear higher than the entered amount."]
	generalFrame.equipmentFilter = equipmentFilter

	-- Enchants
	local enchantFilter = CreateFrame("Frame", "ElitistGroupReportEnchants", generalFrame, "UIDropDownMenuTemplate")
	enchantFilter:SetPoint("TOPLEFT", generalFrame.equipmentFilter, "BOTTOMLEFT", 0, SPACING)
	enchantFilter:SetScript("OnShow", initDropdown)
	enchantFilter.disabledText = L["Don't include enchants"]
	enchantFilter.formatText = L[">= %d%% bad enchants"]
	enchantFilter.configKey = "enchants"
	enchantFilter.menu = {
		{value = "disabled", text = L["Don't include"], func = dropdownSelected},
		{value = 0, arg1 = 0, text = string.format(L["> %d%%"], 0), func = dropdownSelected},
		{value = 0.2, arg1 = 20, text = string.format(L["> %d%%"], 20), func = dropdownSelected},
		{value = 0.4, arg1 = 40, text = string.format(L["> %d%%"], 40), func = dropdownSelected},
		{value = 0.6, arg1 = 60, text = string.format(L["> %d%%"], 60), func = dropdownSelected},
		{value = 0.8, arg1 = 80, text = string.format(L["> %d%%"], 80), func = dropdownSelected},
	}
	initDropdown(enchantFilter)
	ElitistGroupReportEnchantsButton:SetScript("OnEnter", OnEnter)
	ElitistGroupReportEnchantsButton:SetScript("OnLeave", OnLeave)
	ElitistGroupReportEnchantsButton.tooltip = L["Whether enchants should be included in the report.\n\nWhen set, it will show people with a percentage of bad enchants higher than the entered amount."]
	generalFrame.enchantFilter = enchantFilter
	
	-- Gems
	local gemFilter = CreateFrame("Frame", "ElitistGroupReportGems", generalFrame, "UIDropDownMenuTemplate")
	gemFilter:SetPoint("TOPLEFT", generalFrame.enchantFilter, "BOTTOMLEFT", 0, SPACING)
	gemFilter:SetScript("OnShow", initDropdown)
	gemFilter.disabledText = L["Don't include gems"]
	gemFilter.formatText = L[">= %d%% bad gems"]
	gemFilter.configKey = "gems"
	gemFilter.menu = {
		{value = "disabled", text = L["Don't include"], func = dropdownSelected},
		{value = 0, arg1 = 0, text = string.format(L["> %d%%"], 0), func = dropdownSelected},
		{value = 0.2, arg1 = 20, text = string.format(L["> %d%%"], 20), func = dropdownSelected},
		{value = 0.4, arg1 = 40, text = string.format(L["> %d%%"], 40), func = dropdownSelected},
		{value = 0.6, arg1 = 60, text = string.format(L["> %d%%"], 60), func = dropdownSelected},
		{value = 0.8, arg1 = 80, text = string.format(L["> %d%%"], 80), func = dropdownSelected},
	}
	initDropdown(gemFilter)
	ElitistGroupReportGemsButton:SetScript("OnEnter", OnEnter)
	ElitistGroupReportGemsButton:SetScript("OnLeave", OnLeave)
	ElitistGroupReportGemsButton.tooltip = L["Whether enchants should be included in the report.\n\nWhen set, it will show people with a percentage of bad enchants higher than the entered amount."]
	generalFrame.gemFilter = gemFilter
	
	-- Channels
	local channelFilter = CreateFrame("Frame", "ElitistGroupReportChannels", generalFrame, "UIDropDownMenuTemplate")
	channelFilter:SetPoint("TOPLEFT", generalFrame.gemFilter, "BOTTOMLEFT", 0, SPACING)
	channelFilter:SetScript("OnShow", initDropdown)
	channelFilter.disabledText = L["No channel selected"]
	channelFilter.formatText = L["Report to channel %s"]
	channelFilter.configKey = "channel"
	channelFilter.menu = {
		{value = "GUILD", arg1 = L["guild"], text = L["Guild"], func = dropdownSelected},
		{value = "OFFICER", arg1 = L["officer"], text = L["Officer"], func = dropdownSelected},
		{value = "RAID", arg1 = L["raid"], text = L["Raid"], func = dropdownSelected},
		{value = "PARTY", arg1 = L["party"], text = L["Party"], func = dropdownSelected},
		{value = 1, arg1 = 1, text = 1, func = dropdownSelected, isChannel = true},
		{value = 2, arg1 = 2, text = 2, func = dropdownSelected, isChannel = true},
		{value = 3, arg1 = 3, text = 3, func = dropdownSelected, isChannel = true},
		{value = 4, arg1 = 4, text = 4, func = dropdownSelected, isChannel = true},
		{value = 5, arg1 = 5, text = 5, func = dropdownSelected, isChannel = true},
		{value = 6, arg1 = 6, text = 6, func = dropdownSelected, isChannel = true},
		{value = 7, arg1 = 7, text = 7, func = dropdownSelected, isChannel = true},
		{value = 8, arg1 = 8, text = 8, func = dropdownSelected, isChannel = true},
		{value = 9, arg1 = 9, text = 9, func = dropdownSelected, isChannel = true},
		{value = 10, arg1 = 10, text = 10, func = dropdownSelected, isChannel = true},
	}
	initDropdown(channelFilter)
	ElitistGroupReportChannelsButton:SetScript("OnEnter", OnEnter)
	ElitistGroupReportChannelsButton:SetScript("OnLeave", OnLeave)
	ElitistGroupReportChannelsButton.tooltip = L["Channel to report Elitist Group summary to."]
	generalFrame.channelFilter = channelFilter

	-- All or nothing
	local matchFilters = createToggle(generalFrame)
	matchFilters:HookScript("OnClick", function(self) ElitistGroup.db.profile.report.matchAll = self:GetChecked() or nil end)
	matchFilters:SetChecked(ElitistGroup.db.profile.report.matchAll)
	matchFilters.text:SetText(L["Match all filters"])
	matchFilters.tooltip = L["Match all item level, gear, enchant and gem filters to report.\n\nIf unchecked, only have to match one."]
	matchFilters:SetPoint("TOPLEFT", channelFilter, "BOTTOMLEFT", 14, -5)
	generalFrame.matchFilters = matchFilters
	
	-- View
	local view = CreateFrame("Button", nil, generalFrame, "UIPanelButtonGrayTemplate")
	view:SetHeight(20)
	view:SetWidth(75)
	view:SetPoint("BOTTOMLEFT", generalFrame, "BOTTOMLEFT", 2, 2)
	view:SetText(L["View"])
	view:SetPushedTexture(nil)
	view:SetPushedTextOffset(0, 0)
	view:SetScript("OnEnter", function(self)
		local filters = {}
		local itemLevel = ElitistGroup.db.profile.report.itemLevel
		if( itemLevel ) then
			table.insert(filters, string.format(L["average item level below %d"], itemLevel))
		end

		local equipment = ElitistGroup.db.profile.report.equipment
		if( equipment ) then
			table.insert(filters, string.format(L["%d%% or more bad equipped items"], equipment * 100))
		end
		
		local enchants = ElitistGroup.db.profile.report.enchants
		if( enchants ) then
			table.insert(filters, string.format(L["%d%% or more bad enchants"], enchants * 100))
		end
		
		local gems = ElitistGroup.db.profile.report.gems
		if( gems ) then
			table.insert(filters, string.format(L["%d%% or more bad gems"], gems * 100))
		end
		
		if( #(filters) == 0 ) then
			self.tooltip = L["No filters are enabled, nothing to report based off of."]
		elseif( ElitistGroup.db.profile.report.matchAll ) then
			self.tooltip = L["Current filters are all players who have:\n\n"]
			self.tooltip = self.tooltip .. table.concat(filters, L["\n|cffffffffAND|r\n"])
		else
			self.tooltip = L["Current filters are all players who have:\n\n"]
			self.tooltip = self.tooltip .. table.concat(filters, L["\n|cffffffffOR|r\n"])
		end

		OnEnter(self)
	end)
	view:SetScript("OnLeave", OnLeave)

	-- Report
	local report = CreateFrame("Button", nil, generalFrame, "UIPanelButtonGrayTemplate")
	report:SetHeight(20)
	report:SetWidth(75)
	report:SetPoint("BOTTOMRIGHT", generalFrame, "BOTTOMRIGHT", -2, 2)
	report:SetText(L["Report"])
	report:SetScript("OnClick", reportSummary)
	report:SetScript("OnEnter", OnEnter)
	report:SetScript("OnLeave", OnLeave)
	report:SetMotionScriptsWhileDisabled(true)
	report.tooltip = L["Do not abuse this!\n\nAbuse will result in the feature being removed."]
	
	-- Class toggles
	local classFrame = CreateFrame("Frame", nil, frame)   
	classFrame:SetBackdrop(backdrop)
	classFrame:SetBackdropBorderColor(0.60, 0.60, 0.60, 1)
	classFrame:SetBackdropColor(0, 0, 0, 0)
	classFrame:SetWidth(130)
	classFrame:SetHeight(240)
	classFrame:SetPoint("TOPLEFT", self.generalFrame, "TOPRIGHT", 12, 0)
	self.classFrame = classFrame

	classFrame.headerText = classFrame:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
	classFrame.headerText:SetPoint("BOTTOMLEFT", classFrame, "TOPLEFT", 0, 5)
	classFrame.headerText:SetText(L["Classes"])

	classFrame.selectAll = createToggle(classFrame)
	classFrame.selectAll.text:SetText(L["Select all"])
	classFrame.selectAll:SetChecked(true)
	classFrame.selectAll:SetPoint("TOPLEFT", classFrame, "TOPLEFT", 2, -4)
	classFrame.selectAll:HookScript("OnClick", function(self)
		local selected = not self:GetChecked() or nil
		for _, classToken in pairs(CLASS_SORT_ORDER) do
			ElitistGroup.db.profile.report[classToken] = selected
		end
		
		for _, check in pairs(classFrame.checks) do
			check:SetChecked(not selected)
		end
	end)
	
	local function toggleClass(self)
		ElitistGroup.db.profile.report[self.classToken] = not self:GetChecked() or nil
	end
	
	classFrame.checks = {}
	for id, classToken in pairs(CLASS_SORT_ORDER) do
		local check = createToggle(classFrame)
		local classColor = RAID_CLASS_COLORS[classToken]
		check:HookScript("OnClick", toggleClass)
		check:SetChecked(not ElitistGroup.db.profile.report[classToken])
		check.classToken = classToken
		check.text:SetText(LOCALIZED_CLASS_NAMES_MALE[classToken])
		check.text:SetTextColor(classColor.r, classColor.g, classColor.b)

		if( id > 1 ) then
			check:SetPoint("TOPLEFT", classFrame.checks[id - 1], "BOTTOMLEFT", 0, -1)
		else
			check:SetPoint("TOPLEFT", classFrame.selectAll, "BOTTOMLEFT", 0, -3)   
		end
		classFrame.checks[id] = check
	end
    	
	self.frame = frame
end
