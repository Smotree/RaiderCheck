-- RaiderCheck Error Report GUI
-- Окно для отображения ошибок неизвестных гемов

-- Создание окна отчета об ошибках
function RaiderCheck:CreateErrorReportWindow()
	if self.errorReportFrame then
		return -- Окно уже создано
	end

	local frame = CreateFrame("Frame", "RaiderCheckErrorReportFrame", UIParent)
	frame:SetSize(650, 450)
	frame:SetPoint("CENTER")

	-- Современный фон
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

	self.errorReportFrame = frame

	-- Градиентный заголовок
	local header = frame:CreateTexture(nil, "ARTWORK")
	header:SetPoint("TOPLEFT", 4, -4)
	header:SetPoint("TOPRIGHT", -4, -4)
	header:SetHeight(50)
	header:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	header:SetGradientAlpha("VERTICAL", 0.6, 0.1, 0.1, 0.8, 0.3, 0.05, 0.05, 0.8)

	-- Разделитель
	local headerLine = frame:CreateTexture(nil, "OVERLAY")
	headerLine:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 0)
	headerLine:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, 0)
	headerLine:SetHeight(2)
	headerLine:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	headerLine:SetVertexColor(1, 0.3, 0.3, 0.8)

	-- Заголовок
	local title = frame:CreateFontString(nil, "OVERLAY")
	title:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
	title:SetPoint("TOPLEFT", 15, -18)
	title:SetText("Ошибка обработки самоцвета")
	title:SetTextColor(1, 0.3, 0.3, 1)

	-- Подзаголовок
	local subtitle = frame:CreateFontString(nil, "OVERLAY")
	subtitle:SetFont("Fonts\\FRIZQT__.TTF", 10)
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
	subtitle:SetText("Найдены неизвестные самоцветы")
	subtitle:SetTextColor(0.7, 0.7, 0.7, 1)

	-- Современная кнопка закрытия
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

	-- Описание
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

	-- ScrollFrame для текста с ошибками
	local scrollFrame = CreateFrame("ScrollFrame", "RaiderCheckErrorScrollFrame", frame, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", 15, -80)
	scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)

	-- EditBox для копирования текста
	local editBox = CreateFrame("EditBox", nil, scrollFrame)
	editBox:SetMultiLine(true)
	editBox:SetAutoFocus(false)
	editBox:SetFontObject(GameFontNormal)
	editBox:SetWidth(540)
	editBox:SetMaxLetters(0)
	editBox:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	editBox:SetScript("OnEditFocusGained", function(self)
		self:HighlightText()
	end)

	scrollFrame:SetScrollChild(editBox)
	self.errorEditBox = editBox

	-- Кнопка "Выделить всё"
	local selectAllButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	selectAllButton:SetSize(120, 25)
	selectAllButton:SetPoint("BOTTOMLEFT", 15, 15)
	selectAllButton:SetText("Выделить всё")
	selectAllButton:SetScript("OnClick", function()
		editBox:SetFocus()
		editBox:HighlightText()
	end)

	-- Кнопка "Очистить лог"
	local clearButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	clearButton:SetSize(120, 25)
	clearButton:SetPoint("BOTTOM", 0, 15)
	clearButton:SetText("Очистить лог")
	clearButton:SetScript("OnClick", function()
		RaiderCheck_ClearUnknownGems()
		frame:Hide()
	end)

	-- Кнопка "Закрыть"
	local closeBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	closeBtn:SetSize(120, 25)
	closeBtn:SetPoint("BOTTOMRIGHT", -15, 15)
	closeBtn:SetText("Закрыть")
	closeBtn:SetScript("OnClick", function()
		frame:Hide()
	end)
end

