EasySummonRaidList = {
	buttons = {},
	gridButtons = {}, -- Separate pool for grid view
	partyLabels = {}, -- Party number labels for grid view
}

function EasySummonCore:UpdateRaidList()
	EasySummonRaidList:UpdateList(self.playerResponses)
end

function EasySummonRaidList:LoadTestData()
	-- Store original functions
	if not EasySummonGroupUtils._GetRaidStructure then
		EasySummonGroupUtils._GetRaidStructure = EasySummonGroupUtils.GetRaidStructure
	end
	if not EasySummonGroupUtils._GetGroupMembers then
		EasySummonGroupUtils._GetGroupMembers = EasySummonGroupUtils.GetGroupMembers
	end

	-- Override GetRaidStructure for grid view
	EasySummonGroupUtils.GetRaidStructure = function()
		local raidStructure = {}
		local classes = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }

		-- Initialize 8 groups with 5 slots each
		for groupNum = 1, 8 do
			raidStructure[groupNum] = {}

			-- Add 5 players per group
			for slot = 1, 5 do
				local playerNum = ((groupNum - 1) * 5) + slot

				if playerNum <= 20 then
					local classIndex = ((playerNum - 1) % #classes) + 1

					raidStructure[groupNum][slot] = {
						name = "Player " .. playerNum,
						class = classes[classIndex],
						isPlayer = playerNum == 1,
						isInInstance = false,
						inRange = playerNum % 3 == 0,
						zone = "Darnassus",
						online = true,
						unit = "raid" .. playerNum,
					}

					-- Make some players request summons
					if playerNum % 4 == 0 then
						if _G.EasySummonCore and _G.EasySummonCore.playerResponses then
							_G.EasySummonCore.playerResponses["Player " .. playerNum] = true
						end
					end
				else
					raidStructure[groupNum][slot] = nil
				end
			end
		end

		return raidStructure
	end

	-- Override GetGroupMembers for list view
	EasySummonGroupUtils.GetGroupMembers = function()
		local members = {}
		local classes = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }

		for i = 1, 20 do
			local classIndex = ((i - 1) % #classes) + 1

			table.insert(members, {
				name = "Player " .. i,
				class = classes[classIndex],
				isPlayer = i == 1,
				isInInstance = false,
				inRange = i % 3 == 0,
				zone = "Darnassus",
			})

			-- Make some players request summons
			if i % 4 == 0 then
				if _G.EasySummonCore and _G.EasySummonCore.playerResponses then
					_G.EasySummonCore.playerResponses["Player " .. i] = true
				end
			end
		end

		return members
	end

	-- Update the raid list immediately
	if _G.EasySummonCore then
		_G.EasySummonCore:UpdateRaidList()
	end

	print("|cFF33FF33EasySummon:|r Test data loaded with 20 players")
end

function EasySummonRaidList:UpdateList(playerResponses)
	-- Check which view mode we're in
	if EasySummonUI and EasySummonUI.viewMode == "grid" then
		self:UpdateGridView(playerResponses)
	else
		self:UpdateListView(playerResponses)
	end
end

function EasySummonRaidList:UpdateListView(playerResponses)
	for i, button in ipairs(self.buttons) do
		button:Hide()
	end

	-- Hide all grid buttons when in list view
	for i, button in ipairs(self.gridButtons) do
		button:Hide()
	end

	-- Hide all party labels when in list view
	for i, label in ipairs(self.partyLabels) do
		label:Hide()
	end

	local itemHeight = 40
	local members = EasySummonGroupUtils:GetGroupMembers()

	-- Check if the UI is available
	if not EasySummonUI or not EasySummonUI.scrollChild then
		C_Timer.After(0.5, function()
			EasySummonCore:UpdateRaidList()
		end)
		return
	end

	local scrollChild = EasySummonUI.scrollChild

	local playerInInstance, playerInstanceType = IsInInstance()
	playerInInstance = playerInInstance and playerInstanceType ~= "none"
	local inPVPInstance = playerInstanceType == "pvp" or playerInstanceType == "arena"

	-- Reset scroll child dimensions for list view
	scrollChild:SetWidth(EasySummonUI.scrollFrame:GetWidth())
	scrollChild:SetHeight(math.max(#members * itemHeight, EasySummonUI.scrollFrame:GetHeight()))

	for i, member in ipairs(members) do
		local hasAnswered = playerResponses[member.name] or false

		local buttonFrame = self.buttons[i]
		if not buttonFrame then
			buttonFrame = self:CreateMemberButton(scrollChild, i)
			self.buttons[i] = buttonFrame
		end

		buttonFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -((i - 1) * itemHeight))
		buttonFrame.memberName = member.name -- Store member name for click handler

		local classColor = RAID_CLASS_COLORS[member.class] or { r = 1, g = 1, b = 1 }
		local displayText = member.name

		if member.isPlayer then
			displayText = displayText .. " (You)"
		end

		-- Initialize display flags
		local clickable = false -- Determines if clicking the name should call DoSummon
		local textOpacity = 0.5
		local statusText = ""
		local isSummoned = false

		if playerInInstance then
			-- Player IS in instance
			if inPVPInstance then
				-- If Player is in instance and Member is in instance and in range but in battleground
				statusText = "In PVP Instance"
				clickable = false
				textOpacity = 0.7
			elseif not member.isInInstance then
				-- If Player in instance but Member is not in instance
				statusText = "Not Instanced"
				clickable = false
			elseif not member.inRange then
				-- If Player is in instance and Member is in instance but not in range
				statusText = ""
				clickable = true
				textOpacity = 1.0
			else
				-- If Player is in instance and Member is in instance and in range
				statusText = ""
				clickable = false
				if hasAnswered then
					isSummoned = true -- They requested summon but are now in range
				end
			end
		else
			-- Player is NOT in instance
			if member.isInInstance then
				statusText = "Instanced"
				textOpacity = 0.7
				clickable = false
			elseif member.inRange then
				-- If Player is not in instance and Member is not in instance but in range
				statusText = ""
				clickable = false
				if hasAnswered then
					isSummoned = true -- They requested summon but are now in range
				end
			else
				-- If Player is not in instance and Member is not in instance but not in range
				statusText = ""
				clickable = true
				textOpacity = 1.0
			end
		end

		-- never allow self-summon
		if member.isPlayer then
			clickable = false
		end

		-- Handle summon request logic
		local eligibleForSummonRequest = false

		-- Check if eligible for summon request (according to additional cases)
		if
			(not playerInInstance and not member.isInInstance and not member.inRange)
			or (playerInInstance and member.isInInstance and not member.inRange)
		then
			eligibleForSummonRequest = true
		end

		-- Apply summon request status
		if hasAnswered then
			if isSummoned then
				-- Player has been summoned (they requested and are now in range)
				statusText = "Summoned"
				textOpacity = 0.7
				clickable = false
			elseif eligibleForSummonRequest then
				-- Player still needs to be summoned
				statusText = "Summon Requested"
				textOpacity = 1.0
				clickable = true
			end
		end

		-- Apply the calculated settings
		buttonFrame.nameText:SetText(displayText)
		buttonFrame.nameText:SetTextColor(classColor.r, classColor.g, classColor.b, textOpacity)

		-- Set zone text
		if member.zone and member.zone ~= "" then
			buttonFrame.zoneText:SetText(member.zone)
			buttonFrame.zoneText:Show()
		else
			buttonFrame.zoneText:SetText("Unknown location")
			buttonFrame.zoneText:Show()
		end

		-- Set status text
		if statusText ~= "Summon Requested" then
			buttonFrame.statusText:SetText(statusText)
		else
			buttonFrame.statusText:SetText("")
		end

		if statusText == "Summoned" then
			buttonFrame.statusText:SetTextColor(1, 1, 0, textOpacity) -- Yellow color for summoned
		else
			buttonFrame.statusText:SetTextColor(1, 1, 1, textOpacity)
		end

		-- Show/hide request icon based on summon request status
		if statusText == "Summon Requested" then
			buttonFrame.requestIcon:Show()
		else
			buttonFrame.requestIcon:Hide()
		end

		-- Set clickable status
		buttonFrame.clickable = clickable

		-- Set highlight visibility based on clickable status
		if clickable then
			-- Set the highlight texture for mouseover
			buttonFrame:SetHighlightTexture("Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar", "ADD")

			-- Create or update background highlight for clickable rows
			if not buttonFrame.backgroundHighlight then
				buttonFrame.backgroundHighlight = buttonFrame:CreateTexture(nil, "BACKGROUND")
				buttonFrame.backgroundHighlight:SetAllPoints()
				buttonFrame.backgroundHighlight:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
				buttonFrame.backgroundHighlight:SetBlendMode("ADD")
				buttonFrame.backgroundHighlight:SetAlpha(0.15)
				buttonFrame.backgroundHighlight:SetVertexColor(0.7, 0.8, 1.0)
			end
			buttonFrame.backgroundHighlight:Show()

			-- Enable mouse interaction
			buttonFrame:EnableMouse(true)

			-- Add clickable cursor
			buttonFrame:SetScript("OnEnter", function(self)
				if self.clickable then
					SetCursor("INTERACT_CURSOR")
					-- Increase highlight intensity on hover
					self.backgroundHighlight:SetAlpha(0.3)
				end
			end)

			buttonFrame:SetScript("OnLeave", function(self)
				ResetCursor()
				-- Restore normal highlight intensity
				self.backgroundHighlight:SetAlpha(0.15)
			end)
		else
			-- Use empty texture for non-clickable rows
			buttonFrame:SetHighlightTexture("Interface\\Buttons\\UI-EmptySlot", "ADD")
			local highlightTexture = buttonFrame:GetHighlightTexture()
			if highlightTexture then
				highlightTexture:SetAlpha(0)
			end

			-- Hide the background highlight for non-clickable rows
			if buttonFrame.backgroundHighlight then
				buttonFrame.backgroundHighlight:Hide()
			end

			-- Still keep mouse enabled for right-click menu
			buttonFrame:EnableMouse(true)

			-- Remove clickable cursor
			buttonFrame:SetScript("OnEnter", nil)
			buttonFrame:SetScript("OnLeave", nil)
		end

		-- Hide separator on the last item
		if i == #members then
			buttonFrame.separator:Hide()
		else
			buttonFrame.separator:Show()
		end

		buttonFrame:Show()
	end
end

function EasySummonRaidList:CreateMemberButton(parent, index)
	local buttonFrame = CreateFrame("Button", "EasySummonListButton" .. index, parent)
	buttonFrame:SetSize(340, 40)
	buttonFrame:SetFrameLevel(parent:GetFrameLevel() + 1)
	buttonFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	-- Set up click handler
	buttonFrame:SetScript("OnClick", function(self, button)
		if button == "LeftButton" and self.clickable then
			EasySummonSummonButton:DoSummon(self.memberName, self)
		elseif button == "RightButton" then
			local responses = _G.EasySummonCore.playerResponses
			if responses and responses[self.memberName] then
				-- Show context menu on right-click
				local menu = {
					{ text = self.memberName, isTitle = true },
					{
						text = "Clear summon status",
						func = function()
							_G.EasySummonCore:ResetResponse(self.memberName)
						end,
					},
				}
				EasyMenu(
					menu,
					CreateFrame("Frame", "EasySummonContextMenu", UIParent, "UIDropDownMenuTemplate"),
					"cursor",
					0,
					0,
					"MENU"
				)
			end
		end
	end)

	-- Create name text (positioned higher to make room for zone)
	local nameText = buttonFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	nameText:SetPoint("TOPLEFT", 10, -7)
	nameText:SetWidth(0) -- Auto-size based on text
	nameText:SetJustifyH("LEFT")
	nameText:SetWordWrap(false)
	buttonFrame.nameText = nameText

	-- Create request icon (shown next to name when summon is requested)
	local requestIconFrame = CreateFrame("Frame", nil, buttonFrame)
	requestIconFrame:SetSize(16, 16)
	requestIconFrame:SetPoint("LEFT", nameText, "RIGHT", 3, 0)

	local requestIcon = requestIconFrame:CreateTexture(nil, "OVERLAY")
	requestIcon:SetAllPoints(requestIconFrame)
	requestIcon:SetTexture("Interface\\AddOns\\EasySummon\\Textures\\request.png")

	-- Add tooltip on hover
	requestIconFrame:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Requested summon", 1, 1, 1)
		GameTooltip:Show()
	end)

	requestIconFrame:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	requestIconFrame:Hide()
	buttonFrame.requestIcon = requestIconFrame

	-- Create zone text (smaller and positioned below name)
	local zoneText = buttonFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	zoneText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -4)
	zoneText:SetWidth(180)
	zoneText:SetJustifyH("LEFT")
	zoneText:SetTextColor(0.5, 0.5, 0.5, 0.5) -- Dark gray color
	buttonFrame.zoneText = zoneText

	-- Create status text (right-aligned)
	local statusText = buttonFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	statusText:SetPoint("RIGHT", buttonFrame, "RIGHT", -10, 0)
	statusText:SetWidth(120)
	statusText:SetJustifyH("RIGHT")
	buttonFrame.statusText = statusText

	-- Add separator
	local separator = buttonFrame:CreateTexture(nil, "BACKGROUND")
	separator:SetHeight(1)
	separator:SetColorTexture(0, 0, 0, 0.3)
	separator:SetPoint("BOTTOMLEFT", buttonFrame, "BOTTOMLEFT", 0, 0)
	separator:SetPoint("BOTTOMRIGHT", buttonFrame, "BOTTOMRIGHT", 0, 0)
	buttonFrame.separator = separator

	buttonFrame:SetHighlightTexture("Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar", "ADD")

	return buttonFrame
