-- RaiderCheck UI GUI Module
-- Main interface window

local _, RC = ...
RC.UI = RC.UI or {}
RC.UI.GUI = {}
local GUI = RC.UI.GUI
local Core = RC.Core
local C = RC.Data.Constants
local Settings = RC.Data.Settings

-- ============================================
-- STATE
-- ============================================
local mainFrame = nil
local scrollChild = nil
local scrollFrame = nil
local playerFrames = {}

-- ============================================
-- MAIN FRAME CREATION
-- ============================================

function GUI.Create()
	if mainFrame then
		return mainFrame
	end

	-- Main frame
	local frame = CreateFrame("Frame", "RaiderCheckFrame", UIParent)
	frame:SetSize(620, 480)
	frame:SetPoint("TOP")
	frame:SetFrameStrata("HIGH")

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
	frame:Hide()

	-- Header gradient
	local header = frame:CreateTexture(nil, "ARTWORK")
	header:SetPoint("TOPLEFT", 4, -4)
	header:SetPoint("TOPRIGHT", -4, -4)
	header:SetHeight(50)
	header:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	header:SetGradientAlpha("VERTICAL", 0.1, 0.3, 0.5, 0.8, 0.05, 0.15, 0.25, 0.8)

	-- Header line
	local headerLine = frame:CreateTexture(nil, "OVERLAY")
	headerLine:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 0)
	headerLine:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, 0)
	headerLine:SetHeight(2)
	headerLine:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	headerLine:SetVertexColor(0.3, 0.7, 1, 0.8)

	-- Title
	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 15, -18)
	title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
	title:SetText("RaiderCheck")
	title:SetTextColor(0.3, 0.8, 1, 1)

	-- Subtitle
	local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
	subtitle:SetFont("Fonts\\FRIZQT__.TTF", 11)
	subtitle:SetText("Проверка готовности группы")
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

	-- Refresh button
	local refreshButton = CreateFrame("Button", nil, frame)
	refreshButton:SetSize(80, 24)
	refreshButton:SetPoint("TOPRIGHT", closeButton, "TOPLEFT", 0, 0)

	local refreshBg = refreshButton:CreateTexture(nil, "BACKGROUND")
	refreshBg:SetAllPoints()
	refreshBg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	refreshBg:SetVertexColor(0.15, 0.5, 0.75, 0.8)

	local refreshText = refreshButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	refreshText:SetPoint("CENTER")
	refreshText:SetText("Обновить")
	refreshText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")

	refreshButton:SetScript("OnEnter", function(btn)
		refreshBg:SetVertexColor(0.2, 0.6, 0.9, 1)
		btn:SetScale(1.05)
	end)
	refreshButton:SetScript("OnLeave", function(btn)
		refreshBg:SetVertexColor(0.15, 0.5, 0.75, 0.8)
		btn:SetScale(1.0)
	end)
	refreshButton:SetScript("OnClick", function()
		Core.ScanGroup()
	end)

	-- Gem settings panel
	GUI.CreateGemSettingsPanel(frame)

	-- Scroll frame
	scrollFrame = CreateFrame("ScrollFrame", "RaiderCheckScrollFrame", frame, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", 12, -165)
	scrollFrame:SetPoint("BOTTOMRIGHT", -30, 12)

	local scrollBg = scrollFrame:CreateTexture(nil, "BACKGROUND")
	scrollBg:SetAllPoints()
	scrollBg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	scrollBg:SetVertexColor(0.02, 0.02, 0.05, 0.5)

	scrollChild = CreateFrame("Frame", nil, scrollFrame)
	scrollChild:SetSize(570, 1)
	scrollFrame:SetScrollChild(scrollChild)

	mainFrame = frame
	return frame
end

-- ============================================
-- GEM SETTINGS PANEL
-- ============================================

function GUI.CreateGemSettingsPanel(parent)
	local panel = CreateFrame("Frame", nil, parent)
	panel:SetSize(590, 85)
	panel:SetPoint("TOPLEFT", 12, -65)

	panel:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false,
		edgeSize = 10,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	panel:SetBackdropColor(0.1, 0.1, 0.15, 0.8)
	panel:SetBackdropBorderColor(0.3, 0.5, 0.7, 0.6)

	-- Title
	local panelTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	panelTitle:SetPoint("TOPLEFT", 10, -8)
	panelTitle:SetText("Минимальное качество камней:")
	panelTitle:SetTextColor(0.8, 0.8, 0.8, 1)

	-- Quality buttons
	local qualityOrder = C.GEM_PRIORITY_ORDER
	local buttonWidth = 70
	local startX = 10
	local buttonY = -30

	local qualityButtons = {}

	for i, quality in ipairs(qualityOrder) do
		local btn = CreateFrame("Button", nil, panel)
		btn:SetSize(buttonWidth, 22)
		btn:SetPoint("TOPLEFT", startX + (i - 1) * (buttonWidth + 5), buttonY)

		local bg = btn:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
		btn.bg = bg

		local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		text:SetPoint("CENTER")
		text:SetText(quality)
		text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
		btn.text = text

		btn.quality = quality
		qualityButtons[quality] = btn

		btn:SetScript("OnClick", function()
			Settings.SetMinGemQuality(quality)
			GUI.UpdateGemButtons(qualityButtons)
			GUI.Update()
		end)

		btn:SetScript("OnEnter", function(self)
			local current = Settings.GetMinGemQuality()
			if self.quality ~= current then
				self.bg:SetVertexColor(0.3, 0.5, 0.3, 0.8)
			end
		end)

		btn:SetScript("OnLeave", function(self)
			GUI.UpdateGemButtons(qualityButtons)
		end)
	end

	-- Info text
	local infoText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	infoText:SetPoint("TOPLEFT", 10, -58)
	infoText:SetText(
		"Камни ниже выбранного качества будут отмечены как устаревшие"
	)
	infoText:SetTextColor(0.6, 0.6, 0.6, 1)

	panel.qualityButtons = qualityButtons
	GUI.gemSettingsPanel = panel

	-- Initial update
	GUI.UpdateGemButtons(qualityButtons)
end

function GUI.UpdateGemButtons(buttons)
	local currentQuality = Settings.GetMinGemQuality()
	local currentPriority = C.GetGemPriorityValue(currentQuality)

	for quality, btn in pairs(buttons) do
		local priority = C.GetGemPriorityValue(quality)

		if quality == currentQuality then
			-- Selected
			btn.bg:SetVertexColor(0.2, 0.6, 0.2, 1)
			btn.text:SetTextColor(1, 1, 1, 1)
		elseif priority >= currentPriority then
			-- Acceptable
			btn.bg:SetVertexColor(0.15, 0.4, 0.15, 0.6)
			btn.text:SetTextColor(0.7, 1, 0.7, 1)
		else
			-- Below minimum
			btn.bg:SetVertexColor(0.4, 0.15, 0.15, 0.6)
			btn.text:SetTextColor(1, 0.5, 0.5, 1)
		end
	end
end

-- ============================================
-- TOGGLE / SHOW / HIDE
-- ============================================

function GUI.Toggle()
	if not mainFrame then
		GUI.Create()
	end

	if mainFrame:IsShown() then
		mainFrame:Hide()
	else
		mainFrame:Show()
		GUI.Update()
	end
end

function GUI.Show()
	if not mainFrame then
		GUI.Create()
	end
	mainFrame:Show()
	GUI.Update()
end

function GUI.Hide()
	if mainFrame then
		mainFrame:Hide()
	end
end

-- ============================================
-- GUI UPDATE
-- ============================================

function GUI.Update()
	if not mainFrame or not mainFrame:IsShown() then
		return
	end

	-- Update own data
	Core.UpdateOwnData(true)

	-- Clear old frames
	for _, frame in ipairs(playerFrames) do
		frame:Hide()
		frame:SetParent(nil)
	end
	playerFrames = {}

	-- Get group players
	local players = Core.GetGroupPlayers()

	if #players == 0 then
		local noGroupText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		noGroupText:SetPoint("TOP", 0, -10)
		noGroupText:SetText("Вы не в группе или рейде")
		table.insert(playerFrames, noGroupText)
		return
	end

	-- Create player frames
	local yOffset = -10
	for i, playerName in ipairs(players) do
		local playerFrame = GUI.CreatePlayerFrame(playerName, i)
		playerFrame:SetPoint("TOPLEFT", 5, yOffset)
		playerFrame:SetParent(scrollChild)
		playerFrame:Show()

		table.insert(playerFrames, playerFrame)
		yOffset = yOffset - 98
	end

	-- Update scroll child height
	scrollChild:SetHeight(math.abs(yOffset))

	-- Update gem buttons
	if GUI.gemSettingsPanel and GUI.gemSettingsPanel.qualityButtons then
		GUI.UpdateGemButtons(GUI.gemSettingsPanel.qualityButtons)
	end
end

-- ============================================
-- PLAYER FRAME CREATION
-- ============================================

function GUI.CreatePlayerFrame(playerName, index)
	local frame = CreateFrame("Frame", nil, scrollChild)
	frame:SetSize(580, 90)

	-- Get class for coloring
	local className = Core.GetPlayerClass(playerName)
	local classColor = RAID_CLASS_COLORS[className] or { r = 0.3, g = 0.3, b = 0.3 }

	-- Background
	frame:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false,
		tileSize = 16,
		edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	frame:SetBackdropColor(0.08, 0.08, 0.12, 0.9)
	frame:SetBackdropBorderColor(classColor.r * 0.6, classColor.g * 0.6, classColor.b * 0.6, 0.8)

	-- Class color stripe
	local classStripe = frame:CreateTexture(nil, "ARTWORK")
	classStripe:SetPoint("TOPLEFT", 3, -3)
	classStripe:SetPoint("BOTTOMLEFT", 3, 3)
	classStripe:SetWidth(4)
	classStripe:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	classStripe:SetVertexColor(classColor.r, classColor.g, classColor.b, 1)

	-- Player name
	local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	nameText:SetPoint("TOPLEFT", 10, -12)
	nameText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
	nameText:SetTextColor(classColor.r * 1.2, classColor.g * 1.2, classColor.b * 1.2, 1)
	nameText:SetText(playerName)

	-- Check addon presence
	local hasAddon = Core.players[playerName] ~= nil or Core.playerData[playerName] ~= nil
	local clientType = Core.players[playerName] or "RC"

	if playerName == UnitName("player") then
		hasAddon = true
		clientType = "RC"
	end

	-- Status icon
	local statusIcon = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
	statusIcon:SetPoint("TOPLEFT", 10, -34)
	statusIcon:SetFont("Fonts\\FRIZQT__.TTF", 14)

	if hasAddon then
		statusIcon:SetText(clientType)
		if clientType == "WA" then
			statusIcon:SetTextColor(0.6, 0.3, 0.9, 1)
		else
			statusIcon:SetTextColor(0.2, 1, 0.3, 1)
		end
	else
		statusIcon:SetText("-")
		statusIcon:SetTextColor(1, 0.3, 0.2, 1)
	end

	if hasAddon then
		-- Gear analysis
		local gearAnalysis = Core.AnalyzePlayerGear(playerName)
		local gearText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		gearText:SetPoint("TOPLEFT", 40, -36)
		gearText:SetFont("Fonts\\FRIZQT__.TTF", 10)

		local gearExtraText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		gearExtraText:SetPoint("TOPLEFT", 40, -54)
		gearExtraText:SetFont("Fonts\\FRIZQT__.TTF", 10)

		local hasExtra = false

		if gearAnalysis.hasData then
			local enchantRatio = string.format("%d/%d", gearAnalysis.enchantCount, gearAnalysis.totalSlots)
			gearText:SetText("Зачарованно: " .. enchantRatio)

			local extraParts = {}

			-- Empty sockets
			if gearAnalysis.emptySockets and #gearAnalysis.emptySockets > 0 then
				local totalEmpty = 0
				for _, socket in ipairs(gearAnalysis.emptySockets) do
					totalEmpty = totalEmpty + socket.emptyCount
				end
				table.insert(extraParts, "Пусто: " .. totalEmpty)
			end

			-- Low quality gems
			if gearAnalysis.lowQualityGemsCount and gearAnalysis.lowQualityGemsCount > 0 then
				table.insert(extraParts, "Старые: " .. gearAnalysis.lowQualityGemsCount)
			end

			if #extraParts > 0 then
				hasExtra = true
				gearExtraText:SetText(table.concat(extraParts, "  "))
			else
				gearExtraText:SetText("")
			end

			-- Color based on issues
			if
				#gearAnalysis.missingEnchants > 0
				or #gearAnalysis.emptySockets > 0
				or gearAnalysis.lowQualityGemsCount > 0
			then
				gearText:SetTextColor(1, 0.6, 0.2, 1)
				gearExtraText:SetTextColor(1, 0.6, 0.2, 1)
			else
				gearText:SetTextColor(0.3, 1, 0.4, 1)
				gearExtraText:SetTextColor(0.3, 1, 0.4, 1)
			end
		else
			gearText:SetText("Загрузка...")
			gearExtraText:SetText("")
			gearText:SetTextColor(0.6, 0.6, 0.6, 1)
		end

		-- Talents info
		local talentAnalysis = Core.AnalyzePlayerTalents(playerName)
		local talentText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		talentText:SetPoint("TOPLEFT", 40, hasExtra and -68 or -52)
		talentText:SetFont("Fonts\\FRIZQT__.TTF", 10)

		if talentAnalysis.hasData then
			local specInfo = string.format("%s (%s)", talentAnalysis.specName, talentAnalysis.distribution)
			talentText:SetText(specInfo)
			talentText:SetTextColor(0.5, 0.8, 1, 1)
		else
			talentText:SetText("Загрузка...")
			talentText:SetTextColor(0.6, 0.6, 0.6, 1)
		end

		-- Professions info
		local profText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		profText:SetPoint("TOPLEFT", 190, -36)
		profText:SetFont("Fonts\\FRIZQT__.TTF", 10)

		local profText2 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		profText2:SetPoint("TOPLEFT", 190, -52)
		profText2:SetFont("Fonts\\FRIZQT__.TTF", 10)

		local profAnalysis = Core.AnalyzePlayerProfessions(playerName)
		if profAnalysis.hasData and profAnalysis.count > 0 then
			local profNames = {}
			for _, prof in ipairs(profAnalysis.professions) do
				table.insert(profNames, string.format("%s (%d)", prof.name, prof.rank))
			end

			if #profNames > 2 then
				profText:SetText(table.concat({ profNames[1], profNames[2] }, " | "))
				profText:SetTextColor(0.9, 0.7, 0.3, 1)

				local remaining = {}
				for i = 3, #profNames do
					table.insert(remaining, profNames[i])
				end
				profText2:SetText(table.concat(remaining, " | "))
				profText2:SetTextColor(0.9, 0.7, 0.3, 1)
			else
				profText:SetText(table.concat(profNames, " | "))
				profText:SetTextColor(0.9, 0.7, 0.3, 1)
				profText2:SetText("")
			end
		else
			profText:SetText("Нет профессий")
			profText:SetTextColor(0.5, 0.5, 0.5, 1)
			profText2:SetText("")
		end

		-- Buttons
		local function CreateModernButton(parent, width, height, text, color, xPos, yPos)
			local btn = CreateFrame("Button", nil, parent)
			btn:SetSize(width, height)
			btn:SetPoint("TOPRIGHT", xPos, yPos)

			local bg = btn:CreateTexture(nil, "BACKGROUND")
			bg:SetAllPoints()
			bg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
			bg:SetVertexColor(color.r, color.g, color.b, 0.8)
			btn.bg = bg

			local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
			btnText:SetPoint("CENTER")
			btnText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
			btnText:SetText(text)

			btn:SetScript("OnEnter", function(self)
				self.bg:SetVertexColor(color.r * 1.3, color.g * 1.3, color.b * 1.3, 1)
				self:SetScale(1.05)
			end)
			btn:SetScript("OnLeave", function(self)
				self.bg:SetVertexColor(color.r, color.g, color.b, 0.8)
				self:SetScale(1.0)
			end)

			return btn
		end

		-- Inspect button
		local inspectButton = CreateModernButton(frame, 75, 24, "Осмотр", { r = 0.2, g = 0.5, b = 0.8 }, -10, -3)
		inspectButton:SetScript("OnClick", function()
			if RC.UI.Inspect and RC.UI.Inspect.Show then
				local playerData = Core.playerData[playerName]
				if not playerData or not playerData.items then
					print(
						"|cFFFF0000RaiderCheck:|r Нет данных для "
							.. playerName
							.. ". Нажмите 'Обновить'."
					)
				else
					RC.UI.Inspect.Show(playerName)
				end
			end
		end)

		-- Talents button
		local talentsButton =
			CreateModernButton(frame, 75, 24, "Таланты", { r = 0.6, g = 0.3, b = 0.8 }, -10, -31)
		talentsButton:SetScript("OnClick", function()
			if RC.UI.TalentsInspect and RC.UI.TalentsInspect.Show then
				RC.UI.TalentsInspect.Show(playerName)
			end
		end)

		-- Details button
		local detailsButton = CreateModernButton(frame, 75, 24, "Детали", { r = 0.2, g = 0.7, b = 0.4 }, -10, -59)
		detailsButton:SetScript("OnClick", function()
			GUI.ShowPlayerDetails(playerName)
		end)
	else
		-- No addon
		local noAddonText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		noAddonText:SetPoint("TOPLEFT", 40, -50)
		noAddonText:SetText("Аддон не установлен - данные недоступны")
		noAddonText:SetTextColor(0.8, 0.4, 0.4, 1)
	end

	return frame
end

-- ============================================
-- PLAYER DETAILS
-- ============================================

function GUI.ShowPlayerDetails(playerName)
	local playerData = Core.playerData[playerName]
	if not playerData then
		print("|cFF00FF00RaiderCheck:|r Данные для " .. playerName .. " еще не получены.")
		return
	end

	print("|cFF00FF00=== Детали для " .. playerName .. " ===|r")

	-- Talents
	local talentAnalysis = Core.AnalyzePlayerTalents(playerName)
	if talentAnalysis.hasData then
		print("|cFF00FF00Специализация:|r " .. talentAnalysis.specName)
		print("|cFF00FF00Распределение:|r " .. talentAnalysis.distribution)
		print("|cFF00FF00Всего очков:|r " .. talentAnalysis.totalPoints)
	end

	-- Gear
	local gearAnalysis = Core.AnalyzePlayerGear(playerName)
	if gearAnalysis.hasData then
		print(
			"|cFF00FF00Зачаровано слотов:|r "
				.. gearAnalysis.enchantCount
				.. "/"
				.. gearAnalysis.totalSlots
		)

		if #gearAnalysis.missingEnchants > 0 then
			print("|cFFFF0000Отсутствуют зачарования:|r")
			for _, enchant in ipairs(gearAnalysis.missingEnchants) do
				print("  - " .. enchant.slotName)
			end
		end

		if #gearAnalysis.emptySockets > 0 then
			print("|cFFFFAA00Пустые сокеты:|r")
			for _, socket in ipairs(gearAnalysis.emptySockets) do
				if socket.isBeltWithoutBuckle then
					print("  - " .. socket.slotName .. ": Нет поясной пряжки")
				else
					print("  - " .. socket.slotName .. ": " .. socket.emptyCount .. " пустых")
				end
			end
		end

		if gearAnalysis.lowQualityGemsCount and gearAnalysis.lowQualityGemsCount > 0 then
			print("|cFFFF0000Устаревшие камни:|r " .. gearAnalysis.lowQualityGemsCount)
			for _, gemInfo in ipairs(gearAnalysis.lowQualityGems) do
				local gemTypes = {}
				for _, gem in ipairs(gemInfo.gems) do
					table.insert(gemTypes, gem.type)
				end
				print("  - " .. gemInfo.slotName .. ": " .. table.concat(gemTypes, ", "))
			end
		end
	end

	-- Professions
	local profAnalysis = Core.AnalyzePlayerProfessions(playerName)
	if profAnalysis.hasData and profAnalysis.count > 0 then
		print("|cFF00FF00Профессии:|r")
		for _, prof in ipairs(profAnalysis.professions) do
			local color = (prof.rank >= prof.maxRank) and "|cFF00FF00" or "|cFFFFAA00"
			print(string.format("  %s%s|r: %d/%d", color, prof.name, prof.rank, prof.maxRank))
		end
	end
end

-- Export
RaiderCheck.UI = RaiderCheck.UI or {}
RaiderCheck.UI.GUI = GUI
