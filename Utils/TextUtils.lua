-- Utils/TextUtils.lua
EasySummonTextUtils = {}

function EasySummonTextUtils:GetPlayerNameWithoutRealm(fullName)
    return string.match(fullName, "([^%-]+)")  -- Extracts the player name before the dash
end
