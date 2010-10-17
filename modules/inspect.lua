local ElitistGroup = select(2, ...)
local Inspect = ElitistGroup:NewModule("Inspect", "AceEvent-3.0")
local L = ElitistGroup.L
local buttonList = {"gemInfo", "enchantInfo", "gearInfo", "talentInfo"}

function Inspect:OnInitialize()
	if( ElitistGroup.db.profile.inspect.window or ElitistGroup.db.profile.inspect.tooltips ) then
		if( not IsAddOnLoaded("Blizzard_InspectUI") ) then
			self:RegisterEvent("ADDON_LOADED")
		else
			self:ADDON_LOADED(nil, "Blizzard_InspectUI")
		end
	end
end

function Inspect:ADDON_LOADED(event, addon)
	if( addon ~= "Blizzard_InspectUI" ) then return end
	self:UnregisterEvent("ADDON_LOADED")
	
	local function OnShow()
		local self = Inspect
		
		if( InspectFrame.unit and UnitIsFriend(InspectFrame.unit, "player") and CanInspect(InspectFrame.unit) ) then
			self.inspectID = ElitistGroup:GetPlayerID(InspectFrame.unit)
			self:RegisterMessage("EG_DATA_UPDATED")
			ElitistGroup.modules.Sync:RequestMainData(InspectFrame.unit)
			
			-- Setup the summary window for the inspect if it's enabled and we can inspect them
			if( ElitistGroup.db.profile.inspect.window ) then
				self:SetupSummary()
			elseif( self.frame ) then
				self.frame:Hide()
			end
			
			if( ElitistGroup.db.profile.inspect.tooltips ) then
				self:SetupTooltips()
			end
		else
			if( self.frame ) then self.frame:Hide() end
			ElitistGroup.tooltip:Hide()
		end
	end
	
	-- Tell EG that it's ok to inspect this because it's user initiated
	local orig_InspectFrame_Show = InspectFrame_Show
	InspectFrame_Show = function(...)
		ElitistGroup.modules.Scan.allowInspect = true
		return orig_InspectFrame_Show(...)
	end
	
	local orig_InspectFrame_UnitChanged = InspectFrame_UnitChanged
	InspectFrame_UnitChanged = function(...)
		OnShow()
		ElitistGroup.modules.Scan.allowInspect = true
		return orig_InspectFrame_UnitChanged(...)
	end
	
	InspectFrame:HookScript("OnShow", OnShow)
	InspectFrame:HookScript("OnHide", function() Inspect:UnregisterMessage("EG_DATA_UPDATED") end)
	if( InspectFrame:IsVisible() ) then OnShow() end
end

function Inspect:EG_DATA_UPDATED(event, type, playerID)
	if( self.inspectID == playerID and type ~= "note" ) then
		if( ElitistGroup.db.profile.inspect.window ) then
			self:SetupSummary(type)
		end
		
		if( ElitistGroup.db.profile.inspect.tooltips ) then
			self:SetupTooltips()
		end
	end
end

function Inspect:SetupTooltips()
	local userData = self.inspectID and ElitistGroup.userData[self.inspectID]
	if( not userData ) then return end
	
	local equipmentData, enchantData, gemData = ElitistGroup:GetGearSummary(userData)
	local enchantTooltips, gemTooltips = ElitistGroup:GetGearSummaryTooltip(userData.equipment, enchantData, gemData)
	
	for inventoryID, inventoryKey in pairs(ElitistGroup.Items.validInventorySlots) do
		local button = self[inventoryKey] or _G["Inspect" .. inventoryKey]
		local itemLink = userData.equipment[inventoryID]
		if( itemLink ) then
			local baseItemLink = ElitistGroup:GetBaseItemLink(itemLink)
			button.gemTooltip = gemTooltips[itemLink]
			button.enchantTooltip = enchantTooltips[itemLink]
			button.isBadType = equipmentData[itemLink] and "|cffff2020[!]|r " or ""
			button.itemTalentType = ElitistGroup.Items.itemRoleText[ElitistGroup.ITEM_TALENTTYPE[baseItemLink]] or ElitistGroup.ITEM_TALENTTYPE[baseItemLink]
			button.hasData = true
		else
			button.hasData = nil
		end

		-- Force tooltip update so if data was found the tooltip reflects it without having to remouseover
		if( GameTooltip:IsOwned(button) ) then
			button:GetScript("OnEnter")(button)
		end
		
		self[inventoryKey] = button
	end
	
	ElitistGroup:ReleaseTables(equipmentData, enchantData, gemData, enchantTooltips, gemTooltips)
	
	if( not self.hooked ) then
		local function OnEnter(self)
			if( not self.hasData or not ElitistGroup.db.profile.inspect.tooltips ) then return end
			
			ElitistGroup.tooltip:SetOwner(GameTooltip, "ANCHOR_NONE")
			ElitistGroup.tooltip:SetPoint("TOPLEFT", GameTooltip, "BOTTOMLEFT", 0, -5)
			if( self.itemTalentType ) then
				ElitistGroup.tooltip:SetText(string.format(L["|cfffed000Item Type:|r %s%s"], self.isBadType, self.itemTalentType), 1, 1, 1)
			end
			if( self.enchantTooltip ) then
				ElitistGroup.tooltip:AddLine(self.enchantTooltip)
			end
			if( self.gemTooltip ) then
				ElitistGroup.tooltip:AddLine(self.gemTooltip)
			end
			ElitistGroup.tooltip:Show()
		end
		
		local function OnLeave(self)
			ElitistGroup.tooltip:Hide()
		end
		
		for inventoryKey in pairs(ElitistGroup.Items.inventoryToID) do
			local button = self[inventoryKey]
			button:HookScript("OnLeave", OnLeave)
			button:HookScript("OnEnter", OnEnter)
		end
		
		self.hooked = true
	end
