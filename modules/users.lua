local ElitistGroup = select(2, ...)
local Users = ElitistGroup:NewModule("Users", "AceEvent-3.0")
local L = ElitistGroup.L
local backdrop = {bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeSize = 1}
local gemData, enchantData, equipmentData, achievementTooltips, tempList, managePlayerNote, userData, OnEnter, OnLeave
local userList, achievementTooltips, experienceData, experienceDataMain = {}, {}, {}, {}
local MAX_DUNGEON_ROWS, MAX_NOTE_ROWS = 5, 7
local MAX_ACHIEVEMENT_ROWS = 20
local MAX_DATABASE_ROWS = 18
local DungeonData = ElitistGroup.Dungeons

function Users:OnInitialize()
	self.userList = userList
	
	self:RegisterMessage("EG_DATA_UPDATED", function(event, type, user)
		if( not userList[user] ) then
			self.rebuildDatabase = true
		end
		
		local self = Users
		if( self.frame and self.frame:IsVisible() ) then
			if( self.activeUserID and self.activeUserID == user ) then
				self:BuildUI(ElitistGroup.userData[user], type)
			end
			
			self:BuildDatabasePage()
		end
	end)
end

function Users:ResetUserList()
	userList = {}
	self.rebuildDatabase = true
	self:BuildDatabasePage()
end

local function sortAchievements(a, b)
	local aName, _, _, _, _, _, _, aFlags = select(2, GetAchievementInfo(a))
	local bName, _, _, _, _, _, _, bFlags = select(2, GetAchievementInfo(b))
	local aEarned = userData.achievements[a] or 0
	local bEarned = userData.achievements[b] or 0
	local aStatistic = bit.band(aFlags, ACHIEVEMENT_FLAGS_STATISTIC) > 0
	local bStatistic = bit.band(bFlags, ACHIEVEMENT_FLAGS_STATISTIC) > 0
	
	if( not aStatistic and not bStatistic ) then
		return aEarned == bEarned and aName < bName or aEarned > bEarned
	elseif( not aStatistic ) then
		return true
	elseif( not bStatistic ) then
		return false
	end
	
	return aEarned > bEarned
end

function Users:Toggle(userData)
	local userID = string.format("%s-%s", userData.name, userData.server)
	if( self.activeUserID == userID and self.frame:IsVisible() ) then
		self.frame:Hide()
	else
		self:Show(userData)
	end
end

function Users:Show(data)
	userData = data
	self.activeUserID = string.format("%s-%s", userData.name, userData.server)

	self:BuildUI(userData)
	self:BuildDatabasePage()
end

function Users:BuildUI(userData, updateType)
	if( not userData ) then return end
	self:CreateUI()

	local frame = self.frame

	-- Build score as well as figure out their score
	if( not updateType or updateType == "gear" or updateType == "gems" ) then
		ElitistGroup:ReleaseTables(equipmentData, enchantData, gemData)
		equipmentData, enchantData, gemData = ElitistGroup:GetGearSummary(userData)
	end

	-- Build the players info
	local infoFrame = self.infoFrame
	-- CLASS
	local coords = CLASS_BUTTONS[userData.classToken]
	if( coords ) then
		infoFrame.playerInfo:SetFormattedText("%s (%s)", userData.name, userData.level)
		infoFrame.playerInfo.tooltip = string.format(L["%s - %s, level %s %s."], userData.name, userData.server, userData.level, LOCALIZED_CLASS_NAMES_MALE[userData.classToken])
		infoFrame.playerInfo.icon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
		infoFrame.playerInfo.icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
		infoFrame.playerInfo.disableWrap = true
	else
		infoFrame.playerInfo:SetFormattedText("%s", userData.name)
		infoFrame.playerInfo.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
		infoFrame.playerInfo.icon:SetTexCoord(0, 1, 0, 1)
		infoFrame.playerInfo.tooltip = string.format(L["%s - %s, level %s, unknown class."], userData.name, userData.server, userData.level)
		infoFrame.playerInfo.disableWrap = true
	end
	
	-- TALENTS
	if( not userData.pruned and userData.talentTree1 and userData.talentTree2 and userData.talentTree3 ) then
		-- PRIMARY
		local specType, specName, specIcon = ElitistGroup:GetPlayerSpec(userData.classToken, userData)
		ElitistGroup:SetTalentText(infoFrame.talentInfo, specType, specName, userData, "primary")
		infoFrame.talentInfo.icon:SetTexture(specIcon)
		
		-- SECONDARY
		if( userData.secondarySpec ) then
			local specType, specName, specIcon = ElitistGroup:GetPlayerSpec(userData.classToken, userData.secondarySpec)
			ElitistGroup:SetTalentText(infoFrame.secondTalentInfo, specType, specName, userData, "secondary")
			infoFrame.secondTalentInfo.icon:SetTexture(specIcon)
		else
			infoFrame.secondTalentInfo:SetText(L["No secondary spec"])
			infoFrame.secondTalentInfo.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
			infoFrame.secondTalentInfo.tooltip = L["The player has not purchased dual specialization yet."]
		end
	else
		infoFrame.talentInfo:SetText(L["Talents unavailable"])
		infoFrame.talentInfo.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

		infoFrame.secondTalentInfo:SetText(L["Talents unavailable"])
		infoFrame.secondTalentInfo.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
	end
	
	if( not userData.pruned ) then
		local equipmentTooltip, gemTooltip, enchantTooltip = ElitistGroup:GetGeneralSummaryTooltip(equipmentData, gemData, enchantData)

		if( not updateType or updateType == "gear" ) then
			-- EQUIPMENT
			local percent = math.max(math.min(1, (equipmentData.totalEquipped - equipmentData.totalBad) / equipmentData.totalEquipped), 0)
			local r = (percent > 0.5 and (1.0 - percent) * 2 or 1.0) * 255
			local g = (percent > 0.5 and 1.0 or percent * 2) * 255
			infoFrame.equipmentInfo:SetFormattedText(L["[|cff%02x%02x00%d%%|r] [%s%d|r] Equipment"], r, g, percent * 100, ElitistGroup:GetItemColor(equipmentData.totalScore), equipmentData.totalScore)
			infoFrame.equipmentInfo.tooltip = equipmentTooltip
			infoFrame.equipmentInfo.situationalTooltip = ElitistGroup:GetSituationalTooltip(nil, equipmentData)
			infoFrame.equipmentInfo.disableWrap = true
		
			-- ENCHANTS
			if( not enchantData.noData ) then
				local percent = math.max(math.min(1, (enchantData.total - enchantData.totalBad) / enchantData.total), 0)
				local r = (percent > 0.5 and (1.0 - percent) * 2 or 1.0) * 255
				local g = (percent > 0.5 and 1.0 or percent * 2) * 255

				infoFrame.enchantInfo:SetFormattedText(L["[|cff%02x%02x00%d%%|r] Enchants"], r, g, percent * 100)
				infoFrame.enchantInfo.tooltip = enchantTooltip
				infoFrame.enchantInfo.disableWrap = not enchantData.noData
			else
				infoFrame.enchantInfo:SetText(L["[|cffff20200%|r] Enchants"])
				infoFrame.enchantInfo.tooltip = L["No enchants found."]
				infoFrame.enchantInfo.disableWrap = nil
			end
		end
		
		-- GEMS
		if( not updateType or updateType == "gems" ) then
			-- Build gems
			if( not gemData.noData ) then
				local percent = math.max(math.min(1, (gemData.total - gemData.totalBad) / gemData.total), 0)
				local r = (percent > 0.5 and (1.0 - percent) * 2 or 1.0) * 255
				local g = (percent > 0.5 and 1.0 or percent * 2) * 255

				infoFrame.gemInfo:SetFormattedText(L["[|cff%02x%02x00%d%%|r] Gems"], r, g, percent * 100)
				infoFrame.gemInfo.tooltip = gemTooltip
				infoFrame.gemInfo.situationalTooltip = ElitistGroup:GetSituationalTooltip(nil, nil, gemData)
				infoFrame.gemInfo.disableWrap = not gemData.noData
			else
				infoFrame.gemInfo:SetText(L["[|cffff20200%|r] Gems"])
				infoFrame.gemInfo.tooltip = L["No gems found."]
				infoFrame.gemInfo.disableWrap = nil
			end		
		end

		infoFrame.enchantInfo:Show()
		infoFrame.gemInfo:Show()
	else
		infoFrame.equipmentInfo:SetText(L["User data pruned"])
		infoFrame.equipmentInfo.tooltip = L["Data has been pruned to save database space.\n\nPerhaps you want to change prune settings in /eg config?"]
		infoFrame.equipmentInfo.disableWrap = nil
		infoFrame.enchantInfo:Hide()
		infoFrame.gemInfo:Hide()
	end
		
	-- SCAN AGE
	local scanAge = (time() - userData.scanned) / 60
	if( scanAge <= 2 ) then
		infoFrame.scannedInfo:SetText(L["<1 minute old"])
		infoFrame.scannedInfo.icon:SetTexture("Interface\\Icons\\INV_JewelCrafting_Gem_41")
	elseif( scanAge < 60 ) then
		infoFrame.scannedInfo:SetFormattedText(L["%d |4minute:minutes; old"], scanAge)
		infoFrame.scannedInfo.icon:SetTexture("Interface\\Icons\\INV_JewelCrafting_Gem_" .. (scanAge < 30 and 41 or 38))
	elseif( scanAge <= 1440 ) then
		infoFrame.scannedInfo:SetFormattedText(L["%d |4hour:hours; old"], scanAge / 60)
		infoFrame.scannedInfo.icon:SetTexture("Interface\\Icons\\INV_JewelCrafting_Gem_39")
	else
		infoFrame.scannedInfo:SetFormattedText(L["%d |4day:days; old"], scanAge / 1440)
		infoFrame.scannedInfo.icon:SetTexture("Interface\\Icons\\INV_JewelCrafting_Gem_37")
	end
	
	-- TRUSTED
	if( ElitistGroup:IsTrusted(userData.from) ) then
		infoFrame.trustedInfo:SetFormattedText(L["%s (Trusted)"], string.match(userData.from, "(.-)%-"))
		infoFrame.trustedInfo.tooltip = L["Data for this player is from a verified source and can be trusted."]
		infoFrame.trustedInfo.icon:SetTexture(READY_CHECK_READY_TEXTURE)
	else
		infoFrame.trustedInfo:SetFormattedText(L["%s (Untrusted)"], string.match(userData.from, "(.-)%-"))
		infoFrame.trustedInfo.tooltip = L["The data you see should be accurate. However, it is not guaranteed as it is from an unverified source."]
		infoFrame.trustedInfo.icon:SetTexture(READY_CHECK_NOT_READY_TEXTURE)
	end
	
	-- DUNGEON INFO
	-- Find where the players score lets them into at least
	local lockedScore
	if( not userData.pruned ) then
		for i=#(DungeonData.suggested), 1, -4 do
			local score = DungeonData.suggested[i - 2]
			if( lockedScore and lockedScore ~= score ) then
				self.forceOffset = math.ceil((i + 1) / 4)
				break
			elseif( equipmentData.totalScore >= score ) then
				lockedScore = score
				self.forceOffset = math.ceil((i + 1) / 4)
			end
		end
	else
		self.forceOffset = 0
	end
	
	-- NOTE MANAGEMENT
	if( not updateType or updateType == "notes" ) then
		if( ElitistGroup.playerID ~= self.activeUserID ) then
			infoFrame.manageNote:SetText(userData.notes[ElitistGroup.playerID] and L["Edit"] or L["Add"])
			infoFrame.manageNote.tooltip = L["You can edit or add a note on this player here."]
			infoFrame.manageNote:Show()
		else
			infoFrame.manageNote:Hide()
		end
	
		self.activeDataNotes = 0
		local average = 0
		local playerNote = userData.notes[ElitistGroup.playerID]
		for _, data in pairs(userData.notes) do 
			self.activeDataNotes = self.activeDataNotes + 1
			average = average + data.rating
		end
		
		if( average > 0 ) then
			infoFrame.averageInfo:SetFormattedText(L["%d average rating"], average / self.activeDataNotes)
			infoFrame.averageInfo.icon:SetTexture(average > 2 and READY_CHECK_READY_TEXTURE or READY_CHECK_NOT_READY_TEXTURE)
			
			if( playerNote ) then
				local noteAge = (time() - playerNote.time) / 60
				if( noteAge < 60 ) then
					noteAge = string.format(L["%d |4minute:minutes;"], noteAge)
				elseif( noteAge < 1440 ) then
					noteAge = string.format(L["%d |4hour:hours;"], noteAge / 60)
				else
					noteAge = string.format(L["%d |4day:days;"], noteAge / 1440)
				end
				
				infoFrame.averageInfo.tooltip = string.format(L["You wrote %s ago:\n|cffffffff%s|r"], noteAge, playerNote.comment or L["No comment"])
			else
				infoFrame.averageInfo.tooltip = nil
			end
		else
			infoFrame.averageInfo:SetFormattedText(L["Not rated"])
			infoFrame.averageInfo.icon:SetTexture(READY_CHECK_NOT_READY_TEXTURE)
			infoFrame.averageInfo.tooltip = nil
		end
	
		if( self.frame.manageNote and self.frame.manageNote:IsVisible() ) then
			managePlayerNote()
		end
	end

	-- Flag that we need achievement data updated
	if( not updateType or updateType == "achievements" ) then
		self.updateAchievements = true
	end
	
	self:BuildDungeonSuggestPage()
	self:UpdateTabs()
