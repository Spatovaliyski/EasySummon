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
                -- Check if member is in the same instance as the player
                -- This is approximate - in WoW Classic we have limited info
                local unit = "raid" .. i
                local memberIsInInstance = false
                
                -- Best approximation: if player is in instance and member is in same zone, probably in instance
                if playerInInstance and UnitIsConnected(unit) and online then
                    local memberZone = zone or ""
                    local playerZone = GetRealZoneText()
                    memberIsInInstance = (memberZone == playerZone)
                end
                
                table.insert(members, {
                    name = name,
                    class = class,
                    zone = zone,
                    online = online,
                    unit = unit,
                    inRange = UnitInRange(unit),
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
                local memberZone = "" -- We don't have direct access to party member zones
                local memberOnline = UnitIsConnected(unit)
                
                -- Best approximation: if player is in instance and member is in range, probably in instance
                local memberIsInInstance = false
                if playerInInstance and memberOnline and UnitInRange(unit) then
                    memberIsInInstance = true
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