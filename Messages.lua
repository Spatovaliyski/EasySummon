EasySummonMessages = {}

local ANNOUNCE_TEXT = "[EasySummon]: Summoning %s, please click!"
local lastAnnounceTime = 0
local ANNOUNCE_COOLDOWN = 1 -- Prevent spam within 1 second

function EasySummonMessages:AnnounceChannelStart(targetName)
	-- Cooldown check to prevent spam
	if (GetTime() - lastAnnounceTime) < ANNOUNCE_COOLDOWN then
		return
	end
	lastAnnounceTime = GetTime()

	-- Determine channel
	local channel
	if IsInRaid() then
		channel = "RAID"
	elseif IsInGroup() then
		channel = "PARTY"
	else
		return
	end

	-- Validate target
	if not targetName or targetName == "" then
		return
	end

	-- Send announcement
	local message = ANNOUNCE_TEXT:format(targetName)
	SendChatMessage(message, channel)
end
