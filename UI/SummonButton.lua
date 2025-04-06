-- UI/SummonButton.lua
SummonHelperSummonButton = {
  button = nil
}

function SummonHelperSummonButton:DoSummon(name)
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
  
  -- Create the summoning button
  self:CreateSummonButton(name, macroText)
  
  -- Announce the summon
  SendChatMessage("SummonHelper: Summoning " .. name .. ", please click!", channel)
end

function SummonHelperSummonButton:CreateSummonButton(name, macroText)
  local button = CreateFrame("Button", "SummonHelperQuickButton", UIParent, "SecureActionButtonTemplate,UIPanelButtonTemplate")
  button:SetSize(200, 40)
  button:SetPoint("BOTTOM", SummonHelperUI.frame, "TOPRIGHT", -100, 10)
  button:SetAttribute("type", "macro")
  button:SetAttribute("macrotext", macroText)
  button:SetText("Summon " .. name)
  
  -- Add close button
  local closeButton = CreateFrame("Button", nil, button, "UIPanelCloseButton")
  closeButton:SetSize(20, 20)
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
  moverFrame:SetPoint("TOPLEFT", button, "TOPLEFT", 20, 0)
  moverFrame:SetPoint("TOPRIGHT", button, "TOPRIGHT", -20, 0)
  moverFrame:SetHeight(15)
  
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