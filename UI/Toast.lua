EasySummonToast = {}

function EasySummonToast:Initialize()
	local toast = CreateFrame("Frame", "EasySummonToastFrame", UIParent)
	toast:SetSize(300, 80)
	toast:SetPoint("CENTER", 0, -100)
	toast:SetFrameStrata("FULLSCREEN_DIALOG")
	toast:SetFrameLevel(9999) -- High level, its prio
	toast:EnableMouse(true)
	toast:SetMovable(true)
	toast:RegisterForDrag("LeftButton")
	toast:SetScript("OnDragStart", function(self)
		self:StartMoving()
		self.isDragging = true
	end)
	toast:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		self.isDragging = false
		-- Store the current base position
		EasySummonToast:UpdateBasePosition()
	end)
	toast:Hide()

	-- Store base position (where the toast is placed)
	toast.basePoint = "CENTER"
	toast.baseX = 0
	toast.baseY = -100

	-- Store reference to parent object
	self.frame = toast
	local bg = toast:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")

	-- Create title
	local title = toast:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	title:SetPoint("TOP", 0, -15)
	title:SetText("Easy Summon")

	-- Create message text
	local message = toast:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	message:SetPoint("TOP", title, "BOTTOM", 0, -5)
	message:SetPoint("LEFT", 20, 0)
	message:SetPoint("RIGHT", -20, 0)
	message:SetJustifyH("CENTER")

	-- Create close button
	local closeButton = CreateFrame("Button", nil, toast, "UIPanelCloseButton")
	closeButton:SetSize(20, 20)
	closeButton:SetPoint("TOPRIGHT", -5, -5)
	closeButton:SetScript("OnClick", function()
		toast:Hide()
	end)

	-- Click handling
	toast:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			-- Don't handle if clicking the close button or if dragging
			if closeButton:IsMouseOver() or self.isDragging then
				return
			end

			-- Open the EasySummon frame
			EasySummonUI:ToggleMainFrame()
			self:Hide()
		end
	end)

	-- Store toast data
	self.message = message
	self.summoner = nil -- Store the name of the person who requested a summon

	-- Animation group for entrance
	toast.enterGroup = toast:CreateAnimationGroup()
	local slideIn = toast.enterGroup:CreateAnimation("Translation")
	slideIn:SetOffset(0, 20)
	slideIn:SetDuration(0.4)
	slideIn:SetSmoothing("OUT")

	local fadeInAlpha = toast.enterGroup:CreateAnimation("Alpha")
	fadeInAlpha:SetFromAlpha(0)
	fadeInAlpha:SetToAlpha(1)
	fadeInAlpha:SetDuration(0.4)
	fadeInAlpha:SetSmoothing("OUT")

	-- When entrance animation finishes, move frame up to match where animation ended
	toast.enterGroup:SetScript("OnFinished", function()
		if toast:IsShown() then
			toast:ClearAllPoints()
			toast:SetPoint(toast.basePoint, toast.baseX, toast.baseY)
		end
	end)

	-- Animation for fading out and sliding down
	toast.fadeGroup = toast:CreateAnimationGroup()
	local slideDown = toast.fadeGroup:CreateAnimation("Translation")
	slideDown:SetOffset(0, -20)
	slideDown:SetDuration(0.4)
	slideDown:SetStartDelay(3)
	slideDown:SetSmoothing("IN")

	local fadeOut = toast.fadeGroup:CreateAnimation("Alpha")
	fadeOut:SetFromAlpha(1)
	fadeOut:SetToAlpha(0)
	fadeOut:SetDuration(0.4)
	fadeOut:SetStartDelay(3)
	fadeOut:SetSmoothing("IN")

	-- When exit animation finishes, move frame down and hide
	fadeOut:SetScript("OnFinished", function()
		if toast:IsShown() then
			toast:ClearAllPoints()
			toast:SetPoint(toast.basePoint, toast.baseX, toast.baseY - 20)
		end
		toast:Hide()
	end)

	toast:SetScript("OnShow", function()
		toast:SetAlpha(1)
		toast:ClearAllPoints()
		toast:SetPoint(toast.basePoint, toast.baseX, toast.baseY - 20)
		toast.enterGroup:Stop()
		toast.fadeGroup:Stop()
		toast.enterGroup:Play()
		C_Timer.After(0.4, function()
			if toast:IsShown() then
				toast.fadeGroup:Play()
			end
		end)
	end)

	toast:SetScript("OnEnter", function()
		toast.enterGroup:Stop()
		toast.fadeGroup:Stop()
		toast:SetAlpha(1)
	end)

	toast:SetScript("OnLeave", function()
		toast.enterGroup:Stop()
		toast.fadeGroup:Play()
	end)

	local infoText = toast:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	infoText:SetPoint("BOTTOM", 0, 12)
	infoText:SetText("Click to open Easy Summon")
	infoText:SetTextColor(0.7, 0.7, 0.7)
end

function EasySummonToast:UpdateBasePosition()
	local toast = self.frame
	if not toast then
		return
	end

	-- Store the current position as the new base position
	local point, relativeFrame, relativePoint, xOffset, yOffset = toast:GetPoint()
	self.basePoint = point or "CENTER"
	self.baseX = xOffset or 0
	self.baseY = yOffset or -100
end

function EasySummonToast:Show(playerName)
	if not self.frame then
		self:Initialize()
	end

	-- Update message
	self.message:SetText(playerName .. " requested a summon")

	-- Store summoner name
	self.summoner = playerName

	-- Show the frame
	self.frame:Show()

	PlaySound(SOUNDKIT.READY_CHECK, "Dialog")
end
