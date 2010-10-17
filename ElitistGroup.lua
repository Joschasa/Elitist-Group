ElitistGroup = select(2, ...)
ElitistGroup = LibStub("AceAddon-3.0"):NewAddon(ElitistGroup, "ElitistGroup", "AceEvent-3.0")
local L = ElitistGroup.L

ElitistGroup.raidUnits, ElitistGroup.partyUnits = {}, {}
for i=1, MAX_RAID_MEMBERS do ElitistGroup.raidUnits[i] = "raid" .. i end
for i=1, MAX_PARTY_MEMBERS do ElitistGroup.partyUnits[i] = "party" .. i end

function ElitistGroup:OnInitialize()
	self.defaults = {
		profile = {
			expExpanded = {},
			positions = {},
			general = {
				announceData = false,
				databaseExpanded = true,
				selectedTab = "achievements",
				showSlotName = false,
				summaryQueue = true,
			},
			auto = {
				autoPopup = false,
				autoSummary = false,
				alertRating = true,
				keepInspects = 1,
			},
			inspect = {
				window = false,
				tooltips = true,
			},
			database = {
				saveForeign = true,
				pruneBasic = 30,
				pruneFull = 120,
				ignoreBelow = 80,
			},
			report = {
				
			},
			comm = {
				enabled = true,
				gearRequests = true,
				databaseSync = false,
				databaseThreshold = 4,
				autoNotes = true,
				autoMain = true,
				trustGuild = true,
				trustFriends = true,
				areas = {GUILD = true, WHISPER = true, RAID = true, PARTY = true, BATTLEGROUND = false},
			},
		},
		global = {
			main = {},
		},
		factionrealm = {
			trusted = {},
		},
		faction = {
			lastModified = {},
			users = {},
		},
	}
	
	self.db = LibStub("AceDB-3.0"):New("ElitistGroupDB", self.defaults, true)
	self.db.RegisterCallback(self, "OnDatabaseShutdown", "OnDatabaseShutdown")
	self.db.RegisterCallback(self, "OnDatabaseReset", "OnProfileReset")
	self.db.RegisterCallback(self, "OnProfileShutdown", "OnProfileShutdown")
	self.db.RegisterCallback(self, "OnProfileReset", "OnProfileReset")
	
	self.version = "v1.7.7-1-ge9aa6fe"
	self.version = string.match(self.version, "project%-version") and "repo" or string.gsub(self.version, "v", "")
	self.version = string.split("-", self.version, 2)

	self.playerID = string.format("%s-%s", UnitName("player"), GetRealmName())
	self.tooltip = CreateFrame("GameTooltip", "ElitistGroupTooltip", UIParent, "GameTooltipTemplate")
	self.tooltip:Hide()
	
	local emptyEnv = {}
	self.writeQueue = {}
	self.userData = setmetatable({}, {
		__index = function(tbl, name)
			if( not ElitistGroup.db.faction.users[name] ) then
				tbl[name] = false
				return false
			end
			
			local func, msg = loadstring("return " .. ElitistGroup.db.faction.users[name])
			if( func ) then
				func = setfenv(func, emptyEnv)() or false
			elseif( msg ) then
				error(msg, 3)
				rawset(tbl, name, false)
				return false
			end
			
			rawset(tbl, name, func)
			return tbl[name]
		end
	})

	self.ROLE_TANK = 0x04
	self.ROLE_HEALER = 0x02
	self.ROLE_DAMAGE = 0x01
	self.MAX_RATING = 5
	
	-- Data is old enough that we want to remove extra data to save space
	if( self.db.profile.database.pruneBasic > 0 or self.db.database.pruneFull > 0 ) then
		local pruneBasic = time() - (self.db.profile.database.pruneBasic * 86400)
		local pruneFull = time() - (self.db.profile.database.pruneFull * 86400)
		
		for name, modified in pairs(self.db.faction.lastModified) do
			-- Shouldn't happen, but just in case their is a modified field set but not an actual data entry
			if( not self.db.faction.users[name] ) then
				self.db.faction.lastModified[name] = nil
				
			-- Basic pruning, we wipe out any volatile data
			elseif( self.db.profile.database.pruneBasic > 0 and modified <= pruneBasic ) then
				-- If a player has note data on them, then will preserve their entire record, if they don't will just wipe everything out
				local hasNotes
				for note in pairs(self.userData[name].notes) do hasNotes = true break end
				
				if( hasNotes ) then
					local userData = self.userData[name]
					userData.talentTree1 = nil
					userData.talentTree2 = nil
					userData.talentTree3 = nil
					userData.unspentPoints = nil
					userData.specRole = nil
					
					table.wipe(userData.equipment)
					table.wipe(userData.achievements)
					userData.secondarySpec = nil
					userData.mainAchievements = nil
					
					userData.pruned = true

					self.db.faction.lastModified[name] = time()
					self.writeQueue[name] = true
				else
					self.db.faction.lastModified[name] = nil
					self.db.faction.users[name] = nil
					self.writeQueue[name] = nil
					self.userData[name] = nil
				end

			-- Full pruning, all data gets removed
			elseif( self.db.profile.database.pruneFull > 0 and modified <= pruneFull ) then
				self.db.faction.lastModified[name] = nil
				self.db.faction.users[name] = nil
				self.writeQueue[name] = nil
				self.userData[name] = nil
			end
		end
	end
		
	if( not ElitistGroup.db.profile.helped ) then
		self:RegisterEvent("PLAYER_ENTERING_WORLD", function()
			ElitistGroup.db.profile.helped = true
			ElitistGroup:Print(L["Welcome! Type /elitistgroup help (or /eg help) to see a list of available slash commands."])
			DEFAULT_CHAT_FRAME:AddMessage(L["Play on alts all the time? Check out /eg config -> Main/alt experience to have your mains achievements carry over."])
			ElitistGroup:UnregisterEvent("PLAYER_ENTERING_WORLD")
		end)
	end

	self.modules.Sync:Setup()
	self:ShowInfoPanel()
