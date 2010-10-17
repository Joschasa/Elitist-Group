-- Some of the sanity checks in this are a bit unnecessary and me being super paranoid
-- but I know how much people will love to try and break this, so I am going to give them as little way to break it as possible
local ElitistGroup = select(2, ...)
local Sync = ElitistGroup:NewModule("Sync", "AceEvent-3.0", "AceComm-3.0")
local L = ElitistGroup.L
local playerName = UnitName("player")
local combatQueue, pendingComms, requestQueue, commThrottles, emptyEnv, mainThrottles = {}, {}, {}, {}, {}, {}
local cachedPlayerData, expectingList
local COMM_PREFIX = "ELITG"
local MAX_QUEUE = 20
local REQUEST_THROTTLE = 5
local COMM_TIMEOUT = 5

function Sync:Setup()
	if( ElitistGroup.db.profile.comm.enabled ) then
		self:RegisterComm(COMM_PREFIX)
		self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", "ResetPlayerCache")
		self:RegisterEvent("ACHIEVEMENT_EARNED", "ResetPlayerCache")
		self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "ResetPlayerCache")
		self:RegisterEvent("PLAYER_LEAVING_WORLD", "CheckThrottles")
	else
		self:UnregisterComm(COMM_PREFIX)
		self:UnregisterAllEvents()
		
		table.wipe(combatQueue)
		cachedPlayerData = nil
	end
end

function Sync:ResetPlayerCache()
	cachedPlayerData = nil
end

-- For when we inspect somebody, we can say "GIMMIE MAIN DATA"
function Sync:RequestMainData(unit)
	if( not ElitistGroup.db.profile.comm.autoMain or InCombatLockdown() ) then return end
	
	local guid = UnitGUID(unit)
	-- Only request main data once an hour, in reality I could probably make this once per session?
	if( mainThrottles[guid] and mainThrottles[guid] > GetTime() ) then return end
	mainThrottles[guid] = GetTime() + 3600
	
	local name, server = UnitName(unit)
	server = server ~= "" and server or nil
	name = server and string.format("%s-%s", name, server) or name
	
	self:CommMessage("REQMAIN", "WHISPER", name)
end

-- Handles the throttle management
function Sync:CheckThrottles()
	local time = GetTime()
	for name, data in pairs(commThrottles) do
		local allInvalid = true
		for _, endTime in pairs(data) do
			if( endTime > time ) then
				allInvalid = nil
				break
			end
		end
		
		-- All the timers are done with, so we can kill the table
		if( allInvalid ) then
			ElitistGroup:ReleaseTables(data)
			commThrottles[name] = nil
		end
	end
	
	for guid, endTime in pairs(mainThrottles) do
		if( endTime <= time ) then
			mainThrottles[guid] = nil
		end
	end
end

function Sync:SetThrottle(name, type, seconds)
	if( not commThrottles[name] ) then
		commThrottles[name] = ElitistGroup:GetTable()
	end
	
	commThrottles[name][type] = GetTime() + seconds
end

function Sync:IsThrottled(name, type)
	return commThrottles[name] and commThrottles[name][type] and commThrottles[name][type] >= GetTime()
end

local function getFullName(name)
	local name = string.match(name, "(.-)%-") or name
	local server = string.match(name, "%-(.+)")
	server = server and server ~= "" and server or GetRealmName()

	return string.format("%s-%s", name, server), name, server
end

function Sync:VerifyTable(tbl, checkTbl)
	if( type(tbl) ~= "table" ) then return nil end
	
	for key, value in pairs(tbl) do
		if( not checkTbl[key] or type(value) ~= checkTbl[key] or ( ( type(value) == "string" or type(value) == "number" ) and string.len(value) >= 300 ) ) then
			tbl[key] = nil
		end
	end
end

-- Message filtering
local function filterOffline(self, event, msg)
	if( msg ) then
		for target, data in pairs(pendingComms) do
			if( data.msg == msg ) then
				if( not data.announced ) then
					data.announced = true
					ElitistGroup:Print(string.format(L["User %s is or went offline during syncing."], target))
				end
				return true
			end
		end
	end
end

