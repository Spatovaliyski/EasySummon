EasySummonSummonButton = {
	button = nil,
	summonInProgress = false,
}

-- Track summon cast state to prevent spam
local summonCastTracker = CreateFrame("Frame")
summonCastTracker:RegisterEvent("UNIT_SPELLCAST_START")
summonCastTracker:RegisterEvent("UNIT_SPELLCAST_STOP")
summonCastTracker:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
summonCastTracker:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")

summonCastTracker:SetScript("OnEvent", function(self, event, unit, castGUID, spellId)
	if unit ~= "player" then
		return
	end

	if event == "UNIT_SPELLCAST_START" then
		-- Ritual of Summoning: 698
		if spellId == 698 then
			EasySummonSummonButton.summonInProgress = true
		end
	elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
		-- Ritual of Summoning (channel): 46546
		if spellId == 46546 then
			if UnitExists("target") and UnitIsPlayer("target") and not UnitIsUnit("target", "player") then
				local targetName = GetUnitName("target", true) or GetUnitName("target")
				if targetName then
					EasySummonMessages:AnnounceChannelStart(targetName)
				end
			end
		end
	elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_INTERRUPTED" then
		if spellId == 698 then
			EasySummonSummonButton.summonInProgress = false
		end
	end
end)

function EasySummonSummonButton:DoSummon(name, anchorFrame)
	-- Prevent spam if summon is already in progress
	if self.summonInProgress then
		return
	end
	local channel = IsInRaid() and "RAID" or "PARTY"

	-- Create macro for summoning
	local macroName = "SH_Summon"
	local macroIcon = "INV_MISC_QUESTIONMARK"
	local macroText = "/targetexact " .. name .. "\n/cast Ritual of Summoning"

	local macroIndex = GetMacroIndexByName(macroName)
	if macroIndex > 0 then
		DeleteMacro(macroIndex)
	end

	CreateMacro(macroName, macroIcon, macroText, false)

	-- Hide any existing button
	if self.button then
		self.button:Hide()
		self.button = nil
	end

	-- Create the summoning button, passing the anchor frame
	self:CreateSummonButton(name, macroText, anchorFrame)
end

function EasySummonSummonButton:CreateSummonButton(name, macroText, anchorFrame)
	-- Get the scroll frame
	local scrollFrame = _G["EasySummonScrollFrame"]

	-- Create button as a direct child of the scroll frame (not UIParent)
	-- This ensures it respects the scroll frame's boundaries
	local button = CreateFrame("Button", "EasySummonQuickButton", scrollFrame, "SecureActionButtonTemplate")

	button:SetFrameStrata("HIGH")
	button:SetFrameLevel(100) -- High enough to be above list items
	button:SetSize(80, 30)

	if anchorFrame then
		local point, relativeTo, relativePoint, xOfs, yOfs = anchorFrame:GetPoint()

		local buttonX = -80
		local buttonY = 0

		button:SetPoint("LEFT", anchorFrame, "RIGHT", buttonX, buttonY)
	else
		-- Default position
		button:SetPoint("CENTER", scrollFrame, "CENTER", 0, 0)
	end

	button:SetMouseClickEnabled(true)
	button:RegisterForClicks("LeftButtonUp", "LeftButtonDown")

	-- Set attributes for macro functionality
	button:SetAttribute("type", "macro")
	button:SetAttribute("macrotext", macroText)

	-- Apply visual styling to match UIPanelButtonTemplate
	local ntex = button:CreateTexture()
	ntex:SetTexture("Interface/Buttons/UI-Panel-Button-Up")
	ntex:SetTexCoord(0, 0.625, 0, 0.6875)
	ntex:SetAllPoints()
	button:SetNormalTexture(ntex)

	local htex = button:CreateTexture()
	htex:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
	htex:SetTexCoord(0, 0.625, 0, 0.6875)
	htex:SetAllPoints()
	button:SetHighlightTexture(htex)

	local ptex = button:CreateTexture()
	ptex:SetTexture("Interface/Buttons/UI-Panel-Button-Down")
	ptex:SetTexCoord(0, 0.625, 0, 0.6875)
	ptex:SetAllPoints()
	button:SetPushedTexture(ptex)

	-- Add button text
	local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	text:SetPoint("CENTER", 0, 0)
	text:SetText("Summon")
	button.text = text

	-- Add close button
	local closeButton = CreateFrame("Button", nil, button, "UIPanelCloseButton")
	closeButton:SetSize(16, 16)
	closeButton:SetPoint("TOPRIGHT", button, "TOPRIGHT", 2, 2)
	closeButton:SetScript("OnClick", function()
		button:Hide()
		self.button = nil
	end)

	-- Visibility check - hide button if it gets scrolled out of view
	if scrollFrame then
		scrollFrame:HookScript("OnVerticalScroll", function(self, offset)
			if button and button:IsShown() then
				local buttonTop = button:GetTop()
				local buttonBottom = button:GetBottom()
				local frameTop = scrollFrame:GetTop()
				local frameBottom = scrollFrame:GetBottom()

				local bufferZone = 25

				if buttonBottom > frameTop - bufferZone or buttonTop < frameBottom + bufferZone then
					button:Hide()
					C_Timer.After(0.1, function()
						if self.button == button then
							self.button = nil
						end
					end)
				else
					button:Show()
				end
			end
		end)

		scrollFrame:HookScript("OnScrollRangeChanged", function()
			if button and button:IsShown() then
				local buttonTop = button:GetTop()
				local buttonBottom = button:GetBottom()
				local frameTop = scrollFrame:GetTop()
				local frameBottom = scrollFrame:GetBottom()

				local bufferZone = 25

				if buttonBottom > frameTop - bufferZone or buttonTop < frameBottom + bufferZone then
					button:Hide()
					C_Timer.After(0.1, function()
						if self.button == button then
							self.button = nil
						end
					end)
				else
					button:Show()
				end
			end
		end)
	end

	-- Auto-hide after 20 seconds
	C_Timer.After(20, function()
		if button and button:IsShown() then
			button:Hide()
			self.button = nil
		end
	end)

	self.button = button
	return button
end
