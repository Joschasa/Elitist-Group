local ElitistGroup = select(2, ...)
local Notes = ElitistGroup:NewModule("Notes", "AceEvent-3.0")
local L = ElitistGroup.L
local MAX_RATING_ROWS = 8
local playerNames, playerClasses, playerLevels, playerRoles, queuedUnits = {}, {}, {}, {}, {}
local raidUnits, partyUnits = ElitistGroup.raidUnits, ElitistGroup.partyUnits

function Notes:OnInitialize()
	self:RegisterEvent("RAID_ROSTER_UPDATE", "GroupUpdated")
	self:RegisterEvent("PARTY_MEMBERS_CHANGED", "GroupUpdated")
	self:RegisterEvent("LFG_COMPLETION_REWARD")
end

function Notes:Show()
	self:GroupUpdated()
	self:CreateUI()
	self:Update()
end

function Notes:PLAYER_REGEN_ENABLED()
	if( self.groupUpdate ) then
		self.groupUpdate = nil
		self:GroupUpdated()
	end

	if( self.popupRating ) then
		self.popupRating = nil
		self:LFG_COMPLETION_REWARD()
	end
end

function Notes:PLAYER_LEAVING_WORLD()
	self.resetGroup = true
	self:UnregisterEvent("PLAYER_LEAVING_WORLD")
end

-- For LFD dungeons only
function Notes:LFG_COMPLETION_REWARD()
	self:RegisterEvent("PLAYER_LEAVING_WORLD")
	
	if( InCombatLockdown() ) then
		self.popupRating = true
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end
	
	if( ElitistGroup.db.profile.auto.autoPopup ) then
		self:Show()
	else
		local name, typeID = GetLFGCompletionReward()
		local instanceName = typeID == TYPEID_HEROIC_DIFFICULTY and string.format("%s (%s)", name, PLAYER_DIFFICULTY2) or name
		
		ElitistGroup:Print(string.format(L["Completed %s! Type /rate to rate this group."], instanceName))
	end
end

local function addUnit(unit)
	local guid = UnitGUID(unit)
	if( not guid or playerNames[guid] ) then return end
	local playerID = ElitistGroup:GetPlayerID(unit)
	if( not playerID ) then
		queuedUnits[unit] = true
		Notes:RegisterEvent("UNIT_NAME_UPDATE")
		return
	end
	
	local isTank, isHealer, isDamage = UnitGroupRolesAssigned(unit)

	playerNames[guid] = playerID
	playerLevels[playerID] = UnitLevel(unit)
	playerClasses[playerID] = select(2, UnitClass(unit))
	playerRoles[playerID] = bit.bor(isTank and ElitistGroup.ROLE_TANK or 0, isHealer and ElitistGroup.ROLE_HEALER or 0, isDamage and ElitistGroup.ROLE_DAMAGE or 0)
	
	table.insert(playerNames, playerNames[guid])
	
	if( ElitistGroup.db.profile.auto.alertRating ) then
		local userData = ElitistGroup.userData[playerID]
		local note = userData and userData.notes[ElitistGroup.playerID]
		if( note and note.rating <= 2 ) then
			if( note.comment ) then
				ElitistGroup:Print(string.format(L["|cffff2020Warning!|r %s is in your group, you rated them %d for: %s"], playerID, note.rating, note.comment))
			else
				ElitistGroup:Print(string.format(L["|cffff2020Warning!|r %s is in your group, you rated them %d"], playerID, note.rating, note.comment))
			end
		end
	end
end

function Notes:UNIT_NAME_UPDATE(event, unit)
	if( not queuedUnits[unit] ) then return end
	queuedUnits[unit] = nil
	addUnit(unit)
	
	local hasData
	for unit in pairs(queuedUnits) do hasData = true break end
	if( not hasData ) then
		self:UnregisterEvent("UNIT_NAME_UPDATE")
	end
end

-- This is only registered while the UI is open
function Notes:GroupUpdated()
	if( InCombatLockdown() ) then
		self.groupUpdate = true
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end
	
	if( GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 ) then
		self.resetGroup = true
	else
		if( self.resetGroup ) then
			self.resetGroup = nil
			playerNames, playerClasses, playerLevels, playerRoles = {}, {}, {}, {}
		end
		
		self.haveActiveGroup = true
		
		for i=1, GetNumRaidMembers() do
			if( not UnitIsUnit(raidUnits[i], "player") ) then
				addUnit(raidUnits[i])
			end
		end
		
		for i=1, GetNumPartyMembers() do
			addUnit(partyUnits[i])
		end
	end
end

local function sortNames(a, b) return a < b end