-- Sadly, we can't get who the message was sent to, so any whispers reset the timer
function Sync:CHAT_MSG_ADDON(event, prefix, msg, distribution, sender)
	if( sender == playerName and distribution == "WHISPER" ) then	
		self.frame.timeElapsed = 0
	end
end
	
function Sync:EnableOfflineBlock(target, disableAnnounce)
	if( pendingComms[target] ) then
		pendingComms[target].announced = disableAnnounce
		return
	end

	local data = ElitistGroup:GetTable()
	data.msg = string.format(ERR_CHAT_PLAYER_NOT_FOUND_S, target)
	data.disableAnnounce = disableAnnounce
	pendingComms[target] = data
	
	-- Need a timer to see when we should kill the blocking
	if( not self.frame ) then
		self.frame = CreateFrame("Frame")
		self.frame.timeElapsed = 0
		self.frame:SetScript("OnUpdate", function(self, elapsed)
			self.timeElapsed = self.timeElapsed - elapsed
			if( self.timeElapsed >= COMM_TIMEOUT ) then
				self.timeElapsed = self.timeElapsed - COMM_TIMEOUT
				
				for target, data in pairs(pendingComms) do ElitistGroup:ReleaseTables(data) end
				table.wipe(pendingComms)
				
				Sync:UnregisterEvent("CHAT_MSG_ADDON")
				ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", filterOffline)
				self:Hide()
			end
		end)
	end

	Sync:RegisterEvent("CHAT_MSG_ADDON")
	ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", filterOffline)
end

-- COMMUNICATION REQUESTERS
local function verifyInput(name, forceServer)
	if( not name or name == "" ) then
		ElitistGroup:Print(L["You have to enter a name for this to work."])
		return nil
	-- Check common units
	elseif( name == "target" or name == "focus" or name == "mouseover" ) then
		local unit = name
		local server
		name, server = UnitName(name)
		if( not UnitExists(name) or name == UNKNOWN ) then
			ElitistGroup:Print(string.format(L["No player found for unit %s."], unit))
			return nil
		end

		return ( server and server ~= "" ) and string.format("%s-%s", name, server) or forceServer and string.format("%s-%s", name, GetRealmName()) or name
	-- Since we don't want to force the server name, we want to strip it if they put their home server
	elseif( not forceServer and string.match(name, GetRealmName()) ) then
		name = string.match(name, "(.-)%-")
	end
	
	return name
end

function Sync:SendCmdGear(name)
	local name = verifyInput(name)
	if( name ) then
		self:SendPlayersGear(name, true)
		ElitistGroup:Print(string.format(L["Sent your gear to %s! It will arrive in a few seconds"], name))
	end
end

-- Request somebodies gear
function Sync:RequestGear(name)
	local name = verifyInput(name)
	if( name ) then
		ElitistGroup:Print(string.format(L["Requested gear from %s, this might take a second."], name))
		self:CommMessage("REQGEAR", "WHISPER", name)
	end
end

-- Request database
function Sync:RequestDatabase(name)
	if( not ElitistGroup.db.profile.comm.databaseSync ) then
		ElitistGroup:Print(L["You need to enable database syncing in /eg config -> Addon communication to use this."])
		return
	end

	local name = verifyInput(name)
	if( name and not ElitistGroup:IsTrusted(name) ) then
		ElitistGroup:Print(string.format(L["You have to add %s to your trusted list before you can use this."], name))
	elseif( name ) then
		expectingList = true
		ElitistGroup:Print(string.format(L["Requesting Elitist Group database from %s. Keep in mind this is hard throttled at once per hour."], name))
		self:CommMessage("REQUSERS", "WHISPER", name)
	elseif( not IsInGuild() ) then
		ElitistGroup:Print(L["You cannot request the database of everyone in your guild without being a guild!"])
	else
		ElitistGroup:Print(L["Requesting Elitist Group databases from everyone in your guild, this could take a while. Keep in mind this is hard throttled at once per hour."])
		self:CommMessage("REQUSERS", "GUILD")
	end
end