end

-- DATABASE BROWSER
local function sortNames(a, b)
	if( UnitExists(userList[a].name) == UnitExists(userList[b].name) ) then
		return a < b
	elseif( UnitExists(userList[a].name) ) then
		return true
	elseif( UnitExists(userList[b].name) ) then
		return false
	end
end

-- Query builder for searching
function Users:RebuildDatabaseTable()
	if( not self.rebuildDatabase ) then return end
	self.rebuildDatabase = nil
	
	for playerID, data in pairs(ElitistGroup.db.faction.users) do
		local user = userList[playerID]
		if( data and ( not user or not user.classToken or not user.level or not user.server or not user.name ) ) then
			local classToken, level, server, name
			-- Get the data first
			if( rawget(ElitistGroup.userData, playerID) ) then
				name, server, level, classToken = ElitistGroup.userData[playerID].name, ElitistGroup.userData[playerID].server, ElitistGroup.userData[playerID].level, ElitistGroup.userData[playerID].classToken
			elseif( data ~= "" ) then
				name, server, level, classToken = string.match(data, "name=\"(.-)\""), string.match(data, "server=\"(.-)\""), tonumber(string.match(data, "level=([0-9]+)")), string.match(data, "classToken=\"([A-Z]+)\"")
			end
			
			user = user or {}
			user.playerID = playerID
			user.classToken = classToken
			user.level = level
			user.name = name
			user.server = server
			
			if( not userList[playerID] ) then
				userList[playerID] = user
				table.insert(userList, playerID)
			end
		end
	end
end

local query
local function buildQuery(search)
	search = string.lower(search)
	
--local search = not self.databaseFrame.search.searchText and string.gsub(string.lower(self.databaseFrame.search:GetText() or ""), "%-", "%%-") or ""
	local class = string.match(search, L["c%-\"(.-)\""])
	local minRange, maxRange = string.match(search, "(%d+)%-(%d+)")
	local level = string.match(search, "(%d+)")
	local server = string.match(search, L["s%-\"(.-)\""])
	local name = string.match(search, L["n%-\"(.-)\""])
	
	-- Figure out class
	if( class and class ~= "" ) then
		for classToken, classLocale in pairs(LOCALIZED_CLASS_NAMES_MALE) do
			if( string.lower(classLocale) == class ) then
				query.classToken = classToken
				break
			end
		end

		for classToken, classLocale in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do
			if( string.lower(classLocale) == class ) then
				query.classToken = classToken
				break
			end
		end
	end
	
	-- Figure out level
	query.minLevel = tonumber(minRange) or tonumber(level) or -1
	query.maxLevel = tonumber(maxRange) or tonumber(level) or MAX_PLAYER_LEVEL
	
	-- Figure out server
	if( server and server ~= "" ) then
		query.server = server
	end
	
	-- Figure out just name
	if( name and name ~= "" ) then
		query.name = name
	end
	
	-- No name was set, strip everything else out and will use that as the name
	if( not query.name ) then
		search = string.gsub(search, ".%-\".-\"", "")
		search = string.gsub(search, ".%-\"", "")
		search = string.gsub(search, "%d+%-%d+", "")
		search = string.gsub(search, "%d+", "")
		search = string.trim(search)
		if( search ~= "" ) then
			local name, server = string.split("-", search, 2)
			query.name = name
			query.server = query.server or server ~= "" and server or nil
		end
	end
end

function Users:BuildDatabasePage()
	self = Users
	if( not ElitistGroup.db.profile.general.databaseExpanded ) then return end
	
	-- Don't need to recheck these during scroll
	if( not self.scrollUpdate ) then
		query = query or {}
		table.wipe(query)

		local useSearch = not self.databaseFrame.search.searchText and self.databaseFrame.search:GetText()
		useSearch = useSearch and useSearch ~= "" and useSearch or nil
		if( useSearch ) then
			buildQuery(useSearch)
		end
		
		self:RebuildDatabaseTable()
		self.databaseFrame.visibleUsers = 0

		for i=1, #(userList) do
			local user = userList[userList[i]]
			user.visible = nil
			-- Search name
			if( not query.name or string.match(string.lower(user.name), query.name) ) then
				-- Search server
				if( not query.server or string.match(string.lower(user.server), query.server) ) then
					-- Search level
					if( not user.level or not query.minLevel or ( user.level >= query.minLevel and user.level <= query.maxLevel ) ) then
						-- Search class token
						if( not query.classToken or not user.classToken or user.classToken == query.classToken ) then
							user.visible = true
							self.databaseFrame.visibleUsers = self.databaseFrame.visibleUsers + 1
						end
					end
				end
			end
		end
		
		table.sort(userList, sortNames)
	end
	
	FauxScrollFrame_Update(self.databaseFrame.scroll, self.databaseFrame.visibleUsers, MAX_DATABASE_ROWS, 16)
	ElitistGroupDatabaseSearch:SetWidth(self.databaseFrame.scroll:IsVisible() and 195 or 210)

	for _, row in pairs(self.databaseFrame.rows) do row:Hide() end

	local offset = FauxScrollFrame_GetOffset(self.databaseFrame.scroll)
	local rowWidth = self.databaseFrame:GetWidth() - (self.databaseFrame.scroll:IsVisible() and 40 or 24)
	
	local rowID, userID = 1, 1
	for id=1, #(userList) do
		local user = userList[userList[id]]
		if( userID > offset and user.visible ) then
			local row = self.databaseFrame.rows[rowID]
			row.userID = user.playerID
			row.tooltip = string.format(L["View info on %s."], user.playerID)
			row:SetWidth(rowWidth)
			row:Show()
			
			local classColor = user.classToken and RAID_CLASS_COLORS[user.classToken]
			local classHex = classColor and string.format("|cff%02x%02x%02x", classColor.r * 255, classColor.g * 255, classColor.b * 255) or ""
			local selected = row.userID == self.activeUserID and "[*] " or ""
			
			if( user.playerID ~= ElitistGroup.playerID and UnitExists(user.name) ) then
				row:SetFormattedText("%s|cffffffff[%s]|r %s%s|r", selected, GROUP, classHex, user.playerID)
			else
				row:SetFormattedText("%s%s%s|r", selected, classHex, user.playerID)
			end
			
			rowID = rowID + 1
			if( rowID > MAX_DATABASE_ROWS ) then break end
		end
		
		if( user.visible ) then
			userID = userID + 1
		end
	end
end

