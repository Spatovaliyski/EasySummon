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
    if member.isPlayer then
        displayText = displayText .. " (You)"
    end
    if member.isInInstance then
        displayText = displayText .. " - Inside"
    end

    buttonFrame.nameText:SetText(displayText)

    local canBeSummoned = not member.isInInstance and not member.inRange and not member.isPlayer
    local showSummonButton = canBeSummoned or hasAnswered

    if showSummonButton then
    -- Can be summoned - full opacity with summon button
    buttonFrame.nameText:SetTextColor(classColor.r, classColor.g, classColor.b, 1.0)
    buttonFrame.summonButton:Show()

    else
        -- Can't be summoned - 0.5 opacity, no summon button
        buttonFrame.nameText:SetTextColor(classColor.r, classColor.g, classColor.b, 0.5)
        buttonFrame.summonButton:Hide()
    end
    
    -- Special case: If player is in instance and member is in the same instance but not in range
    if member.isInInstance and not member.inRange and not member.isPlayer then
        buttonFrame.nameText:SetTextColor(classColor.r, classColor.g, classColor.b, 1.0)
        buttonFrame.summonButton:Show()
    end
    
    -- Handle summon request indicator
    if hasAnswered then
        buttonFrame.requestText:Show()
        buttonFrame.nameText:SetTextColor(classColor.r, classColor.g, classColor.b, 1.0)
        buttonFrame.summonButton:Show()
    else
        buttonFrame.requestText:Hide()
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
  requestText:SetTextColor(unpack(SummonHelperConfig.Colors.Requested))
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
  
  return buttonFrame
end