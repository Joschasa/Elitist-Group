local ElitistGroup = select(2, ...)
local Cache = ElitistGroup:NewModule("Cache", "AceEvent-3.0")

local CACHE_TIMEOUT = 30 * 60
local statCache, itemMetaTable, gemMetaTable, emptyGemMetaTable, enchantMetaTable = {}
local lastCache = GetTime() + CACHE_TIMEOUT
local ItemData = ElitistGroup.Items

function Cache:OnInitialize()
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

-- Item caching alone will result in 100 entries in ~7 summaries, auto inspecting a party makes this about once every two instances
-- once we do it for raids, it'll be even more so at a certain point we want to wipe our caches and let the garbage collector do it's job
function Cache:PLAYER_ENTERING_WORLD()
	if( lastCache > GetTime() ) then return end
	lastCache = GetTime() + CACHE_TIMEOUT
	
	statCache = {}
	ElitistGroup.ENCHANT_TALENTTYPE = setmetatable({}, enchantMetaTable)
	ElitistGroup.GEM_TALENTTYPE = setmetatable({}, gemMetaTable)
	ElitistGroup.EMPTY_GEM_SLOTS = setmetatable({}, emptyGemMetaTable)
	ElitistGroup.ITEM_TALENTTYPE = setmetatable({}, itemMetaTable)
end

local tooltip = CreateFrame("GameTooltip", "ElitistGroupScanTooltip", UIParent, "GameTooltipTemplate")
tooltip:SetOwner(UIParent, "ANCHOR_NONE")

local function parseText(text)
	text = string.gsub(text, "%%d", "%%d+")
	text = string.gsub(text, "%%s", ".+")
	return string.lower(text)
end

local ITEM_SPELL_TRIGGER_ONEQUIP = parseText(ITEM_SPELL_TRIGGER_ONEQUIP)
local ITEM_SPELL_TRIGGER_ONPROC = parseText(ITEM_SPELL_TRIGGER_ONPROC)
local ITEM_SPELL_TRIGGER_ONUSE = parseText(ITEM_SPELL_TRIGGER_ONUSE)
local ITEM_ONEQUIP = "^" .. parseText(ITEM_SPELL_TRIGGER_ONEQUIP)
local RESILIENCE_MATCH = parseText(ITEM_MOD_RESILIENCE_RATING_SHORT)

-- Yay metatable caching, can only get gem totals via tooltip scanning, GetItemStats won't return a prismatic socketed item
emptyGemMetaTable = {
	__index = function(tbl, link)
		tooltip:SetOwner(UIParent, "ANCHOR_NONE")
		tooltip:SetHyperlink(link)

		local total = 0
		for i=1, MAX_NUM_SOCKETS do
			local texture = _G["ElitistGroupScanTooltipTexture" .. i]
			if( texture and texture:IsVisible() ) then
				total = total + 1
			end
		end
		
		rawset(tbl, link, total)
		return total
	end,
}

-- Find the item type based on stats used
local function matchStats(overrideType)
	local totalStats = 0
	for key in pairs(statCache) do totalStats = totalStats + 1 end
	
	for i=1, #(ItemData.statTalents) do
		local data = ItemData.statTalents[i]
		-- Only use this if other stats are present
		if( not data.require or ( statCache[data.require] or ( data.require2 and statCache[data.require2] ) ) ) then
			-- Only use this if it's the exclusive stat, for matching things like pure MP5 gems, not hybrids
			if( not data.exclusive or totalStats == 1 ) then
				-- Skip this if the stat is present
				if( not data.skipOn or ( not statCache[data.skipOn] and ( not data.skipOn2 or not statCache[data.skipOn2] ) ) ) then
					local statString = data.default or data[overrideType]
					if( data[overrideType] and data.default ) then statString = statString .. data[overrideType] end
					
					if( statString ) then
						for statKey in string.gmatch(statString, "(.-)@") do
							if( statCache[ItemData.statMap[statKey]] ) then
								return data.type
							end
						end
					end
				end
			end
		end
	end
	
	return "unknown"
