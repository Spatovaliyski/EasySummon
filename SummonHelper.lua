local frame = CreateFrame("Frame", "SummonHelperFrame", UIParent, "BackdropTemplate")
frame:SetSize(400, 500)
frame:SetPoint("CENTER")
frame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/DialogFrame/UI-DialogBox-Border", edgeSize = 16})
frame:SetBackdropColor(0, 0, 0, 1.0)
frame:SetClampedToScreen(true)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:SetFrameStrata("HIGH")
frame:SetFrameLevel(100)

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
title:SetPoint("TOP", 0, -10)
title:SetText("Summon Helper")

-- Close Button
local closeButton = CreateFrame("Button", "SummonHelperCloseButton", frame, "UIPanelCloseButton")
closeButton:SetSize(24, 24)
closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
closeButton:SetScript("OnClick", function()
    frame:Hide()
end)

-- Scroll Frame
local scrollFrame = CreateFrame("ScrollFrame", "SummonHelperScrollFrame", frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetSize(360, 400)
scrollFrame:SetPoint("TOP", 0, -40)
scrollFrame:SetPoint("BOTTOM", 0, 40)

local scrollChild = CreateFrame("Frame", "SummonHelperScrollChild", scrollFrame)
scrollChild:SetWidth(360)
scrollFrame:SetScrollChild(scrollChild)

local scrollBar = _G["SummonHelperScrollFrameScrollBar"]
scrollBar:ClearAllPoints()
scrollBar:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", 0, -16)
scrollBar:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 0, 16)

local raidList = {}
local playerResponses = {}
local secureSummonButton

local function SetupSecureSummonButton()
    if not secureSummonButton then
        secureSummonButton = CreateFrame("Button", "SummonHelperSecureButton", UIParent, "SecureActionButtonTemplate")
        secureSummonButton:SetSize(1, 1)
        secureSummonButton:SetPoint("CENTER")
        secureSummonButton:SetAttribute("type", "macro")
        secureSummonButton:SetAttribute("macrotext", "")
        secureSummonButton:Hide()
    end
end

local function DoSummon(name)
    local channel = IsInRaid() and "RAID" or "PARTY"
    local macroName = "SH_Summon"
    local macroIcon = "INV_MISC_QUESTIONMARK"
    local macroText = "/targetexact " .. name .. "\n/cast Ritual of Summoning"
    local macroIndex = GetMacroIndexByName(macroName)
    if macroIndex > 0 then
        DeleteMacro(macroIndex)
    end
    
    CreateMacro(macroName, macroIcon, macroText, false)
    
    -- If an existing button exists, hide it
    if secureSummonButton then
        secureSummonButton:Hide()  -- Hide the previous secure button
        secureSummonButton = nil   -- Delete the reference to the old button
    end
    
    -- Create a new secure button - fix template syntax error
    secureSummonButton = CreateFrame("Button", "SummonHelperQuickButton", UIParent, "SecureActionButtonTemplate,UIPanelButtonTemplate")
    secureSummonButton:SetSize(200, 40)
    secureSummonButton:SetPoint("BOTTOM", frame, "TOPRIGHT", -100, 10)
    secureSummonButton:SetAttribute("type", "macro")
    secureSummonButton:SetAttribute("macrotext", macroText)
    
    -- Set the text directly using the button's text property
    secureSummonButton:SetText("Summon " .. name)
    
    -- Add a close button
    local closeButton = CreateFrame("Button", nil, secureSummonButton, "UIPanelCloseButton")
    closeButton:SetSize(20, 20)
    closeButton:SetPoint("TOPRIGHT", secureSummonButton, "TOPRIGHT", 2, 2)
    closeButton:SetScript("OnClick", function() 
        secureSummonButton:Hide() 
        secureSummonButton = nil  -- Clean up the button reference when closed
    end)
    
    -- Make the button movable
    secureSummonButton:SetMovable(true)
    secureSummonButton:SetClampedToScreen(true)
    
    -- Create a separate frame for dragging that doesn't block clicks
    local moverFrame = CreateFrame("Frame", nil, secureSummonButton)
    moverFrame:SetFrameLevel(secureSummonButton:GetFrameLevel() + 10)
    
    -- Make the mover frame only cover the top bar area of the button
    moverFrame:SetPoint("TOPLEFT", secureSummonButton, "TOPLEFT", 20, 0)  -- Avoid the close button
    moverFrame:SetPoint("TOPRIGHT", secureSummonButton, "TOPRIGHT", -20, 0)
    moverFrame:SetHeight(15)  -- Just the top portion for dragging
    
    moverFrame:EnableMouse(true)
    moverFrame:RegisterForDrag("LeftButton")
    moverFrame:SetScript("OnDragStart", function() secureSummonButton:StartMoving() end)
    moverFrame:SetScript("OnDragStop", function() secureSummonButton:StopMovingOrSizing() end)
    
    -- Make it visible that this is the drag area
    local dragTexture = moverFrame:CreateTexture(nil, "OVERLAY")
    dragTexture:SetAllPoints()
    dragTexture:SetColorTexture(0.4, 0.4, 0.4, 0.1)
    
    -- Add tooltip to the mover frame
    moverFrame:SetScript("OnEnter", function()
        GameTooltip:SetOwner(moverFrame, "ANCHOR_TOP")
        GameTooltip:AddLine("Drag from here to move the button")
        GameTooltip:Show()
    end)
    
    moverFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Add a tooltip to the button itself - properly handle secure template
    secureSummonButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Click to summon " .. name)
        GameTooltip:AddLine("This will target them and cast Ritual of Summoning", 1, 1, 1)
        GameTooltip:Show()
    end)
    
    secureSummonButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Announce the summon when clicked
    SendChatMessage("Summoning " .. name .. ", please click!", channel)
    
    -- Auto-hide after 20 seconds
    C_Timer.After(20, function() 
        if secureSummonButton and secureSummonButton:IsShown() then
            secureSummonButton:Hide()
            secureSummonButton = nil  -- Clean up the button reference when hidden
        end
    end)
