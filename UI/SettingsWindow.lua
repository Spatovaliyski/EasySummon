-- UI/SettingsWindow.lua
EasySummonSettingsWindow = {}

function EasySummonSettingsWindow:Initialize()
	self.phraseButtons = {}
end

function EasySummonSettingsWindow:AddPhrase()
	local inputBox = EasySummonUI.inputBox
	if not inputBox then
		return
	end

	local phrase = inputBox:GetText()

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
	inputBox:SetText("")
	inputBox:ClearFocus()

	print("|cFF33FF33EasySummon:|r Added phrase: " .. phrase)

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
	if not EasySummonUI.keywordsScroll or not EasySummonUI.keywordsListContainer then
		return
	end

	for _, button in ipairs(self.phraseButtons) do
		button:Hide()
	end

	local itemHeight = 20
	local yOffset = 0
	local scrollFrame = EasySummonUI.keywordsScroll
	local listContainer = EasySummonUI.keywordsListContainer

	local totalHeight = math.max(#EasySummonConfig.SummonKeywords * itemHeight, scrollFrame:GetHeight())
	listContainer:SetHeight(totalHeight)

	for i, phrase in ipairs(EasySummonConfig.SummonKeywords) do
		local button = self.phraseButtons[i]

		if not button then
			button = CreateFrame("Button", "EasySummonSettingsPhrase" .. i, listContainer)
			button:SetSize(230, itemHeight)
			button:SetFrameLevel(listContainer:GetFrameLevel() + 1)
			button:RegisterForClicks("AnyUp")

			local backgroundTexture = button:CreateTexture(nil, "BACKGROUND")
			backgroundTexture:SetAllPoints(button)
		backgroundTexture:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
		backgroundTexture:SetBlendMode("ADD")
		backgroundTexture:SetAlpha(0)
		button.backgroundTexture = backgroundTexture

		local phraseText = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		phraseText:SetPoint("LEFT", button, "LEFT", 5, 0)
		phraseText:SetWidth(210)
		phraseText:SetJustifyH("LEFT")
		button.phraseText = phraseText

		button:SetScript("OnClick", function(self, mouseButton)
			EasySummonSettingsWindow:RemovePhrase(self.phraseData)
		end)

		button:SetScript("OnEnter", function(self)
			self.phraseText:SetTextColor(1, 1, 1, 1)
			self.backgroundTexture:SetAlpha(0.15)
			SetCursor("INTERACT_CURSOR")
		end)

		button:SetScript("OnLeave", function(self)
			self.phraseText:SetTextColor(0.8, 0.8, 0.8, 1)
			self.backgroundTexture:SetAlpha(0)
			ResetCursor()
		end)

		self.phraseButtons[i] = button
	end

		button:SetPoint("TOPLEFT", listContainer, "TOPLEFT", 0, -(yOffset + 1))
		button.phraseText:SetText('• "' .. phrase .. '"')	
		button.phraseText:SetTextColor(1, 1, 1, 1)		
		button.phraseData = phrase

		button:Show()
		yOffset = yOffset + itemHeight
	end

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
