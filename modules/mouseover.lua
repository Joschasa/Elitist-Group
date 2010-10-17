local ElitistGroup = select(2, ...)
local Mouseover = ElitistGroup:NewModule("Mouseover", "AceEvent-3.0")
local L = ElitistGroup.L
local OnTooltipSetUnit, OnHide, MOUSEOVER_DISABLED, activePlayerID, updateType
local cachedPlayerIDs = {}
local THRESHOLD_TIME = 10

function Mouseover:Setup()
	if( ElitistGroup.db.profile.general.mouseover ) then
		if( not self.hooked ) then
			GameTooltip:HookScript("OnTooltipSetUnit", OnTooltipSetUnit)
			self.hooked = true
		end
		
		self:RegisterEvent("PLAYER_LEAVING_WORLD")
		self:RegisterMessage("EG_DATA_UPDATED")
		MOUSEOVER_DISABLED = nil
	else
		self:UnregisterEvent("PLAYER_LEAVING_WORLD")
		self:UnregisterMessage("EG_DATA_UPDATED")
		MOUSEOVER_DISABLED = true
	end
end

local blockNext
function Mouseover:PLAYER_LEAVING_WORLD() cachedPlayerIDs = {} end
function Mouseover:EG_DATA_UPDATED(event, type, playerID)
	if( GameTooltip:IsUnit("mouseover") and playerID == activePlayerID and not blockNext ) then
		updateType = type
		GameTooltip:ClearLines()
		GameTooltip:SetUnit("mouseover")
		updateType = nil
	end
	
	blockNext = nil
end

-- Setup tooltips
OnTooltipSetUnit = function(self, unit)
	unit = unit or "mouseover"
	if( InCombatLockdown() or not UnitIsUnit(unit, "mouseover" ) or not UnitIsPlayer(unit) or not UnitIsFriend(unit, "player") or UnitIsUnit(unit, "player") or MOUSEOVER_DISABLED ) then return end

	local guid = UnitGUID(unit)
	cachedPlayerIDs[guid] = cachedPlayerIDs[guid] or ElitistGroup:GetPlayerID(unit)
	activePlayerID = cachedPlayerIDs[guid]

	if( not updateType ) then
		blockNext = true
		ElitistGroup.modules.Scan:InspectUnit(unit)
	end
	
	local userData = ElitistGroup.userData[activePlayerID]
	if( not userData ) then return end
	
	-- Setup everything
	local percentGear, percentEnchants, percentGems = ElitistGroup:GetOptimizedSummary(userData)
	local gearR = (percentGear > 0.5 and (1.0 - percentGear) * 2 or 1.0) * 255
	local gearG = (percentGear > 0.5 and 1.0 or percentGear * 2) * 255
	local enchantR = (percentEnchants > 0.5 and (1.0 - percentEnchants) * 2 or 1.0) * 255
	local enchantG = (percentEnchants > 0.5 and 1.0 or percentEnchants * 2) * 255
	local gemR = (percentGems > 0.5 and (1.0 - percentGems) * 2 or 1.0) * 255
	local gemG = (percentGems > 0.5 and 1.0 or percentGems * 2) * 255
	
	if( percentGems > 0 or updateType ) then
		GameTooltip:AddLine(string.format(L["|cff%02x%02x00%d%%|r Gear, |cff%02x%02x00%d%%|r Gems, |cff%02x%02x00%d%%|r Enchants"], gearR, gearG, percentGear * 100, gemR, gemG, percentGems * 100, enchantR, enchantG, percentEnchants * 100), 1, 1, 1)
	else
		GameTooltip:AddLine(string.format(L["|cff%02x%02x00%d%%|r Gear, --- Gems, |cff%02x%02x00%d%%|r Enchants"], gearR, gearG, percentGear * 100, enchantR, enchantG, percentEnchants * 100), 1, 1, 1)
	end
end

