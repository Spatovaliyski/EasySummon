-- UI/MainFrame.lua
EasySummonUI = {}

function EasySummonUI:Initialize()
	self:CreateMainFrame()
	self.frame:Hide()

	self.frame:RegisterEvent("GROUP_ROSTER_UPDATE")
	self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")

	self.frame:SetScript("OnEvent", function(_, event, ...)
		if event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
			if self.frame:IsShown() then
				EasySummonGroupUtils:UpdateGroupSizeText()
			end
		end
	end)
end

function EasySummonUI:CreateMainFrame()
	local frame = CreateFrame("Frame", "EasySummonFrame", UIParent, "ButtonFrameTemplate")
	frame:SetSize(EasySummonConfig.FrameWidth, EasySummonConfig.FrameHeight)
	frame:SetPoint("CENTER")
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:SetFrameStrata("HIGH")
	frame:SetFrameLevel(50)

	tinsert(UISpecialFrames, "EasySummonFrame")

	-- Set the frame title
	frame.TitleText:SetText("Easy Summon v" .. GetAddOnMetadata("EasySummon", "Version"))
	frame.portrait:SetTexture("Interface\\AddOns\\EasySummon\\Textures\\logo")

	-- Settings button (next to close button)
	local settingsButton = CreateFrame("Button", nil, frame)
	settingsButton:SetSize(16, 16)
	settingsButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -30, -4)
	settingsButton:SetFrameLevel(frame:GetFrameLevel() + 10)

	settingsButton:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
	settingsButton:SetPushedTexture("Interface\\Buttons\\UI-OptionsButton-Down")
	settingsButton:SetHighlightTexture("Interface\\Buttons\\UI-OptionsButton-Up")

	settingsButton:SetScript("OnClick", function()
		EasySummonSettingsWindow:Toggle()
	end)

	self.settingsButton = settingsButton

	-- Group size text display
	local groupSizeText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	groupSizeText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -45)
	groupSizeText:SetText("Group: 0/0")
	self.groupSizeText = groupSizeText

	-- Reset button
	local resetButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	resetButton:SetSize(100, 21)
	resetButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 4, 4)
	resetButton:SetText("Reset")
	resetButton:SetFrameLevel(frame:GetFrameLevel() + 10)
	resetButton:SetScript("OnClick", function()
		_G.EasySummonCore:ResetResponses()
	end)

	local notifyCheckbox = CreateFrame("CheckButton", "EasySummonNotifyCheckbox", frame, "UICheckButtonTemplate")
	notifyCheckbox:SetSize(24, 24)
	notifyCheckbox:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -180, 3)
	notifyCheckbox:SetFrameLevel(frame:GetFrameLevel() + 10)
	notifyCheckbox:SetChecked(EasySummonConfig.NotifyWhenHidden)

	-- checkbox text
	_G[notifyCheckbox:GetName() .. "Text"]:SetText("Show toast on summon request")

	-- checkbox hookup
	notifyCheckbox:SetScript("OnClick", function(self)
		EasySummonConfig.NotifyWhenHidden = self:GetChecked()
	end)

	-- Add OnShow handling
	frame:SetScript("OnShow", function()
		if _G.EasySummonCore then
			_G.EasySummonCore:SetActive(true)
			_G.EasySummonCore:UpdateRaidList()
			EasySummonGroupUtils:UpdateGroupSizeText()
		end
	end)

	frame:SetScript("OnHide", function()
		if EasySummonSummonButton and EasySummonSummonButton.button then
			EasySummonSummonButton.button:Hide()
			EasySummonSummonButton.button = nil
		end

		-- Close the settings window when main frame closes
		if EasySummonSettingsWindow then
			EasySummonSettingsWindow:Hide()
		end

		-- Telling the core its not active anymore
		if _G.EasySummonCore then
			_G.EasySummonCore:SetActive(false)
		end
	end)

	self.frame = frame
	--self.notifyCheckbox = notifyCheckbox
	self:CreateScrollFrame()
end