end

function ElitistGroup:ShowInfoPanel()
	-- We don't need to show this after the next TOC update, it should be known by then
	if( ElitistGroupDB.throttleAnnounced or select(4, GetBuildInfo()) > 30300 ) then return end
	ElitistGroupDB.throttleAnnounced = true
	
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:SetClampedToScreen(true)
	frame:SetFrameStrata("HIGH")
	frame:SetToplevel(true)
	frame:SetWidth(400)
	frame:SetHeight(285)
	frame:SetBackdrop({
		  bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		  edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		  edgeSize = 26,
		  insets = {left = 9, right = 9, top = 9, bottom = 9},
	})
	frame:SetBackdropColor(0, 0, 0, 0.85)
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)

	frame.titleBar = frame:CreateTexture(nil, "ARTWORK")
	frame.titleBar:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
	frame.titleBar:SetPoint("TOP", 0, 8)
	frame.titleBar:SetWidth(225)
	frame.titleBar:SetHeight(45)

	frame.title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	frame.title:SetPoint("TOP", 0, 0)
	frame.title:SetText("Elitist Group")

	frame.text = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	frame.text:SetText(L["As of 3.3.5, Blizzard has started to throttle inspections to 6 inspections every ~10 seconds.|n|nElitist Group has been updated to account for this, but you may see throttle messages when using /eg, group scans will also be slower. A new option has been added in /eg config to save X amount of inspections when scanning.|n|nYou can still use Elitist Armory to check groups without the throttle limit.|n|n|cffff2020Warning!|r|nGearscore has a habit of sending a higher than normal amount of inspect requests, disabling it is recommended.|nTipTop and other tooltip addons that show talents will also contribute to the limit.|n|nYou will only see this message once."])
	frame.text:SetPoint("TOPLEFT", 12, -22)
	frame.text:SetWidth(frame:GetWidth() - 20)
	frame.text:SetJustifyH("LEFT")
	frame:SetHeight(frame.text:GetHeight() + 70)

	frame.hide = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.hide:SetText(L["Ok"])
	frame.hide:SetHeight(20)
	frame.hide:SetWidth(100)
	frame.hide:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 6, 8)
	frame.hide:SetScript("OnClick", function(self)
		self:GetParent():Hide()
	end)
end


function ElitistGroup:ShowURLPopup(url, long)
	StaticPopupDialogs["ELITISTGROUP_URL"] = StaticPopupDialogs["ELITISTGROUP_URL"] or {
		text = not long and "Elitist Armory URL" or "Elitist Armory URL. You will be given a shorter URL once you go to the site.",
		button2 = CLOSE,
		hasEditBox = 1,
		hasWideEditBox = 1,
		OnShow = function(self, url)
			local editBox = _G[this:GetName() .. "WideEditBox"]
			if( editBox ) then
				editBox:SetText(url)
				editBox:SetFocus()
				editBox:HighlightText(0)
			end
			
			local button = _G[this:GetName().."Button2"]
			if( button ) then
				button:ClearAllPoints()
				button:SetWidth(200)
				button:SetPoint("CENTER", editBox, "CENTER", 0, -30)
			end
		end,
		EditBoxOnEscapePressed = function() this:GetParent():Hide() end,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
		maxLetters = 1024,
	}	
	
	StaticPopup_Show("ELITISTGROUP_URL", nil, nil, url)
end

local locale = GetLocale()
function ElitistGroup:GetRegion()
	local region = string.match(GetCVar("realmList"), "^(.-)%.")
	return locale == "koKR" and "kr" or locale == "zhCN" and "cn" or locale == "zhTW" and "tw" or region
end

function ElitistGroup:GetArmoryURL(realm, name)
	local region = self:GetRegion()
	realm = string.gsub(realm, " ", "%%20")
	name = string.gsub(name, " ", "%%20")
	
	return region and realm and name and string.format("http://elitistarmory.com/%s/%s/%s", region, realm, name)
end

-- Permissions, do we trust the person?
local playerName = UnitName("player")
function ElitistGroup:IsTrusted(name)
	if( not name ) then return nil end
	if( name == playerName or name == self.playerID ) then return true end

	local playerName, playerServer = string.split("-", name, 2)
	if( playerServer and playerServer ~= GetRealmName() ) then return false end
	
	name = string.lower(playerName or name)
	if( self.db.factionrealm.trusted[name] ) then return true end
	
	-- Check guild if we're trusting them
	if( self.db.profile.comm.trustGuild ) then
		for i=1, GetNumGuildMembers() do
			if( string.lower(GetGuildRosterInfo(i)) == name ) then
				return true
			end
		end
	end

	-- Finally, check friends
	if( self.db.profile.comm.trustFriends ) then
		for i=1, GetNumFriends() do
			if( string.lower(GetFriendInfo(i)) == name ) then
				return true
			end
		end
	end
	
	return false