function Notes:Update()
	self = Notes

	if( not self.scrollUpdate ) then
		table.sort(playerNames, sortNames)
	end
	
	FauxScrollFrame_Update(self.frame.scroll, #(playerNames), MAX_RATING_ROWS, 24)
	local offset = FauxScrollFrame_GetOffset(self.frame.scroll)
		
	for id, row in pairs(self.frame.rows) do
		local name = playerNames[id + offset]
		if( name ) then
			local classToken = playerClasses[name]
			local classColor = classToken and RAID_CLASS_COLORS[classToken]
			if( classColor ) then
				row.name:SetFormattedText("|cff%02x%02x%02x%s|r", classColor.r * 255, classColor.g * 255, classColor.b * 255, name)
				row.name.tooltip = string.format(L["%s, %s"], name, LOCALIZED_CLASS_NAMES_MALE[classToken])
			else
				row.name:SetFormattedText("|cffffffff%s|r", name)
				row.name.tooltip = string.format(L["%s, unknown class"], name)
			end
			
			local userData = ElitistGroup.userData[name]
			if( not userData ) then
				ElitistGroup.modules.Scan:ManualCreateCore(name, playerLevels[name], playerClasses[name])
			end
			
			local role = 0
			if( userData ) then
				local defaultRole = playerRoles[name]
				local playerNote = userData.notes[ElitistGroup.playerID]
				if( playerNote ) then
					row.playerID = name
					row.defaultRole = defaultRole
				
					row.rating:SetValue(playerNote.rating)
					row.comment.lastText = playerNote.comment or ""
					row.comment:SetText(row.comment.lastText)
				else
					local specType = ElitistGroup:GetPlayerSpec(userData.classToken, userData)
					defaultRole = defaultRole > 0 and defaultRole or specType == "unknown" and 0 or specType == "healer" and ElitistGroup.ROLE_HEALER or ( specType == "feral-tank" or specType == "tank" ) and ElitistGroup.ROLE_TANK or ElitistGroup.ROLE_DAMAGE
					row.playerID = name
					row.defaultRole = defaultRole

					row.rating:SetValue(3)
					row.comment.lastText = ""
					row.comment:SetText("")
				end

				role = ( defaultRole > 0 or not playerNote ) and defaultRole or playerNote.role
			end
			
			SetDesaturation(row.roleTank:GetNormalTexture(), bit.band(role, ElitistGroup.ROLE_TANK) == 0)
			SetDesaturation(row.roleHealer:GetNormalTexture(), bit.band(role, ElitistGroup.ROLE_HEALER) == 0)
			SetDesaturation(row.roleDamage:GetNormalTexture(), bit.band(role, ElitistGroup.ROLE_DAMAGE) == 0)
			
			for _, button in pairs(row) do
				if( type(button) == "table" ) then button:Show() end
			end
		else
			row.playerID = nil
			row.defaultRole = nil
			
			for _, button in pairs(row) do
				if( type(button) == "table" ) then button:Hide() end
			end
		end
	end
end

function Notes:CreateUI()
	if( self.frame ) then
		self.frame:Show()
		return
	end
	
	local OnEnter, OnLeave = ElitistGroup.Widgets.OnEnter, ElitistGroup.Widgets.OnLeave
	
	local function getNote(playerID, defaultRole)
		local userData = ElitistGroup.userData[playerID]
		userData.notes[ElitistGroup.playerID] = userData.notes[ElitistGroup.playerID] or {rating = 3, role = defaultRole, time = time()}
		
		ElitistGroup.writeQueue[playerID] = true
		return userData.notes[ElitistGroup.playerID]
	end
	
	local function UpdateComment(self)
		local text = self:GetText()
		if( text ~= self.lastText and self.parent.playerID ) then
			self.lastText = text
			
			local playerNote = getNote(self.parent.playerID, self.parent.defaultRole)
			playerNote.comment = string.trim(text) ~= "" and text or nil
		end
	end
	
	local function UpdateRole(self)
		if( not self.parent.playerID ) then return end
		
		local playerNote = getNote(self.parent.playerID, self.parent.defaultRole)
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
	end
	
	local function UpdateRating(self)
		if( not self.parent.playerID ) then return end
		
		local playerNote = getNote(self.parent.playerID, self.parent.defaultRole)
		playerNote.rating = self:GetValue()
	end

	-- Main container
	local frame = CreateFrame("Frame", "ElitistGroupGroupRatingFrame", UIParent)
	frame:SetClampedToScreen(true)
	frame:RegisterForDrag("LeftButton", "RightButton")
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetToplevel(true)
	frame:SetHeight(300)
	frame:SetWidth(545)
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
	
	table.insert(UISpecialFrames, "ElitistGroupGroupRatingFrame")
	
	if( ElitistGroup.db.profile.positions.notes ) then
		local scale = frame:GetEffectiveScale()
		frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", ElitistGroup.db.profile.positions.notes.x / scale, ElitistGroup.db.profile.positions.notes.y / scale)
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

	frame.inspectQueue = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	frame.inspectQueue:SetPoint("TOPLEFT", frame, "TOPLEFT", 11, -14)

	-- Close button
	local button = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	button:SetPoint("TOPRIGHT", -3, -3)
	button:SetHeight(28)
	button:SetWidth(28)
	button:SetScript("OnClick", function() frame:Hide() end)
	
	frame.headers = {}
	
	local headerNames = {["name"] = L["Name"], ["role"] = L["Role"], ["terrible"] = L["Terrible"], ["great"] = L["Great"], ["comment"] = L["Comment"]}
	local headerKeys = {"name", "role", "terrible", "great", "comment"}
	for _, key in pairs(headerKeys) do
	   local headerButton = CreateFrame("Button", nil, frame)
	   headerButton:SetNormalFontObject(GameFontNormal)
	   headerButton:SetText(headerNames[key])
	   headerButton:GetFontString():SetPoint("LEFT", 3, 0)
	   headerButton:SetHeight(20)
	   headerButton:SetPushedTextOffset(0, 0)
	   
	   frame.headers[key] = headerButton
	end

	frame.headers.name:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -15)
	frame.headers.name:SetWidth(135)
	frame.headers.role:SetPoint("TOPLEFT", frame.headers.name, "TOPRIGHT", 5, 0)
	frame.headers.role:SetWidth(70)
	frame.headers.terrible:SetPoint("TOPLEFT", frame.headers.role, "TOPRIGHT", 20, 0)
	frame.headers.terrible:SetWidth(50)
	frame.headers.great:SetPoint("TOPLEFT", frame.headers.terrible, "TOPRIGHT", 35, 0)
	frame.headers.great:SetWidth(45)
	frame.headers.comment:SetPoint("TOPLEFT", frame.headers.great, "TOPRIGHT", 15, 0)
	frame.headers.comment:SetWidth(130)

	frame.scroll = CreateFrame("ScrollFrame", "ElitistGroupnotesScroll", frame, "FauxScrollFrameTemplate")
	frame.scroll.bar = ElitistGroupnotesScroll
	frame.scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -36)
	frame.scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -33, 10)
	frame.scroll:SetScript("OnVerticalScroll", function(self, value) Notes.scrollUpdate = true; FauxScrollFrame_OnVerticalScroll(self, value, 24, Notes.Update); Notes.scrollUpdate = nil end)
	
	local function viewDetailedInfo(self)
		local userData = self.parent.playerID and ElitistGroup.userData[self.parent.playerID]
		if( userData ) then
			ElitistGroup.modules.Users:Toggle(userData)
		end
	end
	
	local sliderBackdrop = {
		bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
		edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
		tile = true, tileSize = 8, edgeSize = 8,
		insets = { left = 3, right = 3, top = 6, bottom = 6 }
	}
		
	frame.rows = {}
	for i=1, MAX_RATING_ROWS do
		local row = {}
		
		-- Player name
		row.name = CreateFrame("Button", nil, frame)
		row.name:SetNormalFontObject(GameFontHighlight)
		row.name:SetPushedTextOffset(3, -2)
		row.name:SetFormattedText("*")
		row.name:SetHeight(22)
		row.name:SetScript("OnClick", viewDetailedInfo)
		row.name:SetScript("OnEnter", OnEnter)
		row.name:SetScript("OnLeave", OnLeave)
		row.name.parent = row
		
		local fontString = row.name:GetFontString()
		fontString:SetPoint("TOPLEFT", 0, 0)
		fontString:SetPoint("BOTTOMRIGHT", 0, 0)
		fontString:SetJustifyH("LEFT")
		fontString:SetJustifyV("CENTER")
		
		-- Player role
		row.roleTank = CreateFrame("Button", nil, frame)
		row.roleTank:SetSize(18, 18)
		row.roleTank:SetNormalTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
		row.roleTank:GetNormalTexture():SetTexCoord(0, 19/64, 22/64, 41/64)
		row.roleTank:SetScript("OnClick", UpdateRole)
		row.roleTank:SetScript("OnEnter", OnEnter)
		row.roleTank:SetScript("OnLeave", OnLeave)
		row.roleTank.tooltip = L["Set role as tank."]
		row.roleTank.roleID = ElitistGroup.ROLE_TANK
		row.roleTank.parent = row
		
		row.roleHealer = CreateFrame("Button", nil, frame)
		row.roleHealer:SetSize(18, 18)
		row.roleHealer:SetNormalTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
		row.roleHealer:GetNormalTexture():SetTexCoord(20/64, 39/64, 1/64, 20/64)
		row.roleHealer:SetPoint("LEFT", row.roleTank, "RIGHT", 6, 0)
		row.roleHealer:SetScript("OnClick", UpdateRole)
		row.roleHealer:SetScript("OnEnter", OnEnter)
		row.roleHealer:SetScript("OnLeave", OnLeave)
		row.roleHealer.tooltip = L["Set role as healer."]
		row.roleHealer.roleID = ElitistGroup.ROLE_HEALER
		row.roleHealer.parent = row

		row.roleDamage = CreateFrame("Button", nil, frame)
		row.roleDamage:SetSize(18, 18)
		row.roleDamage:SetNormalTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
		row.roleDamage:GetNormalTexture():SetTexCoord(20/64, 39/64, 22/64, 41/64)
		row.roleDamage:SetPoint("LEFT", row.roleHealer, "RIGHT", 6, 0)
		row.roleDamage:SetScript("OnClick", UpdateRole)
		row.roleDamage:SetScript("OnEnter", OnEnter)
		row.roleDamage:SetScript("OnLeave", OnLeave)
		row.roleDamage.tooltip = L["Set role as damage."]
		row.roleDamage.roleID = ElitistGroup.ROLE_DAMAGE
		row.roleDamage.parent = row
		
		-- Player rating
		row.rating = CreateFrame("Slider", nil, frame)
		row.rating:SetBackdrop(sliderBackdrop)
		row.rating:SetHeight(15)
		row.rating:SetWidth(165)
		row.rating:SetOrientation("HORIZONTAL")
		row.rating:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
		row.rating:SetMinMaxValues(1, 5)
		row.rating:SetValueStep(1)
		row.rating:SetScript("OnValueChanged", UpdateRating)
		row.rating.parent = row
		
		-- Player comment
		row.comment = CreateFrame("EditBox", "ElitistGroupGroupNote" .. i, frame, "InputBoxTemplate")
		row.comment:SetHeight(18)
		row.comment:SetWidth(166)
		row.comment:SetAutoFocus(false)
		row.comment:SetScript("OnTextChanged", UpdateComment)
		row.comment:SetScript("OnEnterPressed", row.comment.ClearFocus)
		row.comment:SetMaxLetters(256)
		row.comment.parent = row
		
		if( i > 1 ) then
			row.name:SetPoint("TOPLEFT", frame.rows[i - 1].name, "BOTTOMLEFT", 0, -10)
			row.name:SetPoint("TOPRIGHT", frame.rows[i - 1].name, "BOTTOMRIGHT", 0, 0)

			row.roleTank:SetPoint("TOPLEFT", frame.rows[i - 1].roleTank, "BOTTOMLEFT", 0, -14)

			row.rating:SetPoint("TOPLEFT", frame.rows[i - 1].rating, "BOTTOMLEFT", 0, -17)
			row.rating:SetPoint("TOPRIGHT", frame.rows[i - 1].rating, "BOTTOMRIGHT", 0, 0)

			row.comment:SetPoint("TOPLEFT", frame.rows[i - 1].comment, "BOTTOMLEFT", 0, -14)
			row.comment:SetPoint("TOPRIGHT", frame.rows[i - 1].comment, "BOTTOMRIGHT", 0, 0)
		else
			row.name:SetPoint("TOPLEFT", frame.headers.name, "BOTTOMLEFT", 3, -2)
			row.name:SetPoint("TOPRIGHT", frame.headers.name, "BOTTOMRIGHT", 0, 0)

			row.roleTank:SetPoint("TOPLEFT", frame.headers.role, "BOTTOMLEFT", 2, -6)

			row.rating:SetPoint("TOPLEFT", frame.headers.terrible, "BOTTOMLEFT", 0, -8)
			row.rating:SetPoint("TOPRIGHT", frame.headers.great, "BOTTOMRIGHT", 0, 0)

			row.comment:SetPoint("TOPLEFT", frame.headers.comment, "BOTTOMLEFT", 8, -6)
			row.comment:SetPoint("TOPRIGHT", frame.headers.comment, "BOTTOMRIGHT", 0, -6)
		end
		
		frame.rows[i] = row
	end

	self.frame = frame
	self.frame:Show()
end