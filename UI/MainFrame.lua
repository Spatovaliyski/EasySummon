-- UI/MainFrame.lua
EasySummonUI = {}

function EasySummonUI:Initialize()
    self:CreateMainFrame()
    self.frame:Hide()

    self.frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    self.frame:SetScript("OnEvent", function(_, event, ...)
        if event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
            if self.frame:IsShown() then
                EasySummonGroupUtils:UpdateGroupSizeText()
            end
        end
    end)
end

function EasySummonUI:CreateMainFrame()
    local frame = CreateFrame("Frame", "EasySummonFrame", UIParent, "ButtonFrameTemplate")
    frame:SetSize(EasySummonConfig.FrameWidth, EasySummonConfig.FrameHeight)
    frame:SetPoint("CENTER")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(50)

    tinsert(UISpecialFrames, "EasySummonFrame")
    
    -- Set the frame title
    frame.TitleText:SetText("Easy Summon v" .. GetAddOnMetadata("EasySummon", "Version"))
    frame.portrait:SetTexture("Interface\\AddOns\\EasySummon\\Textures\\logo")

    -- Group size text display
    local groupSizeText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    groupSizeText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -45)
    groupSizeText:SetText("Group: 0/0")
    self.groupSizeText = groupSizeText

    -- Reset button
    local resetButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    resetButton:SetSize(100, 21)
    resetButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 4, 4)
    resetButton:SetText("Reset")
    resetButton:SetFrameLevel(frame:GetFrameLevel() + 10)
    resetButton:SetScript("OnClick", function()
        _G.EasySummonCore:ResetResponses()
    end)
    
    -- Notification (when frame is hidden) checkbox
    -- local notifyCheckbox = CreateFrame("CheckButton", "EasySummonNotifyCheckbox", frame, "UICheckButtonTemplate")
    -- notifyCheckbox:SetSize(24, 24)
    -- notifyCheckbox:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -120, 3)
    -- notifyCheckbox:SetFrameLevel(frame:GetFrameLevel() + 10)
    -- if EasySummonConfig.NotifyWhenHidden == nil then
    --     EasySummonConfig.NotifyWhenHidden = false
    -- end
    -- notifyCheckbox:SetChecked(EasySummonConfig.NotifyWhenHidden)
    
    -- -- Set checkbox text and tooltip
    -- _G[notifyCheckbox:GetName() .. "Text"]:SetText("Notify when hidden")
    
    -- -- Hook up the checkbox functionality
    -- notifyCheckbox:SetScript("OnClick", function(self)
    --     EasySummonConfig.NotifyWhenHidden = self:GetChecked()
    -- end)
    
    -- Add OnShow handling
    frame:SetScript("OnShow", function()
        if _G.EasySummonCore then
            _G.EasySummonCore:SetActive(true)
            _G.EasySummonCore:UpdateRaidList()
            EasySummonGroupUtils:UpdateGroupSizeText()
        end
    end)



    frame:SetScript("OnHide", function()
        if EasySummonSummonButton and EasySummonSummonButton.button then
            EasySummonSummonButton.button:Hide()
            EasySummonSummonButton.button = nil
        end
        
        -- Telling the core its not active anymore
        if _G.EasySummonCore then
            _G.EasySummonCore:SetActive(false)
        end
    end)
    
    self.frame = frame
    --self.notifyCheckbox = notifyCheckbox
    self:CreateScrollFrame()
end

function EasySummonUI:CreateScrollFrame()
    -- Main scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", "EasySummonScrollFrame", self.frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 16, -70)
    scrollFrame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -36, 40)

    -- Scroll child
    local scrollChild = CreateFrame("Frame", "EasySummonScrollChild", scrollFrame)
    scrollChild:SetSize(1, 1) -- auto
    scrollFrame:SetScrollChild(scrollChild)

    self.scrollFrame = scrollFrame
    self.scrollChild = scrollChild
end

function EasySummonUI:ToggleMainFrame()
    if self.frame:IsShown() then
        self.frame:Hide()
        if EasySummonSummonButton and EasySummonSummonButton.button then
            EasySummonSummonButton.button:Hide()
        end
    else
        self.frame:Show()
        EasySummonGroupUtils:UpdateGroupSizeText()
    end
end
