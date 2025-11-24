-- Config.lua
-- Default configuration
local defaults = {
	-- UI settings
	FrameWidth = 390,
	FrameHeight = 500,

	NotifyWhenHidden = false,

	-- Summoning keywords (default list + custom ones added by player)
	SummonKeywords = {
		"123",
		"+",
		"++",
		"+++",
		"sum",
		"summ pls",
		"summon please",
		"summon pls",
		"summon plz",
		"summon",
		"summon me",
		"tp me",
		"warlock taxi",
		"lock taxi",
		"lock sum",
		"lock port",
		"lock summon",
		"any sum",
		"any summon",
	},

	-- Colors
	Colors = {
		Background = { 0, 0, 0, 1.0 },
		Requested = { 0, 1, 0 },
	},
}

local function InitializeConfig()
	if not EasySummonConfig then
		EasySummonConfig = CopyTable(defaults)
	else
		for k, v in pairs(defaults) do
			if EasySummonConfig[k] == nil then
				EasySummonConfig[k] = v
			end
		end
	end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addonName)
	if event == "ADDON_LOADED" and addonName == "EasySummon" then
		InitializeConfig()
		self:UnregisterEvent("ADDON_LOADED")
	end
end)
