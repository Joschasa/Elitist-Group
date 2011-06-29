local ElitistGroup = select(2, ...)
local L = ElitistGroup.L
local CURRENT_BUILD = tonumber((select(2, GetBuildInfo()))) or 0

local function loadData()
	local Dungeons = ElitistGroup.Dungeons
	-- normal/heroic is for separating the dungeons like TotC/TotGC, hard will be for dungeons like Ulduar or Sartharion with hard modes on heroic
	Dungeons.types = {["normal"] = L["Normal"], ["heroic"] = L["Heroic"], ["hard"] = L["Hard"]}
	
	local dungeonBuild = {
	}
		
	Dungeons.suggested = {
		-- thinking about removing this feature...we'll see...
		-- name, ilvl, raid, difficulty
		L["T11 Dungeons"],					333, false, "heroic",
		L["T11.5 Dungeons"],					346, false, "heroic",
		L["Baradin Hold"],					359, true, "normal",
		L["Bastion of Twilight"],			359, true, "normal",
		L["Blackwing Descent"],				359, true, "normal",
		L["Throne of the Four Winds"],		359, true, "normal",
		L["Bastion of Twilight"],			372, true, "heroic",
		L["Blackwing Descent"],				372, true, "heroic",
		L["Throne of the Four Winds"],		372, true, "heroic",
		L["Firelands"],		378, true, "normal",
		L["Firelands"],		391, true, "heroic",
	}
	
	-- Remove any dungeons that aren't in the game yet
	for i=#(Dungeons.suggested), 1, -4 do
		local name = Dungeons.suggested[i - 3]
		
		if( dungeonBuild[name] and dungeonBuild[name] < CURRENT_BUILD ) then
			table.remove(Dungeons.suggested, i)
			table.remove(Dungeons.suggested, i - 1)
			table.remove(Dungeons.suggested, i - 2)
			table.remove(Dungeons.suggested, i - 3)
		end
	end
	

	local BASE_MOD = 0.91

	Dungeons.minLevel = 1000
	Dungeons.maxLevel = 0
	for i=1, #(Dungeons.suggested), 4 do
		local itemLevel, raid, type = Dungeons.suggested[i + 1], Dungeons.suggested[i + 2], Dungeons.suggested[i + 3]
		local modifier = BASE_MOD
		
		-- raids get a slight modifier compared to 5 mans, heroic modes are also given a slight bump
		if( raid ) then
			modifier = modifier + 0.03
			
			if( type == "heroic" ) then
				modifier = modifier + 0.03
			end
		end
		
		Dungeons.suggested[i + 1] = math.floor(itemLevel * modifier)
		Dungeons.minLevel = math.min(Dungeons.minLevel, Dungeons.suggested[i + 1])
		Dungeons.maxLevel = math.max(Dungeons.maxLevel, Dungeons.suggested[i + 1])
	end

	Dungeons.levelDiff = Dungeons.maxLevel - Dungeons.minLevel

	--[[
		Here's what you need to know about this file:
		Everything needs an id, it has to be unique but a simple t#-#m or name-#m work.
		If you want points from another category to cascade into another use cascade=<to>, <to> being the id.
		Order matters! If you list instance A, B, C, D, E and you setup B and D to cascade to C, then C to cascade to A, it will cascade B/C's combined score into A, but not D.
		You shouldn't want this, so don't mess up ordering!
		
		Currently cascading is setup to do 10 man heroic -> 10 man normal, might also cascade 25 man normal -> 10 man normal, 25 man heroic -> 10 man heroic, but someone is also
		more likely to have been carried through a 25 man than a 10, so not sure if it's "accurate" to cascade that.
	]]
	Dungeons.experience = {
		-- 5 man dungeons
		{name = L["Dungeons"], parent = true, id = "dungeons", heroic = true},
		
		-- T11 Dungeons, 5 man, heroic (Deadmines, Grim Batol, ...)
		{name = L["T11 Dungeons"], childOf = "dungeons", id = "t11-heroic", heroic = true, childless = true,
			experienced = 35, -- 7 full clears
			[5725] = 5, -- Blackrock Caverns
			[5727] = 5, -- Throne of the Tides
			[5729] = 5, -- Stonecore
			[5731] = 5, -- The Vortex Pinnacle
			[5733] = 5, -- Grim Batol
			[5735] = 5, -- Halls of Origination
			[5737] = 5, -- Lost City of the Tol'vir
			[5738] = 5, -- Deadmines
			[5739] = 5, -- Shadowfang Keep
			-- [4844] = 50, -- Cataclysm Dungeon Hero (every Heroic cleared)
			-- [4845] = 100, -- Glory of the Cataclysm Hero (all the achievements ;) )
		},
		{name = L["T11.5 Dungeons"], childOf = "dungeons", id = "t115-heroic", heroic = true, childless = true,
			experienced = 10,
			[5773] = 5, -- Zul'Aman
			[5774] = 5, -- Zul'Gurub
		},
		
		-- raids
		{name = L["Raids"], parent = true, id = "raid"},
		{name = L["Bastion of Twilight"], childOf = "10-man", id = "bot-10m",
			experienced = 50, -- One time cleared
			[5554] = 10, -- Halfus
			[5567] = 10, -- Valiona & Theralion
			[5569] = 10, -- Ascendant Council
			[5572] = 10, -- Cho'Gall
			[4850] = 50, -- "Every Boss killed"-Achievement
		},
		{name = L["Blackwing Descent"], childOf = "raid", id = "blackdesc-10m",
			experienced = 100, -- One time cleared
			[5555] = 10, -- Magmaw
			[5557] = 10, -- Omnotron
			[5559] = 15, -- Maloriak
			[5561] = 15, -- Atramedes
			[5564] = 15, -- Chimaeron
			[5565] = 40, -- Nefarian
			[4842] = 50, -- "Every Boss killed"-Achievement
		},
		{name = L["Throne of the Four Winds"], childOf = "raid", id = "totfw-10m",
			experienced = 50, -- One time cleared
			[5575] = 10, -- Conclave
			[5576] = 20, -- Al'Akir
			[4851] = 50, -- "Every Boss killed"-Achievement
		},
		{name = L["Firelands"], childOf = "raid", id = "fl-10m",
			experienced = 110, -- One time cleared
			[5964] = 10, -- Beth'tilac
			[5966] = 10, -- Lord Rhyolith
			[5970] = 10, -- Alysrazor
			[5968] = 10, -- Shannox
			[5972] = 20, -- Baleroc
			[5974] = 20, -- Majordomo Staghelm
			[5976] = 30, -- Ragnaros
		},		
		{name = L["Baradin Hold"], childOf = "raid", id = "bh-10m", subParent = true,
			experienced = 5, -- every Boss killed once (only one inside atm)
			-- [4016] = 20, -- Earth, Wind & Fire - perhaps there will be some achievement like this again?
		},
		{name = L["Pit Lord Argaloth"], childOf = "bh-10m", id = "argaloth-10m",
			experienced = 50,
			[5578] = 5, -- Pit Lord Argaloth
		},
			
		-- heroic/hard mode raids
		{name = L["Raids"], parent = true, id = "raid-hard", heroic = true},
		{name = L["Bastion of Twilight"], childOf = "raid-hard", id = "bot-10m-h", cascade = "bot-10m", heroic = true,
			experienced = 100,
			[5553] = 10, -- Halfus
			[5568] = 10, -- Valiona & Theralion
			[5570] = 20, -- Ascendant Council
			[5571] = 30, -- Cho'Gall
			[5573] = 50, -- Sinestra
			[5313] = 50, -- Sinestra first attempt without any raid member died
		},
		{name = L["Blackwing Descent"], childOf = "raid-hard", id = "blackdesc-10m-h", cascade = "blackdesc-10m", heroic = true,
			experienced = 40, -- 4 Bosses or Nefarian
			[5556] = 10, -- Magmaw
			[5558] = 10, -- Omnotron
			[5560] = 15, -- Maloriak
			[5562] = 15, -- Atramedes
			[5563] = 15, -- Chimaeron
			[5566] = 40, -- Nefarian
		},
		{name = L["Throne of the Four Winds"], childOf = "raid-hard", id = "totfw-10m-h", cascade = "totfw-10m", heroic = true,
			experienced = 30, -- One time cleared
			[5574] = 10, -- Conclave
			[5577] = 20, -- Al'Akir
		},
		{name = L["Firelands"], childOf = "raid-hard", id = "fl-10m-h", cascade = "fl-10m", heroic = true,
			experienced = 110, -- One time cleared
			[5965] = 10, -- Beth'tilac
			[5967] = 10, -- Lord Rhyolith
			[5971] = 10, -- Alysrazor
			[5969] = 10, -- Shannox
			[5973] = 20, -- Baleroc
			[5975] = 20, -- Majordomo Staghelm
			[5977] = 30, -- Ragnaros
		},	
	}

	-- Remove any dungeons that aren't in the game yet
	for i=#(Dungeons.experience), 1, -1 do
		local data = Dungeons.experience[i]
		if( data.name and dungeonBuild[data.name] and dungeonBuild[data.name] > CURRENT_BUILD ) then
			table.remove(Dungeons.experience, i)
		end
	end
	

	Dungeons.experienceParents = {}
	Dungeons.achievements = {}
	Dungeons.experienceCap = {}
	for _, data in pairs(Dungeons.experience) do
		if( data.subParent ) then
			Dungeons.experienceParents[data.id] = data.childOf
		end
		
		if( data.cap ) then
			for achievementID, cap in pairs(data.cap) do
				Dungeons.experienceCap[achievementID] = cap
			end
		end
		
		for achievementID, points in pairs(data) do
			if( type(achievementID) == "number" ) then
				Dungeons.achievements[achievementID] = true
			end
		end
	end
end

-- This is a trick I'm experiminating with, basically it automatically loads the data then kills the metatable attached to it
-- so for the cost of a table, I get free loading on demand
ElitistGroup.Dungeons = setmetatable({}, {
	__index = function(tbl, key)
		loadData()
		setmetatable(tbl, nil)
		return tbl[key]
end})