function EasySummonUI:CreateScrollFrame()
	local inset = CreateFrame("Frame", nil, self.frame, "InsetFrameTemplate3")
	inset:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 8, -62)
	inset:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -10, 26)

	local scrollFrame = CreateFrame("ScrollFrame", "EasySummonScrollFrame", inset, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", inset, "TOPLEFT", 3, -3)
	scrollFrame:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", -27, 3)

	scrollFrame.targetScrollValue = 0
	scrollFrame.scrollDuration = 0.15
	scrollFrame.scrollElapsed = 0
	scrollFrame.scrollStartValue = 0
	scrollFrame.scrollIsAnimating = false

	scrollFrame:EnableMouseWheel(true)
	scrollFrame:SetScript("OnMouseWheel", function(self, delta)
		local scrollAmount = 25
		local targetValue = self.scrollIsAnimating and self.targetScrollValue or self:GetVerticalScroll()

		if delta < 0 then
			targetValue = targetValue + scrollAmount
		else
			targetValue = targetValue - scrollAmount
		end

		targetValue = math.max(0, math.min(targetValue, self:GetVerticalScrollRange()))

		self.scrollStartValue = self:GetVerticalScroll()
		self.targetScrollValue = targetValue
		self.scrollElapsed = 0
		self.scrollIsAnimating = true
	end)

	scrollFrame:SetScript("OnUpdate", function(self, elapsed)
		if not self.scrollIsAnimating then
			return
		end

		self.scrollElapsed = self.scrollElapsed + elapsed
		local progress = math.min(self.scrollElapsed / self.scrollDuration, 1)
		local smoothedProgress = 1 - (1 - progress) * (1 - progress)

		local newPosition = self.scrollStartValue + (self.targetScrollValue - self.scrollStartValue) * smoothedProgress
		self:SetVerticalScroll(newPosition)

		if progress >= 1 then
			self.scrollIsAnimating = false
		end
	end)

	scrollFrame.ScrollBar:ClearAllPoints()
	scrollFrame.ScrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 7, -16)
	scrollFrame.ScrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 7, 16)

	local scrollUpButton = _G[scrollFrame:GetName() .. "ScrollBarScrollUpButton"]
	if scrollUpButton then
		scrollUpButton:ClearAllPoints()
		scrollUpButton:SetPoint("BOTTOM", scrollFrame.ScrollBar, "TOP", 1, -1)
	end

	local scrollDownButton = _G[scrollFrame:GetName() .. "ScrollBarScrollDownButton"]
	if scrollDownButton then
		scrollDownButton:ClearAllPoints()
		scrollDownButton:SetPoint("TOP", scrollFrame.ScrollBar, "BOTTOM", 1, -1)
	end

	local thumb = _G[scrollFrame:GetName() .. "ScrollBarThumbTexture"]
	if thumb then
		thumb:SetWidth(18)
		thumb:ClearAllPoints()
		thumb:SetPoint("RIGHT", scrollFrame.ScrollBar, "RIGHT", 1.8, 0)
	end

	local bg = scrollFrame:CreateTexture(nil, "BACKGROUND", nil, -6)
	bg:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar")
	bg:SetTexCoord(0, 0.45, 0.1640625, 1)
	bg:SetPoint("TOPLEFT", scrollFrame.ScrollBar, -5, 16)
	bg:SetPoint("BOTTOMRIGHT", scrollFrame.ScrollBar, 5, -16)

	local scrollChild = CreateFrame("Frame", "EasySummonScrollChild", scrollFrame)
	local w, h = scrollFrame:GetSize()
	scrollChild:SetSize(w, h)
	scrollFrame:SetScrollChild(scrollChild)

	self.scrollFrame = scrollFrame
	self.scrollChild = scrollChild
end

function EasySummonUI:ToggleMainFrame()
	if self.frame:IsShown() then
		self.frame:Hide()
		if EasySummonSummonButton and EasySummonSummonButton.button then
			EasySummonSummonButton.button:Hide()
		end
	else
		self.frame:Show()
		EasySummonGroupUtils:UpdateGroupSizeText()
	end
end
