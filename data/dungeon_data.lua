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
		L["T7 Dungeons"],					200, 5,		"heroic",
		L["Sartharion"],					200, 10,	"normal",
		L["Naxxramas"],						200, 10,	"normal",
		L["Archavon, Vault"],				200, 10,	"normal",
		L["Naxxramas"],						213, 25,	"normal",
		L["Malygos"], 						213, 10,	"normal",
		L["Archavon, Vault"],				213, 25,	"normal",
		L["T9 Dungeons"],					219, 5,		"heroic",
		L["Ulduar"], 						219, 10,	"normal",
		L["Emalon, Vault"],					219, 10,	"normal",
		L["Ulduar"], 						226, 25,	"normal",
		L["Emalon, Vault"], 				226, 25,	"normal",
		L["Malygos"], 						226, 25,	"normal",
		L["Sartharion"], 					226, 25,	"normal",
		L["Ulduar"],						226, 10,	"hard",
		L["T10 Dungeons"], 					232, 5,		"heroic",
		L["Koralon, Vault"],				232, 10,	"normal",
		L["Trial of the Crusader"],			232, 10,	"normal",
		L["Onyxia's Lair"], 				232, 10,	"normal",
		L["Ulduar"],						239, 25,	"hard",
		L["Onyxia's Lair"], 				245, 25,	"normal",
		L["Koralon, Vault"], 				245, 25,	"normal",
		L["Trial of the Crusader"],			245, 25,	"normal",
		L["Trial of the Grand Crusader"],	245, 10,	"heroic",
		L["Icecrown Citadel"], 				251, 10,	"normal",
		L["The Ruby Sanctum"],				258, 10,	"normal",
		L["Trial of the Grand Crusader"],	258, 25,	"heroic",
		L["Icecrown Citadel"], 				264, 25,	"normal", 
		L["Icecrown Citadel"],				264, 10,	"heroic",
		L["The Ruby Sanctum"],				271, 25,	"normal",
		L["The Ruby Sanctum"],				271, 10,	"heroic",
		L["Icecrown Citadel"], 				277, 25,	"heroic",
		L["The Ruby Sanctum"],				284, 25,	"heroic",
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
		
		-- T7 Dungeons, 5 man, heroic (Drak'Tharon Keep, Violet Hold, etc)
		{name = L["T7 Dungeons"], childOf = "5-man", id = "t7-heroic", heroic = true, childless = true, players = 5,
			experienced = 30, -- 6 full clears
			[1504] = 5, -- Ingvar the Plunderer kills (Heroic Utgarde Keep)
			[1505] = 5, -- Keristrasza kills (Heroic Nexus)
			[1506] = 5, -- Anub'arak kills (Heroic Azjol-Nerub)
			[1507] = 5, -- Herald Volazj kills (Heroic Ahn'kahet)
			[1508] = 5, -- The Prophet Tharon'ja kills (Heroic Drak'Tharon Keep)
			[1509] = 5, -- Cyanigosa kills (Heroic Violet Hold)
			[1510] = 5, -- Gal'darah kills (Heroic Gundrak)
			[1511] = 5, -- Sjonnir the Ironshaper kills (Heroic Halls of Stone)
			[1512] = 5, -- Loken kills (Heroic Halls of Lightning)
			[1513] = 5, -- Ley-Guardian Eregos kills (Heroic Oculus)
			[1514] = 5, -- King Ymiron kills (Heroic Utgarde Pinnacle)
			[1515] = 5, -- Mal'Ganis defeated (Heroic CoT: Stratholme)
			[2136] = 50, -- Glory of the Hero
		},

		-- T9 Dungeons, 5 man (Trial of the Champion)
		{name = L["T9 Dungeons"], childOf = "5-man", id = "t8-5m", heroic = true, childless = true, players = 5,
			experienced = 15,
			[4027] = 5, -- The Black Knight kills (Heroic Trial of the Champion)
		},

		-- T10 Dungeons, 5 man, heroic
		{name = L["T10 Dungeons"], childOf = "5-man", id = "t10-5m", heroic = true, childless = true, players = 5,
			experienced = 90, -- Works out to about a clear in each dungeon
			[4714] = 2, -- Bronjahm kills (Heroic Forge of Souls)
			[4716] = 8, -- Devourer of Souls kills (Heroic Forge of Souls)
			[4519] = 10, -- Heroic: The Forge of Souls
			[4719] = 1, -- Ick and Krick kills (Heroic Pit of Saron)
			[4721] = 2, -- Scourgelord Tyrannus kills (Heroic Pit of Saron)
			[4728] = 7, -- Forgemaster Garfrost kills (Heroic Pit of Saron)
			[4520] = 10, -- Heroic: The Pit of Saron
			[4723] = 2, -- Falric kills (Heroic Halls of Reflection)
			[4725] = 2, -- Marwyn kills (Heroic Halls of Reflection)
			[4727] = 5, -- Lich King escapes (Heroic Halls of Reflection)
			[4521] = 10, -- Heroic: The Halls of Reflection
		},
		
		-- 10 man dungeons
		{name = L["Raids"], parent = true, id = "10-man", players = 10},
		{name = L["Naxxramas"], childOf = "10-man", id = "naxx-10m", players = 10,
			experienced = 130, -- 1 full clear
			[1361] = 2, -- Anub'Rekhan kills (Naxxramas 10 player)
			[1362] = 2, -- Grand Widow Faerlina kills (Naxxramas 10 player)
			[1363] = 6, -- Maexxna kills (Naxxramas 10 player)
			[1364] = 1, -- Patchwerk kills (Naxxramas 10 player)
			[1371] = 1, -- Grobbulus kills (Naxxramas 10 player)
			[1372] = 2, -- Gluth kills (Naxxramas 10 player)
			[1373] = 6, -- Thaddius kills (Naxxramas 10 player)
			[1365] = 2, -- Noth the Plaguebringer kills (Naxxramas 10 player)
			[1369] = 2, -- Heigan the Unclean kills (Naxxramas 10 player)
			[1370] = 6, -- Loatheb kills (Naxxramas 10 player)
			[1374] = 2, -- Instructor Razuvious kills (Naxxramas 10 player)
			[1366] = 2, -- Gothik the Harvester kills (Naxxramas 10 player)
			[1375] = 6, -- Four Horsemen kills (Naxxramas 10 player)
			[1376] = 10, -- Sapphiron kills (Naxxramas 10 player)
			[1377] = 15, -- Kel'Thuzad kills (Naxxramas 10 player)
			[576] = 65, -- The Fall of Naxxramas (10 player)
			[2187] = 65, -- The Undying
		},
		{name = L["Sartharion"], childOf = "10-man", id = "sarth-10m", players = 10,
			experienced = 10, -- 3 kills or a 3-drake kill
			[1392] = 10, -- Sartharion kills (Chamber of the Aspects 10 player)
			[2051] = 30, -- The Twilight Zone (10 player)
		},
		{name = L["Malygos"], childOf = "10-man", id = "malygos-10m", players = 10,
			experienced = 10, -- 3 kills or a sub-6 minute kill
			[1391] = 10, -- Malygos kills (10 player)
			[1874] = 30, -- You Don't Have An Eternity (10 player)
		},
		{name = L["Ulduar"], childOf = "10-man", id = "ulduar-10m-n", players = 10,
			experienced = 240, -- 3 full clears, 2 with Champion of Ulduar, Algalon is a bonus
			[2856] = 1, -- Flame Leviathan kills (Ulduar 10 player)
			[2857] = 1, -- Razorscale kills (Ulduar 10 player)
			[2858] = 1, -- Ignis the Furnace Master kills (Ulduar 10 player)
			[2859] = 2, -- XT-002 Deconstructor kills (Ulduar 10 player)
			[2860] = 3, -- Assembly of Iron kills (Ulduar 10 player)
			[2868] = 1, -- Auriaya kills (Ulduar 10 player)
			[2861] = 1, -- Kologarn kills (Ulduar 10 player)
			[2862] = 5, -- Hodir victories (Ulduar 10 player)
			[2863] = 5, -- Thorim victories (Ulduar 10 player)
			[2864] = 5, -- Freya victories (Ulduar 10 player)
			[2865] = 5, -- Mimiron victories (Ulduar 10 player)
			[2866] = 10, -- General Vezax kills (Ulduar 10 player)
			[2869] = 15, -- Yogg-Saron kills (Ulduar 10 player)
			[2867] = 15, -- Algalon the Observer kills (Ulduar 10 player)
			[2894] = 60, -- The Secrets of Ulduar (10 player)
			[2903] = 60, -- Champion of Ulduar
		},
		-- Right now, the ToC10 and ToCG10 completion stats are bugged, going to include them so data is recorded, but it's worth 0 right now
		{name = L["Trial of the Crusader"], childOf = "10-man", id = "toc-10m", players = 10,
			experienced = 40, -- Slightly wonky, first 4 bosses killed 3 times, with one being a full clear
			[4028] = 1, -- Victories over the Beasts of Northrend (Trial of the Crusader 10 player)
			[4032] = 2, -- Lord Jaraxxus kills (Trial of the Crusader 10 player)
			[4036] = 3, -- Victories over the Faction Champions (Trial of the Crusader 10 player)
			[4040] = 4, -- Val'kyr Twins kills (Trial of the Crusader 10 player)
			[4044] = 0, -- Times completed the Trial of the Crusader (10 player)
			[3917] = 10, -- Call of the Crusade (10 player)
		},
		{name = L["Onyxia's Lair"], childOf = "10-man", id = "onyxia-10m", players = 10,
			experienced = 10,
			[4396] = 10, -- Onyxia's Lair (10 player)
		},
		
		{name = L["Icecrown Citadel"], childOf = "10-man", id = "icc-10m-n", players = 10,
			experienced = 195, -- 3 full clears
			cap = {[4639] = 10, [4643] = 10, [4644] = 10, [4645] = 10},
			[4639] = 1, -- Lord Marrowgar kills (Icecrown 10 player)
			[4643] = 1, -- Lady Deathwhisper kills (Icecrown 10 player)
			[4644] = 1, -- Gunship Battle victories (Icecrown 10 player)
			[4645] = 1, -- Deathbringer kills (Icecrown 10 player)
			[4646] = 1, -- Festergut kills (Icecrown 10 player)
			[4647] = 2, -- Rotface kills (Icecrown 10 player)
			[4650] = 5, -- Professor Putricide kills (Icecrown 10 player)
			[4648] = 2, -- Blood Prince Council kills (Icecrown 10 player)
			[4651] = 5, -- Blood Queen Lana'thel kills (Icecrown 10 player)
			[4649] = 2, -- Valithria Dreamwalker rescues (Icecrown 10 player)
			[4652] = 5, -- Sindragosa kills (Icecrown 10 player)
			[4653] = 30, -- Victories over the Lich King (Icecrown 10 player)
			--[4527] = 5, -- The Frostwing Halls (10 player)
			--[4528] = 5, -- The Plagueworks (10 player)
			--[4529] = 5, -- The Crimson Hall (10 player)
			--[4531] = 5, -- Storming the Citadel (10 player)
			[4532] = 45, -- Fall of the Lich King (10 player)
		},
		
		{name = L["The Ruby Sanctum"], childOf = "10-man", id = "trs-10m-n", players = 10,
			experienced = 45,
			[4821] = 5, -- Halion kills (Ruby Sanctum 10 player)
			[4817] = 30, --  The Twilight Destroyer (10 player)
		},
		

		{name = L["Vault of Archavon"], childOf = "10-man", id = "voa-10m", players = 10, subParent = true,
			experienced = 120, -- 4 full clears, or three with Toravon
			[4016] = 20, -- Earth, Wind & Fire (10 player)
		},
		{name = L["Archavon the Stone Watcher"], childOf = "voa-10m", id = "arch-10m", players = 10,
			experienced = 5,
			[1753] = 5, -- Archavon the Stone Watcher kills (Wintergrasp 10 player)
		},
		{name = L["Emalon the Storm Watcher"], childOf = "voa-10m", id = "emal-10m", players = 10,
			experienced = 10,
			[2870] = 10, -- Emalon the Storm Watcher kills (Wintergrasp 10 player)
		},
		{name = L["Koralon the Flame Watcher"], childOf = "voa-10m", id = "kora-10m", players = 10,
			experienced = 15,
			[4074] = 15, -- Koralon the Flame Watcher kills (Wintergrasp 10 player)
		},
		{name = L["Toravon the Ice Watcher"], childOf = "voa-10m", id = "tora-10m", players = 10,
			experienced = 40,
			[4657] = 20, -- Toravon the Ice Watcher kills (Wintergrasp 10 player)
		},
			
		-- 25 man raids
		{name = L["Raids"], parent = true, id = "25-man", players = 25},
		{name = L["Naxxramas"], childOf = "25-man", id = "naxx-25m", players = 25,
			experienced = 130, -- 1 full clear
			[1368] = 2, -- Anub'Rekhan kills (Naxxramas 25 player)
			[1380] = 2, -- Grand Widow Faerlina kills (Naxxramas 25 player)
			[1386] = 6, -- Maexxna kills (Naxxramas 25 player)
			[1367] = 1, -- Patchwerk kills (Naxxramas 25 player)
			[1381] = 1, -- Grobbulus kills (Naxxramas 25 player)
			[1378] = 2, -- Gluth kills (Naxxramas 25 player)
			[1388] = 6, -- Thaddius kills (Naxxramas 25 player)
			[1387] = 2, -- Noth the Plaguebringer kills (Naxxramas 25 player)
			[1382] = 2, -- Heigan the Unclean kills (Naxxramas 25 player)
			[1385] = 6, -- Loatheb kills (Naxxramas 25 player)
			[1384] = 2, -- Instructor Razuvious kills (Naxxramas 25 player)
			[1379] = 2, -- Gothik the Harvester kills (Naxxramas 25 player)
			[1383] = 6, -- Four Horsemen kills (Naxxramas 25 player)
			[1389] = 10, -- Sapphiron kills (Naxxramas 25 player)
			[1390] = 15, -- Kel'Thuzad kills (Naxxramas 25 player)
			[577] = 70, -- The Fall of Naxxramas (25 player)
			[2186] = 70, -- The Immortal
		},
		{name = L["Sartharion"], childOf = "25-man", id = "sarth-25m", players = 25,
			experienced = 10, -- 3 kills or 3-drake
			[1393] = 10, -- Sartharion kills (Chamber of the Aspects 25 player)
			[2054] = 30, -- The Twilight Zone (25 player)
		},
		{name = L["Malygos"], childOf = "25-man", id = "malygos-25m", players = 25,
			experienced = 10,
			[1394] = 10, -- Malygos kills (25 player)
			[1875] = 30, -- You Don't Have An Eternity (25 player)
		},
		{name = L["Ulduar"], childOf = "25-man", id = "ulduar-25m-n", players = 25,
			experienced = 240, -- 3 full clears, 2 with Conqueror of Ulduar, Algalon is a bonus
			[2872] = 1, -- Flame Leviathan kills (Ulduar 25 player)
			[2873] = 1, -- Razorscale kills (Ulduar 25 player)
			[2874] = 1, -- Ignis the Furnace Master kills (Ulduar 25 player)
			[2884] = 2, -- XT-002 Deconstructor kills (Ulduar 25 player)
			[2885] = 3, -- Assembly of Iron kills (Ulduar 25 player)
			[2882] = 1, -- Auriaya kills (Ulduar 25 player)
			[2875] = 1, -- Kologarn kills (Ulduar 25 player)
			[2879] = 5, -- Mimiron victories (Ulduar 25 player)
			[3256] = 5, -- Hodir victories (Ulduar 25 player)
			[3257] = 5, -- Thorim victories (Ulduar 25 player)
			[3258] = 5, -- Freya victories (Ulduar 25 player)
			[2880] = 10, -- General Vezax kills (Ulduar 25 player)
			[2883] = 15, -- Yogg-Saron kills (Ulduar 25 player)
			[2881] = 15, -- Algalon the Observer kills (Ulduar 25 player)
			[2895] = 60, -- The Secrets of Ulduar (25 player)
			[2904] = 60, -- Conqueror of Ulduar
		},
		{name = L["Trial of the Crusader"], childOf = "25-man", id = "toc-25m", players = 25,
			experienced = 40, -- 3 full clears
			[4031] = 0, -- Victories over the Beasts of Northrend (Trial of the Crusader 25 player)
			[4034] = 1, -- Lord Jaraxxus kills (Trial of the Crusader 25 player)
			[4038] = 1, -- Victories over the Faction Champions (Trial of the Crusader 25 player)
			[4042] = 2, -- Val'kyr Twins kills (Trial of the Crusader 25 player)
			[4046] = 6, -- Times completed the Trial of the Crusader (25 player)
			[3916] = 10, -- Call of the Crusade (25 player)
		},
		{name = L["Onyxia's Lair"], childOf = "25-man", id = "onyxia-25m", players = 25,
			experienced = 10,
			[4397] = 10, -- Onyxia's Lair (25 player)
		},
		{name = L["Icecrown Citadel"], childOf = "25-man", id = "icc-25m-n", players = 25,
			experienced = 195, -- 3 full clears
			cap = {[4641] = 10, [4655] = 10, [4660] = 10, [4663] = 10},
			[4641] = 1, -- Lord Marrowgar kills (Icecrown 25 player)
			[4655] = 1, -- Lady Deathwhisper kills (Icecrown 25 player)
			[4660] = 1, -- Gunship Battle victories (Icecrown 25 player)
			[4663] = 1, -- Deathbringer kills (Icecrown 25 player)
			[4666] = 1, -- Festergut kills (Icecrown 25 player)
			[4669] = 2, -- Rotface kills (Icecrown 25 player)
			[4678] = 5, -- Professor Putricide kills (Icecrown 25 player)
			[4672] = 2, -- Blood Prince Council kills (Icecrown 25 player)
			[4681] = 5, -- Blood Queen Lana'thel kills (Icecrown 25 player)
			[4675] = 2, -- Valithria Dreamwalker rescues (Icecrown 25 player)
			[4683] = 5, -- Sindragosa kills (Icecrown 25 player)
			[4687] = 30, -- Victories over the Lich King (Icecrown 25 player)
			--[4604] = 0, -- Storming the Citadel (25 player)
			--[4605] = 0, -- The Plagueworks (25 player)
			--[4606] = 0, -- The Crimson Hall (25 player)
			--[4607] = 0, -- The Frostwing Halls (25 player)
			[4608] = 45, -- Fall of the Lich King (25 player)
		},
		{name = L["The Ruby Sanctum"], childOf = "25-man", id = "trs-25m-n", players = 25,
			experienced = 45,
			[4820] = 5, -- Halion kills (Ruby Sanctum 25 player)
			[4815] = 30, -- The Twilight Destroyer (25 player)
		},
		
		
		{name = L["Vault of Archavon"], childOf = "25-man", id = "voa-25m", players = 25, subParent = true,
			experienced = 120, -- 4 full clears, or three with Toravon
			[4017] = 20, -- Earth, Wind & Fire (25 player)
		},
		{name = L["Archavon the Stone Watcher"], childOf = "voa-25m", id = "arch-25m", players = 25,
			experienced = 5,
			[1754] = 5, -- Archavon the Stone Watcher kills (Wintergrasp 25 player)
		},
		{name = L["Emalon the Storm Watcher"], childOf = "voa-25m", id = "emal-25m", players = 25,
			experienced = 10,
			[3236] = 10, -- Emalon the Storm Watcher kills (Wintergrasp 25 player)
		},
		{name = L["Koralon the Flame Watcher"], childOf = "voa-25m", id = "kora-25m", players = 25,
			experienced = 15,
			[4075] = 15, -- Koralon the Flame Watcher kills (Wintergrasp 25 player)
		},
		{name = L["Toravon the Ice Watcher"], childOf = "voa-25m", id = "tora-25m", players = 25,
			experienced = 20,
			[4658] = 20, -- Toravon the Ice Watcher kills (Wintergrasp 25 player)
		},

			-- 10 man heroic/hard mode raids
		{name = L["Raids"], parent = true, id = "10-man-hard", players = 10, heroic = true},
		{name = L["Ulduar"], childOf = "10-man-hard", heroic = true, id = "ulduar-10m-h", cascade = "ulduar-10m-n", players = 10,
			experienced = 60, -- 4 of the 7 hard modes, or one zero light + two other misc hard modes
			[2941] = 15, -- I Choose You, Steelbreaker (10 player)
			[3056] = 5, -- Orbit-uary (10 player)
			[3058] = 10, -- Heartbreaker (10 player)
			[3158] = 25, -- One Light in the Darkness (10 player)
			[3159] = 40, -- Alone in the Darkness (10 player)
			[3179] = 15, -- Knock, Knock, Knock on Wood (10 player)
			[3180] = 15, -- Firefighter (10 player)
			[3181] = 15, -- I Love the Smell of Saronite in the Morning (10 player)
			[3004] = 25, -- He Feeds On Your Tears (10 player)
		},
		{name = L["Trial of the Grand Crusader"], childOf = "10-man-hard", id = "togc-10m", cascade = "toc-10m", heroic = true, players = 10,
			experienced = 50, -- first 4 bosses killed 4 times with one full clear, 3 with >=45 attempts, 1 with 50 attempts
			[4030] = 1, -- Victories over the Beasts of Northrend (Trial of the Grand Crusader 10 player)
			[4033] = 2, -- Lord Jaraxxus kills (Trial of the Grand Crusader 10 player)
			[4037] = 3, -- Victories over the Faction Champions (Trial of the Grand Crusader 10 player)
			[4041] = 4, -- Val'kyr Twins kills (Trial of the Grand Crusader 10 player)
			[4045] = 0, -- Times completed the Trial of the Grand Crusader (10 player)
			[3918] = 10, -- Call of the Grand Crusade (10 player)
			[3809] = 10, -- A Tribute to Mad Skill (10 player)
			[3810] = 30, -- A Tribute to Insanity (10 player)
			[4080] = 30, -- A Tribute to Dedicated Insanity
		},
		{name = L["Icecrown Citadel"], childOf = "10-man-hard", id = "icc-10m-h", cascade = "icc-10m-n", heroic = true, players = 10,
			experienced = 125, -- 1 full clear
			cap = {[4640] = 5, [4659] = 5, [4668] = 5, [4671] = 5},
			[4640] = 1, -- Lord Marrowgar kills (Heroic Icecrown 10 player)
			[4654] = 5, -- Lady Deathwhisper kills (Heroic Icecrown 10 player)
			[4659] = 1, -- Gunship Battle victories (Heroic Icecrown 10 player)
			[4662] = 2, -- Deathbringer kills (Heroic Icecrown 10 player)
			[4665] = 2, -- Festergut kills (Heroic Icecrown 10 player)
			[4668] = 1, -- Rotface kills (Heroic Icecrown 10 player)
			[4677] = 5, -- Professor Putricide kills (Heroic Icecrown 10 player)
			[4671] = 1, -- Blood Prince Council kills (Heroic Icecrown 10 player)
			[4680] = 5, -- Blood Queen Lana'thel kills (Heroic Icecrown 10 player)
			[4674] = 2, -- Valithria Dreamwalker rescues (Heroic Icecrown 10 player)
			[4684] = 7, -- Sindragosa kills (Heroic Icecrown 10 player)
			[4686] = 15, -- Victories over the Lich King (Heroic Icecrown 10 player)
			--[4628] = 0, -- Heroic: Storming the Citadel (10 player)
			--[4629] = 0, -- Heroic: The Plagueworks (10 player)
			--[4630] = 0, -- Heroic: The Crimson Hall (10 player)
			--[4631] = 0, -- Heroic: The Frostwing Halls (10 player)
			[4636] = 45, -- Heroic: Fall of the Lich King (10 player)
		},
		{name = L["The Ruby Sanctum"], childOf = "10-man-hard", id = "trs-10m-h", cascade = "trs-10m-n", heroic = true, players = 10,
			experienced = 45,
			[4822] = 5, -- Halion kills (Heroic Ruby Sanctum 10 player)
			[4818] = 30, -- Heroic: The Twilight Destroyer (10 player)
		},
		
		{name = L["Raids"], parent = true, id = "25-man-hard", players = 25, heroic = true},
		{name = L["Ulduar"], childOf = "25-man-hard", id = "ulduar-25m-h", cascade = "ulduar-25m-n", heroic = true, players = 25,
			experienced = 60, -- 4 of the 7 hard modes, or one zero light + two other misc hard modes
			[2944] = 15, -- I Choose You, Steelbreaker (25 player)
			[3057] = 5, -- Orbit-uary (25 player)
			[3059] = 10, -- Heartbreaker (25 player)
			[3163] = 25, -- One Light in the Darkness (25 player)
			[3164] = 40, -- Alone in the Darkness (25 player)
			[3187] = 15, -- Knock, Knock, Knock on Wood (25 player)
			[3188] = 15, -- I Love the Smell of Saronite in the Morning (25 player)
			[3189] = 15, -- Firefighter (25 player)
			[3005] = 25, -- He Feeds On Your Tears (25 player)
		},
		{name = L["Trial of the Grand Crusader"], childOf = "25-man-hard", id = "togc-25m", cascade = "toc-25m", heroic = true, players = 25,
			experienced = 50, -- 4 full clears, or 3 full clears + mad skill, 1 full clear + insanity
			[4029] = 1, -- Victories over the Beasts of Northrend (Trial of the Grand Crusader 25 player)
			[4035] = 1, -- Lord Jaraxxus kills (Trial of the Grand Crusader 25 player)
			[4039] = 2, -- Victories over the Faction Champions (Trial of the Grand Crusader 25 player)
			[4043] = 3, -- Val'kyr Twins kills (Trial of the Grand Crusader 25 player)
			[4047] = 5, -- Times completed the Trial of the Grand Crusader (25 player)
			[3812] = 10, -- Call of the Grand Crusade (25 player)
			[3818] = 10, -- A Tribute to Mad Skill (25 player)
			[3819] = 30, -- A Tribute to Insanity (25 player)
		},
		{name = L["Icecrown Citadel"], childOf = "25-man-hard", id = "icc-25m-h", cascade = "icc-25m-n", heroic = true, players = 25,
			experienced = 125, -- 1 full clear
			cap = {[4642] = 5, [4661] = 5, [4670] = 5, [4673] = 5},
			[4642] = 1, -- Lord Marrowgar kills (Heroic Icecrown 25 player)
			[4656] = 5, -- Lady Deathwhisper kills (Heroic Icecrown 25 player)
			[4661] = 1, -- Gunship Battle victories (Heroic Icecrown 25 player)
			[4664] = 2, -- Deathbringer kills (Heroic Icecrown 25 player)
			[4667] = 2, -- Festergut kills (Heroic Icecrown 25 player)
			[4670] = 1, -- Rotface kills (Heroic Icecrown 25 player)
			[4679] = 5, -- Professor Putricide kills (Heroic Icecrown 25 player)
			[4673] = 1, -- Blood Prince Council kills (Heroic Icecrown 25 player)
			[4682] = 5, -- Blood Queen Lana'thel kills (Heroic Icecrown 25 player)
			[4676] = 2, -- Valithria Dreamwalker rescues (Heroic Icecrown 25 player)
			[4685] = 7, -- Sindragosa kills (Heroic Icecrown 25 player)
			[4688] = 15, -- Victories over the Lich King (Heroic Icecrown 25 player)
			--[4632] = 0, -- Heroic: Storming the Citadel (25 player)
			--[4633] = 0, -- Heroic: The Plagueworks (25 player)
			--[4634] = 0, -- Heroic: The Crimson Hall (25 player)
			--[4635] = 0, -- Heroic: The Frostwing Halls (25 player)
			[4637] = 45, -- Heroic: Fall of the Lich King (25 player)
		},
		{name = L["The Ruby Sanctum"], childOf = "25-man-hard", id = "trs-25m-h", cascade = "trs-25m-n", heroic = true, players = 25,
			experienced = 45,
			[4823] = 5, -- Halion kills (Heroic Ruby Sanctum 25 player)
			[4816] = 30, -- Heroic: The Twilight Destroyer (25 player)
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
