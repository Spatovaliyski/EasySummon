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
    
    if _G["SummonHelperQuickButton"] then
        _G["SummonHelperQuickButton"]:Hide()
    end
    
    local secureButton = CreateFrame("Button", "SummonHelperQuickButton", UIParent, "SecureActionButtonTemplate")
    secureButton:SetSize(200, 30)
    secureButton:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    
    secureButton:SetAttribute("type", "macro")
    secureButton:SetAttribute("macrotext", macroText)
    
    local ntex = secureButton:CreateTexture()
    ntex:SetTexture("Interface/Buttons/UI-Panel-Button-Up")
    ntex:SetTexCoord(0, 0.625, 0, 0.6875)
    ntex:SetAllPoints()
    secureButton:SetNormalTexture(ntex)
    
    local htex = secureButton:CreateTexture()
    htex:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
    htex:SetTexCoord(0, 0.625, 0, 0.6875)
    htex:SetAllPoints()
    secureButton:SetHighlightTexture(htex)
    
    local ptex = secureButton:CreateTexture()
    ptex:SetTexture("Interface/Buttons/UI-Panel-Button-Down")
    ptex:SetTexCoord(0, 0.625, 0, 0.6875)
    ptex:SetAllPoints()
    secureButton:SetPushedTexture(ptex)
    
    secureButton:SetNormalFontObject("GameFontNormal")
    secureButton:SetHighlightFontObject("GameFontHighlight")
    secureButton:SetText("Summon " .. name)
    
    local closeButton = CreateFrame("Button", nil, secureButton, "UIPanelCloseButton")
    closeButton:SetSize(20, 20)
    closeButton:SetPoint("TOPRIGHT", secureButton, "TOPRIGHT", 2, 2)
    closeButton:SetScript("OnClick", function() 
        secureButton:Hide() 
    end)
    
    secureButton:SetMovable(true)
    secureButton:SetClampedToScreen(true)
    secureButton:EnableMouse(true)
    secureButton:RegisterForDrag("LeftButton")
    
    local moverFrame = CreateFrame("Frame", nil, secureButton)
    moverFrame:SetPoint("TOPLEFT", secureButton, "TOPLEFT", 0, 0)
    moverFrame:SetPoint("BOTTOMRIGHT", secureButton, "BOTTOMRIGHT", 0, 0)
    moverFrame:EnableMouse(true)
    moverFrame:RegisterForDrag("LeftButton")
    moverFrame:SetFrameLevel(secureButton:GetFrameLevel() + 10)
    moverFrame:SetScript("OnDragStart", function() secureButton:StartMoving() end)
    moverFrame:SetScript("OnDragStop", function() secureButton:StopMovingOrSizing() end)
    
    moverFrame:SetHitRectInsets(5, 5, 5, 5)
    
    moverFrame:SetScript("OnEnter", function()
        GameTooltip:SetOwner(secureButton, "ANCHOR_TOP")
        GameTooltip:AddLine("Click to summon " .. name)
        GameTooltip:AddLine("This will target them and cast Ritual of Summoning", 1, 1, 1)
        GameTooltip:Show()
    end)
    
    moverFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Auto-hide after 20 seconds
    C_Timer.After(20, function() 
        if secureButton and secureButton:IsShown() then
            secureButton:Hide()
        end
    end)
    
    -- SendChatMessage("SummonHelper: Summoning " .. name .. "! Two people need to click the portal.", channel)
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
                summonButton:SetText("Summon")
                summonButton:SetFrameLevel(buttonFrame:GetFrameLevel() + 1)
                summonButton:SetScript("OnClick", function()
                    DoSummon(name)
                end)
                buttonFrame.summonButton = summonButton

                local checkmark = buttonFrame:CreateFontString(nil, "OVERLAY", "GameFontGreen")
                checkmark:SetPoint("RIGHT", summonButton, "LEFT", -5, 0)
                checkmark:SetText("✅")
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
    if (event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER" or event == "CHAT_MSG_RAID_WARNING") and msg == "123" then
        playerResponses[sender] = true
        UpdateRaidList()
    end
end

frame:RegisterEvent("GROUP_ROSTER_UPDATE")
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