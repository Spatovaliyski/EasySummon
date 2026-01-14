EasySummonTextUtils = {}

function EasySummonTextUtils:GetPlayerNameWithoutRealm(fullName)
	return string.match(fullName, "([^%-]+)")
end