end

gemMetaTable = {
	__index = function(tbl, link)
		local itemID = link and tonumber(string.match(link, "item:(%d+)"))
		if( itemID and ItemData.itemOverrides[itemID] ) then
			rawset(tbl, link, ItemData.itemOverrides[itemID])
			return ItemData.itemOverrides[itemID]
		elseif( not itemID or not GetItemInfo(itemID) ) then
			rawset(tbl, link, "unknown")
			return "unknown"
		end
		
		local foundData
		table.wipe(statCache)
		
		tooltip:SetOwner(UIParent, "ANCHOR_NONE")
		tooltip:SetHyperlink(link)

		for i=1, tooltip:NumLines() do
			local text = string.lower(_G["ElitistGroupScanTooltipTextLeft" .. i]:GetText())
			for i=1, #(ItemData.orderedStatMap) do
				local key = ItemData.orderedStatMap[i]
				if( string.match(text, ItemData.safeStatMatch[key]) ) then
					foundData = true
					statCache[key] = true
				end
			end
			
			if( foundData ) then break end
		end
		
		if( not foundData ) then
			rawset(tbl, link, "unknown")
			return "unknown"
		end

		rawset(tbl, link, matchStats("gems"))
		return rawget(tbl, link)
	end,
}

-- Note: Regular enchants show up above sockets and below the items base stats. Engineering enchants are at the very bottom :|
-- Because of how engineering enchants are done, we cannot scan for them. They have to be manually overridden cause Blizzard are jerks.
enchantMetaTable = {
	__index = function(tbl, link)
		local enchantID = tonumber(link)
		local type = not enchantID and "unknown" or enchantID == 0 and "none" or ItemData.enchantOverrides[enchantID]
		if( type ) then
			rawset(tbl, link, type)
			return type
		end
		
		-- The reason for using a hardcoded item is it gives us a more consistent set of data to work off of
		-- this means we can rely on the location of an enchant because we know 100% where they will be located.
		-- I would actually rather use something like Worn Dagger, or another piece of gear that has zero green text on it except gems
		-- but I'm worried there might be issues if the item is not immediately available due to not being cached, whereas Hearthstone is always available.
		tooltip:SetOwner(UIParent, "ANCHOR_NONE")
		tooltip:SetHyperlink(string.format("item:6948:%d", enchantID))

		local enchantText
		for i=1, tooltip:NumLines() do
			local text = string.lower(_G["ElitistGroupScanTooltipTextLeft" .. i]:GetText())
			local r, g, b = _G["ElitistGroupScanTooltipTextLeft" .. i]:GetTextColor()
									
			-- If we don't find the enchant up top, but we know one exists then it's an engineering enchant, which means the next line will have the enchant in it
			if( string.match(text, ITEM_SPELL_TRIGGER_ONUSE) ) then
				if( tooltip:NumLines() > i ) then
					enchantText = string.lower(_G["ElitistGroupScanTooltipTextLeft" .. i + 1]:GetText())
				end
				break
			-- First green text we find that isn't the Use: is the enchant
			elseif( ( r >= 0.97 and g < 0.15 and b < 0.15 ) or ( r == 0 and g >= 0.97 and b == 0 ) ) then
				enchantText = text
				break
			end	
		end
		
		if( not enchantText ) then
			rawset(tbl, link, "unknown")
			return "unknown"
		end
				
		-- Parse out the stats
		local foundData
		table.wipe(statCache)
		for i=1, #(ItemData.orderedStatMap) do
			local key = ItemData.orderedStatMap[i]
			if( string.match(enchantText, ItemData.safeStatMatch[key]) ) then
				foundData = true
				statCache[key] = true
			end
		end
		
		if( not foundData ) then
			rawset(tbl, link, "unknown")
			return "unknown"
		end
		
		rawset(tbl, link, matchStats("enchants"))
		return rawget(tbl, link)
	end,
}

