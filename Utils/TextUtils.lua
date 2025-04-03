-- Utils/TextUtils.lua
SummonHelperTextUtils = {}

function SummonHelperTextUtils:GetPlayerNameWithoutRealm(fullName)
    return string.match(fullName, "([^%-]+)")  -- Extracts the player name before the dash
end