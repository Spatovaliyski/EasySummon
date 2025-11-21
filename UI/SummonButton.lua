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
    -- Get the scroll frame
    local scrollFrame = _G["EasySummonScrollFrame"]
    
    -- Create button as a direct child of the scroll frame (not UIParent)
    -- This ensures it respects the scroll frame's boundaries
    local button = CreateFrame("Button", "EasySummonQuickButton", scrollFrame, "SecureActionButtonTemplate")

    button:SetFrameStrata("HIGH")
    button:SetFrameLevel(100) -- High enough to be above list items
    button:SetSize(120, 30)
    
    if anchorFrame then
        local point, relativeTo, relativePoint, xOfs, yOfs = anchorFrame:GetPoint()
        
        local buttonX = -120
        local buttonY = 0
        
        button:SetPoint("LEFT", anchorFrame, "RIGHT", buttonX, buttonY)
    else
        -- Default position
        button:SetPoint("CENTER", scrollFrame, "CENTER", 0, 0)
    end
    
    -- Set attributes for macro functionality
    button:SetAttribute("type", "macro")
    button:SetAttribute("macrotext", macroText)

    -- Rest of your button setup code...
    -- (textures, text, close button, etc.)
    
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