-- Request the notes on a specific person
function Sync:RequestNotes(name)
	local name = verifyInput(name)
	if( name ) then
		ElitistGroup:Print(string.format(L["Requesting Elitist Group notes from %s. Keep in mind this is hard throttled at once every 30 minutes."], name))
		self:CommMessage("REQALLNOTES", "WHISPER", name)
	elseif( not IsInGuild() ) then
		ElitistGroup:Print(L["You cannot request the notes of everyone in your guild without being a guild!"])
	else
		ElitistGroup:Print(L["Requesting Elitist Group notes from everyone in your guild, this could take a minute. Keep in mind this is hard throttled at onnce every 30 minutes."])
		self:CommMessage("REQALLNOTES", "GUILD")
	end
end

-- Send our gear to somebody else
function Sync:SendPlayersGear(sender, override)
	if( not override and not ElitistGroup.db.profile.comm.gearRequests ) then return end
	
	-- Players info should rarely change, so we can just cache it and that will be all we need most of the time
	if( not cachedPlayerData ) then
		ElitistGroup.modules.Scan:UpdatePlayerData("player")
		
		if( ElitistGroup.db.global.main.data and ElitistGroup.db.global.main.character ~= ElitistGroup.playerID ) then
			cachedPlayerData = string.format("GEAR@%s@%s", ElitistGroup:WriteTable(ElitistGroup.userData[ElitistGroup.playerID], true), ElitistGroup.db.global.main.data)
		else
			cachedPlayerData = string.format("GEAR@%s", ElitistGroup:WriteTable(ElitistGroup.userData[ElitistGroup.playerID], true))
		end
	end
	
	self:CommMessage(cachedPlayerData, "WHISPER", sender)
end

-- COMMUNICATION PARSERS
function Sync:SendAllNotes(sender)
	local queuedData = ""
	local NOTE_MATCH = string.format("[\"%s\"]={(.-)};", string.gsub(ElitistGroup.playerID, "%-", "%%-"))
	for name, userData in pairs(ElitistGroup.db.faction.users) do
		if( rawget(ElitistGroup.userData, name) ) then
			local userData = ElitistGroup.userData[name]
			if( userData.notes[ElitistGroup.playerID] ) then
				queuedData = string.format('%s["%s"]=%s;', queuedData, ElitistGroup.playerID, ElitistGroup:WriteTable(userData.notes[ElitistGroup.playerID]))
			end
		else
			local note = userData and string.match(userData, NOTE_MATCH)
			note = note and string.match(note, "={(.+);$")
			if( note and note ~= "" ) then
				queuedData = string.format('%s["%s"]={%s};', queuedData, name, note)
			end
		end
	end
	
	if( queuedData ~= "" ) then
		self:CommMessage(string.format("NOTES@%d@{%s}", time(), queuedData), "WHISPER", sender)
	end
end

-- Received a notes request, send off whatever we have
function Sync:SpecificNotesRequested(sender, ...)
	if( select("#", ...) == 0 or select("#", ...) > 25 ) then return end

	local queuedData = ""
	local NOTE_MATCH = string.format("[\\\"%s\\\"]={(.-)};", ElitistGroup.playerID)
	for i=1, select("#", ...) do
		local name = select(i, ...)
		if( name ~= ElitistGroup.playerID ) then
			if( rawget(ElitistGroup.userData, name) ) then
				local userData = ElitistGroup.userData[name]
				if( userData.notes[ElitistGroup.playerID] ) then
					queuedData = string.format('%s["%s"]=%s;', queuedData, name, ElitistGroup:WriteTable(userData.notes[ElitistGroup.playerID]))
				end
			else
				local userData = ElitistGroup.db.faction.users[name]
				local note = userData and string.match(userData, NOTE_MATCH)
				note = note and string.match(note, "={(.+);$")
				if( note ) then
					queuedData = string.format('%s["%s"]={%s};', queuedData, name, note)
				end
			end
		end
	end
	
	if( queuedData ~= "" ) then
		self:CommMessage(string.format("NOTES@%d@{%s}", time(), queuedData), "WHISPER", sender)
	end
end

