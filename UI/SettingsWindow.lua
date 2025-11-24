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
	frame.TitleText:SetText("Summon Keywords")

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
	instructionsText:SetText("Click to delete a phrase")

	-- Import button
	local importButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	importButton:SetSize(50, 21)
	importButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -15, -90)
	importButton:SetText("Import")
	importButton:SetFrameLevel(frame:GetFrameLevel() + 10)
	importButton:SetScript("OnClick", function()
		EasySummonSettingsWindow:ImportDefaults()
	end)

	-- List of phrases
	local listLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	listLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -115)
	listLabel:SetText("Your Phrases:")

	-- Create scroll frame for phrases with inset
	local inset = CreateFrame("Frame", nil, frame, "InsetFrameTemplate3")
	inset:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -135)
	inset:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 5)

	local scrollFrame = CreateFrame("ScrollFrame", "EasySummonSettingsScrollFrame", inset, "UIPanelScrollFrameTemplate")
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

	-- Create scroll child
	local listContainer = CreateFrame("Frame", "EasySummonPhraseListContainer", scrollFrame)
	local w, h = scrollFrame:GetSize()
	listContainer:SetSize(w, h)
	scrollFrame:SetScrollChild(listContainer)

	self.frame = frame
	self.inputBox = inputBox
	self.scrollFrame = scrollFrame
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
	for _, existingPhrase in ipairs(EasySummonConfig.SummonKeywords) do
		if existingPhrase == phrase then
			print("|cFFFF3333EasySummon:|r Phrase already exists: " .. phrase)
			return
		end
	end

	-- Add the phrase
	table.insert(EasySummonConfig.SummonKeywords, phrase)
	self.inputBox:SetText("")
	self.inputBox:ClearFocus()

	print("|cFF33FF33EasySummon:|r Added phrase: " .. phrase)

	-- Update the display
	self:RefreshPhraseList()
end

function EasySummonSettingsWindow:RemovePhrase(phrase)
	for i, existingPhrase in ipairs(EasySummonConfig.SummonKeywords) do
		if existingPhrase == phrase then
			table.remove(EasySummonConfig.SummonKeywords, i)
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
	local scrollFrame = _G["EasySummonSettingsScrollFrame"]
	local listContainer = self.listContainer

	-- Set scroll child height based on number of phrases
	local totalHeight = math.max(#EasySummonConfig.SummonKeywords * itemHeight, scrollFrame:GetHeight())
	listContainer:SetHeight(totalHeight)

	-- Create or update phrase buttons
	for i, phrase in ipairs(EasySummonConfig.SummonKeywords) do
		local button = self.phraseButtons[i]

		if not button then
			button = CreateFrame("Button", "EasySummonSettingsPhrase" .. i, listContainer)
			button:SetSize(250, itemHeight)
			button:SetFrameLevel(listContainer:GetFrameLevel() + 1)
			button:RegisterForClicks("AnyUp")

			-- Create background texture for hover effect
			local backgroundTexture = button:CreateTexture(nil, "BACKGROUND")
			backgroundTexture:SetAllPoints(button)
			backgroundTexture:SetColorTexture(0.3, 0.3, 0.5, 0)
			button.backgroundTexture = backgroundTexture

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
				self.backgroundTexture:SetAlpha(0.3)
				SetCursor("INTERACT_CURSOR")
			end)

			button:SetScript("OnLeave", function(self)
				self.phraseText:SetTextColor(0.8, 0.8, 0.8, 1)
				self.backgroundTexture:SetAlpha(0)
				ResetCursor()
			end)

			self.phraseButtons[i] = button
		end

		-- Position the button
		button:SetPoint("TOPLEFT", listContainer, "TOPLEFT", 0, -yOffset)
		button.phraseText:SetText('• "' .. phrase .. '"')
		button.phraseText:SetTextColor(0.8, 0.8, 0.8, 1)
		button.phraseData = phrase

		button:Show()
		yOffset = yOffset + itemHeight
	end

	-- Show message if no phrases
	if #EasySummonConfig.SummonKeywords == 0 then
		if not self.emptyText then
			self.emptyText = listContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
			self.emptyText:SetPoint("CENTER", listContainer, "CENTER", 0, 0)
			self.emptyText:SetTextColor(0.5, 0.5, 0.5, 1)
		end
		self.emptyText:SetText("No keywords yet")
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

function EasySummonSettingsWindow:ImportDefaults()
	local defaultKeywords = {
		"123",
		"+",
		"++",
		"+++",
		"sum",
		"summ pls",
		"summon please",
		"summon pls",
		"summon plz",
		"summon",
		"summon me",
		"tp me",
		"warlock taxi",
		"lock taxi",
		"lock sum",
		"lock port",
		"lock summon",
		"any sum",
		"any summon",
	}

	local imported = 0
	local skipped = 0

	for _, keyword in ipairs(defaultKeywords) do
		local found = false
		for _, existing in ipairs(EasySummonConfig.SummonKeywords) do
			if existing == keyword then
				found = true
				skipped = skipped + 1
				break
			end
		end

		if not found then
			table.insert(EasySummonConfig.SummonKeywords, keyword)
			imported = imported + 1
		end
	end

	if imported > 0 then
		print(
			"|cFF33FF33EasySummon:|r Imported "
				.. imported
				.. " default keywords"
				.. (skipped > 0 and " (" .. skipped .. " already existed)" or "")
		)
	else
		print("|cFFFFCC00EasySummon:|r All default keywords already exist")
	end

	self:RefreshPhraseList()
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
