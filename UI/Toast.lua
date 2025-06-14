-- Toast Notification for EasySummon
EasySummonToast = {}

function EasySummonToast:Initialize()
    local toast = CreateFrame("Frame", "EasySummonToastFrame", UIParent)
    toast:SetSize(300, 80)
    toast:SetPoint("CENTER", 0, 100)
    toast:SetFrameStrata("FULLSCREEN_DIALOG") 
    toast:SetFrameLevel(9999) -- High level, its prio
    toast:EnableMouse(true)
    toast:SetMovable(true)
    toast:RegisterForDrag("LeftButton")
    toast:SetScript("OnDragStart", toast.StartMoving)
    toast:SetScript("OnDragStop", toast.StopMovingOrSizing)
    toast:Hide()
    
    -- Create background
    local bg = toast:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    
    -- Create border
    -- local border = CreateFrame("Frame", nil, toast, "DialogBorderTemplate")
    -- border:SetAllPoints()
    
    -- Create title
    local title = toast:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", 0, -15)
    title:SetText("Easy Summon")
    
    -- Create message text
    local message = toast:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    message:SetPoint("TOP", title, "BOTTOM", 0, -5)
    message:SetPoint("LEFT", 20, 0)
    message:SetPoint("RIGHT", -20, 0)
    message:SetJustifyH("CENTER")
    
    -- Create close button
    local closeButton = CreateFrame("Button", nil, toast, "UIPanelCloseButton")
    closeButton:SetSize(20, 20)
    closeButton:SetPoint("TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function() toast:Hide() end)
    
    -- Click handling
    toast:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            -- Don't handle if clicking the close button
            if closeButton:IsMouseOver() then return end
            
            -- Open the EasySummon frame
            EasySummonUI:ToggleMainFrame()
            self:Hide()
        end
    end)
    
    -- Store toast data
    self.frame = toast
    self.message = message
    self.summoner = nil -- Store the name of the person who requested a summon
    
    -- Animation for fading out
    toast.fadeGroup = toast:CreateAnimationGroup()
    local fadeOut = toast.fadeGroup:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(1)
    fadeOut:SetStartDelay(3)
    fadeOut:SetScript("OnFinished", function() toast:Hide() end)
    
    toast:SetScript("OnShow", function() 
        toast:SetAlpha(1)
        toast.fadeGroup:Play()
    end)
    
    toast:SetScript("OnEnter", function()
        toast.fadeGroup:Stop()
        toast:SetAlpha(1)
    end)
    
    toast:SetScript("OnLeave", function()
        toast.fadeGroup:Play()
    end)
    
    local infoText = toast:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("BOTTOM", 0, 12)
    infoText:SetText("Click to open Easy Summon")
    infoText:SetTextColor(0.7, 0.7, 0.7)
end

function EasySummonToast:Show(playerName)
    if not self.frame then
        self:Initialize()
    end
    
    -- Update message
    self.message:SetText(playerName .. " requested a summon")
    
    -- Store summoner name
    self.summoner = playerName
    
    -- Show the frame
    self.frame:Show()
    
    PlaySound(SOUNDKIT.READY_CHECK, "Dialog")
end