EasySummonMeetingStone = {}

-- Announce when Meeting Stone channel starts
local summonAnnounce = CreateFrame("Frame", "EasySummonMeetingStoneAnnouncer")
summonAnnounce:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")

summonAnnounce:SetScript("OnEvent", function(frame, event, unit, castGUID, spellId)
	if event ~= "UNIT_SPELLCAST_CHANNEL_START" then
		return
	end

	if unit ~= "player" then
		return
	end

	-- Meeting Stone (channel): 23598
	if spellId ~= 23598 then
		return
	end

	if not UnitExists("target") or not UnitIsPlayer("target") then
		return
	end
	if UnitIsUnit("target", "player") then
		return
	end

	local targetName = GetUnitName("target", true) or GetUnitName("target")
	if not targetName then
		return
	end

	EasySummonMessages:AnnounceChannelStart(targetName)
end)