end

function ElitistGroup:GetItemColor(itemLevel)
	local quality = itemLevel >= 210 and ITEM_QUALITY_EPIC or itemLevel >= 195 and ITEM_QUALITY_RARE or itemLevel >= 170 and ITEM_QUALITY_UNCOMMON or ITEM_QUALITY_COMMON
	return ITEM_QUALITY_COLORS[quality].hex
end

function ElitistGroup:GetItemLink(link)
	return link and string.match(link, "|H(.-)|h")
end

function ElitistGroup:GetItemWithEnchant(link)
	return link and string.match(link, "item:%d+:%d+")
end

function ElitistGroup:GetBaseItemLink(link)
	return link and string.match(link, "item:%d+")
end

function ElitistGroup:GetPlayerID(unit)
	local name, server = UnitName(unit)
	return name and name ~= UNKNOWN and string.format("%s-%s", name, server and server ~= "" and server or GetRealmName())
end

function ElitistGroup:CalculateScore(itemLink, itemQuality, itemLevel)
	-- Quality 7 is heirloom, apply our modifier based on the item level
	if( itemQuality == 7 ) then
		itemLevel = (tonumber(string.match(itemLink, "(%d+)$")) or 1) * ElitistGroup.Items.heirloomLevel
	end
	
	return itemLevel * (self.Items.qualityModifiers[itemQuality] or 1)
end

function ElitistGroup:GetPlayerSpec(classToken, talentData)
	if( not talentData.talentTree1 or not talentData.talentTree2 or not talentData.talentTree3 ) then
		return "unknown", L["Unknown"], "Interface\\Icons\\INV_Misc_QuestionMark"
	end
	
	local treeOffset
	if( talentData.talentTree1 > talentData.talentTree2 and talentData.talentTree1 > talentData.talentTree3 ) then
		treeOffset = 1
	elseif( talentData.talentTree2 > talentData.talentTree1 and talentData.talentTree2 > talentData.talentTree3 ) then
		treeOffset = 4
	elseif( talentData.talentTree3 > talentData.talentTree1 and talentData.talentTree3 > talentData.talentTree2 ) then
		treeOffset = 7
	else
		return "unknown", L["Unknown"], "Interface\\Icons\\INV_Misc_QuestionMark"
	end
	
	return talentData.specRole or self.Talents.treeData[classToken][treeOffset], self.Talents.treeData[classToken][treeOffset + 1], self.Talents.treeData[classToken][treeOffset + 2] 
end

function ElitistGroup:SetTalentText(fontString, specType, specName, userData, talentType)
	specType = self.Talents.talentText[specType] or specType

	local specData = talentType == "primary" and userData or userData.secondarySpec
	local detailText = talentType == "secondary" and L["Secondary"] or specType
	local talentTypeText = talentType == "primary" and L["Active"] or L["Secondary"]
	
	if( specData.unspentPoints ) then
		if( talentType == "primary" ) then
			fontString:SetFormattedText(L["|cffff2020%d unspent |4point:points;|r"], specData.unspentPoints)
		else
			fontString:SetFormattedText(L["|cffff2020%d unspent|r (Secondary)"], specData.unspentPoints)
		end
		fontString.tooltip = string.format(L["|cffffffff%s|r %s, %s role.\n\nThe player has not spent %d talent points."], talentTypeText, specName or L["Unknown"], specType or L["Unknown"], specData.unspentPoints)
		return
	end
	
	-- No sense in flagging non-max level players, look for people who have no points spent in two trees, means they dumped it all into one
	if( playerLevel == MAX_PLAYER_LEVEL ) then
		local totalEmpty = (specData.talentTree1 == 0 and 1 or 0) + (specData.talentTree3 == 0 and 1 or 0) + (specData.talentTree3 == 0 and 1 or 0)
		if( totalEmpty == 2 ) then
			fontString:SetFormattedText("|cffff2020%d/%d/%d|r (%s)", specData.talentTree1, specData.talentTree2, specData.talentTree3, detailText)
			fontString.tooltip = string.format(L["|cffffffff%s|r %s, %s role.\n\nThe player put all of his talent points into one tree."], talentTypeText, specName, specType)
			return
		end
	end
	
	fontString:SetFormattedText("%d/%d/%d (%s)", specData.talentTree1 or 0, specData.talentTree2 or 0, specData.talentTree3 or 0, detailText)
	fontString.tooltip = string.format(L["|cffffffff%s|r %s, %s role."], talentTypeText, specName, specType)
end
	
local tableCache = setmetatable({}, {__mode = "k"})
function ElitistGroup:GetTable()
	return table.remove(tableCache, 1) or {}
end

function ElitistGroup:ReleaseTables(...)	
	for i=1, select("#", ...) do
		local tbl = select(i, ...)
		if( tbl ) then
			table.wipe(tbl)
			table.insert(tableCache, tbl)
		end
	end
end

