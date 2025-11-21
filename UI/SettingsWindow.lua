-- UI/SettingsWindow.lua
EasySummonSettingsWindow = {}

function EasySummonSettingsWindow:Initialize()
	self:CreateSettingsFrame()
	self.frame:Hide()
end

function EasySummonSettingsWindow:CreateSettingsFrame()
	local frame = CreateFrame("Frame", "EasySummonSettingsFrame", UIParent, "BasicFrameTemplateWithInset")
	frame:SetSize(280, 350)
	frame:SetPoint("TOPLEFT", EasySummonFrame, "TOPRIGHT", 10, 0)
	frame:SetClampedToScreen(true)
	frame:SetFrameStrata("HIGH")
	frame:SetFrameLevel(51)

	-- Set the frame title
	frame.TitleBg:SetHeight(30)
	frame.TitleText:SetText("Custom Phrases")

	-- Close button is already part of BasicFrameTemplateWithInset
	frame.CloseButton:SetScript("OnClick", function()
		EasySummonSettingsWindow:Hide()
	end)

	-- Input field for new phrase
	local inputLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	inputLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -40)
	inputLabel:SetText("New Phrase:")

	local inputBox = CreateFrame("EditBox", "EasySummonPhraseInput", frame, "InputBoxTemplate")
	inputBox:SetAutoFocus(false)
	inputBox:SetSize(160, 20)
	inputBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -62)
	inputBox:SetMaxLetters(50)
	inputBox:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)

	-- Add button
	local addButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	addButton:SetSize(50, 21)
	addButton:SetPoint("LEFT", inputBox, "RIGHT", 8, 0)
	addButton:SetText("Add")
	addButton:SetFrameLevel(frame:GetFrameLevel() + 10)
	addButton:SetScript("OnClick", function()
		EasySummonSettingsWindow:AddPhrase()
	end)

	-- Instructions
	local instructionsText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	instructionsText:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -90)
	instructionsText:SetWidth(250)
	instructionsText:SetJustifyH("LEFT")
	instructionsText:SetText("|cFFFFCC00Click|r to delete a phrase")

	-- List of phrases
	local listLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	listLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -115)
	listLabel:SetText("Your Phrases:")

	-- Simple list container (no scroll frame, just display)
	local listContainer = CreateFrame("Frame", "EasySummonPhraseListContainer", frame)
	listContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -135)
	listContainer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -15, 10)

	self.frame = frame
	self.inputBox = inputBox
	self.listContainer = listContainer
	self.phraseButtons = {}
end

function EasySummonSettingsWindow:AddPhrase()
	local phrase = self.inputBox:GetText()

	if phrase == "" then
		print("|cFFFF3333EasySummon:|r Please enter a phrase")
		return
	end

	-- Convert to lowercase for consistency
	phrase = string.lower(phrase)

	-- Check if phrase already exists
	for _, existingPhrase in ipairs(EasySummonConfig.CustomPhrases) do
		if existingPhrase == phrase then
			print("|cFFFF3333EasySummon:|r Phrase already exists: " .. phrase)
			return
		end
	end

	-- Add the phrase
	table.insert(EasySummonConfig.CustomPhrases, phrase)
	self.inputBox:SetText("")
	self.inputBox:ClearFocus()

	print("|cFF33FF33EasySummon:|r Added phrase: " .. phrase)

	-- Update the display
	self:RefreshPhraseList()
end

function EasySummonSettingsWindow:RemovePhrase(phrase)
	for i, existingPhrase in ipairs(EasySummonConfig.CustomPhrases) do
		if existingPhrase == phrase then
			table.remove(EasySummonConfig.CustomPhrases, i)
			print("|cFF33FF33EasySummon:|r Removed phrase: " .. phrase)
			self:RefreshPhraseList()
			return
		end
	end
end

function EasySummonSettingsWindow:RefreshPhraseList()
	-- Hide all existing buttons
	for _, button in ipairs(self.phraseButtons) do
		button:Hide()
	end

	local itemHeight = 20
	local yOffset = 0

	-- Create or update phrase buttons
	for i, phrase in ipairs(EasySummonConfig.CustomPhrases) do
		local button = self.phraseButtons[i]

		if not button then
			button = CreateFrame("Button", "EasySummonSettingsPhrase" .. i, self.listContainer)
			button:SetSize(250, itemHeight)
			button:SetFrameLevel(self.listContainer:GetFrameLevel() + 1)
			button:RegisterForClicks("AnyUp")

			-- Create phrase text
			local phraseText = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			phraseText:SetPoint("LEFT", button, "LEFT", 5, 0)
			phraseText:SetWidth(230)
			phraseText:SetJustifyH("LEFT")
			button.phraseText = phraseText

			-- Set up click handler to delete
			button:SetScript("OnClick", function(self, mouseButton)
				EasySummonSettingsWindow:RemovePhrase(self.phraseData)
			end)

			-- Set up hover
			button:SetScript("OnEnter", function(self)
				self.phraseText:SetTextColor(1, 1, 1, 1)
				SetCursor("INTERACT_CURSOR")
			end)

			button:SetScript("OnLeave", function(self)
				self.phraseText:SetTextColor(0.8, 0.8, 0.8, 1)
				ResetCursor()
			end)

			self.phraseButtons[i] = button
		end

		-- Position the button
		button:SetPoint("TOPLEFT", self.listContainer, "TOPLEFT", 0, -yOffset)
		button.phraseText:SetText('• "' .. phrase .. '"')
		button.phraseText:SetTextColor(0.8, 0.8, 0.8, 1)
		button.phraseData = phrase

		button:Show()
		yOffset = yOffset + itemHeight
	end

	-- Show message if no phrases
	if #EasySummonConfig.CustomPhrases == 0 then
		if not self.emptyText then
			self.emptyText = self.listContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
			self.emptyText:SetPoint("CENTER", self.listContainer, "CENTER", 0, 0)
			self.emptyText:SetTextColor(0.5, 0.5, 0.5, 1)
		end
		self.emptyText:SetText("No custom phrases yet")
		self.emptyText:Show()
	else
		if self.emptyText then
			self.emptyText:Hide()
		end
	end
end

function EasySummonSettingsWindow:Show()
	self:RefreshPhraseList()
	self.frame:Show()
end

function EasySummonSettingsWindow:Hide()
	if self.frame then
		self.frame:Hide()
	end
end

function EasySummonSettingsWindow:Toggle()
	if not self.frame then
		return
	end
	if self.frame:IsShown() then
		self:Hide()
	else
		self:Show()
	end
end