-- Получить информацию о геме через tooltip
local function GetGemStats(itemID)
	-- Получаем базовую информацию из GetItemInfo
	local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType = GetItemInfo(itemID)

	-- Создаем временный tooltip для чтения статов
	local tt = CreateFrame("GameTooltip", "RaiderCheckGemScanTooltip", nil, "GameTooltipTemplate")
	tt:SetOwner(UIParent, "ANCHOR_NONE")
	tt:SetHyperlink("item:" .. itemID)

	local stats = ""

	-- Читаем строки tooltip для поиска статов
	for i = 1, tt:NumLines() do
		local line = _G["RaiderCheckGemScanTooltipTextLeft" .. i]
		if line then
			local text = line:GetText()
			if text then
				-- Ищем строку со статами (начинается с + или содержит "к ")
				if text:find("^%+") or text:find("%+%d+") then
					if not stats or stats == "" then
						stats = text
					end
				end
			end
		end
	end

	tt:Hide()
	return stats, itemLevel or 0
end

-- Показать окно с ошибками
function RaiderCheck:ShowErrorReport()
	if not self.errorReportFrame then
		self:CreateErrorReportWindow()
	end

	if not RaiderCheck_UnknownGems or #RaiderCheck_UnknownGems == 0 then
		return -- Нет ошибок для показа
	end

	-- Формируем текст отчета с автоматическим получением статов
	local reportText = "=== RaiderCheck Error Report ===\n\n"
	reportText = reportText
		.. string.format("Найдено неизвестных самоцветов: %d\n\n", #RaiderCheck_UnknownGems)
	reportText = reportText .. "Добавьте эти строки в GemsEnchantMapping.lua:\n\n"

	for i, gem in ipairs(RaiderCheck_UnknownGems) do
		-- Получаем информацию о геме
		local stats, itemLevel = GetGemStats(gem.gemID)
		local gemName = gem.itemLink and gem.itemLink:match("%[(.+)%]") or "Неизвестный гем"

		-- Определяем тип гема по item level и названию
		local gemType = "БК"

		-- Если в названии есть "черный бриллиант" - это точно Донатные
		if gemName:find("черный бриллиант") or gemName:find("черного бриллианта") then
			gemType = "Донатные"
		elseif itemLevel >= 200 then
			gemType = "Донатные"
		elseif itemLevel >= 90 then
			gemType = "НРБК"
		elseif itemLevel >= 88 then
			gemType = "РБК+"
		elseif itemLevel >= 80 then
			gemType = "ЛК"
		else
			gemType = "БК"
		end

		-- Формируем строку для добавления в базу
		reportText = reportText
			.. string.format(
				'\t[%d] = "%s", -- %s (%s)\n',
				gem.gemID,
				gemType,
				gemName,
				stats ~= "" and stats or "статы не определены"
			)
	end

	reportText = reportText .. "\n=== Дополнительная информация ===\n\n"

	for i, gem in ipairs(RaiderCheck_UnknownGems) do
		local stats, itemLevel = GetGemStats(gem.gemID)
		reportText = reportText .. string.format("--- Гем #%d ---\n", i)
		reportText = reportText .. string.format("Item ID: %d\n", gem.gemID)
		reportText = reportText .. string.format("Item Level: %d\n", itemLevel)
		reportText = reportText
			.. string.format("Статы: %s\n", stats ~= "" and stats or "не определены")
		reportText = reportText .. string.format("Игрок: %s | Слот: %d\n", gem.player, gem.slot)
		reportText = reportText .. "\n"
	end

	reportText = reportText .. "=== Конец отчета ===\n"

	-- Устанавливаем текст в EditBox
	self.errorEditBox:SetText(reportText)
	self.errorEditBox:SetCursorPosition(0)

	-- Показываем окно
	self.errorReportFrame:Show()
end

-- Автоматическое открытие окна при обнаружении новой ошибки
local function OnUnknownGemDetected()
	if RaiderCheck and RaiderCheck.ShowErrorReport then
		-- Открываем окно автоматически только если оно еще не открыто
		if not RaiderCheck.errorReportFrame or not RaiderCheck.errorReportFrame:IsShown() then
			RaiderCheck:ShowErrorReport()
		end
	end
end

-- Регистрируем обработчик для автоматического открытия
if not RaiderCheck_ErrorReportHooked then
	RaiderCheck_ErrorReportHooked = true
	-- Хук будет срабатывать при добавлении ошибки в Items.lua
end

print("|cFF00FF00RaiderCheck ErrorReportGUI:|r Модуль загружен успешно")