function ElitistGroup:GetSituationalTooltip(filterItem, equipmentData, gemData)
	local tempList = self:GetTable()
	
	if( equipmentData ) then
		for i=1, #(equipmentData), 2 do
			local itemLink, message = equipmentData[equipmentData[i]], equipmentData[i + 1]
			if( message and ( not filterItem or filterItem == itemLink ) ) then
				table.insert(tempList, message)
			end
		end
	end
	
	if( gemData ) then
		for i=1, #(gemData), 4 do
			local itemLink, message = gemData[gemData[i]], gemData[i + 3]
			if( message and ( not filterItem or filterItem == itemLink ) ) then
				table.insert(tempList, message)
			end
		end
	end
	
	local tooltip = table.concat(tempList, "\n\n")
	self:ReleaseTables(tempList)
	
	return tooltip
end

function ElitistGroup:GetGearSummaryTooltip(equipment, enchantData, gemData)
	local enchantTooltips, gemTooltips = self:GetTable(), self:GetTable()
	local tempList = self:GetTable()
		
	-- Compile all the gems into tooltips per item
	local unusedTooltip = ""
	local lastItemLink
	local totalBad = 0
	for i=1, #(gemData), 4 do
		local itemLink, gemLink, arg = gemData[gemData[i]], gemData[i + 1], gemData[i + 2]		
		if( lastItemLink ~= itemLink ) then
			if( lastItemLink ) then
				table.insert(tempList, 1, string.format(L["Gems: |cffff2020[!]|r |cffffffff%d bad|r%s"], totalBad, unusedTooltip))
				gemTooltips[lastItemLink] = table.concat(tempList, "\n")
				table.wipe(tempList)
			end
			
			unusedTooltip = ""
			lastItemLink = itemLink
			totalBad = 0
		end
		totalBad = totalBad + 1
				
		if( arg == "missing" ) then
			unusedTooltip = string.format(L[" (%d unused |4socket:sockets;)"], gemLink)
		elseif( arg == "buckle" ) then
			unusedTooltip = L[" (no belt buckle)"]
		elseif( type(arg) == "string" ) then
			table.insert(tempList, string.format(L["%s - |cffffffff%s|r gem"], select(2, GetItemInfo(gemLink)) or gemLink, self.Items.itemRoleText[arg] or arg))
		else
			table.insert(tempList, string.format(L["%s - |cffffffff%s|r quality gem"], select(2, GetItemInfo(gemLink)) or gemLink, _G["ITEM_QUALITY" .. arg .. "_DESC"]))
		end
	end
	
	-- And grab the last one
	if( lastItemLink ) then
		table.insert(tempList, 1, string.format(L["Gems: |cffff2020[!]|r |cffffffff%d bad|r%s"], totalBad, unusedTooltip))
		gemTooltips[lastItemLink] = table.concat(tempList, "\n")
	end
	
	-- Now compile all the enchants
	for i=1, #(enchantData), 2 do
		local itemLink, enchantTalent = enchantData[enchantData[i]], enchantData[i + 1]
		if( enchantTalent == "missing" ) then
			enchantTooltips[itemLink] = L["Enchant: |cffff2020[!]|r |cffffffffNone found|r"]
		else
			enchantTooltips[itemLink] = string.format(L["Enchant: |cffff2020[!]|r |cffffffff%s|r enchant"], self.Items.itemRoleText[enchantTalent] or enchantTalent)
		end
	end
		
	-- Add the pass/no socket stuff
	for _, link in pairs(equipment) do
		gemTooltips[link] = gemTooltips[link] or self.EMPTY_GEM_SLOTS[link] == 0 and L["Gems: |cffffffffNo sockets|r"] or L["Gems: |cffffffffPass|r"]
	end
	
	for inventoryID, inventoryKey in pairs(self.Items.validInventorySlots) do
		local link = equipment[inventoryID]
		if( link  ) then
			enchantTooltips[link] = enchantTooltips[link] or enchantData[inventoryKey] and L["Enchant: |cffffffffPass|r"] or L["Enchant: |cffffffffCannot enchant|r"]
		end
	end
	
	self:ReleaseTables(tempList)
	return enchantTooltips, gemTooltips, situationalTooltips
end