local function getRelicSpecType(link)
	tooltip:SetOwner(UIParent, "ANCHOR_NONE")
	tooltip:SetHyperlink(link)
		
	local equipText
	for i=tooltip:NumLines(), 1, -1 do
		local text = string.lower(_G["ElitistGroupScanTooltipTextLeft" .. i]:GetText())
		if( string.match(text, ITEM_ONEQUIP) ) then
			equipText = text
			break
		end
	end
	
	if( not equipText ) then
		return "unknown"
	elseif( string.match(equipText, RESILIENCE_MATCH) ) then
		return "pvp"
	end

	-- Some relics can be forced into a type by spell, eg Rejuvenation means it's obviously for healers
	-- some relics... actually realy only ferals, are classified as hybrid by doing two things which
	-- is where the stat scanning comes into play
	for spell, type in pairs(ItemData.relicSpells) do
		if( string.match(equipText, spell) ) then
			return type
		end
	end
	
	-- Failed to find the relic type, scan for stats and see if we can identify it that way
	table.wipe(statCache)
	for i=1, #(ItemData.orderedStatMap) do
		local key = ItemData.orderedStatMap[i]
		if( string.match(equipText, ItemData.safeStatMatch[key]) ) then
			statCache[key] = true
		end
	end
	
	return matchStats("relic")
end

itemMetaTable = {
	__index = function(tbl, link)
		local itemID = tonumber(string.match(link, "item:(%d+)"))
		if( itemID and ItemData.itemOverrides[itemID] ) then
			rawset(tbl, link, ItemData.itemOverrides[itemID])
			return ItemData.itemOverrides[itemID]
		end
		
		local inventoryType = select(9, GetItemInfo(link))
		local equipType = inventoryType and ItemData.equipToType[inventoryType]
		if( not equipType ) then 
			rawset(tbl, link, "unknown")
			return "unknown"
		-- Relics need special handling, because they do not have passive stats :(
		elseif( inventoryType == "INVTYPE_RELIC" ) then
			local itemType = getRelicSpecType(link)
			
			rawset(tbl, link, itemType)
			return itemType
		end
		
		table.wipe(statCache)
		GetItemStats(link, statCache)

		-- Failed to identify the item, check everything
		if( inventoryType == "INVTYPE_TRINKET" ) then
			-- Basically. 99% of trinkets say the stat they increase, regardless of whether it's "chance to increase spell power by X every 20 seconds"
			-- so will find that part of the text and scan it to try and identify what kind of item it is, we only do this if we failed to find it through the stats
			tooltip:SetOwner(UIParent, "ANCHOR_NONE")
			tooltip:SetHyperlink(link)
			
			local statText
			for i=tooltip:NumLines(), 1, -1 do
				local row = _G["ElitistGroupScanTooltipTextLeft" .. i]
				local r, g, b = row:GetTextColor()
				
				if( r == 0 and g > 0.97 and b == 0 ) then
					local text = string.lower(row:GetText())
					if( string.match(text, ITEM_SPELL_TRIGGER_ONEQUIP) or string.match(text, ITEM_SPELL_TRIGGER_ONPROC) or string.match(text, ITEM_SPELL_TRIGGER_ONUSE) ) then
						statText = text
						break
					end
				end
			end
			
			-- Yay we found the enchant proc
			if( statText ) then
				for i=1, #(ItemData.orderedStatMap) do
					local key = ItemData.orderedStatMap[i]
					if( string.match(statText, ItemData.safeStatMatch[key]) ) then
						statCache[key] = true
					end
				end
			end
		end
		
		rawset(tbl, link, matchStats(equipType))
		return rawget(tbl, link)
	end,
}

ElitistGroup.ENCHANT_TALENTTYPE = setmetatable({}, enchantMetaTable)
ElitistGroup.GEM_TALENTTYPE = setmetatable({}, gemMetaTable)
ElitistGroup.EMPTY_GEM_SLOTS = setmetatable({}, emptyGemMetaTable)
ElitistGroup.ITEM_TALENTTYPE = setmetatable({}, itemMetaTable)