-- Parse the notes somebody sent us
function Sync:ParseSentNotes(sender, currentTime, senderTime, data)
	senderTime = tonumber(senderTime)
	if( not senderTime or not data ) then return end

	local sentNotes, msg = loadstring("return " .. data)
	if( not sentNotes ) then
		--[===[@debug@
		error(string.format("Failed to load sent notes: %s", msg), 3)
		--@end-debug@]===]
		return
	end
	
	local noteTable = setfenv(sentNotes, emptyEnv)() or false
	if( not noteTable ) then return end
	
	-- time() can differ between players, will have the player send their time so it can be calibrated
	-- this is still maybe 2-3 seconds off, but better 2-3 seconds off than hours
	local timeDrift = senderTime - currentTime
	local senderName, name, server = getFullName(sender)
	
	for noteFor, note in pairs(noteTable) do
		self:VerifyTable(note, ElitistGroup.VALID_NOTE_FIELDS)
		if( type(note) == "table" and type(noteFor) == "string" and note.time and note.role and note.rating and string.match(noteFor, "%-") and senderName ~= noteFor and ( not note.comment or string.len(note.comment) <= ElitistGroup.MAX_NOTE_LENGTH ) ) then
			local name, server = string.split("-", noteFor, 2)
			local userData = ElitistGroup.userData[noteFor]
			if( not userData ) then
				userData = {notes = {}, achievements = {}, equipment = {}}
				userData.name = name
				userData.server = server
				userData.scanned = time()
				userData.from = senderName
				userData.level = -1
				userData.pruned = true
			end
			
			-- If the time drift is over a day, reset the time of the comment to right now
			note.time = timeDrift > 86400 and time() or note.time + timeDrift
			note.comment = note.comment
			note.from = senderName
			note.rating = math.max(math.min(5, note.rating), 1)
			
			userData.notes[senderName] = note
			
			ElitistGroup.userData[noteFor] = userData
			ElitistGroup.db.faction.users[noteFor] = ElitistGroup.db.faction.users[noteFor] or ""
			ElitistGroup.writeQueue[noteFor] = true

			self:SendMessage("EG_DATA_UPDATED", "note", noteFor)
		end
	end
end

-- Parse the gear somebody sent
local function parseGear(senderName, playerID, playerName, playerServer, data, isSelf)
	-- Convert it into a table
	local sentData, msg = loadstring("return " .. data)
	if( not sentData ) then
		--[===[@debug@
		error(string.format("Failed to load sent data: %s", msg), 3)
		--@end-debug@]===]
		return
	end
	
	local sentData = setfenv(sentData, emptyEnv)() or false
	if( not sentData ) then return end

	Sync:VerifyTable(sentData, ElitistGroup.VALID_DB_FIELDS)
	if( not sentData or not sentData.achievements or not sentData.equipment ) then return end
	
	-- Verify gear
	for key, value in pairs(sentData.equipment) do
		if( type(key) ~= "number" or type(value) ~= "string" or not string.match(value, "item:(%d+)") or string.len(value) > ElitistGroup.MAX_LINK_LENGTH or not ElitistGroup.Items.validInventorySlots ) then
			sentData.equipment[key] = nil
		end
	end
	
	-- Verify achievements
	for key, value in pairs(sentData.achievements) do
		if( type(key) ~= "number" or type(value) ~= "number" or not ElitistGroup.Dungeons.achievements[key] ) then
			sentData.achievements[key] = nil
		else
			local flags = select(9, GetAchievementInfo(key))
			if( bit.band(flags, ACHIEVEMENT_FLAGS_STATISTIC) == 0 ) then
				sentData.achievements[key] = value >= 1 and 1 or nil
			else
				sentData.achievements[key] = math.max(sentData.achievements[key], 0)
			end
		end
	end
	
	-- Verify talent data
	if( sentData.secondarySpec ) then
		Sync:VerifyTable(sentData.secondarySpec, ElitistGroup.VALID_TALENT_FIELDS)
		
		local hasData
		for key in pairs(sentData.secondarySpec) do
			hasData = true
			break
		end
		
		if( not hasData ) then
			sentData.secondarySpec = nil
		end
	end
			
	-- Merge everything into the current table
	local userData = ElitistGroup.userData[playerID] or {}
	local notes = userData.notes or {}

	-- Finalize it all
	table.wipe(userData)

	for key, value in pairs(sentData) do userData[key] = value end
	userData.name = playerName
	userData.server = playerServer
	userData.notes = notes
	userData.scanned = time()
	userData.from = senderName
		
	ElitistGroup.writeQueue[playerID] = true
	ElitistGroup.userData[playerID] = userData
	ElitistGroup.db.faction.users[playerID] = ElitistGroup.db.faction.users[playerID] or ""

	Sync:SendMessage("EG_DATA_UPDATED", "gear", playerID)
	if( ElitistGroup.db.profile.general.announceData and isSelf ) then
		ElitistGroup:Print(string.format(L["Gear received from %s."], playerID))
	end