function ElitistGroup:GetGeneralSummaryTooltip(equipmentData, gemData, enchantData)
	local tempList = self:GetTable()
	local equipmentTooltip, gemTooltip, enchantTooltip
	
	-- Equipment
	if( equipmentData.totalBad > 0 ) then
		table.insert(tempList, string.format(L["Equipment: |cffffffff%d bad items found|r"], equipmentData.totalBad))
		
		for i=1, #(equipmentData), 2 do
			local itemLink, message = equipmentData[i], equipmentData[i + 1]
			local equipText = select(2, GetItemInfo(itemLink))
			if( self.db.profile.general.showSlotName ) then
				equipText = equipmentData[equipText]
			end
			
			table.insert(tempList, string.format(L["%s - |cffffffff%s|r item"], equipText, self.Items.itemRoleText[equipmentData[itemLink]] or equipmentData[itemLink]))
		end
		
		equipmentTooltip = table.concat(tempList, "\n")
	end
	
	-- Gems
	if( gemData.noData ) then
		gemTooltip = L["Gems: |cffffffffFailed to find any gems|r"]
	elseif( gemData.totalBad > 0 ) then
		table.wipe(tempList)
		table.insert(tempList, string.format(L["Gems: |cffffffff%d bad|r"], gemData.totalBad))
		
		for i=1, #(gemData), 4 do
			local fullItemLink, arg = gemData[i], gemData[i + 2]
			local equipText = self.db.profile.general.showSlotName and equipmentData[fullItemLink] or fullItemLink
			
			if( arg == "buckle" ) then
				table.insert(tempList, string.format(L["%s - Missing belt buckle or gem"], equipText))
			elseif( arg == "missing" ) then
				table.insert(tempList, string.format(L["%s - |cffffffff%d|r missing |4gem:gems;"], equipText, gemData[i + 1]))
			elseif( type(arg) == "string" ) then
				table.insert(tempList, string.format(L["%s - |cffffffff%s|r gem"], equipText, self.Items.itemRoleText[arg] or arg))
			else
				table.insert(tempList, string.format(L["%s - |cffffffff%s|r quality gem"], equipText, _G["ITEM_QUALITY" .. arg .. "_DESC"]))
			end
		end
		
		gemTooltip = table.concat(tempList, "\n")
	end
	
	-- Enchants
	if( enchantData.noData ) then
		enchantTooltip = L["Enchants: |cffffffffThe player does not have any enchants|r"]
	elseif( enchantData.totalBad > 0 ) then
		table.wipe(tempList)
		table.insert(tempList, string.format(L["Enchants: |cffffffff%d bad|r"], enchantData.totalBad))
		
		for i=1, #(enchantData), 2 do
			local fullItemLink, enchantTalent = enchantData[i], enchantData[i + 1]
			local equipText = self.db.profile.general.showSlotName and equipmentData[fullItemLink] or fullItemLink

			if( enchantTalent == "missing" ) then
				table.insert(tempList, string.format(L["%s - Unenchanted"], equipText))
			else
				table.insert(tempList, string.format(L["%s - |cffffffff%s|r"], equipText, ElitistGroup.Items.itemRoleText[enchantTalent] or enchantTalent))
			end
		end
		
		enchantTooltip = table.concat(tempList, "\n")
	end
	
	self:ReleaseTables(tempList)
	
	return equipmentTooltip or L["Equipment: |cffffffffPass|r"], gemTooltip or L["Gems: |cffffffffPass|r"], enchantTooltip or L["Enchants: |cffffffffPass|r"]
end

local function getSituationalOverride(type, itemLink, itemType, userData, spec)
	local situational = ElitistGroup.Items.situationalOverrides[itemLink]
	if( situational ) then
		local type, message = situational(type, userData, spec)
		if( type ) then
			return type, message or false
		end
	end
	
	return itemType, false
end

