-- UI/MainFrame.lua
SummonHelperUI = {}

function SummonHelperUI:Initialize()
    self:CreateMainFrame()
    self.frame:Hide()
end

function SummonHelperUI:CreateMainFrame()
    -- Create the main frame
    local frame = CreateFrame("Frame", "SummonHelperFrame", UIParent, "BackdropTemplate")
    frame:SetSize(SummonHelperConfig.FrameWidth, SummonHelperConfig.FrameHeight)
    frame:SetPoint("CENTER")
    frame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
                      edgeFile = "Interface/DialogFrame/UI-DialogBox-Border", 
                      edgeSize = 16})
    frame:SetBackdropColor(unpack(SummonHelperConfig.Colors.Background))
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(100)
    
    -- Create title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("Summon Helper")
    
    -- Create close button
    local closeButton = CreateFrame("Button", "SummonHelperCloseButton", frame, "UIPanelCloseButton")
    closeButton:SetSize(32, 32)
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -3)
    closeButton:SetScript("OnClick", function()
        frame:Hide()
        if SummonHelperSummonButton.button then
            SummonHelperSummonButton.button:Hide()
        end
    end)
    
    -- Create reset button
    local resetButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    resetButton:SetSize(100, 22)
    resetButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
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
        if _G.SummonHelperCore then
            _G.SummonHelperCore:SetActive(false)
        end
    end)
    
    self.frame = frame
    self:CreateScrollFrame()
end

function SummonHelperUI:CreateScrollFrame()
    -- Create scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", "SummonHelperScrollFrame", self.frame, "UIPanelScrollFrameTemplate")
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