end
-- Grid View Functions
function EasySummonRaidList:UpdateGridView(playerResponses)
	-- Hide all list view buttons
	for i, button in ipairs(self.buttons) do
		button:Hide()
	end

	-- Get raid structure
	local raidStructure = EasySummonGroupUtils:GetRaidStructure()

	-- Check if the UI is available
	if not EasySummonUI or not EasySummonUI.scrollChild then
		C_Timer.After(0.5, function()
			EasySummonCore:UpdateRaidList()
		end)
		return
	end

	local scrollChild = EasySummonUI.scrollChild

	local playerInInstance, playerInstanceType = IsInInstance()
	playerInInstance = playerInInstance and playerInstanceType ~= "none"
	local inPVPInstance = playerInstanceType == "pvp" or playerInstanceType == "arena"

	-- Fixed grid settings
	local cellWidth = 155
	local cellHeight = 30
	local cellPadding = 4
	local partySpacing = 4 -- Horizontal spacing between party columns
	local rowSpacing = 20 -- Vertical spacing between party rows
	local partyLabelHeight = 16 -- Height reserved for party label
	local startX = 4 -- Left margin
	local startY = -5

	-- Layout: 4 vertical party columns per row
	-- Each party column has 5 players stacked vertically
	-- 2 rows of parties (8 parties total)
	local partyHeight = (cellHeight * 5) + (cellPadding * 4) + partyLabelHeight -- 5 players tall + label
	local partyWidth = cellWidth

	-- Set fixed scroll child dimensions (ALWAYS set both width and height)
	local totalWidth = (partyWidth * 4) + (partySpacing * 3) + (startX * 2)
	local totalHeight = (partyHeight * 2) + rowSpacing + (startY * -2)
	scrollChild:SetWidth(totalWidth)
	scrollChild:SetHeight(totalHeight)

	-- Create party labels (8 parties)
	for groupNum = 1, 8 do
		if not self.partyLabels[groupNum] then
			local label = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
			label:SetTextColor(0.4, 0.4, 0.4, 1)
			label:SetJustifyH("LEFT")
			label:SetFont(label:GetFont(), 10)
			self.partyLabels[groupNum] = label
		end

		local partyRow = math.floor((groupNum - 1) / 4)
		local partyCol = (groupNum - 1) % 4
		local x = startX + (partyCol * (partyWidth + partySpacing))
		local y = startY - (partyRow * (partyHeight + rowSpacing))

		local label = self.partyLabels[groupNum]
		label:ClearAllPoints()
		label:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", x + 2, y - 2)
		label:SetText("Party " .. groupNum)
		label:Show()
	end

	-- Pre-create all 40 slots (8 parties × 5 players)
	for slotIndex = 1, 40 do
		-- Ensure button exists
		if not self.gridButtons[slotIndex] then
			self.gridButtons[slotIndex] = self:CreateGridButton(scrollChild, slotIndex)
		end
	end

	-- Now fill in the player data
	local slotIndex = 1
	for groupNum = 1, 8 do
		-- Calculate which party row and column this group is in
		-- 4 parties per row: groups 1-4 in row 0, groups 5-8 in row 1
		local partyRow = math.floor((groupNum - 1) / 4) -- 0, 0, 0, 0, 1, 1, 1, 1
		local partyCol = (groupNum - 1) % 4 -- 0, 1, 2, 3, 0, 1, 2, 3

		for playerSlot = 1, 5 do
			local buttonFrame = self.gridButtons[slotIndex]

			-- Calculate position:
			-- X: party column (0-3)
			-- Y: party row + player slot within party (vertically stacked), offset by label height
			local x = startX + (partyCol * (partyWidth + partySpacing))
			local y = startY
				- (partyRow * (partyHeight + rowSpacing))
				- partyLabelHeight
				- ((playerSlot - 1) * (cellHeight + cellPadding))

			-- Set position and size
			buttonFrame:ClearAllPoints()
			buttonFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", x, y)
			buttonFrame:SetSize(cellWidth, cellHeight)

			-- Get member data for this slot
			local member = raidStructure[groupNum][playerSlot]

			-- Set alternating party background for visual separation
			-- Odd parties (1,3,5,7) get slightly darker background
			if groupNum % 2 == 1 then
				buttonFrame:SetBackdropColor(0, 0, 0, 0.15)
			else
				buttonFrame:SetBackdropColor(0, 0, 0, 0.05)
			end

			if member then
				-- Filled slot
				self:UpdateFilledGridSlot(buttonFrame, member, playerResponses, playerInInstance, inPVPInstance)
			else
				-- Empty slot
				self:UpdateEmptyGridSlot(buttonFrame)
			end

			buttonFrame:Show()
			slotIndex = slotIndex + 1
		end
	end
