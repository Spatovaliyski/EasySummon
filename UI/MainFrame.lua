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
		EasySummonUI:ToggleSettings()
	end)

	self.settingsButton = settingsButton
	self.settingsExpanded = false

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

		if _G.EasySummonCore then
			_G.EasySummonCore:SetActive(false)
		end
	end)

	self.frame = frame
	self:CreateScrollFrame()
	self:CreateSettingsPanel()
end

function EasySummonUI:CreateScrollFrame()
	local inset = CreateFrame("Frame", nil, self.frame, "InsetFrameTemplate3")
	inset:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 8, -62)
	inset:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 8, 26)
	inset:SetWidth(EasySummonConfig.FrameWidth - 18)

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

	-- phase background
	local bgTexture = scrollChild:CreateTexture(nil, "BACKGROUND")
	bgTexture:SetAllPoints(scrollChild)
	bgTexture:SetTexture("Interface\\AddOns\\EasySummon\\Textures\\art")
	bgTexture:SetAlpha(0.1)

	self.scrollFrame = scrollFrame
	self.scrollChild = scrollChild
	self.inset = inset
end

function EasySummonUI:CreateSettingsPanel()
	local settingsPanel = CreateFrame("Frame", "EasySummonSettingsPanel", self.frame)
	settingsPanel:SetPoint("TOPLEFT", self.inset, "TOPRIGHT", 10, 0)
	settingsPanel:SetPoint("BOTTOMLEFT", self.inset, "BOTTOMRIGHT", 10, 0)
	settingsPanel:SetWidth(270)
	settingsPanel:Hide()

	-- Notify checkbox
	local notifyCheckbox =
		CreateFrame("CheckButton", "EasySummonNotifyCheckbox", settingsPanel, "UICheckButtonTemplate")
	notifyCheckbox:SetSize(24, 24)
	notifyCheckbox:SetPoint("TOPLEFT", settingsPanel, "TOPLEFT", 15, -10)
	notifyCheckbox:SetChecked(EasySummonConfig.NotifyWhenHidden)
	_G[notifyCheckbox:GetName() .. "Text"]:SetText("Show toast notification")
	notifyCheckbox:SetScript("OnClick", function(self)
		EasySummonConfig.NotifyWhenHidden = self:GetChecked()
	end)

	-- Divider
	local divider = settingsPanel:CreateTexture(nil, "ARTWORK")
	divider:SetHeight(1)
	divider:SetPoint("LEFT", 15, 0)
	divider:SetPoint("RIGHT", -15, 0)
	divider:SetPoint("TOP", notifyCheckbox, "BOTTOM", 0, -10)
	divider:SetColorTexture(0.3, 0.3, 0.3, 1)

	-- Keywords section title
	local keywordsTitle = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	keywordsTitle:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 0, -10)
	keywordsTitle:SetText("Summon Keywords")

	-- Input field for new phrase
	local inputLabel = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	inputLabel:SetPoint("TOPLEFT", keywordsTitle, "BOTTOMLEFT", 0, -8)
	inputLabel:SetText("New Keyword:")

	local inputBox = CreateFrame("EditBox", "EasySummonPhraseInput", settingsPanel, "InputBoxTemplate")
	inputBox:SetAutoFocus(false)
	inputBox:SetSize(160, 20)
	inputBox:SetPoint("TOPLEFT", inputLabel, "BOTTOMLEFT", 5, -5)
	inputBox:SetMaxLetters(50)
	inputBox:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)

	-- Add button
	local addButton = CreateFrame("Button", nil, settingsPanel, "UIPanelButtonTemplate")
	addButton:SetSize(50, 21)
	addButton:SetPoint("LEFT", inputBox, "RIGHT", 8, 0)
	addButton:SetText("Add")
	addButton:SetScript("OnClick", function()
		if EasySummonSettingsWindow then
			EasySummonSettingsWindow:AddPhrase()
		end
	end)

	-- Instructions
	local instructionsText = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	instructionsText:SetPoint("TOPLEFT", inputBox, "BOTTOMLEFT", -5, -5)
	instructionsText:SetWidth(130)
	instructionsText:SetJustifyH("LEFT")
	instructionsText:SetTextColor(0.7, 0.7, 0.7)
	instructionsText:SetText("Click to delete")

	-- Create scroll frame for keywords
	local keywordsInset = CreateFrame("Frame", nil, settingsPanel, "InsetFrameTemplate3")
	keywordsInset:SetPoint("TOPLEFT", instructionsText, "BOTTOMLEFT", -5, -10)
	keywordsInset:SetPoint("TOPRIGHT", settingsPanel, "TOPRIGHT", -15, 0)
	keywordsInset:SetHeight(250)

	local keywordsScroll =
		CreateFrame("ScrollFrame", "EasySummonKeywordsScrollFrame", keywordsInset, "UIPanelScrollFrameTemplate")
	keywordsScroll:SetPoint("TOPLEFT", keywordsInset, "TOPLEFT", 3, -3)
	keywordsScroll:SetPoint("BOTTOMRIGHT", keywordsInset, "BOTTOMRIGHT", -27, 3)

	keywordsScroll.targetScrollValue = 0
	keywordsScroll.scrollDuration = 0.15
	keywordsScroll.scrollElapsed = 0
	keywordsScroll.scrollStartValue = 0
	keywordsScroll.scrollIsAnimating = false

	keywordsScroll:EnableMouseWheel(true)
	keywordsScroll:SetScript("OnMouseWheel", function(self, delta)
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

	keywordsScroll:SetScript("OnUpdate", function(self, elapsed)
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

	keywordsScroll.ScrollBar:ClearAllPoints()
	keywordsScroll.ScrollBar:SetPoint("TOPLEFT", keywordsScroll, "TOPRIGHT", 7, -16)
	keywordsScroll.ScrollBar:SetPoint("BOTTOMLEFT", keywordsScroll, "BOTTOMRIGHT", 7, 16)

	local scrollUpButton = _G[keywordsScroll:GetName() .. "ScrollBarScrollUpButton"]
	if scrollUpButton then
		scrollUpButton:ClearAllPoints()
		scrollUpButton:SetPoint("BOTTOM", keywordsScroll.ScrollBar, "TOP", 1, -1)
	end

	local scrollDownButton = _G[keywordsScroll:GetName() .. "ScrollBarScrollDownButton"]
	if scrollDownButton then
		scrollDownButton:ClearAllPoints()
		scrollDownButton:SetPoint("TOP", keywordsScroll.ScrollBar, "BOTTOM", 1, -1)
	end

	local thumb = _G[keywordsScroll:GetName() .. "ScrollBarThumbTexture"]
	if thumb then
		thumb:SetWidth(18)
		thumb:ClearAllPoints()
		thumb:SetPoint("RIGHT", keywordsScroll.ScrollBar, "RIGHT", 1.8, 0)
	end

	local listContainer = CreateFrame("Frame", "EasySummonKeywordsListContainer", keywordsScroll)
	local w, h = keywordsScroll:GetSize()
	listContainer:SetSize(w, h)
	keywordsScroll:SetScrollChild(listContainer)

	-- Import button below keywords list
	local importLabel = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	importLabel:SetPoint("TOPLEFT", keywordsInset, "BOTTOMLEFT", 5, -6)
	importLabel:SetTextColor(0.7, 0.7, 0.7)
	importLabel:SetText("Import common keywords:")

	local importButton = CreateFrame("Button", nil, settingsPanel, "UIPanelButtonTemplate")
	importButton:SetSize(70, 21)
	importButton:SetPoint("LEFT", importLabel, "RIGHT", 5, 0)
	importButton:SetText("Import")
	importButton:SetScript("OnClick", function()
		if EasySummonSettingsWindow then
			EasySummonSettingsWindow:ImportDefaults()
		end
	end)

	self.settingsPanel = settingsPanel
	self.keywordsScroll = keywordsScroll
	self.keywordsListContainer = listContainer
	self.inputBox = inputBox
end

function EasySummonUI:ToggleSettings()
	if self.settingsExpanded then
		self.settingsExpanded = false
		self.settingsPanel:Hide()
		self.frame:SetWidth(EasySummonConfig.FrameWidth)
		self.inset:SetWidth(EasySummonConfig.FrameWidth - 18)
	else
		self.settingsExpanded = true
		self.settingsPanel:Show()
		self.frame:SetWidth(EasySummonConfig.FrameWidth + 280)
		self.inset:SetWidth(EasySummonConfig.FrameWidth - 18)
		if EasySummonSettingsWindow and EasySummonSettingsWindow.RefreshPhraseList then
			EasySummonSettingsWindow:RefreshPhraseList()
		end
	end
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