-- EQUIPMENT PAGE UPDATE
function Users:BuildEquipmentPage()
	local equipmentFrame = self.equipmentFrame
	local enchantTooltips, gemTooltips = ElitistGroup:GetGearSummaryTooltip(userData.equipment, enchantData, gemData)
	
	for _, slot in pairs(equipmentFrame.equipSlots) do
		-- Yay, item!
		if( slot.inventoryID and userData.equipment[slot.inventoryID] ) then
			local itemLink = userData.equipment[slot.inventoryID]
			local fullItemLink, itemQuality, itemLevel, _, _, _, _, itemEquipType, itemIcon = select(2, GetItemInfo(itemLink))
			if( itemQuality and itemLevel ) then
				local baseItemLink = ElitistGroup:GetBaseItemLink(itemLink)
			
				-- Now sum it all up
				slot.tooltip = nil
				slot.equippedItem = itemLink
				slot.gemTooltip = gemTooltips[itemLink]
				slot.enchantTooltip = enchantTooltips[itemLink]
				slot.isBadType = equipmentData[itemLink] and "|cffff2020[!]|r " or ""
				slot.itemTalentType = ElitistGroup.Items.itemRoleText[ElitistGroup.ITEM_TALENTTYPE[baseItemLink]] or ElitistGroup.ITEM_TALENTTYPE[baseItemLink]
				slot.situationalTooltip = ElitistGroup:GetSituationalTooltip(itemLink, equipmentData, gemData)
				slot.fullItemLink = fullItemLink
				slot.icon:SetTexture(itemIcon)
				slot.typeText:SetText(slot.itemTalentType)
				slot:Enable()
				slot:Show()
			
				if( equipmentData[itemLink] ) then
					slot.typeText:SetTextColor(1, 0.15, 0.15)
				else
					slot.typeText:SetTextColor(1, 1, 1)
				end

				local color = ITEM_QUALITY_COLORS[itemQuality] or ITEM_QUALITY_COLORS[-1]
				slot.levelText:SetText(math.floor(ElitistGroup:CalculateScore(itemLink, itemQuality, itemLevel)))
				slot.levelText:SetTextColor(color.r, color.g, color.b)
				
				if( enchantData[fullItemLink] and gemData[fullItemLink] ) then
					slot.enhanceText:SetText(L["Gems/Enchant"])
				elseif( gemData[fullItemLink] ) then
					slot.enhanceText:SetText(L["Gems"])
				elseif( enchantData[fullItemLink] ) then
					slot.enhanceText:SetText(L["Enchant"])
				else
					slot.enhanceText:SetText(nil)
				end

			-- We have an item, but the cache does't exist yet
			else
				slot.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
				slot.enhanceText:SetText(nil)
				slot.typeText:SetFormattedText(L["Item #%d not in cache"], string.match(itemLink, "item:(%d+)") or -1)
				slot.typeText:SetTextColor(1, 1, 1)
				slot.levelText:SetText("---")
				slot.levelText:SetTextColor(1, 1, 1)
				slot:Disable()
				slot:Show()
			end
		-- No item :(
		elseif( slot.inventoryID ) then
			local texture = slot.emptyTexture
			if( slot.checkRelic and ( userData.classToken == "PALADIN" or userData.classToken == "DRUID" or userData.classToken == "SHAMAN" ) ) then
				texture = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Relic.blp"
			end
		
			slot.icon:SetTexture(texture)
			slot.enhanceText:SetText(nil)
			slot.typeText:SetText(L["No item equipped"])
			slot.typeText:SetTextColor(1, 1, 1)
			slot.levelText:SetText("---")
			slot.levelText:SetTextColor(1, 1, 1)
			slot.tooltip = L["No item equipped"]
			slot:Disable()
			slot:Show()
		end
	end

	ElitistGroup:ReleaseTables(enchantTooltips, gemTooltips)
end


-- Create the achievement data
function Users:UpdateAchievementData()
	if( not self.updateAchievements ) then return end
	self.updateAchievements = true
	
	tempList = ElitistGroup:GetTable()
	table.wipe(achievementTooltips)
	table.wipe(experienceData)
	table.wipe(experienceDataMain)

	for _, data in pairs(DungeonData.experience) do
		experienceData[data.id] = experienceData[data.id] or 0
		experienceDataMain[data.id] = experienceDataMain[data.id] or 0
			
		for id, points in pairs(data) do
			if( userData.achievements[id] ) then
				local total = userData.achievements[id] * points
				if( DungeonData.experienceCap[id] and DungeonData.experienceCap[id] < total ) then
					total = DungeonData.experienceCap[id]
				end
				
				experienceData[data.id] = experienceData[data.id] + total
			end
			
			if( userData.mainAchievements and userData.mainAchievements[id] ) then
				local total = userData.mainAchievements[id] * points
				if( DungeonData.experienceCap[id] and DungeonData.experienceCap[id] < total ) then
					total = DungeonData.experienceCap[id]
				end

				experienceDataMain[data.id] = experienceDataMain[data.id] + total
			end
		end
		
		-- Add the childs score to the parents
		if( not data.parent ) then
			experienceData[data.childOf] = (experienceData[data.childOf] or 0) + experienceData[data.id]
			experienceDataMain[data.childOf] = (experienceDataMain[data.childOf] or 0) + experienceDataMain[data.id]
		end
		
		-- Cascade the scores from this one to whatever it's supposed to
		if( data.cascade ) then
			experienceData[data.cascade] = (experienceData[data.cascade] or 0) + experienceData[data.id]
			experienceDataMain[data.cascade] = (experienceDataMain[data.cascade] or 0) + experienceDataMain[data.id]
		end
		
		-- Build the tooltip, caching it because it really does not need to be recalcualted that often
		table.wipe(tempList)
		for achievementID, points in pairs(data) do
			if( type(achievementID) == "number" and type(points) == "number" ) then
				table.insert(tempList, achievementID)
			end
		end
		
		table.sort(tempList, sortAchievements)
		
		achievementTooltips[data.id] = ""
		for i=1, #(tempList) do
			local achievementID = tempList[i]
			local name, _, _, _, _, _, _, flags = select(2, GetAchievementInfo(achievementID))
			name = string.trim(string.gsub(name, "%((.-)%)$", ""))
			
			local earned = userData.achievements[achievementID]
			local mainEarned = userData.mainAchievements and userData.mainAchievements[achievementID]
			if( mainEarned and userData.mainAchievements ) then
				if( bit.band(flags, ACHIEVEMENT_FLAGS_STATISTIC) > 0 ) then
					achievementTooltips[data.id] = achievementTooltips[data.id] .. "\n" .. string.format("|cffffffff[%d | %d]|r %s", mainEarned or 0, earned or 0, name)
				else
					achievementTooltips[data.id] = achievementTooltips[data.id] .. "\n" .. string.format("|cffffffff[%s | %s]|r %s", mainEarned == 1 and YES or NO, earned == 1 and YES or NO, name)
				end
			else
				if( bit.band(flags, ACHIEVEMENT_FLAGS_STATISTIC) > 0 ) then
					achievementTooltips[data.id] = achievementTooltips[data.id] .. "\n" .. string.format("|cffffffff[%d]|r %s", earned or 0, name)
				else
					achievementTooltips[data.id] = achievementTooltips[data.id] .. "\n" .. string.format("|cffffffff[%s]|r %s", earned == 1 and YES or NO, name)
				end
			end
		end
	end
	
	ElitistGroup:ReleaseTables(tempList)
end

-- ACHIEVEMENTS
function Users:BuildAchievementPage()
	local self = Users
	local totalEntries = userData.mainAchievements and 1 or 0

	-- Figure out what's visible, since some categories can be expanded
	for id, data in pairs(DungeonData.experience) do
		experienceData[data.id] = experienceData[data.id] or 0
		if( not data.childOf or ( data.childOf and ElitistGroup.db.profile.expExpanded[data.childOf] and ( not DungeonData.experienceParents[data.childOf] or ElitistGroup.db.profile.expExpanded[DungeonData.experienceParents[data.childOf]] ) ) ) then
			totalEntries = totalEntries + 1
			data.isVisible = true
		else
			data.isVisible = nil
		end
	end
	
	FauxScrollFrame_Update(self.achievementsFrame.scroll, totalEntries, MAX_ACHIEVEMENT_ROWS, 18)
	
	for _, row in pairs(self.achievementsFrame.rows) do row.tooltip = nil; row.toggle:Hide(); row:Hide() end

	local rowID, rowOffset, id = 1, 0, 0
	local rowWidth = self.achievementsFrame:GetWidth() - (self.achievementsFrame.scroll:IsVisible() and 26 or 10)
	local offset = FauxScrollFrame_GetOffset(self.achievementsFrame.scroll)
	
	if( userData.mainAchievements and offset == 0 ) then
		local row = self.frame.achievementFrame.rows[rowID]
		row.nameText:SetFormattedText(L["Mains experience on left, %s on right"], userData.name)
		row.tooltip = row.nameText:GetText()
		row.expandedInfo = nil
		row:SetWidth(rowWidth - 4)
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", self.frame.achievementFrame, "TOPLEFT", 2, -2)
		row.toggle.id = nil
		row.toggle:Hide()
		row:Show()

		rowID = rowID + 1
	end
	
	for _, data in pairs(DungeonData.experience) do
		if( data.isVisible ) then
			id = id + 1
			if( id >= offset ) then
				local row = self.achievementsFrame.rows[rowID]

				-- Setup toggle button
				if( not data.childless and ( DungeonData.experienceParents[data.id] or data.parent ) ) then
					local type = not ElitistGroup.db.profile.expExpanded[data.id] and "Plus" or "Minus"
					row.toggle:SetNormalTexture("Interface\\Buttons\\UI-" .. type .. "Button-UP")
					row.toggle:SetPushedTexture("Interface\\Buttons\\UI-" .. type .. "Button-DOWN")
					row.toggle:SetHighlightTexture("Interface\\Buttons\\UI-" .. type .. "Button-Hilight", "ADD")
					row.toggle.id = data.id
					row.toggle:Show()
				else
					row.toggle.id = nil
					row.toggle:Hide()
				end

				local rowOffset = data.subParent and 20 or DungeonData.experienceParents[data.childOf] and 10 or data.childOf and 4 or 16
				
				local players = data.parent and data.players and string.format(L[" (%d-man)"], data.players) or ""
				-- Children categories without experience requirements should be shown in the experienceText so we don't get an off looking gap
				local heroicIcon = data.heroic and "|TInterface\\LFGFrame\\UI-LFG-ICON-HEROIC:16:13:-2:-2:32:32:0:16:0:20|t" or ""
				if( not data.experienced ) then
					row.nameText:SetFormattedText("%s%s%s", heroicIcon, data.name, players)
				-- Anything with an experience requirement obviously should show it
				elseif( data.experienced ) then
					local experienceText
					-- Not an alt, so do the simple display
					if( not userData.mainAchievements ) then
						local percent = math.min(experienceData[data.id] / data.experienced, 1)
						local r = (percent > 0.5 and (1.0 - percent) * 2 or 1.0) * 255
						local g = (percent > 0.5 and 1.0 or percent * 2) * 255
						experienceText = percent >= 1 and L["Experienced"] or percent >= 0.8 and L["Nearly-experienced"] or percent >= 0.5 and L["Semi-experienced"] or L["Inexperienced"]
						
						if( data.childOf and not row.toggle:IsShown() ) then
							row.nameText:SetFormattedText("- [|cff%02x%02x00%d%%|r] %s%s", r, g, percent * 100, heroicIcon, data.name)
						else
							row.nameText:SetFormattedText("[|cff%02x%02x00%d%%|r] %s%s%s", r, g, percent * 100, heroicIcon, data.name, players)
						end
					-- An alt, fun times
					else
						-- Calculate the alts (the shown characters) experience
						local percentAlt = math.min(experienceData[data.id] / data.experienced, 1)
						local altR = (percentAlt > 0.5 and (1.0 - percentAlt) * 2 or 1.0) * 255
						local altG = (percentAlt > 0.5 and 1.0 or percentAlt * 2) * 255
						-- Now calculate the mains
						local percentMain = math.min(experienceDataMain[data.id] / data.experienced, 1)
						local mainR = (percentMain > 0.5 and (1.0 - percentMain) * 2 or 1.0) * 255
						local mainG = (percentMain > 0.5 and 1.0 or percentMain * 2) * 255

						local totalPercent = percentAlt + percentMain
						experienceText = totalPercent >= 1 and L["Experienced"] or totalPercent >= 0.8 and L["Nearly-experienced"] or totalPercent >= 0.5 and L["Semi-experienced"] or L["Inexperienced"]
						
						if( data.childOf and not row.toggle:IsShown() ) then
							row.nameText:SetFormattedText("- [|cff%02x%02x00%d%%|r | |cff%02x%02x00%d%%|r] %s%s", mainR, mainG, percentMain * 100, altR, altG, percentAlt * 100, heroicIcon, data.name)
						else
							row.nameText:SetFormattedText("[|cff%02x%02x00%d%%|r | |cff%02x%02x00%d%%|r] %s%s%s", mainR, mainG, percentMain * 100, altR, altG, percentAlt * 100, heroicIcon, data.name, players)
						end
					end
					
					row.tooltip = string.format(L["%s - %d-man %s (%s)"], experienceText, data.players, data.name, data.heroic and L["Heroic"] or L["Normal"])
					row.expandedInfo = achievementTooltips[data.id]
				end
				
				row:SetWidth(rowWidth - rowOffset)
				row:ClearAllPoints()
				row:SetPoint("TOPLEFT", self.achievementsFrame, "TOPLEFT", 4 + rowOffset, -3 - 17 * (rowID - 1))
				row:Show()
				
				rowID = rowID + 1
				if( rowID > MAX_ACHIEVEMENT_ROWS ) then break end
			end
		end
	end
end

-- NOTES
function Users:BuildNotesPage()
	self = Users
	FauxScrollFrame_Update(self.notesFrame.scroll, self.activeDataNotes, MAX_NOTE_ROWS - 1, 48)
		
	for _, row in pairs(self.notesFrame.rows) do row:Hide() end
	local rowWidth = self.notesFrame:GetWidth() - (self.notesFrame.scroll:IsVisible() and 24 or 10)
	
	local id, rowID = 1, 1
	local offset = FauxScrollFrame_GetOffset(self.notesFrame.scroll)
	for from, note in pairs(userData.notes) do
		if( id >= offset ) then
			local row = self.notesFrame.rows[rowID]

			local percent = (note.rating - 1) / (ElitistGroup.MAX_RATING - 1)
			local r = (percent > 0.5 and (1.0 - percent) * 2 or 1.0) * 255
			local g = (percent > 0.5 and 1.0 or percent * 2) * 255
			local roles = ""
			if( bit.band(note.role, ElitistGroup.ROLE_HEALER) > 0 ) then roles = HEALER end
			if( bit.band(note.role, ElitistGroup.ROLE_TANK) > 0 ) then roles = roles .. ", " .. TANK end
			if( bit.band(note.role, ElitistGroup.ROLE_DAMAGE) > 0 ) then roles = roles .. ", " .. DAMAGE end
			roles = roles == "" and UNKNOWN or roles
			
			row.infoText:SetFormattedText("|cff%02x%02x00%d|r/|cff20ff20%s|r from %s", r, g, note.rating, ElitistGroup.MAX_RATING, string.match(from, "(.-)%-") or from)
			row.commentText:SetText(ElitistGroup:Decode(note.comment) or L["No comment"])
			row.tooltip = string.format(L["Seen as %s - %s:\n|cffffffff%s|r"], string.trim(string.gsub(roles, "^, ", "")), date("%m/%d/%Y", note.time), note.comment or L["No comment"])
			row:SetWidth(rowWidth)
			row:Show()
			
			rowID = rowID + 1
			if( rowID > MAX_NOTE_ROWS ) then break end
		end
		
		id = id + 1
	end
end

-- SUGGESTED DUNGEONS
function Users:BuildDungeonSuggestPage()
	local self = Users
	local TOTAL_DUNGEONS = #(DungeonData.suggested) / 4

	FauxScrollFrame_Update(self.dungeonFrame.scroll, TOTAL_DUNGEONS, MAX_DUNGEON_ROWS - 1, 28)
	if( self.forceOffset ) then
		self.forceOffset = math.ceil(math.min(self.forceOffset, TOTAL_DUNGEONS - MAX_DUNGEON_ROWS + 1))
		self.dungeonFrame.scroll.offset = self.forceOffset
		self.dungeonFrame.scroll.bar:SetValue(28 * self.forceOffset)
		self.forceOffset = nil
	end

	for _, row in pairs(self.dungeonFrame.rows) do row:Hide() end
	
	local id, rowID = 1, 1
	local offset = FauxScrollFrame_GetOffset(self.dungeonFrame.scroll)
	for dataID=1, #(DungeonData.suggested), 4 do
		if( id >= offset ) then
			local row = self.dungeonFrame.rows[rowID]
			
			local name, score, players, type = DungeonData.suggested[dataID], DungeonData.suggested[dataID + 1], DungeonData.suggested[dataID + 2], DungeonData.suggested[dataID + 3]
			local levelDiff = score - equipmentData.totalScore
			local percent = levelDiff <= 0 and 1 or levelDiff >= 30 and 0 or levelDiff <= 10 and 0.80 or levelDiff <= 20 and 0.50 or levelDiff <= 30 and 0.40
			local r = (percent > 0.5 and (1.0 - percent) * 2 or 1.0) * 255
			local g = (percent > 0.5 and 1.0 or percent * 2) * 255
			local heroicIcon = (type == "heroic" or type == "hard") and "|TInterface\\LFGFrame\\UI-LFG-ICON-HEROIC:16:13:-2:-1:32:32:0:16:0:20|t" or ""
			
			row.dungeonName:SetFormattedText("%s|cff%02x%02x00%s|r", heroicIcon, r, g, name)
			row.dungeonInfo:SetFormattedText(L["|cff%02x%02x00%d|r avg, %d-man (%s)"], r, g, score, players, DungeonData.types[type])
			row:Show()

			rowID = rowID + 1
			if( rowID > MAX_DUNGEON_ROWS ) then break end
		end
		
		id = id + 1
	end
end

-- TAB UPDATER
function Users:UpdateTabs()
	self.tabContainer.notes:SetFormattedText(L["Notes (%d)"], self.activeDataNotes)
	if( userData.pruned ) then
		self.tabContainer.achievements:Disable()
		self.tabContainer.equipment:Disable()
	else
		self.tabContainer.achievements:Enable()
		self.tabContainer.equipment:Enable()
	end
	
	if( self.activeDataNotes == 0 ) then
		self.tabContainer.notes:Disable()
	else
		self.tabContainer.notes:Enable()
	end
	
	local selectedTab = self.tabContainer.selectedTab
	selectedTab = selectedTab ~= "notes" and userData.pruned and "notes" or selectedTab == "notes" and self.activeDataNotes == 0 and "achievements" or selectedTab
	
	-- Handle the visuals
	self.notesFrame:Hide()
	self.tabContainer.notes:UnlockHighlight()
	self.equipmentFrame:Hide()
	self.tabContainer.equipment:UnlockHighlight()
	self.achievementsFrame:Hide()
	self.tabContainer.achievements:UnlockHighlight()
	
	self[selectedTab .. "Frame"]:Show()
	self.tabContainer[selectedTab]:LockHighlight()
	
	-- Now handle the updating part
	if( selectedTab == "achievements" ) then
		self:UpdateAchievementData()
		self:BuildAchievementPage()
	elseif( selectedTab == "notes" ) then
		self:BuildNotesPage()
	elseif( selectedTab == "equipment" ) then
		self:BuildEquipmentPage()
	end
end

-- MANUAL NOTE MANAGER
managePlayerNote = function()
	local self = Users
	local frame = self.frame
	if( self.activeUserID == ElitistGroup.playerID ) then
		if( frame.manageNote ) then
			frame.manageNote:Hide()
		end

		Users.infoFrame.manageNote:UnlockHighlight()
		return
	end
	
	local defaultRole = 0
	if( not frame.manageNote ) then
		local function getNote()
			if( not userData.notes[ElitistGroup.playerID] ) then
				Users.activeDataNotes = Users.activeDataNotes + 1
				userData.notes[ElitistGroup.playerID] = {rating = 3, role = defaultRole, time = time()}
			end
			
			ElitistGroup.writeQueue[Users.activeUserID] = true
			Users.infoFrame.manageNote:SetText(L["Edit"])
			frame.manageNote.delete:Enable()
			frame.manageNote.queuedPlayer = Users.activeUserID
			return userData.notes[ElitistGroup.playerID]
		end
		
		local function UpdateComment(self)
			local text = self:GetText()
			if( text ~= self.lastText ) then
				self.lastText = text
				local playerNote = getNote()
				playerNote.comment = string.trim(text) ~= "" and text or nil
				Users:UpdateTabs()
			end
		end
		
		local function UpdateRole(self)
			local playerNote = getNote()
			local isTank, isHealer, isDamage = bit.band(playerNote.role, ElitistGroup.ROLE_TANK) > 0, bit.band(playerNote.role, ElitistGroup.ROLE_HEALER) > 0, bit.band(playerNote.role, ElitistGroup.ROLE_DAMAGE) > 0
			if( self.roleID == ElitistGroup.ROLE_TANK ) then
				isTank = not isTank
			elseif( self.roleID == ElitistGroup.ROLE_HEALER ) then
				isHealer = not isHealer
			elseif( self.roleID == ElitistGroup.ROLE_DAMAGE ) then
				isDamage = not isDamage
			end
			
			playerNote.role = bit.bor(isTank and ElitistGroup.ROLE_TANK or 0, isHealer and ElitistGroup.ROLE_HEALER or 0, isDamage and ElitistGroup.ROLE_DAMAGE or 0)
			SetDesaturation(self:GetNormalTexture(), bit.band(playerNote.role, self.roleID) == 0)
			Users:UpdateTabs()
		end
		
		local function UpdateRating(self)
			local playerNote = getNote()
			playerNote.rating = self:GetValue()
			Users:UpdateTabs()
		end
		
		local function OnHide(self)
			if( self.queuedPlayer ) then
				Users:SendMessage("EG_DATA_UPDATED", "notes", self.queuedPlayer)
				self.queuedPlayer = nil
			end
		end
		
		frame.manageNote = CreateFrame("Frame", nil, frame)
		frame.manageNote:EnableMouse(true)
		frame.manageNote:SetFrameLevel(self.dungeonFrame:GetFrameLevel() + 10)
		frame.manageNote:SetFrameStrata("MEDIUM")
		frame.manageNote:SetBackdrop(backdrop)
		frame.manageNote:SetBackdropBorderColor(0.60, 0.60, 0.60, 1)
		frame.manageNote:SetBackdropColor(0, 0, 0)
		frame.manageNote:SetHeight(99)
		frame.manageNote:SetWidth(185)
		frame.manageNote:SetPoint("TOPRIGHT", self.infoFrame.manageNote, "BOTTOMRIGHT", 3, -1)
		frame.manageNote:SetScript("OnHide", OnHide)
		frame.manageNote:Hide()
		
		frame.manageNote.delete = CreateFrame("Button", nil, frame.manageNote, "UIPanelButtonGrayTemplate")
		frame.manageNote.delete:SetHeight(18)
		frame.manageNote.delete:SetWidth(55)
		frame.manageNote.delete:SetText(L["Delete"])
		frame.manageNote.delete:SetPoint("TOPLEFT", frame.manageNote, "TOPLEFT", 2, -4)
		frame.manageNote.delete:SetScript("OnClick", function(self)
			Users.infoFrame.manageNote:UnlockHighlight()

			local parent = self:GetParent()
			parent.lastText = ""
			parent.comment:SetText("")
			parent.rating:SetValue(3)
			parent:Hide()

			SetDesaturation(parent.roleTank:GetNormalTexture(), true)
			SetDesaturation(parent.roleHealer:GetNormalTexture(), true)
			SetDesaturation(parent.roleDamage:GetNormalTexture(), true)

			ElitistGroup.userData[Users.activeUserID].notes[ElitistGroup.playerID] = nil
			ElitistGroup.writeQueue[Users.activeUserID] = true

			Users:BuildUI(userData, "notes")
			self:Disable()
		end)

		frame.manageNote.roleTank = CreateFrame("Button", nil, frame.manageNote)
		frame.manageNote.roleTank:SetSize(20, 20)
		frame.manageNote.roleTank:SetNormalTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
		frame.manageNote.roleTank:GetNormalTexture():SetTexCoord(0, 19/64, 22/64, 41/64)
		frame.manageNote.roleTank:SetPoint("TOPLEFT", frame.manageNote, "TOPLEFT", 110, -5)
		frame.manageNote.roleTank:SetScript("OnClick", UpdateRole)
		frame.manageNote.roleTank:SetScript("OnEnter", OnEnter)
		frame.manageNote.roleTank:SetScript("OnLeave", OnLeave)
		frame.manageNote.roleTank.tooltip = L["Set role as tank."]
		frame.manageNote.roleTank.roleID = ElitistGroup.ROLE_TANK

		frame.manageNote.roleHealer = CreateFrame("Button", nil, frame.manageNote)
		frame.manageNote.roleHealer:SetSize(20, 20)
		frame.manageNote.roleHealer:SetNormalTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
		frame.manageNote.roleHealer:GetNormalTexture():SetTexCoord(20/64, 39/64, 1/64, 20/64)
		frame.manageNote.roleHealer:SetPoint("LEFT", frame.manageNote.roleTank, "RIGHT", 4, 0)
		frame.manageNote.roleHealer:SetScript("OnClick", UpdateRole)
		frame.manageNote.roleHealer:SetScript("OnEnter", OnEnter)
		frame.manageNote.roleHealer:SetScript("OnLeave", OnLeave)
		frame.manageNote.roleHealer.tooltip = L["Set role as healer."]
		frame.manageNote.roleHealer.roleID = ElitistGroup.ROLE_HEALER

		frame.manageNote.roleDamage = CreateFrame("Button", nil, frame.manageNote)
		frame.manageNote.roleDamage:SetSize(20, 20)
		frame.manageNote.roleDamage:SetNormalTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
		frame.manageNote.roleDamage:GetNormalTexture():SetTexCoord(20/64, 39/64, 22/64, 41/64)
		frame.manageNote.roleDamage:SetPoint("LEFT", frame.manageNote.roleHealer, "RIGHT", 4, 0)
		frame.manageNote.roleDamage:SetScript("OnClick", UpdateRole)
		frame.manageNote.roleDamage:SetScript("OnEnter", OnEnter)
		frame.manageNote.roleDamage:SetScript("OnLeave", OnLeave)
		frame.manageNote.roleDamage.tooltip = L["Set role as damage."]
		frame.manageNote.roleDamage.roleID = ElitistGroup.ROLE_DAMAGE

		frame.manageNote.comment = CreateFrame("EditBox", "ElitistGroupUsersComment", frame.manageNote, "InputBoxTemplate")
		frame.manageNote.comment:SetHeight(18)
		frame.manageNote.comment:SetWidth(175)
		frame.manageNote.comment:SetAutoFocus(false)
		frame.manageNote.comment:SetPoint("TOPLEFT", frame.manageNote.delete, "BOTTOMLEFT", 6, -12)
		frame.manageNote.comment:SetScript("OnTextChanged", UpdateComment)
		frame.manageNote.comment:SetScript("OnEditFocusGained", function(self)
			if( self.searchText ) then
				self.searchText = nil
				self.lastText = ""
				self:SetText("")
				self:SetTextColor(1, 1, 1, 1)
			end
		end)
		frame.manageNote.comment:SetScript("OnEditFocusLost", function(self)
			if( string.trim(self:GetText()) == "" ) then
				self.searchText = true
				self.lastText = L["Comment..."]
				self:SetText(L["Comment..."])
				self:SetTextColor(0.90, 0.90, 0.90, 0.80)
			end
		end)
		frame.manageNote.comment:SetMaxLetters(256)

		frame.manageNote.rating = CreateFrame("Slider", nil, frame.manageNote)
		frame.manageNote.rating:SetBackdrop({bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
			edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
			tile = true, tileSize = 8, edgeSize = 8,
			insets = { left = 3, right = 3, top = 6, bottom = 6 }
		})

		frame.manageNote.rating:SetPoint("TOPLEFT", frame.manageNote.comment, "BOTTOMLEFT", -4, -14)
		frame.manageNote.rating:SetHeight(15)
		frame.manageNote.rating:SetWidth(175)
		frame.manageNote.rating:SetOrientation("HORIZONTAL")
		frame.manageNote.rating:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
		frame.manageNote.rating:SetMinMaxValues(1, 5)
		frame.manageNote.rating:SetValue(3)
		frame.manageNote.rating:SetValueStep(1)
		frame.manageNote.rating:SetScript("OnValueChanged", UpdateRating)
		
		local min = frame.manageNote:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		min:SetText(L["Terrible"])
		min:SetPoint("TOPLEFT", frame.manageNote.rating, "BOTTOMLEFT", 0, -2)

		local max = frame.manageNote:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		max:SetText(L["Great"])
		max:SetPoint("TOPRIGHT", frame.manageNote.rating, "BOTTOMRIGHT", 0, -2)
	end
		
	-- Now setup what we got
	local note = userData.notes[ElitistGroup.playerID]
	if( note ) then
		frame.manageNote.comment.lastText = note.comment or ""
		frame.manageNote.comment:SetText(note.comment or "")
		frame.manageNote.rating:SetValue(note.rating)
		frame.manageNote.delete:Enable()
	else
		frame.manageNote.comment.lastText = ""
		frame.manageNote.comment:SetText("")
		frame.manageNote.rating:SetValue(3)
		frame.manageNote.delete:Disable()
		
		if( not userData.pruned ) then
			local specType = ElitistGroup:GetPlayerSpec(userData.classToken, userData)
			defaultRole = specType == "unknown" and 0 or specType == "healer" and ElitistGroup.ROLE_HEALER or ( specType == "feral-tank" or specType == "tank" ) and ElitistGroup.ROLE_TANK or ElitistGroup.ROLE_DAMAGE
		end
	end

	-- Show the comment... text if we have nothing useful in it
	frame.manageNote.comment:GetScript("OnEditFocusLost")(frame.manageNote.comment)
	
	local role = note and note.role or defaultRole
	SetDesaturation(frame.manageNote.roleTank:GetNormalTexture(), bit.band(role, ElitistGroup.ROLE_TANK) == 0)
	SetDesaturation(frame.manageNote.roleHealer:GetNormalTexture(), bit.band(role, ElitistGroup.ROLE_HEALER) == 0)
	SetDesaturation(frame.manageNote.roleDamage:GetNormalTexture(), bit.band(role, ElitistGroup.ROLE_DAMAGE) == 0)
end

--[[
local function showElitistArmoryURL(self)
	local url = ElitistGroup:GetArmoryURL(userData.server, userData.name)
	if( not url ) then
		ElitistGroup:Print(L["Cannot find URL for this player, don't seem to have name, server or region data."])
		return
	end
	
	ElitistGroup:ShowURLPopup(url)
end
]]

-- Really need to restructure all of this soon
function Users:CreateUI()
	if( Users.frame ) then
		Users.frame:Show()
		return
	end
	
	-- Initial database has to be built still
	self.rebuildDatabase = true
	
	local function OnAchievementEnter(self)
		if( self.tooltip ) then
			GameTooltip:SetOwner(self.toggle:IsVisible() and self.toggle or self, "ANCHOR_LEFT")
			GameTooltip:SetText(self.tooltip, nil, nil, nil, nil, true)
			GameTooltip:AddLine(self.expandedInfo)
			GameTooltip:Show()
		end
	end
	
	local suitTooltip
	OnEnter = function(self)
		if( self.tooltip ) then
			GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
			GameTooltip:SetText(self.tooltip, nil, nil, nil, nil, not self.disableWrap)
			GameTooltip:Show()

			if( self.situationalTooltip ) then
				suitTooltip = suitTooltip or CreateFrame("GameTooltip", "ElitistGroupsituationalTooltip", UIParent, "GameTooltipTemplate")
				suitTooltip:SetOwner(GameTooltip, "ANCHOR_NONE")
				suitTooltip:SetText(self.situationalTooltip, nil, nil, nil, nil, true)
				suitTooltip:SetPoint("TOPLEFT", GameTooltip, "TOPRIGHT", 0, 10)
			end

		elseif( self.equippedItem ) then
			GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
			
			if( self.itemTalentType ) then
				GameTooltip:SetText(string.format(L["|cfffed000Item Type:|r %s%s"], self.isBadType, self.itemTalentType), 1, 1, 1)
			end
			if( self.enchantTooltip ) then
				GameTooltip:AddLine(self.enchantTooltip)
			end
			if( self.gemTooltip ) then
				GameTooltip:AddLine(self.gemTooltip)
			end
			
			GameTooltip:Show()
			
			if( self.situationalTooltip ) then
				suitTooltip = suitTooltip or CreateFrame("GameTooltip", "ElitistGroupsituationalTooltip", UIParent, "GameTooltipTemplate")
				suitTooltip:SetOwner(GameTooltip, "ANCHOR_NONE")
				suitTooltip:SetText(self.situationalTooltip, nil, nil, nil, nil, true)
				suitTooltip:SetPoint("TOPLEFT", GameTooltip, "BOTTOMLEFT", 0, -10)
			end
			
			-- Because of how large equipment tooltips are, and the positioning of them now
			-- it's better to smart anchor tooltips based off of where the most room is
			local left, right = GameTooltip:GetLeft(), GameTooltip:GetRight()
			local totalRight = UIParent:GetRight()
			right = totalRight - right
			
			local point, relative, pos = "TOPRIGHT", "TOPLEFT", -10
			if( right > left ) then
				point, relative, pos = "TOPLEFT", "TOPRIGHT", 10
			end
				
			-- Show the item as a second though
			ElitistGroup.tooltip:SetOwner(GameTooltip, "ANCHOR_NONE")
			ElitistGroup.tooltip:SetPoint(point, GameTooltip, relative, pos, 0)
			ElitistGroup.tooltip:SetHyperlink(self.equippedItem)
			ElitistGroup.tooltip:Show()
		end
	end
	
	OnLeave = function(self)
		GameTooltip:Hide()
		ElitistGroup.tooltip:Hide()
	end
		
	-- Main container
	local frame = CreateFrame("Frame", "ElitistGroupUserInfo", UIParent)
	self.frame = frame
	frame:SetClampedToScreen(true)
	frame:SetWidth(468)
	frame:SetHeight(400)
	frame:RegisterForDrag("LeftButton", "RightButton")
	frame:EnableMouse(true)
	frame:SetToplevel(true)
	frame:SetMovable(true)
	frame:SetFrameLevel(5)
	frame:SetScript("OnDragStart", function(self, mouseButton)
		if( mouseButton == "RightButton" ) then
			frame:ClearAllPoints()
			frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
			ElitistGroup.db.profile.positions.user = nil
			return
		end
		
		self:StartMoving()
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		
		local scale = self:GetEffectiveScale()
		ElitistGroup.db.profile.positions.user = {x = self:GetLeft() * scale, y = self:GetTop() * scale}
	end)
	frame:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		edgeSize = 26,
		insets = {left = 9, right = 9, top = 9, bottom = 9},
	})
	frame:SetBackdropColor(0, 0, 0, 0.90)
	
	table.insert(UISpecialFrames, "ElitistGroupUserInfo")
	
	if( ElitistGroup.db.profile.positions.user ) then
		local scale = frame:GetEffectiveScale()
		frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", ElitistGroup.db.profile.positions.user.x / scale, ElitistGroup.db.profile.positions.user.y / scale)
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
	button:SetPoint("TOPRIGHT", -2, -2)
	button:SetHeight(28)
	button:SetWidth(28)
	button:SetScript("OnClick", function() frame:Hide() end)
	
	-- Database frame
	local databaseFrame = CreateFrame("Frame", nil, frame)   
	databaseFrame:SetHeight(frame:GetHeight() - 6)
	databaseFrame:SetWidth(230)
	databaseFrame:SetFrameLevel(2)
	databaseFrame:SetBackdrop({
		  bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		  edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		  edgeSize = 20,
		  insets = {left = 6, right = 6, top = 6, bottom = 6},
	})
	databaseFrame:SetBackdropColor(0, 0, 0, 0.9)
	databaseFrame.fadeFrame = CreateFrame("Frame", nil, databaseFrame)
	databaseFrame.fadeFrame:SetAllPoints(databaseFrame)
	databaseFrame.fadeFrame:SetFrameLevel(3)
	self.databaseFrame = databaseFrame
	
	if( ElitistGroup.db.profile.general.databaseExpanded ) then
		databaseFrame:SetPoint("TOPLEFT", frame, "TOPRIGHT", -10, -3)
	else
		databaseFrame:SetPoint("TOPLEFT", frame, "TOPRIGHT", -230, -3)
		databaseFrame.fadeFrame:SetAlpha(0)
	end

	local TIME_TO_MOVE = 0.50
	local TIME_TO_FADE = 0.25
	
	databaseFrame.timeElapsed = 0
	local function frameAnimator(self, elapsed)
		self.timeElapsed = self.timeElapsed + elapsed
		self:SetPoint("TOPLEFT", frame, "TOPRIGHT", self.startOffset + (self.endOffset * math.min((self.timeElapsed / TIME_TO_MOVE), 1)), -3)
		
		if( self.timeElapsed >= TIME_TO_MOVE ) then
			self.timeElapsed = 0
			self:SetScript("OnUpdate", nil)
		end
	end

	databaseFrame.scroll = CreateFrame("ScrollFrame", "ElitistGroupUserFrameDatabase", databaseFrame.fadeFrame, "FauxScrollFrameTemplate")
	databaseFrame.scroll.bar = ElitistGroupUserFrameDatabase
	databaseFrame.scroll:SetPoint("TOPLEFT", databaseFrame, "TOPLEFT", 0, -7)
	databaseFrame.scroll:SetPoint("BOTTOMRIGHT", databaseFrame, "BOTTOMRIGHT", -28, 6)
	databaseFrame.scroll:SetScript("OnVerticalScroll", function(self, value) Users.scrollUpdate = true; FauxScrollFrame_OnVerticalScroll(self, value, 14, Users.BuildDatabasePage); Users.scrollUpdate = nil end)

	databaseFrame.toggle = CreateFrame("Button", nil, databaseFrame)
	databaseFrame.toggle:SetPoint("LEFT", databaseFrame, "RIGHT", -3, 0)
	databaseFrame.toggle:SetFrameLevel(frame:GetFrameLevel() + 2)
	databaseFrame.toggle:SetHeight(128)
	databaseFrame.toggle:SetWidth(8)
	databaseFrame.toggle:SetNormalTexture("Interface\\AddOns\\ElitistGroup\\media\\tabhandle")
	databaseFrame.toggle:SetScript("OnEnter", function(self)
		SetCursor("INTERACT_CURSOR")
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
		GameTooltip:SetText(L["Click to open and close the database viewer."])
		GameTooltip:Show()
	end)
	databaseFrame.toggle:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
		SetCursor(nil)
	end)
	databaseFrame.toggle:SetScript("OnClick", function(self)
		if( ElitistGroup.db.profile.general.databaseExpanded ) then
			databaseFrame.startOffset = -10
			databaseFrame.endOffset = -220

			UIFrameFadeIn(databaseFrame.fadeFrame, 0.25, 1, 0)
		else
			databaseFrame.startOffset = -220
			databaseFrame.endOffset = 210
			
			UIFrameFadeIn(databaseFrame.fadeFrame, 0.50, 0, 1)
		end
		
		ElitistGroup.db.profile.general.databaseExpanded = not ElitistGroup.db.profile.general.databaseExpanded
		Users:BuildDatabasePage()
		databaseFrame:SetScript("OnUpdate", frameAnimator)
	end)

	databaseFrame.search = CreateFrame("EditBox", "ElitistGroupDatabaseSearch", databaseFrame.fadeFrame, "InputBoxTemplate")
	databaseFrame.search:SetHeight(18)
	databaseFrame.search:SetWidth(195)
	databaseFrame.search:SetAutoFocus(false)
	databaseFrame.search:ClearAllPoints()
	databaseFrame.search:SetPoint("TOPLEFT", databaseFrame, "TOPLEFT", 12, -7)
	databaseFrame.search:SetFrameLevel(3)

	databaseFrame.search.searchText = true
	databaseFrame.search:SetText(L["Search..."])
	databaseFrame.search:SetTextColor(0.90, 0.90, 0.90, 0.80)
	databaseFrame.search:SetScript("OnTextChanged", function(self) Users:BuildDatabasePage() end)
	databaseFrame.search:SetScript("OnEditFocusGained", function(self)
		if( self.searchText ) then
			self.searchText = nil
			self:SetText("")
			self:SetTextColor(1, 1, 1, 1)
		end
	end)
	databaseFrame.search:SetScript("OnEditFocusLost", function(self)
		if( not self.searchText and string.trim(self:GetText()) == "" ) then
			self.searchText = true
			self:SetText(L["Search..."])
			self:SetTextColor(0.90, 0.90, 0.90, 0.80)
		end
	end)

	local function viewUserData(self)
		Users:Show(ElitistGroup.userData[self.userID])
	end

	databaseFrame.rows = {}
	for i=1, MAX_DATABASE_ROWS do
		local button = CreateFrame("Button", nil, databaseFrame.fadeFrame)
		button:SetScript("OnClick", viewUserData)
		button:SetScript("OnEnter", OnEnter)
		button:SetScript("OnLeave", OnLeave)
		button:SetHeight(14)
		button:SetNormalFontObject(GameFontNormal)
		--button:SetHighlightFontObject(GameFontHighlight)
		button:SetText("*")
		button:GetFontString():SetPoint("TOPLEFT", button, "TOPLEFT")
		button:GetFontString():SetPoint("TOPRIGHT", button, "TOPRIGHT")
		button:GetFontString():SetJustifyH("LEFT")
		button:GetFontString():SetJustifyV("CENTER")
		
		if( i > 1 ) then
			button:SetPoint("TOPLEFT", databaseFrame.rows[i - 1], "BOTTOMLEFT", 0, -6)
		else
			button:SetPoint("TOPLEFT", databaseFrame, "TOPLEFT", 12, -30)
		end

		databaseFrame.rows[i] = button
	end

	-- User data container
	local infoFrame = CreateFrame("Frame", nil, frame)   
	infoFrame:SetBackdrop(backdrop)
	infoFrame:SetBackdropBorderColor(0.60, 0.60, 0.60, 1)
	infoFrame:SetBackdropColor(0, 0, 0, 0)
	infoFrame:SetWidth(185)
	infoFrame:SetHeight(176)
	infoFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -42)
	self.infoFrame = infoFrame
	
	infoFrame.headerText = infoFrame:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
	infoFrame.headerText:SetPoint("BOTTOMLEFT", infoFrame, "TOPLEFT", 0, 5)
	infoFrame.headerText:SetText(L["Player info"])

	local buttonList = {"playerInfo", "trustedInfo", "scannedInfo", "averageInfo", "talentInfo", "secondTalentInfo", "equipmentInfo", "enchantInfo", "gemInfo"}
	for i, key in pairs(buttonList) do
		local button = CreateFrame("Button", nil, infoFrame)
		button:SetNormalFontObject(GameFontHighlight)
		button:SetText("*")
		button:SetHeight(15)
		button:SetScript("OnEnter", OnEnter)
		button:SetScript("OnLeave", OnLeave)
		button:SetPushedTextOffset(0, 0)
		button:GetFontString():SetJustifyH("LEFT")
		button:GetFontString():SetJustifyV("CENTER")
		button:GetFontString():SetWidth(infoFrame:GetWidth() - 23)
		button:GetFontString():SetHeight(15)
		
		if( i > 6 ) then
			button:GetFontString():SetPoint("LEFT", button, "LEFT", 2, 0)
		else
			button.icon = button:CreateTexture(nil, "ARTWORK")
			button.icon:SetPoint("LEFT", button, "LEFT", 0, 0)
			button.icon:SetSize(16, 16)
			button:GetFontString():SetPoint("LEFT", button.icon, "RIGHT", 2, 0)
		end
		
		local offset = (key == "averageInfo" or key == "playerInfo") and -50 or 0
		if( i > 1 ) then
			button:SetPoint("TOPLEFT", infoFrame[buttonList[i - 1]], "BOTTOMLEFT", 0, -4)
			button:SetPoint("TOPRIGHT", infoFrame[buttonList[i - 1]], "BOTTOMRIGHT", offset, -4)
		else
			button:SetPoint("TOPLEFT", infoFrame, "TOPLEFT", 3, -4)
			button:SetPoint("TOPRIGHT", infoFrame, "TOPRIGHT", offset, 0)
		end
		
		infoFrame[key] = button
	end
	
	-- Add a highlight indicating it's the primary
	--[[
	local talentInfo = infoFrame.talentInfo
	talentInfo.highlight = talentInfo:CreateTexture(nil, "OVERLAY")
	talentInfo.highlight:SetSize(31, 31)
	talentInfo.highlight:ClearAllPoints()
	talentInfo.highlight:SetPoint("CENTER", talentInfo.icon, "CENTER", 0, 0)
	talentInfo.highlight:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
	talentInfo.highlight:SetVertexColor(1, 1, 1)
	talentInfo.highlight:SetBlendMode("ADD")
	]]