end

function EasySummonRaidList:CreateGridButton(parent, index)
	local buttonFrame = CreateFrame("Button", "EasySummonGridButton" .. index, parent, "BackdropTemplate")
	buttonFrame:SetFrameLevel(parent:GetFrameLevel() + 1)
	buttonFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	-- Set backdrop without border
	buttonFrame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		tile = false,
		tileSize = 0,
		edgeSize = 0,
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
	})

	-- Set black background color
	buttonFrame:SetBackdropColor(0, 0, 0, 0.6)

	-- Store reference for later color changes
	buttonFrame.backdrop = true

	-- Name text (left aligned)
	local nameText = buttonFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	nameText:SetPoint("LEFT", buttonFrame, "LEFT", 5, 0)
	nameText:SetWidth(0) -- Auto-width
	nameText:SetJustifyH("LEFT")
	nameText:SetWordWrap(false)
	buttonFrame.nameText = nameText

	-- Request icon (small, right of name)
	local requestIconFrame = CreateFrame("Frame", nil, buttonFrame)
	requestIconFrame:SetSize(12, 12)
	requestIconFrame:SetPoint("LEFT", nameText, "RIGHT", 2, 0)

	local requestIcon = requestIconFrame:CreateTexture(nil, "OVERLAY")
	requestIcon:SetAllPoints(requestIconFrame)
	requestIcon:SetTexture("Interface\\AddOns\\EasySummon\\Textures\\request.png")
	requestIconFrame:Hide()
	buttonFrame.requestIcon = requestIconFrame

	-- Zone text (right after request icon or name)
	local zoneText = buttonFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	zoneText:SetPoint("LEFT", requestIconFrame, "RIGHT", 3, 0)
	zoneText:SetPoint("RIGHT", buttonFrame, "RIGHT", -5, 0)
	zoneText:SetJustifyH("LEFT")
	zoneText:SetWordWrap(false)
	zoneText:SetTextColor(0.7, 0.7, 0.7)
	buttonFrame.zoneText = zoneText

	return buttonFrame