local MAINHAND_SLOT, OFFHAND_SLOT, WAIST_SLOT = GetInventorySlotInfo("MainHandSlot"), GetInventorySlotInfo("SecondaryHandSlot"), GetInventorySlotInfo("WaistSlot")
function ElitistGroup:GetGearSummary(userData)
	local spec = self:GetPlayerSpec(userData.classToken, userData)
	local validSpecTypes = self.Items.talentToRole[spec]
	local equipment, gems, enchants = self:GetTable(), self:GetTable(), self:GetTable()
	
	equipment.totalScore = 0
	equipment.totalEquipped = 0
	equipment.totalBad = 0
	equipment.pass = true
	
	enchants.total = 0
	enchants.totalUsed = 0
	enchants.totalBad = 0
	enchants.pass = true
	
	gems.total = 0
	gems.totalUsed = 0
	gems.totalBad = 0
	gems.pass = true
	
	for inventoryID, itemLink in pairs(userData.equipment) do
		local fullItemLink, itemQuality, itemLevel, _, _, _, _, itemEquipType, itemIcon = select(2, GetItemInfo(itemLink))
		if( fullItemLink and itemQuality ) then
			local baseItemLink, enchantItemLink = string.match(itemLink, "item:%d+"), string.match(itemLink, "item:%d+:(%d+)")
						
			-- Figure out the items primary info
			equipment.totalScore = equipment.totalScore + self:CalculateScore(itemLink, itemQuality, itemLevel)
			equipment.totalEquipped = equipment.totalEquipped + 1
			
			local equipID = self.Items.equipToType[itemEquipType]
			local roleOverride = self.Items.roleOverrides[spec] and self.Items.roleOverrides[spec].type == equipID and self.Items.roleOverrides[spec]
			-- Check if we have an override on this item
			local itemTalent, suitMessage = getSituationalOverride(inventoryID, baseItemLink, self.ITEM_TALENTTYPE[baseItemLink], userData, spec)
			
			-- Figure out the items slot name if necessary
			if( ElitistGroup.db.profile.general.showSlotName ) then
				local equipSlot = self.Items.validInventorySlots[inventoryID]
				if( equipSlot == "RangedSlot" and ( userData.classToken == "DRUID" or userData.classToken == "PALADIN" or userData.classToken == "SHAMAN") ) then
					equipSlot = "RelicSlot"
				-- Use the unique keys which show Ring #/Trinket #
				elseif( equipID == "rings" or equipID == "trinkets" ) then
					equipSlot = equipSlot .. "_UNIQUE"
				end
				
				local color = ITEM_QUALITY_COLORS[itemQuality] or ITEM_QUALITY_COLORS[1]
				equipment[fullItemLink] = string.format("%s%s|r", color.hex, _G[string.upper(equipSlot)])
			end

			-- Now check item
			if( itemTalent ~= "unknown" and validSpecTypes and not validSpecTypes[itemTalent] and ( not roleOverride or not roleOverride[itemTalent] ) ) then
				equipment.pass = nil
				equipment[itemLink] = itemTalent
				equipment.totalBad = equipment.totalBad + 1
				
				table.insert(equipment, itemLink)
				table.insert(equipment, suitMessage)
			end
			
			-- Either the item is not unenchantable period, or if it's unenchantable for everyone but a specific class
			local unenchantable = ElitistGroup.Items.unenchantableTypes[itemEquipType]
			if( not unenchantable or type(unenchantable) == "string" and unenchantable == userData.classToken ) then
				enchants.total = enchants.total + 1
				enchants[ElitistGroup.Items.validInventorySlots[inventoryID]] = true

				local enchantTalent = ElitistGroup.ENCHANT_TALENTTYPE[enchantItemLink]
				if( enchantTalent ~= "none" ) then
					enchants.totalUsed = enchants.totalUsed + 1
					
					if( enchantTalent ~= "unknown" and validSpecTypes and not validSpecTypes[enchantTalent] ) then
						enchants.totalBad = enchants.totalBad + 1
						enchants[fullItemLink] = itemLink
						enchants.pass = nil
						
						table.insert(enchants, fullItemLink)
						table.insert(enchants, enchantTalent)
					end
				else
					table.insert(enchants, fullItemLink)
					table.insert(enchants, "missing")
					
					enchants[fullItemLink] = itemLink
					enchants.totalBad = enchants.totalBad + 1
					enchants.pass = nil
				end
			end

			-- Last but not least, off to the gems
			gems.total = gems.total + self.EMPTY_GEM_SLOTS[itemLink]
			
			local itemUnsocketed = self.EMPTY_GEM_SLOTS[itemLink]
			local alreadyFailed
			for socketID=1, MAX_NUM_SOCKETS do
				local gemLink = ElitistGroup:GetBaseItemLink(select(2, GetItemGem(itemLink, socketID)))
				if( gemLink ) then
					gems.totalUsed = gems.totalUsed + 1
					itemUnsocketed = itemUnsocketed - 1
					
					local gemTalent, suitMessage = getSituationalOverride(nil, gemLink, self.GEM_TALENTTYPE[gemLink], userData, spec)
					if( gemTalent ~= "unknown" and validSpecTypes and not validSpecTypes[gemTalent] ) then
						table.insert(gems, fullItemLink)
						table.insert(gems, gemLink)
						table.insert(gems, gemTalent)
						table.insert(gems, suitMessage)
						
						gems[fullItemLink] = itemLink
						gems.totalBad = gems.totalBad + 1
						gems.pass = nil
					else
						local gemQuality = select(3, GetItemInfo(gemLink))
						if( self.Items.gemQualities[itemQuality] and gemQuality < self.Items.gemQualities[itemQuality] ) then
							gems[fullItemLink] = itemLink
							gems.totalBad = gems.totalBad + 1
							gems.pass = nil

							table.insert(gems, fullItemLink)
							table.insert(gems, gemLink)
							table.insert(gems, gemQuality)
							table.insert(gems, false)
						end
					end
				end
			end
			
			if( itemUnsocketed > 0 ) then
				table.insert(gems, fullItemLink)
				table.insert(gems, itemUnsocketed)
				table.insert(gems, "missing")
				table.insert(gems, false)
				
				gems.pass = nil
				gems.totalBad = gems.totalBad + itemUnsocketed
				gems[fullItemLink] = itemLink
			end
		end
	end
	
	-- Belt buckles are a special case, you cannot detect them through item links at all or tooltip scanning
	local itemLink = userData.equipment[WAIST_SLOT]
	if( itemLink and userData.level >= 70 ) then
		local baseSocketCount = self.EMPTY_GEM_SLOTS[self:GetBaseItemLink(itemLink)]
		local gem1, gem2, gem3 = string.match(itemLink, "item:%d+:%d+:(%d+):(%d+):(%d+)")
		local totalSockets = (gem1 ~= "0" and 1 or 0) + (gem2 ~= "0" and 1 or 0) + (gem3 ~= "0" and 1 or 0)
		
		-- The item by default has 1 socket, and the player only has 1 gem socketed, missing buckle
		-- if the player had 2 available sockets and only 1 socketed, nothing is shown since they are missing a socket at that point
		if( ( baseSocketCount > 0 and totalSockets == baseSocketCount ) or ( baseSocketCount == 0 and totalSockets == 0 ) ) then
			local fullItemLink = select(2, GetItemInfo(itemLink))
			table.insert(gems, fullItemLink)
			table.insert(gems, false)
			table.insert(gems, "buckle")
			table.insert(gems, false)
			
			gems.pass = nil
			gems.totalBad = gems.totalBad + 1
			gems[fullItemLink] = itemLink
		end
	end
	
	-- Try and account for the fact that the inspection can fail to find gems, so if we find 0 gems used will give a warning
	if( gems.total > 0 and gems.totalUsed == 0 ) then
		gems.noData = true
	end
	
	if( enchants.total > 0 and enchants.totalUsed == 0 ) then
		enchants.noData = true
	end
	
	if( equipment.totalEquipped == 0 ) then
		equipment.noData = true
	end
	
	equipment.totalScore = equipment.totalEquipped > 0 and equipment.totalScore / equipment.totalEquipped or 0
	return equipment, enchants, gems
end

