-- UI/RaidList.lua
SummonHelperRaidList = {
    buttons = {}
}

function SummonHelperCore:UpdateRaidList()
    SummonHelperRaidList:UpdateList(self.playerResponses)
end

function SummonHelperRaidList:UpdateList(playerResponses)
    -- Hide all existing buttons
    for i, button in ipairs(self.buttons) do
        button:Hide()
    end
    
    local itemHeight = 30
    local members = SummonHelperGroupUtils:GetGroupMembers()
    local scrollChild = SummonHelperUI.scrollChild
    
    -- Check if player is in an instance
    local playerInInstance, playerInstanceType = IsInInstance()
    playerInInstance = playerInInstance and playerInstanceType ~= "none"
    
    scrollChild:SetHeight(math.max(#members * itemHeight, SummonHelperUI.scrollFrame:GetHeight()))

    for i, member in ipairs(members) do
        local hasAnswered = playerResponses[member.name] or false
        
        local buttonFrame = self.buttons[i]
        if not buttonFrame then
            buttonFrame = self:CreateMemberButton(scrollChild, i)
            self.buttons[i] = buttonFrame
        end
        
        -- Position the button
        buttonFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -((i-1) * itemHeight))
        
        -- Set appearance
        local classColor = RAID_CLASS_COLORS[member.class] or {r=1, g=1, b=1}
        local displayText = member.name
        
        -- Add player identifier
        if member.isPlayer then
            displayText = displayText .. " (You)"
        end
        
        -- Initialize display flags
        local showSummonButton = false
        local textOpacity = 0.5
        local instanceText = ""
        local isSummoned = false
                
        if not playerInInstance then
            if member.isInInstance then
                instanceText = " - Instanced"
                showSummonButton = false
            elseif member.inRange then
                -- If Player is not in instance and Member is not in instance but in range
                showSummonButton = false
                if hasAnswered then
                    isSummoned = true -- They requested summon but are now in range
                end
            else
                -- If Player is not in instance and Member is not in instance but not in range
                showSummonButton = true
                textOpacity = 1.0
            end
        else  -- Player IS in instance
            if not member.isInInstance then
                -- If Player in instance but Member is not in instance
                instanceText = " - Not instanced"
                showSummonButton = false
            elseif not member.inRange then
                -- If Player is in instance and Member is in instance but not in range
                showSummonButton = true
                textOpacity = 1.0
            else
                -- If Player is in instance and Member is in instance but in range
                showSummonButton = false
                if hasAnswered then
                    isSummoned = true  -- They requested summon but are now in range
                end
            end
        end
        
        -- never show summon button for self
        if member.isPlayer then
            showSummonButton = false
        end
        
        -- Add instance text to display
        displayText = displayText .. instanceText
        
        -- Handle summon request logic
        local eligibleForSummonRequest = false
        
        -- Check if eligible for summon request (according to additional cases)
        if (not playerInInstance and not member.isInInstance and not member.inRange) or
           (playerInInstance and member.isInInstance and not member.inRange) then
            eligibleForSummonRequest = true
        end
        
        -- Apply summon request status
        if hasAnswered then
            if isSummoned then
                -- Player has been summoned (they requested and are now in range)
                buttonFrame.requestText:SetText("[Summoned]")
                buttonFrame.requestText:SetTextColor(1, 1, 1)
                buttonFrame.requestText:Show()
                textOpacity = 0.5
                showSummonButton = false
            elseif eligibleForSummonRequest then
                -- Player still needs to be summoned
                buttonFrame.requestText:SetText("[Summon me]")
                buttonFrame.requestText:SetTextColor(0, 1, 0)
                buttonFrame.requestText:Show()
                textOpacity = 1.0
                showSummonButton = true
            else
                -- Player requested but is now in a state where they can't be summoned
                buttonFrame.requestText:Hide()
            end
        else
            buttonFrame.requestText:Hide()
        end
    
        -- Apply the calculated settings
        buttonFrame.nameText:SetText(displayText)
        buttonFrame.nameText:SetTextColor(classColor.r, classColor.g, classColor.b, textOpacity)
        
        if showSummonButton then
            buttonFrame.summonButton:Show()
        else
            buttonFrame.summonButton:Hide()
        end
        
        -- Hide separator on the last item
        if i == #members then
            buttonFrame.separator:Hide()
        else
            buttonFrame.separator:Show()
        end
        
        -- Set button callback with the correct member.name
        buttonFrame.summonButton:SetScript("OnClick", function()
            SummonHelperSummonButton:DoSummon(member.name)
        end)
        
        buttonFrame:Show()
    end
end
  
-- Add the CreateMemberButton
function SummonHelperRaidList:CreateMemberButton(parent, index)
    local buttonFrame = CreateFrame("Frame", "SummonHelperListButton"..index, parent)
    buttonFrame:SetSize(340, 30)
    buttonFrame:SetFrameLevel(parent:GetFrameLevel() + 1)
    
    -- Create name text
    local nameText = buttonFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("LEFT", 10, 0)
    nameText:SetWidth(180)
    nameText:SetJustifyH("LEFT")
    buttonFrame.nameText = nameText
    
    -- Create request indicator
    local requestText = buttonFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    requestText:SetPoint("LEFT", nameText, "RIGHT", -15, 0)
    requestText:SetText("[Summon me]")
    requestText:SetTextColor(0, 1, 0)
    requestText:Hide()
    buttonFrame.requestText = requestText
    
    -- Create summon button
    local summonButton = CreateFrame("Button", nil, buttonFrame, "UIPanelButtonTemplate")
    summonButton:SetSize(80, 20)
    summonButton:SetPoint("RIGHT", -10, 0)
    summonButton:SetText("Target")
    summonButton:SetFrameLevel(buttonFrame:GetFrameLevel() + 1)
    buttonFrame.summonButton = summonButton
    
    -- Add separator
    local separator = buttonFrame:CreateTexture(nil, "BACKGROUND")
    separator:SetHeight(1)
    separator:SetColorTexture(0.5, 0.5, 0.5, 0.5)
    separator:SetPoint("BOTTOMLEFT", buttonFrame, "BOTTOMLEFT", 10, 0)
    separator:SetPoint("BOTTOMRIGHT", buttonFrame, "BOTTOMRIGHT", -10, 0)
    buttonFrame.separator = separator
    
    -- Context menu
    buttonFrame:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" and playerResponses[member.name] then
            local menu = {
                { text = member.name, isTitle = true },
                { text = "Clear summon status", 
                  func = function() 
                      _G.SummonHelperCore:ResetResponse(member.name) 
                  end 
                },
            }
            EasyMenu(menu, CreateFrame("Frame", "SummonHelperContextMenu", UIParent, "UIDropDownMenuTemplate"), "cursor", 0, 0, "MENU")
        end
    end)

    return buttonFrame
end
