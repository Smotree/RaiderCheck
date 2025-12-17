-- RaiderCheck UI ErrorReport Module
-- Error report window for unknown gems

local _, RC = ...
RC.UI = RC.UI or {}
RC.UI.ErrorReport = {}
local ER = RC.UI.ErrorReport

-- ============================================
-- STATE
-- ============================================
local errorFrame = nil
local pendingErrorReport = false

-- ============================================
-- UNKNOWN GEMS STORAGE
-- ============================================

-- Global storage for unknown gems
RaiderCheck_UnknownGems = RaiderCheck_UnknownGems or {}

-- Add unknown gem to storage
function RaiderCheck_AddUnknownGem(gemId, gemName, gemLink, slotName, playerName)
	if not RaiderCheck_UnknownGems then
		RaiderCheck_UnknownGems = {}
	end

	-- Check if already exists
	for _, gem in ipairs(RaiderCheck_UnknownGems) do
		if gem.id == gemId then
			return false
		end
	end

	table.insert(RaiderCheck_UnknownGems, {
		id = gemId,
		name = gemName or "Unknown",
		link = gemLink,
		slot = slotName,
		player = playerName,
		time = date("%Y-%m-%d %H:%M:%S"),
	})

	return true
end

-- ============================================
-- COMBAT HANDLING
-- ============================================

local combatFrame = CreateFrame("Frame")
combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
combatFrame:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_REGEN_DISABLED" then
		-- Entered combat - hide window
		if errorFrame and errorFrame:IsShown() then
			errorFrame:Hide()
			pendingErrorReport = true
		end
	elseif event == "PLAYER_REGEN_ENABLED" then
		-- Left combat - show pending window
		if pendingErrorReport then
			pendingErrorReport = false
			ER.Show()
		end
	end
end)

-- ============================================
-- FRAME CREATION
-- ============================================

function ER.Create()
	if errorFrame then
		return errorFrame
	end

	local frame = CreateFrame("Frame", "RaiderCheckErrorReportFrame", UIParent)
	frame:SetSize(650, 450)
	frame:SetPoint("CENTER")

	-- Background
	frame:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	frame:SetBackdropColor(0.05, 0.05, 0.08, 0.95)
	frame:SetBackdropBorderColor(0.2, 0.6, 0.8, 1)

	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:SetFrameStrata("DIALOG")
	frame:Hide()

	-- Header gradient (red for errors)
	local header = frame:CreateTexture(nil, "ARTWORK")
	header:SetPoint("TOPLEFT", 4, -4)
	header:SetPoint("TOPRIGHT", -4, -4)
	header:SetHeight(50)
	header:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	header:SetGradientAlpha("VERTICAL", 0.6, 0.1, 0.1, 0.8, 0.3, 0.05, 0.05, 0.8)

	-- Header line
	local headerLine = frame:CreateTexture(nil, "OVERLAY")
	headerLine:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 0)
	headerLine:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, 0)
	headerLine:SetHeight(2)
	headerLine:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	headerLine:SetVertexColor(1, 0.3, 0.3, 0.8)

	-- Title
	local title = frame:CreateFontString(nil, "OVERLAY")
	title:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
	title:SetPoint("TOPLEFT", 15, -18)
	title:SetText("Ошибка обработки самоцвета")
	title:SetTextColor(1, 0.3, 0.3, 1)

	-- Subtitle
	local subtitle = frame:CreateFontString(nil, "OVERLAY")
	subtitle:SetFont("Fonts\\FRIZQT__.TTF", 10)
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
	subtitle:SetText("Найдены неизвестные самоцветы")
	subtitle:SetTextColor(0.7, 0.7, 0.7, 1)

	-- Close button
	local closeButton = CreateFrame("Button", nil, frame)
	closeButton:SetSize(24, 24)
	closeButton:SetPoint("TOPRIGHT", -8, -8)

	local closeBg = closeButton:CreateTexture(nil, "BACKGROUND")
	closeBg:SetAllPoints()
	closeBg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	closeBg:SetVertexColor(0.8, 0.2, 0.2, 0.6)

	local closeText = closeButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	closeText:SetPoint("CENTER")
	closeText:SetText("×")
	closeText:SetTextColor(1, 1, 1, 1)

	closeButton:SetScript("OnEnter", function(self)
		closeBg:SetVertexColor(1, 0.3, 0.3, 0.9)
		self:SetScale(1.1)
	end)
	closeButton:SetScript("OnLeave", function(self)
		closeBg:SetVertexColor(0.8, 0.2, 0.2, 0.6)
		self:SetScale(1.0)
	end)
	closeButton:SetScript("OnClick", function()
		frame:Hide()
	end)

	-- Description
	local description = frame:CreateFontString(nil, "OVERLAY")
	description:SetFont("Fonts\\FRIZQT__.TTF", 10)
	description:SetPoint("TOPLEFT", 15, -70)
	description:SetWidth(600)
	description:SetText(
		"Найдены неизвестные самоцветы. Скопируйте информацию ниже и отправьте создателю аддона в дискорд @smotree:"
	)
	description:SetJustifyH("LEFT")
	description:SetWordWrap(true)
	description:SetTextColor(0.9, 0.7, 0.3, 1)

	-- ScrollFrame
	local scrollFrame = CreateFrame("ScrollFrame", "RaiderCheckErrorScrollFrame", frame, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", 15, -100)
	scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)

	-- EditBox
	local editBox = CreateFrame("EditBox", nil, scrollFrame)
	editBox:SetMultiLine(true)
	editBox:SetAutoFocus(false)
	editBox:SetFontObject(GameFontNormal)
	editBox:SetWidth(580)
	editBox:SetMaxLetters(0)
	editBox:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	editBox:SetScript("OnEditFocusGained", function(self)
		self:HighlightText()
	end)

	scrollFrame:SetScrollChild(editBox)
	frame.editBox = editBox

	-- Clear button
	local clearButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	clearButton:SetSize(120, 25)
	clearButton:SetPoint("BOTTOMLEFT", 15, 15)
	clearButton:SetText("Очистить список")
	clearButton:SetScript("OnClick", function()
		RaiderCheck_UnknownGems = {}
		ER.Update()
		print("|cFF00FF00RaiderCheck:|r Список неизвестных камней очищен")
	end)

	errorFrame = frame
	return frame