end

local function UpdateRaidList()
    for i, button in ipairs(raidList) do
        button:Hide()
    end
    
    local itemHeight = 30
    local numVisibleMembers = 0
    
    for i = 1, 40 do
        local name = GetRaidRosterInfo(i)
        if name then
            numVisibleMembers = numVisibleMembers + 1
        end
    end
    
    scrollChild:SetHeight(math.max(numVisibleMembers * itemHeight, scrollFrame:GetHeight()))
    
    local visibleIndex = 0
    for i = 1, 40 do
        local name, _, _, _, _, class, zone, online = GetRaidRosterInfo(i)
        if name then
            visibleIndex = visibleIndex + 1
            local unit = "raid" .. i
            local inRange = UnitInRange(unit)
            local meIsInInstance = IsInInstance() and UnitIsConnected(unit) and online
            local isInInstance = IsInInstance()
            local hasAnswered = playerResponses[name] or false
            
            local buttonFrame = raidList[visibleIndex]
            if not buttonFrame then
                buttonFrame = CreateFrame("Frame", nil, scrollChild)
                buttonFrame:SetSize(340, itemHeight)
                buttonFrame:SetFrameLevel(scrollChild:GetFrameLevel() + 1)
                raidList[visibleIndex] = buttonFrame

                local nameText = buttonFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                nameText:SetPoint("LEFT", 10, 0)
                nameText:SetWidth(150)
                nameText:SetJustifyH("LEFT")
                buttonFrame.nameText = nameText

                local summonButton = CreateFrame("Button", nil, buttonFrame, "UIPanelButtonTemplate")
                summonButton:SetSize(80, 20)
                summonButton:SetPoint("RIGHT", -10, 0)
                summonButton:SetText("Target")
                summonButton:SetFrameLevel(buttonFrame:GetFrameLevel() + 1)
                summonButton:SetScript("OnClick", function()
                    DoSummon(name)
                end)
                buttonFrame.summonButton = summonButton

                local checkmark = buttonFrame:CreateFontString(nil, "OVERLAY", "GameFontGreen")
                checkmark:SetPoint("LEFT", nameText, "RIGHT", 10, 0)  -- Moved here to the right of the nameText
                checkmark:SetText("Requested")
                checkmark:Hide()
                buttonFrame.checkmark = checkmark
            
                local separator = buttonFrame:CreateTexture(nil, "BACKGROUND")
                separator:SetHeight(1)
                separator:SetColorTexture(0.5, 0.5, 0.5, 0.5)
                separator:SetPoint("BOTTOMLEFT", buttonFrame, "BOTTOMLEFT", 10, 0)
                separator:SetPoint("BOTTOMRIGHT", buttonFrame, "BOTTOMRIGHT", -10, 0)
                buttonFrame.separator = separator
            end

            -- Position the button based on its visible index
            buttonFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -((visibleIndex-1) * itemHeight))
            
            -- Set Name and Location
            local classColor = RAID_CLASS_COLORS[class] or {r=1, g=1, b=1}
            local displayText = name
            if isInInstance then
                displayText = displayText .. " - " .. "Inside"
            end
            buttonFrame.nameText:SetText(displayText)
            
            -- Apply appropriate styling based on player status
            if isInInstance or inRange then
                -- Player is in range or in instance - 0.5 opacity, no summon button
                buttonFrame.nameText:SetTextColor(classColor.r, classColor.g, classColor.b, 0.5)
                buttonFrame.summonButton:Hide()
            else
                -- Player is out of range - full opacity with summon button
                buttonFrame.nameText:SetTextColor(classColor.r, classColor.g, classColor.b, 1.0)
                buttonFrame.summonButton:Show()
            end

            -- If the player(me) is in the same instance, and the raid member too but not in range, show summon button
            if meIsInInstance and isInInstance and not inRange then
                buttonFrame.nameText:SetTextColor(classColor.r, classColor.g, classColor.b, 1.0)
                buttonFrame.summonButton:Show()
            end


            -- Handle checkmark visibility (123 responders)
            if hasAnswered then
                buttonFrame.checkmark:Show()
                -- Always full opacity for players who responded
                buttonFrame.nameText:SetTextColor(classColor.r, classColor.g, classColor.b, 1.0)
            else
                buttonFrame.checkmark:Hide()
            end

            -- Hide separator on the last item
            if visibleIndex == numVisibleMembers then
                buttonFrame.separator:Hide()
            else
                buttonFrame.separator:Show()
            end

            buttonFrame:Show()
        end
    end
