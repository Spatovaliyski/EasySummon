-- Utils/GroupUtils.lua
SummonHelperGroupUtils = {}

function SummonHelperGroupUtils:IsInRaid()
    return IsInRaid()
end

function SummonHelperGroupUtils:IsInstanceZone(zoneName)
    if not zoneName or zoneName == "" then
        return false
    end
    
    -- List of instance zone names to check against
    local instanceZones = {
        -- Raids
        "Molten Core", "Blackwing Lair", "Onyxia's Lair", "Zul'Gurub",
        "Ruins of Ahn'Qiraj", "Temple of Ahn'Qiraj", "Naxxramas",
        -- Dungeons
        "Ragefire Chasm", "Wailing Caverns", "The Deadmines", "Shadowfang Keep",
        "Blackfathom Deeps", "The Stockade", "Gnomeregan", "Razorfen Kraul",
        "Scarlet Monastery", "Razorfen Downs", "Uldaman", "Zul'Farrak",
        "Maraudon", "The Temple of Atal'Hakkar", "Blackrock Depths",
        "Blackrock Spire", "Dire Maul", "Stratholme", "Scholomance"
    }
    
    for _, instanceName in ipairs(instanceZones) do
        if zoneName == instanceName then
            return true
        end
    end
    
    return false
end

function SummonHelperGroupUtils:GetGroupMembers()
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
                
                -- For party, we have to make educated guesses
                local zone
                if UnitIsVisible(unit) then
                    zone = GetRealZoneText() -- Same zone as player
                else
                    zone = "Different Zone"
                end
                
                local memberData = {
                    name = name,
                    class = class,
                    isPlayer = false,
                    online = online,
                    unit = unit,
                    zone = zone,
                    inRange = UnitInRange(unit),
                    isInInstance = not UnitIsVisible(unit) and playerData.isInInstance
                }
                table.insert(members, memberData)
            end
        end
    end
    
    return members
end
