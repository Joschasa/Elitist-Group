local ElitistGroup = select(2, ...)
local L = ElitistGroup.L
local _G = getfenv(0)

local function loadData()
	local Items = ElitistGroup.Items
	-- While it's true that we could apply additional modifiers like 1.05 for legendaries, it's not really necessary because legendaries aren't items
	-- that people have 70% of their equipment as that need a modifier to separate them.
	Items.qualityModifiers = {
		[ITEM_QUALITY_POOR] = 0.50,
		[ITEM_QUALITY_COMMON] = 0.60,
		[ITEM_QUALITY_UNCOMMON] = 0.90,
		[ITEM_QUALITY_RARE] = 0.95,
		[ITEM_QUALITY_EPIC] = 1,
	}

	-- Specific override, epic items must have a rare or higher quality gem in them
	Items.gemQualities = {
		[ITEM_QUALITY_EPIC] = ITEM_QUALITY_RARE,
	}

	-- Item level of heirlooms based on the player's level. Currently this is ~2.22/per player level, meaning they work out to 187 item level blues at 80
	-- with the quality modifier they are item level ~177
	-- This will have to change come Cataclysm, not quite sure how Blizzard is going to handle heirlooms then
	-- History: Changed from (187 / 80) to (333 / 85) in Cataclysm. Should be enough...i want to look for potential raid members, not non hero dungeons
	Items.heirloomLevel = (333 / 85)

	Items.inventoryToID = {
		["HeadSlot"] = "head", ["ChestSlot"] = "chest", ["RangedSlot"] = "ranged",
		["WristSlot"] = "wrists", ["Trinket1Slot"] = "trinkets", ["Trinket0Slot"] = "trinkets",
		["MainHandSlot"] = "weapons", ["SecondaryHandSlot"] = "weapons", ["Finger0Slot"] = "rings",
		["Finger1Slot"] = "rings", ["NeckSlot"] = "neck", ["FeetSlot"] = "boots", ["LegsSlot"] = "legs",
		["WaistSlot"] = "waist", ["HandsSlot"] = "hands", ["BackSlot"] = "cloak", ["ShoulderSlot"] = "shoulders",
	}
	
	Items.validInventorySlots = {}
	for slotType in pairs(Items.inventoryToID) do
		Items.validInventorySlots[GetInventorySlotInfo(slotType)] = slotType
	end
	
	Items.SubTypeSlots = {
		["HeadSlot"] = "head", ["ShoulderSlot"] = "shoulders", ["ChestSlot"] = "chest",
		["WristSlot"] = "wrists", ["HandsSlot"] = "hands", ["WaistSlot"] = "waist",		
		["LegsSlot"] = "legs", ["FeetSlot"] = "boots",
	}
	
	Items.validSubTypeSlots = {}
	for slotType in pairs(Items.SubTypeSlots) do
		Items.validSubTypeSlots[GetInventorySlotInfo(slotType)] = slotType
	end

	Items.classToValidSubType = {
		["SHAMAN"] = L["Mail"],
		["MAGE"] = L["Cloth"],
		["WARLOCK"] = L["Cloth"],
		["DRUID"] = L["Leather"],
		["WARRIOR"] = L["Plate"],
		["ROGUE"] = L["Leather"],
		["PALADIN"] = L["Plate"],
		["HUNTER"] = L["Mail"],
		["PRIEST"] = L["Cloth"],
		["DEATHKNIGHT"] = L["Plate"],
	}

	-- Yes, technically you can enchant rings. But we can't accurately figure out if the person is an enchanter
	-- while we will rate the enchant if one is present, it won't be flagged as they don't have it enchanted
	-- Setting a class token means that it's unenchantable for everyone except that class
	Items.unenchantableTypes = {
		["INVTYPE_NECK"] = true, ["INVTYPE_FINGER"] = true, ["INVTYPE_TRINKET"] = true, ["INVTYPE_HOLDABLE"] = true, ["INVTYPE_THROWN"] = true, ["INVTYPE_RELIC"] = true, ["INVTYPE_WAIST"] = true,
		["INVTYPE_RANGEDRIGHT"] = "HUNTER",
		["INVTYPE_RANGED"] = "HUNTER",
	}

	Items.equipToType = {
		["INVTYPE_RANGEDRIGHT"] = "ranged", ["INVTYPE_SHIELD"] = "weapons", ["INVTYPE_WEAPONOFFHAND"] = "weapons",
		["INVTYPE_RANGED"] = "ranged", ["INVTYPE_WEAPON"] = "weapons", ["INVTYPE_2HWEAPON"] = "weapons",
		["INVTYPE_WRIST"] = "wrists", ["INVTYPE_TRINKET"] = "trinkets", ["INVTYPE_NECK"] = "neck",
		["INVTYPE_CLOAK"] = "cloak", ["INVTYPE_HEAD"] = "head", ["INVTYPE_FEET"] = "boots",
		["INVTYPE_SHOULDER"] = "shoulders", ["INVTYPE_WAIST"] = "waist", ["INVTYPE_WEAPONMAINHAND"] = "weapons",
		["INVTYPE_FINGER"] = "rings", ["INVTYPE_THROWN"] = "ranged", ["INVTYPE_HAND"] = "hands",
		["INVTYPE_RELIC"] = "ranged", ["INVTYPE_HOLDABLE"] = "weapons", ["INVTYPE_LEGS"] = "legs",
		["INVTYPE_ROBE"] = "chest", ["INVTYPE_CHEST"] = "chest",
	}

	Items.itemRoleText = {
		["pvp"] = L["PVP"],
		["healer"] = L["Healer (All)"],
		["caster-dps"] = L["DPS (Caster)"],
		["caster"] = L["Caster (All)"],
		["tank"] = L["Tank"],
		["unknown"] = L["Unknown"],
		["melee-dps"] = L["DPS (Melee)"],
		["range-dps"] = L["DPS (Ranged)"],
		["physical-dps"] = L["DPS (Physical)"],
		["melee-agi"] = L["Melee (Agi)"],
		["melee-str"] = L["Melee (Str)"],
		["never"] = L["Always bad"],
		["dps"] = L["DPS (All)"],
		["healer/dps"] = L["Healer/DPS"],
		["tank/dps"] = L["Tank/DPS"],
		["all"] = L["All"],
		["physical-all"] = L["Physical (All)"],
		["tank/pvp"] = L["Tank/PVP"],
		["caster-spirit"] = L["Caster (Spirit)"],
		["situational-caster"] = L["situational (Caster)"],
		["situational-healer"] = L["situational (Healer)"],
		["manaless"] = L["Healing Priest/Druid"],
		["tank/ranged"] = L["Tank/Ranged DPS"],
		["elemental/pvp"] = L["PVP/Elemental Shaman"],
	}

	local function mergeTable(into, ...)
		for i=1, select("#", ...) do
			local key = select(i, ...)
			if( type(key) == "table" ) then
				for subKey in pairs(key) do
					into[subKey] = true
				end
			else
				into[key] = true
			end
		end
		
		return into
	end
	
	-- Set the primary spec arch types
	local tank = {
		["all"] = true,
		["tank"] = true, 
		["melee"] = true, 
		["physical-all"] = true, 
		["tank/dps"] = true, 
		["tank/ranged"] = true, 
		["tank/pvp"] = true,
	}
	local casterDamage = {
		["all"] = true, 
		["caster-dps"] = true, 
		["caster"] = true, 
		["healer/dps"] = true, 
		["tank/dps"] = true, 
		["dps"] = true, 
	}
	local meleeDamage = {
		["all"] = true, 
		["melee"] = true, 
		["melee-dps"] = true, 
		["physical-dps"] = true, 
		["physical-all"] = true, 
		["tank/dps"] = true, 
		["healer/dps"] = true, 
		["dps"] = true
	}
	local rangeDamage = {
		["all"] = true, 
		["range-dps"] = true, 
		["tank/ranged"] = true, 
		["physical-dps"] = true, 
		["physical-all"] = true, 
		["healer/dps"] = true, 
		["tank/dps"] = true, 
		["dps"] = true,
		["melee-agi"] = true,
	}
	local healer = {
		["all"] = true, 
		["healer"] = true, 
		["caster"] = true, 
		["healer/dps"] = true,
		["caster-spirit"] = true,
	}
	local hybridCaster = mergeTable({}, casterDamage, "caster-spirit")
	local meleeDamageAgi = mergeTable({}, meleeDamage, "melee-agi")
	local meleeDamageStr = mergeTable({}, meleeDamage, "melee-str")

	-- Now define type by spec
	Items.talentToRole = {
		-- Shamans
		["elemental-shaman"] = mergeTable({}, hybridCaster, "elemental/pvp"),
		["enhance-shaman"] = meleeDamageAgi,
		["resto-shaman"] = healer, 
		-- Mages
		["arcane-mage"] = casterDamage,
		["fire-mage"] = casterDamage,
		["frost-mage"] = casterDamage,
		-- Warlocks
		["afflict-warlock"] = casterDamage,
		["demon-warlock"] = casterDamage,
		["destro-warlock"] = casterDamage,
		-- Druids
		["balance-druid"] = hybridCaster,
		["cat-druid"] = meleeDamageAgi,
		["bear-druid"] = mergeTable({}, meleeDamageAgi, tank),
		["resto-druid"] = healer,
		-- Warriors
		["arms-warrior"] = meleeDamageStr,
		["fury-warrior"] = meleeDamageStr,
		["prot-warrior"] = mergeTable({}, meleeDamageStr, tank),
		-- Rogues
		["assass-rogue"] = meleeDamageAgi,
		["combat-rogue"] = meleeDamageAgi,
		["subtlety-rogue"] = meleeDamageAgi,
		-- Paladins
		["holy-paladin"] = healer,
		["prot-paladin"] = mergeTable({}, meleeDamageStr, tank),
		["ret-paladin"] = meleeDamageStr,
		-- Hunters
		["beast-hunter"] = rangeDamageAgi,
		["marks-hunter"] = rangeDamageAgi,
		["survival-hunter"] = rangeDamageAgi,
		-- Priests
		["disc-priest"] = healer,
		["holy-priest"] = healer,
		["shadow-priest"] = hybridCaster,
		-- Death Knights
		["blood-dk"] = mergeTable({}, meleeDamageStr, tank),
		["frost-dk"] = meleeDamageStr,
		["unholy-dk"] = meleeDamageStr,
	}

	-- This will likely have to be cleaned up, but for now this will allow overrides on what is allowed based on slot
	Items.roleOverrides = {
		["blood-dk"] = {type = "weapons", ["physical-dps"] = true, ["dps"] = true, ["melee-dps"] = true}
	}

	local function getSpell(id)
		local name = GetSpellInfo(id)
		if( not name ) then
			print(string.format("Failed to find spell id #%d.", id or 0))
			return "<error>"
		end
		
		return string.lower(name)
	end

	-- As with some items, some enchants have special text that doesn't tell you what they do so we need manual flagging
	Items.enchantOverrides = {
		-- Tailoring
		[4115] = "caster", -- Lightweave Embroidery Rank 2 - 580 Int
		[4116] = "healer", -- Darkglow Embroidery Rank 2 - 580 Spi
		[4118] = "physical-all", -- Swordguard Embroidery Rank 2 - 1000 AP
		
		-- Leatherworking
		[4127] = "tank", -- Charscale Leg Armor
		
		-- Old Enchants
		[1896] = "never", -- Lifestealing
		[1900] = "never", -- Crusader
		[2613] = "never", -- Enchant Gloves - Threat 
		[2621] = "never", -- Enchant Cloak - Subtlety 
		[2673] = "never", -- Mongoose
		[2674] = "never", -- Spellsurge 
		[2675] = "never", -- Battlemaster 
		[2939] = "never", -- Cat's Swiftness 
		[2940] = "never", -- Boar's Speed 
		[3225] = "never", -- Executioner
		[3232] = "never", -- Tuskarr's Vitality
		[3238] = "never", -- Gatherer 
		[3239] = "never", -- Icebreaker
		[3241] = "never", -- Lifeward
		[3244] = "never", -- Greater Vitality
		[3247] = "never", -- Scourgebane 
		[3251] = "never", -- Giant Slayer 
		[3253] = "never", -- Armsman
		[3731] = "pvp", -- Titanium Weapon Chain
		[3748] = "never", -- Titanium Spike
		[3788] = "never", -- Accuracy
		[3789] = "never", -- Berserking 
		[3790] = "never", -- Black Magic 
		[3826] = "never", -- Icewalker
		[3849] = "never", -- Titanium Plating
		[3852] = "never", -- Greater Inscription of the Gladiator
		[3869] = "never", -- Blade Ward
		[3870] = "never", -- Blood Draining
		[803] = "never", -- Fiery Weapon
		[846] = "never", -- Angler 
		[910] = "pvp", -- Enchant Cloak - Stealth
		[930] = "never", -- Riding Skill

		-- Runeforging
		[3883] = "tank", -- Rune of the Nerubian Carapace
		[3847] = "tank", -- Rune of the Stoneskin Gargoyle
		[3368] = "melee-dps", -- Rune of the Fallen Crusader
		[3369] = "melee-dps", -- Rune of Cinderglacier
		[3370] = "melee-dps", -- Rune of Razorice
		[3365] = "tank", -- Rune of Swordshattering
		[3594] = "tank", -- Rune of Swordbreaking
		[3367] = "pvp", -- Rune of Spellshattering
		[3595] = "pvp", -- Rune of Spellbreaking
		[3366] = "never", -- Rune of Lichbane
	}
	
	-- Allows overriding of items based on the presence of other items and in general, more complicated factors
	local TRINKET1 = GetInventorySlotInfo("Trinket0Slot")
	local TRINKET2 = GetInventorySlotInfo("Trinket1Slot")
	Items.situationalOverrides = {
		-- removed for cata, examples can be found via github history ;)
	}

	-- Certain items can't be classified with normal stat scans, you can specify a specific type using this
	Items.itemOverrides = {
		-- Trinkets + Items
		[59354] = "healer", -- Jar of Ancient Remedys
		[65029] = "healer", -- Jar of Ancient Remedys (heroic)
		[59500] = "healer", -- Fall of Mortality
		[65124] = "healer", -- Fall of Mortality (heroic)
		[64645] = "healer", -- Tyrande's Favorite Doll
		[58184] = "healer", -- Core of Ripeness
		-- Gems
		-- [41382] = "never", -- Trenchant Earthsiege Diamond
	}

	-- Map for checking stats on gems and enchants
	Items.statMap = {
		RESILIENCE_RATING = "ITEM_MOD_RESILIENCE_RATING_SHORT", SPELL_PENETRATION = "ITEM_MOD_SPELL_PENETRATION_SHORT", SPELL_HEALING_DONE = "ITEM_MOD_SPELL_HEALING_DONE_SHORT",
		HIT_SPELL_RATING = "ITEM_MOD_HIT_SPELL_RATING_SHORT", RANGED_ATTACK_POWER = "ITEM_MOD_RANGED_ATTACK_POWER_SHORT", CRIT_RANGED_RATING = "ITEM_MOD_CRIT_RANGED_RATING_SHORT",
		HIT_RANGED_RATING = "ITEM_MOD_HIT_RANGED_RATING_SHORT", DODGE_RATING = "ITEM_MOD_DODGE_RATING_SHORT", DEFENSE_SKILL_RATING = "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT",
		BLOCK_RATING = "ITEM_MOD_BLOCK_RATING_SHORT", BLOCK_VALUE = "ITEM_MOD_BLOCK_VALUE_SHORT", EXPERTISE_RATING = "ITEM_MOD_EXPERTISE_RATING_SHORT",
		HIT_MELEE_RATING = "ITEM_MOD_HIT_MELEE_RATING_SHORT", MELEE_ATTACK_POWER = "ITEM_MOD_MELEE_ATTACK_POWER_SHORT", STRENGTH = "ITEM_MOD_STRENGTH_SHORT",
		CRIT_MELEE_RATING = "ITEM_MOD_CRIT_MELEE_RATING_SHORT", AGILITY = "ITEM_MOD_AGILITY_SHORT", ARMOR_PENETRATION_RATING = "ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT",
		ATTACK_POWER = "ITEM_MOD_ATTACK_POWER_SHORT", POWER_REGEN0 = "ITEM_MOD_POWER_REGEN0_SHORT", SPELL_DAMAGE_DONE = "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT",
		SPELL_POWER = "ITEM_MOD_SPELL_POWER_SHORT", SPIRIT = "ITEM_MOD_SPIRIT_SHORT", MANA_REGENERATION = "ITEM_MOD_MANA_REGENERATION_SHORT",
		HASTE_SPELL_RATING = "ITEM_MOD_HASTE_SPELL_RATING_SHORT", CRIT_SPELL_RATING = "ITEM_MOD_CRIT_SPELL_RATING_SHORT", INTELLECT = "ITEM_MOD_INTELLECT_SHORT", RESISTANCE0 = "RESISTANCE0_NAME", RESISTANCE1 = "RESISTANCE1_NAME", RESISTANCE2 = "RESISTANCE2_NAME", RESISTANCE3 = "RESISTANCE3_NAME", RESISTANCE4 = "RESISTANCE4_NAME", RESISTANCE5 = "RESISTANCE5_NAME", RESISTANCE6 = "RESISTANCE6_NAME",
		STAMINA = "ITEM_MOD_STAMINA_SHORT", RESIST = "RESIST", CRIT_RATING = "ITEM_MOD_CRIT_RATING_SHORT", MANA = "ITEM_MOD_MANA_SHORT", HIT_RATING = "ITEM_MOD_HIT_RATING_SHORT",
		HASTE_RATING = "ITEM_MOD_HASTE_RATING_SHORT", SPELL_STATALL = "SPELL_STATALL", PARRY_RATING = "ITEM_MOD_PARRY_RATING_SHORT", HEALTH = "HEALTH", DAMAGE = "DAMAGE",
		MASTERY_RATING = "ITEM_MOD_MASTERY_RATING_SHORT",
		
		HELPFUL_SPELL = L["helpful spell"], HARMFUL_SPELL = L["harmful spell"], PERIODIC_DAMAGE = L["periodic damage"], MELEE_ATTACK = L["chance on melee attack"],
		CHANCE_MELEE_OR_RANGE = L["chance on melee or range"], CHANCE_MELEE_AND_RANGE = L["chance on melee and range"], RANGED_CRITICAL_STRIKE = L["ranged critical"],
		MELEE_OR_RANGE = L["melee or range"], SPELL_DAMAGE = L["spell damage"], MELEE_AND_RANGE = L["melee and ranged"], DEAL_DAMAGE = L["deal damage"],
		ARMOR_BY = L["armor by"], ARMOR_FOR = L["armor for"], WHEN_HIT = L["when hit"], ROOT_DURATION = L["root duration"], SILENCE_DURATION = L["silence duration"],
		STUN_RESISTANCE = L["stun resistance"], FEAR_DURATION = L["fear duration"], STUN_DURATION = L["stun duration"], RUN_SPEED = L["run speed"],
		MAGICAL_HEALS = L["magical heals"],
	}

	Items.safeStatMatch = {}
	for _, key in pairs(Items.statMap) do
		local text = _G[key] or key
		text = string.gsub(text, "%(", "%%(")
		text = string.gsub(text, "%)", "%%)")
		text = string.gsub(text, "%.", "%%.")
		Items.safeStatMatch[key] = string.lower(text)
	end

	-- Basically, some stats like "armor" will conflict with "armor penetration", as well melee hit and so on
	-- so will set it up so the longest strings get matched first to prevent any chance of conflicts happening
	Items.orderedStatMap = {}
	for key in pairs(Items.safeStatMatch) do table.insert(Items.orderedStatMap, key) end
	table.sort(Items.orderedStatMap, function(a, b) return string.len(_G[a] or a) > string.len(_G[b] or b) end)

	-- These are strings returned from GlobalStrings, ITEM_MOD_####_SHORT/####_NAME for GetItemStats, the ordering is important, do not mess with it
	Items.statTalents = {
		{type = "pvp",			default = "RESILIENCE_RATING@SPELL_PENETRATION@"},
		{type = "elemental/pvp",gems = "STAMINA@", require = "ITEM_MOD_SPELL_POWER_SHORT", require2 = "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT"},
		{type = "all",			gems = "SPELL_STATALL@", enchants = "SPELL_STATALL@"},
		{type = "never",		gems = "RESIST@"},
		{type = "never",		gems = "MANA@", exclusive = true},
		{type = "healer", 		gems = "MANA@", skipOn = "ITEM_MOD_INTELLECT_SHORT", skipOn2 = "ITEM_MOD_SPELL_POWER_SHORT"},
		{type = "tank",			default = "DEFENSE_SKILL_RATING@", trinkets = "WHEN_HIT@"},
		{type = "healer",		default = "SPELL_HEALING_DONE@", trinkets = "HELPFUL_SPELL@MAGICAL_HEALS@"},
		{type = "caster-dps",	default = "HIT_SPELL_RATING@", trinkets = "HARMFUL_SPELL@PERIODIC_DAMAGE@SPELL_DAMAGE@"},
		{type = "caster-dps",	default = "HIT_RATING@", require = "ITEM_MOD_SPELL_POWER_SHORT", require2 = "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT"},
		{type = "melee-agi",	default = "AGILITY@"},
		{type = "melee-str",	default = "STRENGTH@"},
		{type = "physical-dps", default = "ARMOR_PENETRATION_RATING@", trinkets = "ATTACK@MELEE_OR_RANGE_DAMAGE@CHANCE_MELEE_OR_RANGE@MELEE_AND_RANGE@MELEE_AND_RANGE@"},
		{type = "range-dps",	default = "RANGED_ATTACK_POWER@CRIT_RANGED_RATING@HIT_RANGED_RATING@RANGED_CRITICAL_STRIKE@"},
		-- {type = "melee-str",	gems = "STRENGTH@", require = "ITEM_MOD_STAMINA_SHORT"},
		-- {type = "caster-spirit",gems = "SPIRIT@", enchants = "SPIRIT@", trinkets = "SPIRIT@"},
		{type = "caster-spirit",default = "SPIRIT@"},
		{type = "caster",		default = "POWER_REGEN0@SPELL_DAMAGE_DONE@SPELL_POWER@MANA_REGENERATION@HASTE_SPELL_RATING@CRIT_SPELL_RATING@INTELLECT@", gems = "MANA@", enchants = "MANA@"},
		{type = "caster",		default = "MANA@", require = "ITEM_MOD_SPELL_POWER_SHORT", require2 = "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT"},
		{type = "tank",			default = "PARRY_RATING@DODGE_RATING@DEFENSE_SKILL_RATING@BLOCK_RATING@BLOCK_VALUE@", enchants = "STAMINA@HEALTH@RESISTANCE0@", trinkets = "RESISTANCE0@STAMINA@", weapons = "RESISTANCE0@", rings = "RESISTANCE0"},
		{type = "melee",		default = "EXPERTISE_RATING@"},
		{type = "physical-dps",	default = "ATTACK_POWER@"},
		{type = "melee-dps",	default = "HIT_MELEE_RATING@MELEE_ATTACK_POWER@STRENGTH@CRIT_MELEE_RATING@", trinkets = "MELEE_ATTACK@"},
		{type = "tank/dps", 	enchants = "HIT_RATING@", gems = "HIT_RATING@"},
		{type = "dps",			trinkets = "DAMAGE@DEAL_DAMAGE@"},
		{type = "dps",			default = "HIT_RATING@"},
		{type = "healer/dps",	default = "CRIT_RATING@HASTE_RATING@"},
		{type = "tank",			default = "RESISTANCE1@RESISTANCE2@RESISTANCE3@RESISTANCE4@RESISTANCE5@RESISTANCE6@", gems = "STAMINA@"},
	}
end

-- This is a trick I'm experiminating with, basically it automatically loads the data then kills the metatable attached to it
-- so for the cost of a table, I get free loading on demand
ElitistGroup.Items = setmetatable({}, {
	__index = function(tbl, key)
		setmetatable(tbl, nil)
		loadData()
		return tbl[key]
end})