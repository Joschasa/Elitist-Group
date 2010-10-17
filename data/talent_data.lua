local ElitistGroup = select(2, ...)
local L = ElitistGroup.L

local function loadData()
	local Talents = ElitistGroup.Talents

	local CASTER_DAMAGE = L["DPS, Caster"]
	local MELEE_DAMAGE = L["DPS, Melee"]
	local RANGE_DAMAGE = L["DPS, Ranged"]
	local HEALER = L["Healer"]
	local TANK = L["Tank"]
	Talents.talentText = {["elemental-shaman"] = CASTER_DAMAGE, ["enhance-shaman"] = MELEE_DAMAGE, ["resto-shaman"] = HEALER, ["arcane-mage"] = CASTER_DAMAGE, ["fire-mage"] = CASTER_DAMAGE, ["frost-mage"] = CASTER_DAMAGE, ["afflict-warlock"] = CASTER_DAMAGE, ["demon-warlock"] = CASTER_DAMAGE, ["destro-warlock"] = CASTER_DAMAGE, ["balance-druid"] = CASTER_DAMAGE, ["cat-druid"] = MELEE_DAMAGE, ["bear-druid"] = TANK, ["resto-druid"] = HEALER, ["arms-warrior"] = MELEE_DAMAGE, ["fury-warrior"] = MELEE_DAMAGE, ["prot-warrior"] = TANK, ["assass-rogue"] = MELEE_DAMAGE, ["combat-rogue"] = MELEE_DAMAGE, ["subtlety-rogue"] = MELEE_DAMAGE, ["holy-paladin"] = HEALER, ["prot-paladin"] = TANK, ["ret-paladin"] = MELEE_DAMAGE, ["beast-hunter"] = RANGE_DAMAGE, ["marks-hunter"] = RANGE_DAMAGE, ["survival-hunter"] = RANGE_DAMAGE, ["disc-priest"] = HEALER, ["holy-priest"] = HEALER, ["shadow-priest"] = CASTER_DAMAGE, ["blood-dk"] = MELEE_DAMAGE, ["frost-dk"] = MELEE_DAMAGE, ["unholy-dk"] = MELEE_DAMAGE, ["tank-dk"] = TANK}

	Talents.TANK = TANK
	Talents.HEALER = HEALER
	Talents.MELEE_DAMAGE = MELEE_DAMAGE
	Talents.CASTER_DAMAGE = CASTER_DAMAGE
	Talents.RANGE_DAMAGE = RANGE_DAMAGE
	
	-- required = How many of the talents the class needs
	-- the number set for the talent is how many they need
	-- Death Knights for example need capped Blade Barrier, Anticipation or Toughness, any 2 to be a tank
	-- This isn't really perfect, if a Druid tries to hybrid it up then it's hard for us to figure out what spec they are
	-- a good idea might be to force set their role based on the assignment they chose when possible, and use this as a fallback
	Talents.specOverride = {
		["DEATHKNIGHT"] = {
			["required"] = 3,
			["role"] = "tank-dk",
			
			[GetSpellInfo(16271)] = 5, -- Anticipation
			[GetSpellInfo(49042)] = 5, -- Toughness
			[GetSpellInfo(55225)] = 5, -- Blade Barrier
		},
		["DRUID"] = {
			["required"] = 3,
			["role"] = "bear-druid",
			
			[GetSpellInfo(57881)] = 2, -- Natural Reaction
			[GetSpellInfo(16929)] = 3, -- Thick Hide
			[GetSpellInfo(61336)] = 1, -- Survival Instincts
			[GetSpellInfo(57877)] = 3, -- Protector of the Pack
		},
	}

	-- Tree names
	Talents.treeData = {
		["SHAMAN"] = {
			"elemental-shaman", L["Elemental"], "Interface\\Icons\\Spell_Nature_Lightning",
			"enhance-shaman", L["Enhancement"], "Interface\\Icons\\Spell_Nature_LightningShield",
			"resto-shaman", L["Restoration"], "Interface\\Icons\\Spell_Nature_MagicImmunity",
		},
		["MAGE"] = {
			"arcane-mage", L["Arcane"], "Interface\\Icons\\Spell_Holy_MagicalSentry",
			"fire-mage", L["Fire"], "Interface\\Icons\\Spell_Fire_FlameBolt", 
			"frost-mage", L["Frost"], "Interface\\Icons\\Spell_Frost_FrostBolt02",
		},
		["WARLOCK"] = {
			"afflict-warlock", L["Affliction"], "Interface\\Icons\\Spell_Shadow_DeathCoil",
			"demon-warlock", L["Demonology"], "Interface\\Icons\\Spell_Shadow_Metamorphosis",
			"destro-warlock", L["Destruction"], "Interface\\Icons\\Spell_Shadow_RainOfFire",
		},
		["DRUID"] = {
			"balance-druid", L["Balance"], "Interface\\Icons\\Spell_Nature_Lightning",
			"cat-druid", L["Feral"], "Interface\\Icons\\Ability_Racial_BearForm",
			"resto-druid", L["Restoration"], "Interface\\Icons\\Spell_Nature_HealingTouch",
		},
		["WARRIOR"] = {
			"arms-warrior", L["Arms"], "Interface\\Icons\\Ability_Rogue_Eviscerate", 
			"fury-warrior", L["Fury"], "Interface\\Icons\\Ability_Warrior_InnerRage", 
			"prot-warrior", L["Protection"], "Interface\\Icons\\INV_Shield_06",
		},
		["ROGUE"] = {
			"assass-rogue", L["Assassination"], "Interface\\Icons\\Ability_Rogue_Eviscerate",
			"combat-rogue", L["Combat"], "Interface\\Icons\\Ability_BackStab", 
			"subtlety-rogue", L["Subtlety"], "Interface\\Icons\\Ability_Stealth",
		},
		["PALADIN"] = {
			"holy-paladin", L["Holy"], "Interface\\Icons\\Spell_Holy_HolyBolt", 
			"prot-paladin", L["Protection"], "Interface\\Icons\\Spell_Holy_DevotionAura",
			"ret-paladin", L["Retribution"], "Interface\\Icons\\Spell_Holy_AuraOfLight",
		},
		["HUNTER"] = {
			"beast-hunter", L["Beast Mastery"], "Interface\\Icons\\Ability_Hunter_BeastTaming",
			"marks-hunter", L["Marksmanship"], "Interface\\Icons\\Ability_Marksmanship",
			"survival-hunter", L["Survival"], "Interface\\Icons\\Ability_Hunter_SwiftStrike",
		},
		["PRIEST"] = {
			"disc-priest", L["Discipline"], "Interface\\Icons\\Spell_Holy_WordFortitude",
			"holy-priest", L["Holy"], "Interface\\Icons\\Spell_Holy_HolyBolt",
			"shadow-priest", L["Shadow"], "Interface\\Icons\\Spell_Shadow_ShadowWordPain",
		},
		["DEATHKNIGHT"] = {
			"blood-dk", L["Blood"], "Interface\\Icons\\Spell_Shadow_BloodBoil",
			"frost-dk", L["Frost"], "Interface\\Icons\\Spell_Frost_FrostNova",
			"unholy-dk", L["Unholy"], "Interface\\Icons\\Spell_Shadow_ShadeTrueSight",
		},
	}
end

-- This is a trick I'm experiminating with, basically it automatically loads the data then kills the metatable attached to it
-- so for the cost of a table, I get free loading on demand
ElitistGroup.Talents = setmetatable({}, {
	__index = function(tbl, key)
		loadData()
		setmetatable(tbl, nil)
		return tbl[key]
end})
