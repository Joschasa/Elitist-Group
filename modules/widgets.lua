local ElitistGroup = select(2, ...)
ElitistGroup.Widgets = {}
local Widgets = ElitistGroup.Widgets

Widgets.OnEnter = function(self)
	if( self.tooltip ) then
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
		GameTooltip:SetText(self.tooltip, nil, nil, nil, nil, not self.disableWrap)
		GameTooltip:Show()
	end
end

Widgets.OnLeave = function(self)
	GameTooltip:Hide()
end


-- SCROLL FRAME
local function onVerticalScroll(self, offset)
	offset = ceil(offset)
	self.bar:SetValue(offset)
	self.offset = math.max(ceil(offset / self.displayNum), 0)

	local min, max = self.bar:GetMinMaxValues()
	if( min == offset ) then
		self.up:Disable()
	else
		self.up:Enable()
	end

	if( max == offset ) then
		self.down:Disable()
	else
		self.down:Enable()
	end

	self.updateHandler[self.updateFunc](self.updateHandler, self)
end

local function onMouseWheel(self, offset)
	if( self.scroll ) then self = self.scroll end
	if( offset > 0 ) then
		self.bar:SetValue(self.bar:GetValue() - (self.bar:GetHeight() / 2))
	else
		self.bar:SetValue(self.bar:GetValue() + (self.bar:GetHeight() / 2))
	end
end

local function onParentMouseWheel(self, offset)
	onMouseWheel(self.scroll, offset)
end

local function UpdateScroll(scroll, totalRows)
	-- Macs are unhappy if max is less then the min
	local max = (totalRows - scroll.displayNum) * scroll.displayNum
	scroll.bar:SetMinMaxValues(0, math.max(max, 0))

	if( totalRows > scroll.displayNum ) then
		scroll:Show()
		scroll.bar:Show()
		scroll.up:Show()
		scroll.down:Show()
		scroll.bar:GetThumbTexture():Show()
	else
		scroll:Hide()
		scroll.bar:Hide()
		scroll.up:Hide()
		scroll.down:Hide()
		scroll.bar:GetThumbTexture():Hide()
	end
end

local function onValueChanged(self, offset)
	self:GetParent():SetVerticalScroll(offset)
end

local function scrollButtonUp(self)
	local parent = self:GetParent()
	parent:SetValue(parent:GetValue() - (parent:GetHeight() / 2))
	PlaySound("UChatScrollButton")
end

local function scrollButtonDown(self)
	local parent = self:GetParent()
	parent:SetValue(parent:GetValue() + (parent:GetHeight() / 2))
	PlaySound("UChatScrollButton")
end

function Widgets:CreateScrollFrame(frame, displayNum, scrollHandler, scrollFunc)
	frame:EnableMouseWheel(true)
	frame:SetScript("OnMouseWheel", onParentMouseWheel)

	frame.scroll = CreateFrame("ScrollFrame", nil, frame)
	frame.scroll:EnableMouseWheel(true)
	frame.scroll:SetWidth(16)
	frame.scroll:SetHeight(270)
	frame.scroll:SetScript("OnVerticalScroll", onVerticalScroll)
	frame.scroll:SetScript("OnMouseWheel", onMouseWheel)

	frame.scroll.offset = 0
	frame.scroll.displayNum = displayNum
	frame.scroll.updateHandler = scrollHandler
	frame.scroll.updateFunc = scrollFunc

	-- Actual bar for scrolling
	frame.scroll.bar = CreateFrame("Slider", nil, frame.scroll)
	frame.scroll.bar:SetValueStep(frame.scroll.displayNum)
	frame.scroll.bar:SetMinMaxValues(0, 0)
	frame.scroll.bar:SetValue(0)
	frame.scroll.bar:SetWidth(16)
	frame.scroll.bar:SetScript("OnValueChanged", onValueChanged)
	frame.scroll.bar:SetPoint("TOPLEFT", frame.scroll, "TOPRIGHT", 6, -16)
	frame.scroll.bar:SetPoint("BOTTOMLEFT", frame.scroll, "BOTTOMRIGHT", 6, -16)

	-- Up/Down buttons
	frame.scroll.up = CreateFrame("Button", nil, frame.scroll.bar, "UIPanelScrollUpButtonTemplate")
	frame.scroll.up:ClearAllPoints()
	frame.scroll.up:SetPoint( "BOTTOM", frame.scroll.bar, "TOP" )
	frame.scroll.up:SetScript("OnClick", scrollButtonUp)

	frame.scroll.down = CreateFrame("Button", nil, frame.scroll.bar, "UIPanelScrollDownButtonTemplate")
	frame.scroll.down:ClearAllPoints()
	frame.scroll.down:SetPoint( "TOP", frame.scroll.bar, "BOTTOM" )
	frame.scroll.down:SetScript("OnClick", scrollButtonDown)

	-- That square thingy that shows where the bar is
	frame.scroll.bar:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")

	local thumb = frame.scroll.bar:GetThumbTexture()
	thumb:SetHeight(16)
	thumb:SetWidth(16)
	thumb:SetTexCoord(0.25, 0.75, 0.25, 0.75)

	--[[
	-- Border graphic
	frame.scroll.barUpTexture = frame.scroll:CreateTexture(nil, "BACKGROUND")
	frame.scroll.barUpTexture:SetWidth(31)
	frame.scroll.barUpTexture:SetHeight(256)
	frame.scroll.barUpTexture:SetPoint("TOPLEFT", frame.scroll.up, "TOPLEFT", -7, 5)
	frame.scroll.barUpTexture:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar")
	frame.scroll.barUpTexture:SetTexCoord(0, 0.484375, 0, 1.0)

	frame.scroll.barDownTexture = frame.scroll:CreateTexture(nil, "BACKGROUND")
	frame.scroll.barDownTexture:SetWidth(31)
	frame.scroll.barDownTexture:SetHeight(106)
	frame.scroll.barDownTexture:SetPoint("BOTTOMLEFT", frame.scroll.down, "BOTTOMLEFT", -7, -3)
	frame.scroll.barDownTexture:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar")
	frame.scroll.barDownTexture:SetTexCoord(0.515625, 1.0, 0, 0.4140625)
	]]
	frame.scroll.Update = UpdateScroll
end

