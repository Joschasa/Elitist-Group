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
		-- L["T7 Dungeons"],					200, 5,		"heroic",
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
	

	local BASE_MOD = 0.89

	Dungeons.minLevel = 1000
	Dungeons.maxLevel = 0
	for i=1, #(Dungeons.suggested), 4 do
		local itemLevel, players, type = Dungeons.suggested[i + 1], Dungeons.suggested[i + 2], Dungeons.suggested[i + 3]
		local modifier = BASE_MOD
		
		-- 10/25 mans get a slight modifier compared to 5 mans, hard/heroic mdoes are also given a slight bump
		if( players >= 10 ) then
			modifier = modifier + 0.01
			
			if( type == "heroic" or type == "hard" ) then
				modifier = modifier + 0.01
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
		{name = L["Dungeons"], parent = true, id = "5-man", players = 5, heroic = true},
		
		-- T11 Dungeons, 5 man, heroic (Deadmines, Grim Batol, ...)
		{name = L["T11 Dungeons"], childOf = "5-man", id = "t11-heroic", heroic = true, childless = true, players = 5,
			experienced = 35, -- 7 full clears
			-- Since there are no statistic (# of kills for every last boss), i'll use the normal achievements here.
			[5060] = 5, -- Blackrock Caverns
			[5061] = 5, -- Throne of the Tides
			[5062] = 5, -- Grim Batol
			[5063] = 5, -- Stonecore
			[5064] = 5, -- The Vortex Pinnacle
			[5065] = 5, -- Halls of Origination
			[5066] = 5, -- Lost City of the Tol'vir
			[5083] = 5, -- Deadmines
			[5093] = 5, -- Shadowfang Keep
			-- [4844] = 50, -- Cataclysm Dungeon Hero (every Heroic cleared)
			-- [4845] = 100, -- Glory of the Cataclysm Hero (all the achievements ;) )
		},
		
		-- raids
		{name = L["Raids"], parent = true, id = "10-man", players = 10},
		{name = L["Bastion of Twilight"], childOf = "10-man", id = "bot-10m", players = 10,
			experienced = 50, -- One time cleared
			[4850] = 50, -- "Every Boss killed"-Achievement
		},
		{name = L["Blackwing Descent"], childOf = "10-man", id = "blackdesc-10m", players = 10,
			experienced = 50, -- One time cleared
			[4842] = 50, -- "Every Boss killed"-Achievement
		},
		{name = L["Throne of the Four Winds"], childOf = "10-man", id = "totfw-10m", players = 10,
			experienced = 50, -- One time cleared
			[4851] = 50, -- "Every Boss killed"-Achievement
		},
		{name = L["Baradin Hold"], childOf = "10-man", id = "bh-10m", players = 10, subParent = true,
			experienced = 5, -- every Boss killed once (only one inside atm)
			-- [4016] = 20, -- Earth, Wind & Fire (10 player)
		},
		{name = L["Pit Lord Argaloth"], childOf = "bh-10m", id = "argaloth-10m", players = 10,
			experienced = 5,
			[5416] = 5, -- Archavon the Stone Watcher kills (Wintergrasp 10 player)
		},
			
		-- heroic/hard mode raids
		{name = L["Raids"], parent = true, id = "10-man-hard", players = 10, heroic = true},
		{name = L["Bastion of Twilight"], childOf = "10-man-hard", id = "bot-10m-h", cascade = "bot-10m", players = 10,
			experienced = 50, -- 2 + Cho'Gall or Sinestra
			[5118] = 10, -- Halfus
			[5117] = 10, -- Valiona & Theralion
			[5119] = 10, -- Council
			[5120] = 30, -- Cho'Gall
			[5121] = 50, -- Sinestra
			[5313] = 50, -- Sinestra first attempt without any raid member died
		},
		{name = L["Blackwing Descent"], childOf = "10-man-hard", id = "blackdesc-10m-h", cascade = "blackdesc-10m", players = 10,
			experienced = 40, -- 4 Bosses or Nefarian
			[5094] = 10, -- Magmaw
			[5107] = 10, -- Omnotron Defense System
			[5115] = 10, -- Chimaeron
			[5108] = 10, -- Maloriak
			[5109] = 10, -- Atramedes
			[5116] = 40, -- Nefarian
		},
		{name = L["Throne of the Four Winds"], childOf = "10-man-hard", id = "totfw-10m-h", cascade = "totfw-10m", players = 10,
			experienced = 30, -- One time cleared
			[5122] = 10, -- Conclave of Wind
			[5123] = 20, -- Al'Akir
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
