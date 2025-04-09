-- UI/MainFrame.lua
SummonHelperUI = {}

function SummonHelperUI:Initialize()
    self:CreateMainFrame()
    self.frame:Hide()
end

function SummonHelperUI:CreateMainFrame()
    local frame = CreateFrame("Frame", "SummonHelperFrame", UIParent, "ButtonFrameTemplate")
    frame:SetSize(SummonHelperConfig.FrameWidth, SummonHelperConfig.FrameHeight)
    frame:SetPoint("CENTER")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(50)

    tinsert(UISpecialFrames, "SummonHelperFrame")
    
    -- Set the frame title
    frame.TitleText:SetText("Summon Helper")
    
    frame.portrait:SetTexture("Interface\\AddOns\\SummonHelper\\Textures\\SHLogoTransparent")


    -- Create reset button
    local resetButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    resetButton:SetSize(100, 22)
    resetButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 4)
    resetButton:SetText("Reset")
    resetButton:SetFrameLevel(frame:GetFrameLevel() + 10)
    resetButton:SetScript("OnClick", function()
        _G.SummonHelperCore:ResetResponses()
    end)
    
    -- Add OnShow handling
    frame:SetScript("OnShow", function()
        if _G.SummonHelperCore then
            _G.SummonHelperCore:SetActive(true)
            _G.SummonHelperCore:UpdateRaidList()
        end
    end)

    frame:SetScript("OnHide", function()
        if SummonHelperSummonButton and SummonHelperSummonButton.button then
            SummonHelperSummonButton.button:Hide()
            SummonHelperSummonButton.button = nil
        end
        
        -- Telling the core its not active anymore
        if _G.SummonHelperCore then
            _G.SummonHelperCore:SetActive(false)
        end
    end)
    
    self.frame = frame
    self:CreateScrollFrame()
end

function SummonHelperUI:CreateScrollFrame()
    -- Main scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", "SummonHelperScrollFrame", self.frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 16, -70)
    scrollFrame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -36, 40)

    -- Scroll child
    local scrollChild = CreateFrame("Frame", "SummonHelperScrollChild", scrollFrame)
    scrollChild:SetSize(1, 1) -- auto
    scrollFrame:SetScrollChild(scrollChild)

    self.scrollFrame = scrollFrame
    self.scrollChild = scrollChild
end

function SummonHelperUI:ToggleMainFrame()
    if self.frame:IsShown() then
        self.frame:Hide()
        if SummonHelperSummonButton and SummonHelperSummonButton.button then
            SummonHelperSummonButton.button:Hide()
        end
    else
        self.frame:Show()
    end
end