end

local function CheckForSummonRequest(_, event, msg, sender)
    -- Check for "123" message which is commonly used to request a summon
    if (event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER" or 
        event == "CHAT_MSG_RAID_WARNING" or event == "CHAT_MSG_PARTY" or 
        event == "CHAT_MSG_PARTY_LEADER") and 
        (msg == "123" or string.lower(msg):match("^123") or 
         string.lower(msg):match("summon") or string.lower(msg):match("need%s+summ?on")) then
        
        -- Add the player to our responses list
        playerResponses[sender] = true
        
        -- Update the UI to show the checkmark
        UpdateRaidList()
    end
end

frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("CHAT_MSG_PARTY")
frame:RegisterEvent("CHAT_MSG_RAID")
frame:RegisterEvent("CHAT_MSG_RAID_LEADER")
frame:RegisterEvent("CHAT_MSG_RAID_WARNING")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "GROUP_ROSTER_UPDATE" then
        UpdateRaidList()
    elseif event:match("CHAT_MSG_") then
        CheckForSummonRequest(self, event, ...)
    end
end)

local function ResetResponses()
    wipe(playerResponses)
    UpdateRaidList()
end

local resetButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
resetButton:SetSize(100, 22)
resetButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
resetButton:SetText("Reload")
resetButton:SetFrameLevel(frame:GetFrameLevel() + 10)
resetButton:SetScript("OnClick", ResetResponses)

frame:SetScript("OnShow", UpdateRaidList)

SLASH_SUMMONHELPER1 = "/sh"
SLASH_SUMMONHELPER2 = "/summonhelper"
SlashCmdList["SUMMONHELPER"] = function()
    if frame:IsShown() then
        frame:Hide()
        secureSummonButton:Hide()
    else
        frame:Show()
        UpdateRaidList()
    end
end

local function InitializeAddon()
    SetupSecureSummonButton()
    print("|cFF33FF33SummonHelper:|r Initialized")
    frame:Hide()
end
InitializeAddon()