-- While GetGearSummary works, for things like tooltips we really need an optimized form that is based on speed without extra data
function ElitistGroup:GetOptimizedSummary(userData)
	local spec = self:GetPlayerSpec(userData.classToken, userData)
	local validSpecTypes = self.Items.talentToRole[spec]
	if( not validSpecTypes ) then return nil end

	local totalGear, totalBadGear, totalEnchants, totalBadEnchants, totalGems, totalBadGems, totalLevel = 0, 0, 0, 0, 0, 0, 0
	for inventoryID, itemLink in pairs(userData.equipment) do
		local itemQuality, itemLevel, _, _, _, _, itemEquipType = select(3, GetItemInfo(itemLink))
		if( itemEquipType ) then
			totalGear = totalGear + 1	
			totalLevel = totalLevel + self:CalculateScore(itemLink, itemQuality, itemLevel)
			
			local itemTalent = self.ITEM_TALENTTYPE[string.match(itemLink, "item:%d+")]
			local roleOverride = self.Items.roleOverrides[spec] and self.Items.roleOverrides[spec].type == self.Items.equipToType[itemEquipType] and self.Items.roleOverrides[spec]
			if( itemTalent ~= "unknown" and not validSpecTypes[itemTalent] and ( not roleOverride or not roleOverride[itemTalent] ) ) then
				totalBadGear = totalBadGear + 1
			end

			-- Either the item is not unenchantable period, or if it's unenchantable for everyone but a specific class
			local unenchantable = ElitistGroup.Items.unenchantableTypes[itemEquipType]
			if( not unenchantable or type(unenchantable) == "string" and unenchantable == userData.classToken ) then
				totalEnchants = totalEnchants + 1
				
				local enchantTalent = ElitistGroup.ENCHANT_TALENTTYPE[string.match(itemLink, "item:%d+:(%d+)")]
				if( enchantTalent == "none" or ( enchantTalent ~= "unknown" and not validSpecTypes[enchantTalent] ) ) then
					totalBadEnchants = totalBadEnchants + 1
				end
			end

			-- Last but not least, off to the gems
			local itemUnsocketed = self.EMPTY_GEM_SLOTS[itemLink]
			totalGems = totalGems + itemUnsocketed
			
			for socketID=1, MAX_NUM_SOCKETS do
				local gemLink = select(2, GetItemGem(itemLink, socketID))
				if( not gemLink ) then break end
				itemUnsocketed = itemUnsocketed - 1
				
				local gemTalent = self.GEM_TALENTTYPE[string.match(gemLink, "item:%d+")]
				if( gemTalent ~= "unknown" and not validSpecTypes[gemTalent]) then
					totalBadGems = totalBadGems + 1
				else
					local gemQuality = select(3, GetItemInfo(gemLink))
					if( self.Items.gemQualities[itemQuality] and gemQuality < self.Items.gemQualities[itemQuality] ) then
						totalBadGems = totalBadGems + 1
					end
				end
			end
			
			totalBadGems = totalBadGems + itemUnsocketed
		end
	end
	
	-- Belt buckles are a special case, you cannot detect them through item links at all or tooltip scanning
	local itemLink = userData.equipment[WAIST_SLOT]
	if( itemLink and userData.level >= 70 ) then
		local baseSocketCount = self.EMPTY_GEM_SLOTS[self:GetBaseItemLink(itemLink)]
		local gem1, gem2, gem3 = string.match(itemLink, "item:%d+:%d+:(%d+):(%d+):(%d+)")
		local totalSockets = (gem1 ~= "0" and 1 or 0) + (gem2 ~= "0" and 1 or 0) + (gem3 ~= "0" and 1 or 0)
		
		-- The item by default has 1 socket, and the player only has 1 gem socketed, missing buckle
		-- if the player had 2 available sockets and only 1 socketed, nothing is shown since they are missing a socket at that point
		if( ( baseSocketCount > 0 and totalSockets == baseSocketCount ) or ( baseSocketCount == 0 and totalSockets == 0 ) ) then
			totalBadGems = totalBadGems + 1
			totalGems = totalGems + 1
		end
	end
	
	local percentGear = math.min(1, (totalGear - totalBadGear) / totalGear)
	local percentEnchants = math.min(1, (totalEnchants - totalBadEnchants) / totalEnchants)
	local percentGems = totalBadGems == 0 and totalGems == 0 and 0 or (totalGems - totalBadGems) / totalGems
	return math.floor(totalLevel / totalGear), percentGear, percentEnchants, percentGems
end