end

function EasySummonRaidList:UpdateFilledGridSlot(buttonFrame, member, playerResponses, playerInInstance, inPVPInstance)
	local hasAnswered = playerResponses[member.name] or false

	buttonFrame.memberName = member.name

	local classColor = RAID_CLASS_COLORS[member.class] or { r = 1, g = 1, b = 1 }

	-- Initialize display flags
	local clickable = false
	local textOpacity = 0.5
	local isSummoned = false
	local showGreenOverlay = false

	if playerInInstance then
		if inPVPInstance then
			clickable = false
			textOpacity = 0.7
		elseif not member.isInInstance then
			clickable = false
		elseif not member.inRange then
			clickable = true
			textOpacity = 1.0
		else
			clickable = false
			if hasAnswered then
				isSummoned = true
				showGreenOverlay = true
			end
		end
	else
		if member.isInInstance then
			textOpacity = 0.7
			clickable = false
		elseif member.inRange then
			clickable = false
			if hasAnswered then
				isSummoned = true
				showGreenOverlay = true
			end
		else
			clickable = true
			textOpacity = 1.0
		end
	end

	if member.isPlayer then
		clickable = false
	end

	-- Check if eligible for summon request
	local eligibleForSummonRequest = false
	if
		(not playerInInstance and not member.isInInstance and not member.inRange)
		or (playerInInstance and member.isInInstance and not member.inRange)
	then
		eligibleForSummonRequest = true
	end

	-- Apply summon request status
	if hasAnswered then
		if isSummoned then
			textOpacity = 0.7
			clickable = false
			showGreenOverlay = false
		elseif eligibleForSummonRequest then
			textOpacity = 1.0
			clickable = true
		end
	end

	if showGreenOverlay then
		buttonFrame:SetBackdropColor(0, 0.3, 0, 0.2)
	elseif isSummoned then
		buttonFrame:SetBackdropColor(0.3, 0.3, 0, 0.2)
	elseif clickable then
		buttonFrame:SetBackdropColor(0.15, 0.15, 0.15, 0.3)
	end

	-- Set name with class color
	buttonFrame.nameText:SetText(member.name)
	buttonFrame.nameText:SetTextColor(classColor.r, classColor.g, classColor.b, textOpacity)

	-- Show request icon if summon requested and not summoned
	if hasAnswered and eligibleForSummonRequest and not isSummoned then
		buttonFrame.requestIcon:Show()
	else
		buttonFrame.requestIcon:Hide()
	end

	-- Hide zone text in grid view
	buttonFrame.zoneText:SetText("")

	-- Set clickable status
	buttonFrame.clickable = clickable

	if clickable then
		buttonFrame:SetHighlightTexture("Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar", "ADD")
		local highlight = buttonFrame:GetHighlightTexture()
		if highlight then
			highlight:ClearAllPoints()
			highlight:SetPoint("TOPLEFT", buttonFrame, "TOPLEFT", 1, -1)
			highlight:SetPoint("BOTTOMRIGHT", buttonFrame, "BOTTOMRIGHT", -1, 1)
		end
		buttonFrame:EnableMouse(true)

		buttonFrame:SetScript("OnEnter", function(self)
			if self.clickable then
				SetCursor("INTERACT_CURSOR")
			end
			-- Show tooltip with full info
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			local displayName = member.name
			if member.level and member.level > 0 then
				displayName = member.name .. " (" .. member.level .. ")"
			end
			GameTooltip:SetText(displayName, classColor.r, classColor.g, classColor.b)
			GameTooltip:AddLine(member.zone, 1, 1, 1)
			if hasAnswered and eligibleForSummonRequest then
				GameTooltip:AddLine("Summon Requested", 1, 1, 0)
			elseif isSummoned then
				GameTooltip:AddLine("Summoned", 1, 1, 0)
			end
			GameTooltip:Show()
		end)

		buttonFrame:SetScript("OnLeave", function(self)
			ResetCursor()
			GameTooltip:Hide()
		end)
	else
		buttonFrame:SetHighlightTexture("")
		buttonFrame:EnableMouse(true)

		-- Still show tooltip but no cursor change
		buttonFrame:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			local displayName = member.name
			if member.level and member.level > 0 then
				displayName = member.name .. " (" .. member.level .. ")"
			end
			GameTooltip:SetText(displayName, classColor.r, classColor.g, classColor.b)
			GameTooltip:AddLine(member.zone, 1, 1, 1)
			if isSummoned then
				GameTooltip:AddLine("Summoned", 1, 1, 0)
			end
			GameTooltip:Show()
		end)

		buttonFrame:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)
	end

	-- Click handler
	buttonFrame:SetScript("OnClick", function(self, button)
		if button == "LeftButton" and self.clickable then
			EasySummonSummonButton:DoSummon(self.memberName, self)
		end
	end)
end

function EasySummonRaidList:UpdateEmptyGridSlot(buttonFrame)
	-- Empty slot styling
	buttonFrame:SetBackdropColor(0, 0, 0, 0.3)
	buttonFrame.nameText:SetText("")
	buttonFrame.zoneText:SetText("")
	buttonFrame.requestIcon:Hide()
	buttonFrame.memberName = nil
	buttonFrame.clickable = false

	-- Disable interaction
	buttonFrame:EnableMouse(false)
	buttonFrame:SetHighlightTexture("")
	buttonFrame:SetScript("OnEnter", nil)
	buttonFrame:SetScript("OnLeave", nil)
	buttonFrame:SetScript("OnClick", nil)
end