end

function Sync:ParseSelfSentGear(sender, data, mainExperience)
	-- If the player already scanned data on this person from within 10 minutes, don't accept the comm
	local playerID, playerName, playerServer = getFullName(sender)
	local userData = ElitistGroup.userData[playerID]
	if( userData and userData.from ~= ElitistGroup.playerID and userData.scanned and userData.scanned > (time() - 600) ) then
		return
	end
	
	parseGear(playerID, playerID, playerName, playerServer, data, true)
	
	-- Loadup main experience too
	if( mainExperience and mainExperience ~= "" ) then
		self:ParseMainExperience(sender, string.split("@", mainExperience))
	end
end

function Sync:SendDatabaseList(sender)
	-- We're not accepting database requests, exit quickly
	if( not ElitistGroup:IsTrusted(sender) or not ElitistGroup.db.profile.comm.databaseSync ) then
		self:CommMessage("LISTERR@DISABLED", "WHISPER", sender)
		return
	end
	
	local userList = ""
	local fromPlayer = string.format("from=\"%s\";", string.gsub(ElitistGroup.playerID, "%-", "%%-"))
	for playerID, data in pairs(ElitistGroup.db.faction.users) do
		if( rawget(ElitistGroup.userData, playerID) ) then
			local userData = ElitistGroup.userData[playerID]
			if( not userData.pruned and userData.from == ElitistGroup.playerID and data.scanned ) then
				userList = string.format("%s@%s@%s", userList, playerID, time() - data.scanned)
			end
		elseif( not string.match(data, "pruned=true;") and string.match(data, fromPlayer) ) then
			local scanned = tonumber(string.match(data, "scanned=(%d+);"))
			if( scanned ) then
				userList = string.format("%s@%s@%s", userList, playerID, time() - scanned)
			end
		end
	end
	
	if( userList == "" ) then
		self:CommMessage("LISTERR@NONE", "WHISPER", sender)
	else
		self:CommMessage(string.format("USERLIST%s", userList), "WHISPER", sender)
	end
end

-- Parse their data and see what we want
function Sync:QueueDatabaseRequests(sender, ...)
	-- Reset the queue we had for this person, they should only really send one of these
	for playerID, target in pairs(requestQueue) do
		if( target == sender ) then
			requestQueue[playerID] = nil
		end
	end
		
	-- Parse out the list
	for i=1, select("#", ...), 2 do
		local playerID, secondsOld = select(i, ...)
		secondsOld = tonumber(secondsOld)
		-- Do some basic checking to make sure nothing bad is going down
		if( playerID and secondsOld and secondsOld > 0 and string.match(playerID, "%-") and playerID ~= ElitistGroup.playerID ) then
			-- Now make sure it's not too old
			local daysOld = math.floor(secondsOld / 86400)
			if( daysOld < ElitistGroup.db.profile.comm.databaseThreshold ) then
				-- Find out if we don't have data that takes priority
				local userData = ElitistGroup.userData[playerID]
				if( userData and not userData.pruned and userData.level >= 0 and ( userData.talentTree1 ~= 0 or userData.talentTree2 ~= 0 or userData.talentTree3 ~= 0 ) ) then
					local scanAge = time() - userData.scanned
					if( not scanned or scanAge > secondsOld ) then
						requestQueue[playerID] = sender
					end
				else
					requestQueue[playerID] = sender
				end
			end
		end
	end
	
	-- Now request a user from the queue
	for playerID, target in pairs(requestQueue) do
		if( target == sender ) then
			self:CommMessage(string.format("REQOTHGEAR@%s", playerID), "WHISPER", target)
			requestQueue[playerID] = nil
			break
		end
	end
end

function Sync:SendOthersGear(sender, playerID)
	if( not playerID or not ElitistGroup.db.faction.users[playerID] ) then return end
	local userData = ElitistGroup.db.faction.users[playerID]
	-- Strip out notes before sending it
	userData = string.gsub(userData, "notes={(.-);};};", "")
	userData = string.gsub(userData, "notes={};", "")
	
	self:CommMessage(string.format("GEAROTH@%s@%s", playerID, userData), "WHISPER", sender)
