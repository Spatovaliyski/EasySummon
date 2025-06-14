-- Core.lua
EasySummon = {}
EasySummon.__index = EasySummon

function EasySummon:New()
    local self = setmetatable({}, EasySummon)
    self.playerResponses = {}
    self.updateInterval = 2
    self.lastUpdate = 0
    self:InitializeEvents()
    return self
end

function EasySummon:InitializeEvents()
    self.frame = CreateFrame("Frame")
    self.frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    self.frame:RegisterEvent("CHAT_MSG_PARTY")
    self.frame:RegisterEvent("CHAT_MSG_PARTY_LEADER")
    self.frame:RegisterEvent("CHAT_MSG_RAID")
    self.frame:RegisterEvent("CHAT_MSG_RAID_LEADER")
    self.frame:RegisterEvent("CHAT_MSG_RAID_WARNING")
    
    self.frame:SetScript("OnEvent", function(_, event, ...)
        if not self.isActive and event == "GROUP_ROSTER_UPDATE" then
            return
        end

        if event == "GROUP_ROSTER_UPDATE" then
            self:UpdateRaidList()
        elseif event:match("CHAT_MSG_") then
            self:CheckForSummonRequest(event, ...)
        end
    end)

    self.frame:SetScript("OnUpdate", function(_, elapsed)
        if not self.isActive then
            return
        end

        self.lastUpdate = self.lastUpdate + elapsed
        if self.lastUpdate >= self.updateInterval then
            self.lastUpdate = 0
  
            -- Only update the list if UI is visible
            if EasySummonUI and EasySummonUI.frame and EasySummonUI.frame:IsShown() then
                self:UpdateRaidList()
            end
            
            -- Also update when summon button is visible
            if EasySummonSummonButton and EasySummonSummonButton.button and 
               EasySummonSummonButton.button:IsShown() then
                self:UpdateRaidList()
            end
        end
    end)
end

function EasySummon:SetActive(isActive)
    self.isActive = isActive
    
    -- If we're activating, do an immediate update
    if isActive then
        self:UpdateRaidList()
    end
end

function EasySummon:ResetResponses()
    wipe(self.playerResponses)
    self:UpdateRaidList()
end

function EasySummon:ResetResponse(playerName)
    if self.playerResponses[playerName] then
        self.playerResponses[playerName] = nil
        self:UpdateRaidList()
    end
end

-- Define a placeholder UpdateRaidList method
function EasySummon:UpdateRaidList()
  -- Will be overridden by RaidList.lua
  if EasySummonRaidList and EasySummonRaidList.UpdateList then
      EasySummonRaidList:UpdateList(self.playerResponses)
  end
end

function EasySummon:CheckForSummonRequest(event, msg, sender)
    local playerName = EasySummonTextUtils:GetPlayerNameWithoutRealm(sender)
    if self:IsSummonRequest(msg, event) then
        -- Always process summon requests for notification purposes
        if self.playerResponses[playerName] then
            return  -- Ignore if already responded
        end
        
        -- Only process the request if:
        -- 1. The frame is visible, OR
        -- 2. NotifyWhenHidden is enabled
        if EasySummonUI.frame:IsShown() or EasySummonConfig.NotifyWhenHidden then
            self.playerResponses[playerName] = true
            
            if not EasySummonUI.frame:IsShown() and EasySummonConfig.NotifyWhenHidden then
                if EasySummonToast then
                    EasySummonToast:Show(playerName)
                end
            else
                -- Just play sound if window is open
                PlaySound(SOUNDKIT.READY_CHECK, "Dialog")
            end
            
            -- Only update raid list if active
            if self.isActive then
                self:UpdateRaidList()
            end
        end
    end
end

function EasySummon:IsSummonRequest(msg, event)
    -- Logic to determine if a message is a summon request
    local lowerMsg = string.lower(msg)
    
    local ignorePhrases = {
        "^easysummon: ",
        "^attempting to summon",
        "^summoning ",
        "^need a summon?",
        "^123 for summons",
        "^123 for summ",
    }
    
    for _, pattern in ipairs(ignorePhrases) do
        if lowerMsg:match(pattern) then
            return false
        end
    end
 
    
    for _, phrase in ipairs(EasySummonConfig.SummonPhrases) do
        if lowerMsg == phrase then
            return true
        end
    end
    
    return false
end

-- Global initialization
local function InitializeAddon()
    if not EasySummonToast then
        print("EasySummonToast not found, creating it")
        EasySummonToast = {}
        EasySummonToast.Initialize = function() 
            -- (copy the Initialize function from Toast.lua)
        end
        EasySummonToast.Show = function(self, playerName)
            -- (copy the Show function from Toast.lua)
        end
    end
    
    if EasySummonToast and EasySummonToast.Initialize then
        print("Initializing EasySummonToast")
        EasySummonToast:Initialize()
    end

    _G.EasySummonCore = EasySummon:New()

    -- Delay UI init
    C_Timer.After(0.5, function()
        if EasySummonUI and EasySummonUI.Initialize then
            EasySummonUI:Initialize()
            
            -- Initialize toast notification system
            if EasySummonToast and EasySummonToast.Initialize then
                EasySummonToast:Initialize()
            end
            
            print("|cFF33FF33EasySummon:|r initialized")
            
            if _G.EasySummonCore and _G.EasySummonCore.UpdateRaidList then
                _G.EasySummonCore:UpdateRaidList()
            end
        else
            print("|cFFFF3333EasySummon:|r Error: UI module not found")
        end
    end)
end

-- Register slash commands
SLASH_SCMD1 = "/easysummon"
SLASH_SCMD2 = "/es"
SLASH_SCMD3 = "/summon"
SlashCmdList["SCMD"] = function()
    if InCombatLockdown() then
        print("|cFFFFCC00EasySummon:|r Cannot open during combat. Will open when combat ends.")
    
        if not EasySummon.combatMonitor then
            EasySummon.combatMonitor = CreateFrame("Frame")
            EasySummon.combatMonitor:RegisterEvent("PLAYER_REGEN_ENABLED")
            EasySummon.combatMonitor:SetScript("OnEvent", function(self, event)
                if event == "PLAYER_REGEN_ENABLED" and EasySummon.pendingOpen then
                    EasySummon.pendingOpen = false
                    print("|cFF33FF33EasySummon:|r Combat ended, opening interface.")
                    EasySummonUI:ToggleMainFrame()
                end
            end)
        end
        
        -- Set flag to open when combat ends
        EasySummon.pendingOpen = true

        -- if Frame already open, then close it
        if EasySummonUI and EasySummonUI.frame and EasySummonUI.frame:IsShown() then
            
        end
    else
        -- Not in combat, open immediately
        EasySummonUI:ToggleMainFrame()
    end
end

SLASH_ESSUMMONTEST1 = "/estest"
SlashCmdList["ESSUMMONTEST"] = function()
    EasySummonRaidList:LoadTestData()
end

-- Call initialization when addon loads
InitializeAddon()