-- Broker plugin
LibStub("LibDataBroker-1.1"):NewDataObject("Elitist Group", {
	type = "launcher",
	icon = "Interface\\Icons\\inv_weapon_glave_01",
	OnClick = function(self, mouseButton)
		-- Reporting
		if( mouseButton == "LeftButton" and IsAltKeyDown() and ( GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0 ) ) then
			ElitistGroup.modules.Report:Show()
		-- Inspecting
		elseif( mouseButton == "LeftButton" ) then
			SlashCmdList["ELITISTGROUP"]("")
		-- Rating
		elseif( mouseButton == "RightButton" and IsAltKeyDown() ) then
			if( GetNumPartyMembers() > 0 ) then
				SlashCmdList["ELITISTGROUPRATE"]("")
			end
		-- Summaries
		elseif( mouseButton == "RightButton" ) then
			if( GetNumRaidMembers() > 0 ) then
				ElitistGroup.modules.RaidSummary:Show()
			elseif( GetNumPartyMembers() > 0 ) then
				ElitistGroup.modules.PartySummary:Show()
			end
		end
	end,
	OnTooltipShow = function(tooltip)
		if( not tooltip ) then return end
		
		tooltip:SetText("Elitist Group")
		tooltip:AddLine(L["Left Click - Open player/target information"], 1, 1, 1, nil, nil)
		
		if( GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0 ) then
			tooltip:AddLine(L["ALT + Left Click - Open report window for group"], 1, 1, 1, nil, nil)
		end
		
		if( GetNumRaidMembers() > 0 ) then
			tooltip:AddLine(L["Right Click - Open summary for your raid"], 1, 1, 1, nil, nil)
			tooltip:AddLine(L["ALT + Right Click - Open rating window for raid"], 1, 1, 1, nil, nil)
		elseif( GetNumPartyMembers() > 0 ) then
			tooltip:AddLine(L["Right Click - Open summary for your party"], 1, 1, 1, nil, nil)
			tooltip:AddLine(L["ALT + Right Click - Open rating window for party"], 1, 1, 1, nil, nil)
		end
	end,
})

-- Encodes text in a way that it won't interfere with the table being loaded
local map = {	["{"] = "\\" .. string.byte("{"), ["}"] = "\\" .. string.byte("}"),
				['"'] = "\\" .. string.byte('"'), [";"] = "\\" .. string.byte(";"),
				["%["] = "\\" .. string.byte("["), ["%]"] = "\\" .. string.byte("]"),
				["@"] = "\\" .. string.byte("@")}
function ElitistGroup:SafeEncode(text)
	if( not text ) then return nil end
	
	for find, replace in pairs(map) do
		text = string.gsub(text, find, replace)
	end
	
	return text
end

function ElitistGroup:Decode(text)
	if( not text ) then return nil end

	for replace, find in pairs(map) do
		text = string.gsub(text, find, replace)
	end
	
	return text
end

function ElitistGroup:WriteTable(tbl, skipNotes)
	local data = ""
	for key, value in pairs(tbl) do
		if( not skipNotes or key ~= "notes" ) then
			local valueType = type(value)
			
			-- Wrap the key in brackets if it's a number
			if( type(key) == "number" ) then
				key = string.format("[%s]", key)
			-- This will match any punctuation, spacing or control characters, basically anything that requires wrapping around them
			elseif( string.match(key, "[%p%s%c]") ) then
				key = string.format("[\"%s\"]", key)
			end
			
			-- foo = {bar = 5}
			if( valueType == "table" ) then
				data = string.format("%s%s=%s;", data, key, self:WriteTable(value))
			-- foo = true / foo = 5
			elseif( valueType == "number" or valueType == "boolean" ) then
				data = string.format("%s%s=%s;", data, key, tostring(value))
			-- foo = "bar"
			else
				data = string.format("%s%s=\"%s\";", data, key, tostring(self:SafeEncode(value)))
			end
		end
	end
	
	return "{" .. data .. "}"
end

-- db:ResetProfile or db:ResetDB called
function ElitistGroup:OnProfileReset()
	table.wipe(self.writeQueue)
	table.wipe(self.userData)
end

-- db:SetProfile called, this is the old profile before it gets switched
function ElitistGroup:OnProfileShutdown()
	self:OnDatabaseShutdown()

	table.wipe(self.writeQueue)
	table.wipe(self.userData)
end

-- Player is logging out, write the cache
function ElitistGroup:OnDatabaseShutdown()
	for name in pairs(self.writeQueue) do
		-- We need to make sure what we are writing has data, for example if we inspect scan someone we create the template
		-- if we fail to find talent data for them, and we don't have notes then will just throw out their data and not bother writing it
		local userData = self.userData[name]
		local hasData = userData.talentTree1 ~= 0 or userData.talentTree2 ~= 0 or userData.talentTree3 ~= 0
		if( not hasData ) then
			for _, note in pairs(userData.notes) do
				hasData = true
				break
			end
		end
		
		if( hasData and userData.level and ( userData.level == -1 or userData.level >= self.db.profile.database.ignoreBelow ) and ( self.db.profile.database.saveForeign or userData.server == GetRealmName() ) ) then
			self.db.faction.lastModified[name] = time()
			self.db.faction.users[name] = self:WriteTable(userData)
		else
			self.db.faction.lastModified[name] = nil
			self.db.faction.users[name] = nil
		end
	end
	
	-- Save main data too
	if( self.db.global.main.character == self.playerID ) then
		local data = ""
		
		for achievementID in pairs(self.Dungeons.achievements) do
			local id, _, _, completed, _, _, _, _, flags = GetAchievementInfo(achievementID)
			if( bit.band(flags, ACHIEVEMENT_FLAGS_STATISTIC) > 0 ) then
				local statistic = tonumber(GetStatistic(id))
				if( statistic ) then
					data = data .. "@" .. id .. "@" .. statistic
				end
			elseif( completed ) then
				data = data .. "@" .. id .. "@1"
			end
		end
		
		data = string.gsub(data, "^@", "")
		self.db.global.main.data = data ~= "" and data or nil
	end
end

function ElitistGroup:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Elitist Group|r: " .. msg)
end