end

function Sync:ParseOthersGear(sender, playerID, data)
	local playerName, playerServer = string.match(playerID, "(.-)%-(.+)")
	if( not playerName or not playerServer ) then return end
	
	parseGear(getFullName(sender), playerID, playerName, playerServer, data)
	
	requestQueue[playerID] = nil
	
	-- Now request a user from the queue
	-- The reason I do a request user -> send user -> request user -> send user -> repeat is so if one of the users
	-- goes offline during the transaction we don't have a large queue of 10KB+ that has to basically be spammed and sent
	-- even if they were offline, it also means that if either one of them goes into combat it will pause and queue itself
	-- instead of continuning to send and requiring more parsing or a larger queue
	for playerID, target in pairs(requestQueue) do
		if( target == sender ) then
			self:CommMessage(string.format("REQOTHGEAR@%s", playerID), "WHISPER", target)
			requestQueue[playerID] = nil
			break
		end
	end
end

function Sync:ListReqErrored(sender, type)
	if( not expectingList ) then return nil end
	expectingList = nil
	
	if( type == "NONE" ) then
		ElitistGroup:Print(string.format(L["%s does not have any users to send you."], sender))
	elseif( type == "DISABLED" ) then
		ElitistGroup:Print(string.format(L["%s either disabled database syncing, or you are not on their trusted list."], sender))
	end
end

-- Alt/main handling
function Sync:ParseMainExperience(sender, ...)
	local playerID, playerName, playerServer = getFullName(sender)
	local userData = ElitistGroup.userData[playerID]
	if( not userData ) then
		userData = {notes = {}, achievements = {}, equipment = {}}
		userData.name = playerName
		userData.server = playerServer
		userData.scanned = time()
		userData.from = playerID
		userData.level = -1
		userData.pruned = nil

		ElitistGroup.db.faction.users[playerID] = ""
		ElitistGroup.userData[playerID] = userData
	end
	
	userData.mainAchievements = userData.mainAchievements or {}
	table.wipe(userData.mainAchievements)
	for i=1, select("#", ...), 2 do
		local achievementID, earned = select(i, ...)
		achievementID = tonumber(achievementID)
		earned = tonumber(earned)

		if( achievementID and earned and ElitistGroup.Dungeons.achievements[achievementID] ) then
			local flags = select(9, GetAchievementInfo(achievementID))
			if( bit.band(flags, ACHIEVEMENT_FLAGS_STATISTIC) == 0 ) then
				earned = earned >= 1 and 1 or nil
			elseif( earned <= 0 ) then
				earned = nil
			end

			userData.mainAchievements[achievementID] = earned
		end
	end
	
	ElitistGroup.writeQueue[playerID] = true
	self:SendMessage("EG_DATA_UPDATED", "mainExp", playerID)
end

function Sync:SendMainExperience(sender)
	if( not ElitistGroup.db.global.main.data or ElitistGroup.db.global.main.character == ElitistGroup.playerID ) then return end
	self:CommMessage(string.format("MAIN@%s", ElitistGroup.db.global.main.data), "WHISPER", sender)
end