end

-- ============================================
-- UPDATE
-- ============================================

function ER.Update()
	if not errorFrame or not errorFrame.editBox then
		return
	end

	local text = "=== Неизвестные камни ===\n\n"

	if not RaiderCheck_UnknownGems or #RaiderCheck_UnknownGems == 0 then
		text = text .. "Нет неизвестных камней.\n"
	else
		for i, gem in ipairs(RaiderCheck_UnknownGems) do
			text = text
				.. string.format(
					"%d. ID: %s | Название: %s | Слот: %s | Игрок: %s | Время: %s\n",
					i,
					tostring(gem.id or "?"),
					tostring(gem.name or "?"),
					tostring(gem.slot or "?"),
					tostring(gem.player or "?"),
					tostring(gem.time or "?")
				)
		end
	end

	errorFrame.editBox:SetText(text)
end

-- ============================================
-- SHOW / HIDE
-- ============================================

function ER.Show()
	-- Don't show in combat
	if InCombatLockdown() then
		pendingErrorReport = true
		return
	end

	if not errorFrame then
		ER.Create()
	end

	ER.Update()
	errorFrame:Show()
end

function ER.Hide()
	if errorFrame then
		errorFrame:Hide()
	end
end

-- ============================================
-- NOTIFICATION
-- ============================================

function ER.NotifyUnknownGems()
	if RaiderCheck_UnknownGems and #RaiderCheck_UnknownGems > 0 then
		print(
			"|cFFFF0000RaiderCheck:|r Найдено "
				.. #RaiderCheck_UnknownGems
				.. " неизвестных камней. Используйте /rc report"
		)
	end
end

-- Export for backwards compatibility
RaiderCheck.ShowErrorReport = function(self)
	ER.Show()
end

RaiderCheck.NotifyUnknownGems = function(self)
	ER.NotifyUnknownGems()
end
