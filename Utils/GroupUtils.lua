-- Utils/GroupUtils.lua
EasySummonGroupUtils = {}

function EasySummonGroupUtils:IsInRaid()
    return IsInRaid()
end

function EasySummonGroupUtils:IsInstanceZone(zoneName)
    if not zoneName or zoneName == "" then return false end
    
    -- These zones might be reported as instances but aren't truly instanced
    if zoneName == "Dire Maul" or zoneName == "Blackrock Mountain" then
        return false
    end
    
    -- Check for outside/entrance areas
    if zoneName:find("%(Outside%)") or zoneName:find("Entrance") then
        return false
    end
    
    -- Check for specific instance wings/sections
    if (zoneName:find("Dire Maul") and (zoneName:find("North") or zoneName:find("East") or zoneName:find("West"))) or
       (zoneName:find("Blackrock") and (zoneName:find("Depths") or zoneName:find("Spire"))) then
        return true
    end
    
    -- Check for known dungeon/raid names
    local instancePatterns = {
        "Molten Core", "Blackwing Lair", "Onyxia's Lair", "Naxxramas",
        "Zul'Gurub", "Ruins of Ahn'Qiraj", "Temple of Ahn'Qiraj",
        "Scarlet Monastery", "Stratholme", "Scholomance", "Ragefire Chasm",
        "Deadmines", "Wailing Caverns", "Shadowfang Keep", "Blackfathom Deeps",
        "Gnomeregan", "Maraudon", "Razorfen", "Stockade", "Sunken Temple", "Uldaman",
        "Dungeon", "Raid"
    }
    
    for _, pattern in ipairs(instancePatterns) do
        if zoneName:find(pattern) then
            return true
        end
    end
    
    return false
end

function EasySummonGroupUtils:GetGroupMembers()
    local members = {}
    local playerName = UnitName("player")
    local isInRaid = IsInRaid()
    
    -- First add the player
    local playerData = {
        name = playerName,
        class = select(2, UnitClass("player")),
        isPlayer = true,
        online = true,
        unit = "player",
        zone = GetRealZoneText(),
        inRange = true,
        isInInstance = select(1, IsInInstance())
    }
    table.insert(members, playerData)
    
    -- Get members from raid roster
    if isInRaid then
        for i = 1, GetNumGroupMembers() do
            local name, _, _, _, _, class, zone, _, _, _, _, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
            
            if name and name ~= playerName then
                local unit = "raid" .. i
                
                local memberData = {
                    name = name,
                    class = class,
                    isPlayer = false,
                    online = online == 1,
                    unit = unit,
                    zone = zone or "Unknown",
                    inRange = UnitInRange(unit),
                    isInInstance = self:IsInstanceZone(zone)
                }
                table.insert(members, memberData)
            end
        end
    else
        -- Get members from party
        for i = 1, GetNumGroupMembers() - 1 do
            local unit = "party" .. i
            local name = UnitName(unit)
            
            if name and name ~= playerName then
                local _, class = UnitClass(unit)
                local online = UnitIsConnected(unit)
                
                local zone
                local isInInstance = false
                
                -- Use inference based on visibility and range
                if not zone or zone == "" then
                    local inSameInstance, instanceType = IsInInstance()
                    
                    if UnitIsVisible(unit) then
                        if UnitInRange(unit) then
                            zone = GetRealZoneText()
                            isInInstance = inSameInstance
                        else
                            zone = "In the same zone"
                            isInInstance = inSameInstance
                        end
                    else
                        -- If not visible, check other indicators
                        local inInstance = select(1, IsInInstance())
                        if inInstance then
                            zone = "Different Instance"
                            isInInstance = false -- Not in the same instance
                        else
                            if C_Map and C_Map.GetBestMapForUnit then
                                local playerMapID = C_Map.GetBestMapForUnit("player")
                                local playerContinent = playerMapID and C_Map.GetMapInfo(playerMapID) and C_Map.GetMapInfo(playerMapID).parentMapID

                                if playerContinent == 1 or playerContinent == 1414 then -- Kalimdor
                                    zone = "Elsewhere in Kalimdor"
                                elseif playerContinent == 2 or playerContinent == 1415 then -- Eastern Kingdoms
                                    zone = "Elsewhere in Eastern Kingdoms"
                                else
                                    zone = "Different Zone"
                                end
                            else
                                zone = "Different Zone"
                            end
                            isInInstance = false
                        end
                    end
                end
                
                local memberData = {
                    name = name,
                    class = class,
                    isPlayer = false,
                    online = online,
                    unit = unit,
                    zone = zone or "Unknown",
                    inRange = UnitInRange(unit),
                    isInInstance = isInInstance
                }
                table.insert(members, memberData)
            end
        end
    end
    
    return members
end

function EasySummonGroupUtils:UpdateGroupSizeText()
    if not EasySummonUI.groupSizeText then return end
    
    local groupSize = 0
    local maxSize = 5
    local groupType = "Party"
    
    if IsInRaid() then
        groupSize = GetNumGroupMembers()
        maxSize = 40
        groupType = "Raid"
    elseif IsInGroup() then
        groupSize = GetNumGroupMembers()
        maxSize = 5
        groupType = "Party"
    else
        EasySummonUI.groupSizeText:SetText("Not in a group")
        return
    end
    
    EasySummonUI.groupSizeText:SetText(string.format("%s: %d/%d", groupType, groupSize, maxSize))
end
