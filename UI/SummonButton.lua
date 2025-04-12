-- UI/SummonButton.lua
EasySummonSummonButton = {
  button = nil
}

function EasySummonSummonButton:DoSummon(name, anchorFrame)
    local channel = IsInRaid() and "RAID" or "PARTY"

    -- Create macro for summoning
    local macroName = "SH_Summon"
    local macroIcon = "INV_MISC_QUESTIONMARK"
    local macroText

    if channel == "RAID" then
        macroText = "/targetexact " .. name .. "\n/cast Ritual of Summoning\n/raid EasySummon: Summoning " .. name .. ", please click!"
    else
        macroText = "/targetexact " .. name .. "\n/cast Ritual of Summoning\n/party EasySummon: Summoning " .. name .. ", please click!"
    end

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
    local button = CreateFrame("Button", "EasySummonQuickButton", UIParent, "SecureActionButtonTemplate")

    button:SetFrameStrata("HIGH")
    button:SetFrameLevel(101)
    button:SetSize(120, 30)
    
    if anchorFrame then
        button:SetPoint("LEFT", anchorFrame, "RIGHT", -120, 0)
    else
        button:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    
    -- Set attributes AFTER positioning (ONLY ONCE)
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

    -- Make button movable
    button:SetMovable(true)
    button:SetClampedToScreen(true)

    -- Create drag handle
    local moverFrame = CreateFrame("Frame", nil, button)
    moverFrame:SetFrameLevel(button:GetFrameLevel() + 10)
    moverFrame:SetPoint("TOPLEFT", button, "TOPLEFT", 16, 0)
    moverFrame:SetPoint("TOPRIGHT", button, "TOPRIGHT", -16, 0)
    moverFrame:SetHeight(1)

    moverFrame:EnableMouse(true)
    moverFrame:RegisterForDrag("LeftButton")
    moverFrame:SetScript("OnDragStart", function() button:StartMoving() end)
    moverFrame:SetScript("OnDragStop", function() button:StopMovingOrSizing() end)

    -- Add visual cue for drag area
    local dragTexture = moverFrame:CreateTexture(nil, "OVERLAY")
    dragTexture:SetAllPoints()
    dragTexture:SetColorTexture(0.4, 0.4, 0.4, 0.1)

    -- Add tooltips
    moverFrame:SetScript("OnEnter", function()
        GameTooltip:SetOwner(moverFrame, "ANCHOR_TOP")
        GameTooltip:AddLine("Drag from here to move the button")
        GameTooltip:Show()
    end)

    moverFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Click to summon " .. name)
        GameTooltip:AddLine("This will target them and cast Ritual of Summoning", 1, 1, 1)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

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
