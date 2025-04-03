-- Utils/GroupUtils.lua
SummonHelperGroupUtils = {}

function SummonHelperGroupUtils:IsInRaid()
    return IsInRaid()
end

function SummonHelperGroupUtils:GetGroupMembers()
    local members = {}
    local playerInInstance = IsInInstance()
    
    if self:IsInRaid() then
        for i = 1, 40 do
            local name, _, _, _, _, class, zone, online = GetRaidRosterInfo(i)
            if name then
                local unit = "raid" .. i
                local memberIsInInstance = false
                
                local playerZone = GetRealZoneText()
                local memberIsPlayer = (UnitIsUnit(unit, "player"))
                
                if memberIsPlayer then
                    -- For the player, we know exactly if we're in an instance
                    memberIsInInstance = playerInInstance
                else
                    -- For other raid members:
                    -- 1. If they're in a different zone than us, they might be in an instance
                    -- 2. If we're outside and they're in a different zone, assume they're instanced
                    if zone and zone ~= "" and zone ~= playerZone and not playerInInstance then
                        -- We're outside and they're in a different zone - likely in an instance
                        memberIsInInstance = true
                    elseif zone and zone ~= "" and zone == playerZone and playerInInstance then
                        -- We're in an instance and they're in the same zone - they're also in the instance
                        memberIsInInstance = true
                    end
                end
                
                -- Debug output
                -- if not memberIsPlayer and ((not playerInInstance and memberIsInInstance) or 
                --                            (playerInInstance and not memberIsInInstance)) then
                --     print("|cFF33FF33Debug:|r " .. name .. " - Zone: " .. (zone or "unknown") .. 
                --           ", isInInstance: " .. tostring(memberIsInInstance))
                -- end
                
                table.insert(members, {
                    name = name,
                    class = class,
                    zone = zone,
                    online = online,
                    unit = unit,
                    inRange = UnitInRange(unit),
                    isPlayer = memberIsPlayer,
                    isInInstance = memberIsInInstance
                })
            end
        end
    else
        -- Add player first
        local playerName = UnitName("player")
        local _, playerClass = UnitClass("player")
        
        table.insert(members, {
            name = playerName,
            class = playerClass,
            zone = GetRealZoneText(),
            online = true,
            unit = "player",
            inRange = true,
            isPlayer = true,
            isInInstance = playerInInstance
        })
        
        -- Add party members
        for i = 1, 4 do
            local unit = "party" .. i
            if UnitExists(unit) then
                local memberName = UnitName(unit)
                local _, memberClass = UnitClass(unit)
                local memberOnline = UnitIsConnected(unit)
                
                -- For party, use a similar approach to raid
                local memberIsInInstance = false
                local playerZone = GetRealZoneText()
                local memberZone = ""
                
                GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
                GameTooltip:SetUnit(unit)
                for i = 1, GameTooltip:NumLines() do
                    local text = _G["GameTooltipTextLeft" .. i]:GetText()
                    if text and text:match("^Zone: ") then
                        memberZone = text:match("^Zone: (.+)")
                        break
                    end
                end
                GameTooltip:Hide()
                
                if memberZone ~= "" and memberZone ~= playerZone and not playerInInstance then
                    -- We're outside and they're in a different zone - likely in an instance
                    memberIsInInstance = true
                elseif memberZone ~= "" and memberZone == playerZone and playerInInstance then
                    -- We're in an instance and they're in the same zone - they're also in the instance
                    memberIsInInstance = true
                elseif memberZone == "" then
                    -- Couldn't get zone - fallback to range check
                    if playerInInstance and UnitInRange(unit) then
                        -- If we're in instance and they're in range, they're likely in the instance too
                        memberIsInInstance = true
                    end
                end
                
                table.insert(members, {
                    name = memberName,
                    class = memberClass,
                    zone = memberZone,
                    online = memberOnline,
                    unit = unit,
                    inRange = UnitInRange(unit),
                    isInInstance = memberIsInInstance
                })
            end
        end
    end
    
    return members
end