--[[
	-- Elitist Armory hookin
	local button = CreateFrame("Button", nil, infoFrame, "GameMenuButtonTemplate")
	button:SetWidth(40)
	button:SetHeight(15)
	button:SetPoint("LEFT", infoFrame.playerInfo, "RIGHT", 6, 0)
	button:SetText(L["URL"])
	button:SetScript("OnClick", showElitistArmoryURL)
	button:SetScript("OnEnter", OnEnter)
	button:SetScript("OnLeave", OnLeave)
	button.tooltip = L["View the player on ElitistArmory.com"]
]]

	-- Editing notes
	local button = CreateFrame("Button", nil, infoFrame, "UIPanelButtonGrayTemplate")
	button:SetWidth(45)
	button:SetHeight(18)
	button:SetPoint("LEFT", infoFrame.averageInfo, "RIGHT", 2, 0)
	button:SetText(L["Edit"])
	button:SetScript("OnClick", function(self)
		managePlayerNote()
		
		if( frame.manageNote:IsVisible() ) then
			frame.manageNote:Hide()
			infoFrame.manageNote:UnlockHighlight()
		else
			frame.manageNote:Show()
			infoFrame.manageNote:LockHighlight()
		end
	end)
	button:SetScript("OnEnter", OnEnter)
	button:SetScript("OnLeave", OnLeave)
	infoFrame.manageNote = button
	
	-- Dungeon suggested container
	local dungeonFrame = CreateFrame("Frame", nil, frame)   
	dungeonFrame:SetBackdrop(backdrop)
	dungeonFrame:SetBackdropBorderColor(0.60, 0.60, 0.60, 1)
	dungeonFrame:SetBackdropColor(0, 0, 0, 0)
	dungeonFrame:SetWidth(185)
	dungeonFrame:SetHeight(147)
	dungeonFrame:SetPoint("TOPLEFT", infoFrame, "BOTTOMLEFT", 0, -24)
	dungeonFrame:SetScript("OnShow", function(self)
		local parent = self:GetParent()
		if( parent.manageNote ) then
			parent.manageNote:SetFrameLevel(self:GetFrameLevel() + 10)
		end
	end)
	self.dungeonFrame = dungeonFrame

	dungeonFrame.headerText = dungeonFrame:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
	dungeonFrame.headerText:SetPoint("BOTTOMLEFT", dungeonFrame, "TOPLEFT", 0, 5)
	dungeonFrame.headerText:SetText(L["Suggested dungeons"])

	dungeonFrame.scroll = CreateFrame("ScrollFrame", "ElitistGroupUserFrameDungeon", dungeonFrame, "FauxScrollFrameTemplate")
	dungeonFrame.scroll.bar = ElitistGroupUserFrameDungeonScrollBar
	dungeonFrame.scroll:SetPoint("TOPLEFT", dungeonFrame, "TOPLEFT", 0, -2)
	dungeonFrame.scroll:SetPoint("BOTTOMRIGHT", dungeonFrame, "BOTTOMRIGHT", -24, 1)
	dungeonFrame.scroll:SetScript("OnVerticalScroll", function(self, value) FauxScrollFrame_OnVerticalScroll(self, value, 28, Users.BuildDungeonSuggestPage) end)

	dungeonFrame.rows = {}
	for i=1, MAX_DUNGEON_ROWS do
		local button = CreateFrame("Frame", nil, dungeonFrame)
		button:SetHeight(28)
		button:SetWidth(dungeonFrame:GetWidth() - 25)
		button.dungeonName = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		button.dungeonName:SetHeight(14)
		button.dungeonName:SetJustifyH("LEFT")
		button.dungeonName:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
		button.dungeonName:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)

		button.dungeonInfo = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		button.dungeonInfo:SetHeight(14)
		button.dungeonInfo:SetJustifyH("LEFT")
		button.dungeonInfo:SetPoint("TOPLEFT", button.dungeonName, "BOTTOMLEFT", 0, 2)
		button.dungeonInfo:SetPoint("TOPRIGHT", button.dungeonName, "BOTTOMRIGHT", 0, 2)

		if( i > 1 ) then
			button:SetPoint("TOPLEFT", dungeonFrame.rows[i - 1], "BOTTOMLEFT", 0, -2)
		else
			button:SetPoint("TOPLEFT", dungeonFrame, "TOPLEFT", 3, -1)
		end

		dungeonFrame.rows[i] = button
	end
	
	-- Parent container
	local tabContainer = CreateFrame("Frame", nil, frame)   
	tabContainer:SetBackdrop(backdrop)
	tabContainer:SetBackdropBorderColor(0.60, 0.60, 0.60, 1)
	tabContainer:SetBackdropColor(0, 0, 0, 0)
	tabContainer:SetWidth(250)
	tabContainer:SetHeight(347)
	tabContainer:SetPoint("TOPLEFT", infoFrame, "TOPRIGHT", 10, 0)
	tabContainer.selectedTab = ElitistGroup.db.profile.general.selectedTab
	self.tabContainer = tabContainer
	
	local function tabClicked(self)
		tabContainer.selectedTab = self.tabID
		ElitistGroup.db.profile.general.selectedTab = self.tabID
		
		Users:UpdateTabs()
	end

	tabContainer.equipment = CreateFrame("Button", nil, tabContainer)
	tabContainer.equipment:SetNormalFontObject(GameFontNormal)
	tabContainer.equipment:SetHighlightFontObject(GameFontHighlight)
	tabContainer.equipment:SetDisabledFontObject(GameFontDisable)
	tabContainer.equipment:SetPoint("BOTTOMLEFT", tabContainer, "TOPLEFT", 0, -1)
	tabContainer.equipment:SetScript("OnClick", tabClicked)
	tabContainer.equipment:SetText(L["Gear"])
	tabContainer.equipment:GetFontString():SetPoint("LEFT", 3, 0)
	tabContainer.equipment:SetHeight(18)
	tabContainer.equipment:SetWidth(62)
	tabContainer.equipment:SetBackdrop(backdrop)
	tabContainer.equipment:SetBackdropColor(0, 0, 0, 0)
	tabContainer.equipment:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
	tabContainer.equipment.tabID = "equipment"

	tabContainer.achievements = CreateFrame("Button", nil, tabContainer)
	tabContainer.achievements:SetNormalFontObject(GameFontNormal)
	tabContainer.achievements:SetHighlightFontObject(GameFontHighlight)
	tabContainer.achievements:SetDisabledFontObject(GameFontDisable)
	tabContainer.achievements:SetPoint("TOPLEFT", tabContainer.equipment, "TOPRIGHT", 4, 0)
	tabContainer.achievements:SetScript("OnClick", tabClicked)
	tabContainer.achievements:SetText(L["Experience"])
	tabContainer.achievements:GetFontString():SetPoint("LEFT", 3, 0)
	tabContainer.achievements:SetHeight(18)
	tabContainer.achievements:SetWidth(90)
	tabContainer.achievements:SetBackdrop(backdrop)
	tabContainer.achievements:SetBackdropColor(0, 0, 0, 0)
	tabContainer.achievements:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
	tabContainer.achievements.tabID = "achievements"
	
	tabContainer.notes = CreateFrame("Button", nil, tabContainer)
	tabContainer.notes:SetNormalFontObject(GameFontNormal)
	tabContainer.notes:SetHighlightFontObject(GameFontHighlight)
	tabContainer.notes:SetDisabledFontObject(GameFontDisable)
	tabContainer.notes:SetPoint("TOPLEFT", tabContainer.achievements, "TOPRIGHT", 4, 0)
	tabContainer.notes:SetScript("OnClick", tabClicked)
	tabContainer.notes:SetText("*")
	tabContainer.notes:GetFontString():SetPoint("LEFT", 3, 0)
	tabContainer.notes:SetHeight(18)
	tabContainer.notes:SetWidth(90)
	tabContainer.notes:SetBackdrop(backdrop)
	tabContainer.notes:SetBackdropColor(0, 0, 0, 0)
	tabContainer.notes:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
	tabContainer.notes.tabID = "notes"

	-- Equipment container
	local equipmentFrame = CreateFrame("Frame", nil, tabContainer)
	equipmentFrame:SetAllPoints(tabContainer)
	self.equipmentFrame = equipmentFrame
	
	local function OnItemClick(self)
		if( self.fullItemLink ) then
			HandleModifiedItemClick(self.fullItemLink)
		end
	end
	
	local inventoryMap = {"HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "WristSlot", "HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "Trinket0Slot", "Trinket1Slot", "MainHandSlot", "SecondaryHandSlot", "RangedSlot"}
	equipmentFrame.equipSlots = {}
	for i=1, 17 do
		local slot = CreateFrame("Button", nil, equipmentFrame)
		slot:SetHeight(16)
		slot:SetWidth(tabContainer:GetWidth() - 3)
		slot:SetScript("OnEnter", OnEnter)
		slot:SetScript("OnLeave", OnLeave)
		slot:SetScript("OnClick", OnItemClick)
		slot:SetMotionScriptsWhileDisabled(true)
		slot.icon = slot:CreateTexture(nil, "BACKGROUND")
		slot.icon:SetHeight(16)
		slot.icon:SetWidth(16)
		slot.icon:SetPoint("TOPLEFT", slot)

		slot.levelText = slot:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		slot.levelText:SetPoint("LEFT", slot.icon, "RIGHT", 2, 0)
		slot.levelText:SetJustifyV("CENTER")
		slot.levelText:SetJustifyH("LEFT")
		slot.levelText:SetWidth(30)
		slot.levelText:SetHeight(11)

		slot.typeText = slot:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		slot.typeText:SetPoint("LEFT", slot.levelText, "RIGHT", 6, 0)
		slot.typeText:SetJustifyV("CENTER")
		slot.typeText:SetJustifyH("LEFT")
		slot.typeText:SetWidth(100)
		slot.typeText:SetHeight(11)

		slot.enhanceText = slot:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		slot.enhanceText:SetPoint("RIGHT", slot, "RIGHT", -4, 0)
		slot.enhanceText:SetJustifyV("CENTER")
		slot.enhanceText:SetJustifyH("RIGHT")
		slot.enhanceText:SetWidth(90)
		slot.enhanceText:SetHeight(11)
		slot.enhanceText:SetTextColor(1, 0.15, 0.15)

		if( i > 1 ) then
			slot:SetPoint("TOPLEFT", equipmentFrame.equipSlots[i - 1], "BOTTOMLEFT", 0, -4)
		else
			slot:SetPoint("TOPLEFT", equipmentFrame, "TOPLEFT", 3, -6)
		end

		slot.inventorySlot = inventoryMap[i]
		slot.inventoryType = ElitistGroup.Items.inventoryToID[inventoryMap[i]]
		slot.inventoryID, slot.emptyTexture, slot.checkRelic = GetInventorySlotInfo(inventoryMap[i])
		equipmentFrame.equipSlots[i] = slot
	end

	-- Achievement container
	local achievementsFrame = CreateFrame("Frame", nil, tabContainer)   
	achievementsFrame:SetAllPoints(tabContainer)
	self.achievementsFrame = achievementsFrame
	
	achievementsFrame.scroll = CreateFrame("ScrollFrame", "ElitistGroupUserFrameAchievements", achievementsFrame, "FauxScrollFrameTemplate")
	achievementsFrame.scroll.bar = ElitistGroupUserFrameAchievementsScrollBar
	achievementsFrame.scroll:SetPoint("TOPLEFT", achievementsFrame, "TOPLEFT", 0, -2)
	achievementsFrame.scroll:SetPoint("BOTTOMRIGHT", achievementsFrame, "BOTTOMRIGHT", -24, 1)
	achievementsFrame.scroll:SetScript("OnVerticalScroll", function(self, value) FauxScrollFrame_OnVerticalScroll(self, value, 14, Users.BuildAchievementPage) end)
	
	local function toggleCategory(self)
		local id = self.toggle and self.toggle.id or self.id
		if( not id ) then return end
		
		ElitistGroup.db.profile.expExpanded[id] = not ElitistGroup.db.profile.expExpanded[id]
		Users:BuildAchievementPage()
	end
	
	achievementsFrame.rows = {}
	for i=1, MAX_ACHIEVEMENT_ROWS do
		local button = CreateFrame("Button", nil, achievementsFrame)
		button:SetScript("OnEnter", OnAchievementEnter)
		button:SetScript("OnLeave", OnLeave)
		button:SetScript("OnClick", toggleCategory)
		button:SetHeight(14)
		button.nameText = button:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		button.nameText:SetHeight(14)
		button.nameText:SetJustifyH("LEFT")
		button.nameText:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
		button.nameText:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)

		button.toggle = CreateFrame("Button", nil, button)
		button.toggle:SetScript("OnClick", toggleCategory)
		button.toggle:SetPoint("TOPRIGHT", button, "TOPLEFT", -2, 0)
		button.toggle:SetHeight(14)
		button.toggle:SetWidth(14)

		achievementsFrame.rows[i] = button
	end

	-- Notes container
	local notesFrame = CreateFrame("Frame", nil, tabContainer)   
	notesFrame:SetAllPoints(tabContainer)
	self.notesFrame = notesFrame
	
	notesFrame.scroll = CreateFrame("ScrollFrame", "ElitistGroupUserFrameNotes", notesFrame, "FauxScrollFrameTemplate")
	notesFrame.scroll.bar = ElitistGroupUserFrameNotesScrollBar
	notesFrame.scroll:SetPoint("TOPLEFT", notesFrame, "TOPLEFT", 0, -2)
	notesFrame.scroll:SetPoint("BOTTOMRIGHT", notesFrame, "BOTTOMRIGHT", -24, 1)
	notesFrame.scroll:SetScript("OnVerticalScroll", function(self, value) FauxScrollFrame_OnVerticalScroll(self, value, 46, Users.BuildNotesPage) end)

	notesFrame.rows = {}
	for i=1, MAX_NOTE_ROWS do
		local button = CreateFrame("Frame", nil, notesFrame)
		button:SetScript("OnEnter", OnEnter)
		button:SetScript("OnLeave", OnLeave)
		button:EnableMouse(true)
		button:SetHeight(46)
		button:SetWidth(notesFrame:GetWidth() - 24)
		button.infoText = button:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		button.infoText:SetHeight(16)
		button.infoText:SetJustifyH("LEFT")
		button.infoText:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
		button.infoText:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)

		button.commentText = button:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		button.commentText:SetHeight(32)
		button.commentText:SetJustifyH("LEFT")
		button.commentText:SetJustifyV("TOP")
		button.commentText:SetPoint("TOPLEFT", button.infoText, "BOTTOMLEFT", 0, 0)
		button.commentText:SetPoint("TOPRIGHT", button.infoText, "BOTTOMRIGHT", 0, 0)

		if( i > 1 ) then
			button:SetPoint("TOPLEFT", notesFrame.rows[i - 1], "BOTTOMLEFT", 0, -4)
		else
			button:SetPoint("TOPLEFT", notesFrame, "TOPLEFT", 4, -2)
		end
		notesFrame.rows[i] = button
	end
end