-- Handle the actual comm
function Sync:OnCommReceived(prefix, message, distribution, sender, currentTime)
	if( prefix ~= COMM_PREFIX or sender == playerName or not ElitistGroup.db.profile.comm.areas[distribution] ) then return end
	if( InCombatLockdown() ) then
		if( #(combatQueue) < MAX_QUEUE ) then
			table.insert(combatQueue, {message, distribution, sender, time()})
			self:RegisterEvent("PLAYER_REGEN_ENABLED")
		end
		return
	end
	
	local cmd, args = string.split("@", message, 2)
	--[[
		Throttling is currently:
		
		Responding to requests for our gear - 5 minutes
		Responding to requests for our notes on specific people - 10 minutes
		Requesting all notes - 30 minutes
		Responding to requests for database - 60 minutes
		Parsing/queuing database list requests - 58 minutes
		Parsing somebodies gear or notes - 30 seconds
		Requesting mains data - 60 minutes
		Parsing main data - 60 seconds
	]]
	
	-- REQGEAR - Requests your currently equipped data in case you are out of inspection range
	if( cmd == "REQGEAR" and not self:IsThrottled(sender, "myGear") ) then
		self:SetThrottle(sender, "myGear", 300)
		self:SendPlayersGear(sender)
	
	-- REQMAIN - Requests only the main experience data
	elseif( cmd == "REQMAIN" and not self:IsThrottled(sender, "mainReq") ) then
		self:SetThrottle(sender, "mainReq", 3600)
		self:SendMainExperience(sender)
		
	-- MAIN@data - Gets the experience data of the players main
	elseif( cmd == "MAIN" and args and not self:IsThrottled(sender, "main") ) then
		self:SetThrottle(sender, "main", 60)
		self:ParseMainExperience(sender, string.split("@", args))
	
	-- LISTERR@type - There was an error when requesting list data
	elseif( cmd == "LISTERR" and args ) then
		self:ListReqErrored(sender, args)
	
	-- REQALLNOTES - Requests all notes
	elseif( cmd == "REQALLNOTES" and ElitistGroup:IsTrusted(sender) and not self:IsThrottled(sender, "fullNotes") ) then
		self:SetThrottle(sender, "fullNotes", 1800)
		self:SendAllNotes(sender)
	
	-- REQNOTES@playerA@playerBplayerC@etc - Request notes on the given players
	elseif( cmd == "REQNOTES" and args and not self:IsThrottled(sender, "notes") ) then
		self:SetThrottle(sender, "notes", 600)
		self:SpecificNotesRequested(sender, string.split("@", args))

	-- REQUSERS - Tells the person that you want their delicious and tasty database
	elseif( cmd == "REQUSERS" and not self:IsThrottled(sender, "fullReq") ) then
		self:SetThrottle(sender, "fullReq", 3600)
		self:SendDatabaseList(sender)

	-- USERLIST@playerID@secondsOld... - Used in response to REQUSERS, let's us figure out what data will want
	elseif( cmd == "USERLIST" and args and ElitistGroup:IsTrusted(sender) and ElitistGroup.db.profile.comm.databaseSync and not self:IsThrottled(sender, "reqList") ) then
		self:SetThrottle(sender, "reqList", 3500)
		self:QueueDatabaseRequests(sender, string.split("@", args))
	
	-- REQOTHGEAR@playerID - Used in response to a USERLIST indicating what user we want
	elseif( cmd == "REQOTHGEAR" and args and ElitistGroup:IsTrusted(sender) and ElitistGroup.db.profile.comm.databaseSync ) then
		self:SendOthersGear(sender, string.split("@", args))
	
	-- GEAROTH@<name>@<data> - Somebody is sending you somebody elses gear
	elseif( cmd == "GEAROTH" and args and ElitistGroup:IsTrusted(sender) and ElitistGroup.db.profile.comm.databaseSync ) then
		self:ParseOthersGear(sender, string.split("@", args))
	
	-- GEAR@<serialized table of the persons gear>
	elseif( cmd == "GEAR" and args and not self:IsThrottled(sender, "gear") ) then
		self:SetThrottle(sender, "gear", 30)
		self:ParseSelfSentGear(sender, string.split("@", args, 2))
	
	-- NOTES@:<serialized table of the notes on the people requested through REQNOTES
	elseif( cmd == "NOTES" and args and ElitistGroup:IsTrusted(sender) and not self:IsThrottled(sender, "notes") ) then
		self:SetThrottle(sender, "notes", 30)
		self:ParseSentNotes(sender, currentTime or time(), string.split("@", args))
	end
end

-- If the fact that the comm is not delayed causes issues, then will have to fix it
function Sync:PLAYER_REGEN_ENABLED()
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	
	for i=#(combatQueue), 1, -1 do
		local data = table.remove(combatQueue, i)
		self:OnCommReceived(COMM_PREFIX, data[1], data[2], data[3], data[4])
	end
end

function Sync:CommMessage(message, channel, target)
	if( ElitistGroup.db.profile.comm.enabled ) then
		if( channel == "WHISPER" ) then
			self:EnableOfflineBlock(target)
		end
		
		self:SendCommMessage(COMM_PREFIX, message, channel, target)
	end
end