end

function Inspect:SetupSummary(updateType)
	self:CreateSummary()
	
	local userData = self.inspectID and ElitistGroup.userData[self.inspectID]
	local hasData = userData and ( userData.talentTree1 ~= 0 or userData.talentTree2 ~= 0 or userData.talentTree3 ~= 0 )
	if( not hasData ) then
		for _, key in pairs(buttonList) do
			self.frame[key]:SetText(L["Loading"])
			self.frame[key]:GetFontString():SetTextColor(GameFontHighlight:GetTextColor())
			self.frame[key].tooltip = L["Data is loading, please wait."]
			self.frame[key].disableWrap = nil
		end
	end
	
	if( userData ) then
		if( not updateType or updateType == "talents" ) then
			-- Make sure they are talented enough
			local specType, specName, specIcon = ElitistGroup:GetPlayerSpec(userData.classToken, userData)
			ElitistGroup:SetTalentText(self.frame.talentInfo, specType, specName, userData, "primary")
		end
		
		local equipmentData, enchantData, gemData = ElitistGroup:GetGearSummary(userData)
		local equipmentTooltip, gemTooltip, enchantTooltip = ElitistGroup:GetGeneralSummaryTooltip(equipmentData, gemData, enchantData)
		
		-- Build equipment
		local percent = math.max(math.min(1, (equipmentData.totalEquipped - equipmentData.totalBad) / equipmentData.totalEquipped), 0)
		local r = (percent > 0.5 and (1.0 - percent) * 2 or 1.0) * 255
		local g = (percent > 0.5 and 1.0 or percent * 2) * 255
		self.frame.gearInfo:SetFormattedText(L["(%s%d|r) Gear [|cff%02x%02x00%d%%|r]"], ElitistGroup:GetItemColor(equipmentData.totalScore), equipmentData.totalScore, r, g, percent * 100)
		self.frame.gearInfo.tooltip = equipmentTooltip
		self.frame.gearInfo.disableWrap = true
		
		if( hasData ) then
			-- Build enchants
			if( not enchantData.noData ) then
				local percent = math.max(math.min(1, (enchantData.total - enchantData.totalBad) / enchantData.total), 0)
				local r = (percent > 0.5 and (1.0 - percent) * 2 or 1.0) * 255
				local g = (percent > 0.5 and 1.0 or percent * 2) * 255

				self.frame.enchantInfo:SetFormattedText(L["Enchants [|cff%02x%02x00%d%%|r]"], r, g, percent * 100)
				self.frame.enchantInfo.tooltip = enchantTooltip
				self.frame.enchantInfo.disableWrap = not enchantData.noData
			else
				self.frame.enchantInfo:SetText(L["Enchants [|cffff20200%|r]"])
				self.frame.enchantInfo.tooltip = L["No enchants found."]
				self.frame.enchantInfo.disableWrap = nil
			end

			if( not updateType or updateType == "gems" ) then
				-- Build gems
				if( not gemData.noData ) then
					local percent = math.max(math.min(1, (gemData.total - gemData.totalBad) / gemData.total), 0)
					local r = (percent > 0.5 and (1.0 - percent) * 2 or 1.0) * 255
					local g = (percent > 0.5 and 1.0 or percent * 2) * 255

					self.frame.gemInfo:SetFormattedText(L["Gems [|cff%02x%02x00%d%%|r]"], r, g, percent * 100)
					self.frame.gemInfo.tooltip = gemTooltip
					self.frame.gemInfo.disableWrap = not gemData.noData
				else
					self.frame.gemInfo:SetText(L["Gems [|cffff20200%|r]"])
					self.frame.gemInfo.tooltip = L["No gems found."]
					self.frame.gemInfo.disableWrap = nil
				end		
			end
		end
		
		ElitistGroup:ReleaseTables(equipmentData, enchantData, gemData)
	end
end

function Inspect:CreateSummary()
	if( self.frame ) then
		self.frame:Show()
		return
	end

	local function OnEnter(self)
		if( self.tooltip ) then
			GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
			GameTooltip:SetText(self.tooltip, nil, nil, nil, nil, not self.disableWrap)
			GameTooltip:Show()
		end
	end

	local function OnLeave(self)
		GameTooltip:Hide()
	end
	
	local frame = CreateFrame("Frame", nil, InspectModelFrame)
	frame:SetFrameLevel(100)
	frame:SetSize(1, 1)
	frame:Hide()
	
	local font, size = GameFontHighlight:GetFont()
	for i, key in pairs(buttonList) do
		local button = CreateFrame("Button", nil, frame)
		button:SetNormalFontObject(GameFontHighlight)
		button:SetText("*")
		button:SetHeight(15)
		button:SetWidth(125)
		button:SetScript("OnEnter", OnEnter)
		button:SetScript("OnLeave", OnLeave)
		button:SetPushedTextOffset(0, 0)	
		local fontString = button:GetFontString()
		fontString:SetFont(font, size, "OUTLINE")
		fontString:SetPoint("RIGHT", button, "RIGHT", -2, 0)
		fontString:SetJustifyH("RIGHT")
		fontString:SetJustifyV("CENTER")
		fontString:SetWidth(button:GetWidth() + (i == 4 and 40 or 0))
		fontString:SetHeight(15)
		
		if( i > 1 ) then
			button:SetPoint("TOPRIGHT", frame[buttonList[i - 1]], "BOTTOMRIGHT", 0, -4)
		else
			button:SetPoint("TOPRIGHT", InspectFinger1Slot, "TOPLEFT", -8, -25)
		end
		
		frame[key] = button
	end	
	
	self.frame = frame
	self.frame:Show()
end