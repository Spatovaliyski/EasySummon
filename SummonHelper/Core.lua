-- Core.lua
SummonHelper = {}
SummonHelper.__index = SummonHelper

function SummonHelper:New()
    local self = setmetatable({}, SummonHelper)
    self.playerResponses = {}
    self.updateInterval = 2
    self.lastUpdate = 0
    self:InitializeEvents()
    return self
end

function SummonHelper:InitializeEvents()
    self.frame = CreateFrame("Frame")
    self.frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    self.frame:RegisterEvent("CHAT_MSG_PARTY")
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
            if SummonHelperUI and SummonHelperUI.frame and SummonHelperUI.frame:IsShown() then
                self:UpdateRaidList()
            end
            
            -- Also update when summon button is visible
            if SummonHelperSummonButton and SummonHelperSummonButton.button and 
               SummonHelperSummonButton.button:IsShown() then
                self:UpdateRaidList()
            end
        end
    end)
end

function SummonHelper:SetActive(isActive)
    self.isActive = isActive
    
    -- If we're activating, do an immediate update
    if isActive then
        self:UpdateRaidList()
    end
end

function SummonHelper:ResetResponses()
    wipe(self.playerResponses)
    self:UpdateRaidList()
end

function SummonHelper:ResetResponse(playerName)
    if self.playerResponses[playerName] then
        self.playerResponses[playerName] = nil
        self:UpdateRaidList()
    end
end

-- Define a placeholder UpdateRaidList method
function SummonHelper:UpdateRaidList()
  -- Will be overridden by RaidList.lua
  if SummonHelperRaidList and SummonHelperRaidList.UpdateList then
      SummonHelperRaidList:UpdateList(self.playerResponses)
  end
end

function SummonHelper:CheckForSummonRequest(event, msg, sender)
    if not self.isActive then
        return
    end
    
    local playerName = SummonHelperTextUtils:GetPlayerNameWithoutRealm(sender)
    if self:IsSummonRequest(msg, event) then
        if self.playerResponses[playerName] then
            return  -- Ignore if already responded
        end
        
        self.playerResponses[playerName] = true
        PlaySound(SOUNDKIT.READY_CHECK, "Master")
        self:UpdateRaidList()
    end
end

function SummonHelper:IsSummonRequest(msg, event)
    -- Logic to determine if a message is a summon request
    local lowerMsg = string.lower(msg)
    
    if lowerMsg:match("^summonhelper: summoning") then
        return false
    end
    
    -- Also ignore other patterns that might indicate a summon is already happening
    if lowerMsg:match("^attempting to summon") or lowerMsg:match("^summoning ") then
        return false
    end
    
    for _, phrase in ipairs(SummonHelperConfig.SummonPhrases) do
        if lowerMsg == phrase then
            return true
        end
    end
    
    return false
end

-- Global initialization
local function InitializeAddon()
  _G.SummonHelperCore = SummonHelper:New()
  print("|cFF33FF33SummonHelper:|r Core initialized")
  
  -- Delay UI init
  C_Timer.After(0.5, function()
      if SummonHelperUI and SummonHelperUI.Initialize then
          SummonHelperUI:Initialize()
          print("|cFF33FF33SummonHelper:|r UI initialized")
          
          if _G.SummonHelperCore and _G.SummonHelperCore.UpdateRaidList then
            _G.SummonHelperCore:UpdateRaidList()
          end
      else
          print("|cFFFF3333SummonHelper:|r Error: UI module not found")
      end
  end)
end

-- Register slash commands
SLASH_SUMMONHELPER1 = "/sh"
SLASH_SUMMONHELPER2 = "/summonhelper"
SlashCmdList["SUMMONHELPER"] = function()
    SummonHelperUI:ToggleMainFrame()
end

-- Call initialization when addon loads
InitializeAddon()