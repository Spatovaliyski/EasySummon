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
        if not self.isActive and event ~= "GROUP_ROSTER_UPDATE" then
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
    if not self.isActive then
        return
    end
    
    local playerName = EasySummonTextUtils:GetPlayerNameWithoutRealm(sender)
    if self:IsSummonRequest(msg, event) then
        if self.playerResponses[playerName] then
            return  -- Ignore if already responded
        end
        
        self.playerResponses[playerName] = true
        PlaySound(SOUNDKIT.READY_CHECK, "Master")
        self:UpdateRaidList()
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
        "^123 for summons"
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
    _G.EasySummonCore = EasySummon:New()

    -- Delay UI init
    C_Timer.After(0.5, function()
        if EasySummonUI and EasySummonUI.Initialize then
            EasySummonUI:Initialize()
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
SLASH_SCOMMAND1 = "/easysummon"
SLASH_SCOMMAND3 = "/summon"
SLASH_SCOMMAND2 = "/es"
SLASH_SCOMMAND4 = "/sh" -- Legacy
SlashCmdList["SCOMMAND"] = function()
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
    else
        -- Not in combat, open immediately
        EasySummonUI:ToggleMainFrame()
    end
end

-- Call initialization when addon loads
InitializeAddon()
