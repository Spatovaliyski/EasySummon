-- UI/RaidList.lua
SummonHelperRaidList = {
    buttons = {}
}

function SummonHelperCore:UpdateRaidList()
    SummonHelperRaidList:UpdateList(self.playerResponses)
end

function SummonHelperRaidList:UpdateList(playerResponses)
    for i, button in ipairs(self.buttons) do
        button:Hide()
    end
    
    local itemHeight = 40
    local members = SummonHelperGroupUtils:GetGroupMembers()

    -- Check if the UI is available
    if not SummonHelperUI or not SummonHelperUI.scrollChild then
        C_Timer.After(0.5, function()
            SummonHelperCore:UpdateRaidList()
        end)
        return
    end

    local scrollChild = SummonHelperUI.scrollChild

    local playerInInstance, playerInstanceType = IsInInstance()
    playerInInstance = playerInInstance and playerInstanceType ~= "none"
    local inPVPInstance = playerInstanceType == "pvp" or playerInstanceType == "arena"
    
    scrollChild:SetHeight(math.max(#members * itemHeight, SummonHelperUI.scrollFrame:GetHeight()))

    for i, member in ipairs(members) do
        local hasAnswered = playerResponses[member.name] or false
        
        local buttonFrame = self.buttons[i]
        if not buttonFrame then
            buttonFrame = self:CreateMemberButton(scrollChild, i)
            self.buttons[i] = buttonFrame
        end
        
        buttonFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -((i-1) * itemHeight))
        buttonFrame.memberName = member.name  -- Store member name for click handler
        
        local classColor = RAID_CLASS_COLORS[member.class] or {r=1, g=1, b=1}
        local displayText = member.name
        
        if member.isPlayer then
            displayText = displayText .. " (You)"
        end
        
        -- Initialize display flags
        local clickable = false  -- Determines if clicking the name should call DoSummon
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

            elseif not member.inRange  then
                -- If Player is in instance and Member is in instance but not in range
                statusText = ""
                clickable = true
                textOpacity = 1.0
            else
                -- If Player is in instance and Member is in instance and in range
                statusText = ""
                clickable = false
                if hasAnswered then
                    isSummoned = true  -- They requested summon but are now in range
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
        if (not playerInInstance and not member.isInInstance and not member.inRange) or
           (playerInInstance and member.isInInstance and not member.inRange) then
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
        buttonFrame.statusText:SetText(statusText)
        if statusText == "Summon Requested" then
            buttonFrame.statusText:SetTextColor(0, 1, 0, textOpacity)  -- Green color for summon requested
        elseif statusText == "Summoned" then
            buttonFrame.statusText:SetTextColor(1, 1, 0, textOpacity)  -- Yellow color for summoned
        else
            buttonFrame.statusText:SetTextColor(1, 1, 1, textOpacity)
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
  
function SummonHelperRaidList:CreateMemberButton(parent, index)
    local buttonFrame = CreateFrame("Button", "SummonHelperListButton"..index, parent)
    buttonFrame:SetSize(340, 40)
    buttonFrame:SetFrameLevel(parent:GetFrameLevel() + 1)
    buttonFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    
    -- Set up click handler
    buttonFrame:SetScript("OnClick", function(self, button)
        if button == "LeftButton" and self.clickable then
            SummonHelperSummonButton:DoSummon(self.memberName, self)
        elseif button == "RightButton" then
            local responses = _G.SummonHelperCore.playerResponses
            if responses and responses[self.memberName] then
                -- Show context menu on right-click
                local menu = {
                    { text = self.memberName, isTitle = true },
                    { text = "Clear summon status", 
                      func = function() 
                          _G.SummonHelperCore:ResetResponse(self.memberName) 
                      end 
                    },
                }
                EasyMenu(menu, CreateFrame("Frame", "SummonHelperContextMenu", UIParent, "UIDropDownMenuTemplate"), "cursor", 0, 0, "MENU")
            end
        end
    end)
    
    -- Create name text (positioned higher to make room for zone)
    local nameText = buttonFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("TOPLEFT", 10, -7)
    nameText:SetWidth(180)
    nameText:SetJustifyH("LEFT")
    buttonFrame.nameText = nameText
    
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
