-- RaiderCheck GUI Module
-- Модуль для отображения интерфейса

local GUI = {}

-- Создание главного окна
function RaiderCheck:CreateGUI()
	-- Создаем основной фрейм
	local frame = CreateFrame("Frame", "RaiderCheckFrame", UIParent)
	frame:SetSize(620, 480)
	frame:SetPoint("TOP")
	frame:SetFrameStrata("HIGH")

	-- Основной фон с градиентом
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

	self.frame = frame

	-- Шапка окна (градиентная полоса)
	local header = frame:CreateTexture(nil, "ARTWORK")
	header:SetPoint("TOPLEFT", 4, -4)
	header:SetPoint("TOPRIGHT", -4, -4)
	header:SetHeight(50)
	header:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	header:SetGradientAlpha("VERTICAL", 0.1, 0.3, 0.5, 0.8, 0.05, 0.15, 0.25, 0.8)

	-- Линия разделителя под шапкой
	local headerLine = frame:CreateTexture(nil, "OVERLAY")
	headerLine:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 0)
	headerLine:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, 0)
	headerLine:SetHeight(2)
	headerLine:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	headerLine:SetVertexColor(0.3, 0.7, 1, 0.8)

	-- Заголовок
	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 15, -18)
	title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
	title:SetText("RaiderCheck")
	title:SetTextColor(0.3, 0.8, 1, 1)

	-- Подзаголовок
	local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
	subtitle:SetFont("Fonts\\FRIZQT__.TTF", 11)
	subtitle:SetText("Проверка готовности группы")
	subtitle:SetTextColor(0.7, 0.7, 0.7, 1)

	-- Кнопка закрытия (стильная)
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

	-- Кнопка обновления (современная)
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
		self:ScanGroup()
		-- Анимация нажатия (WoW 3.3.5 compatible - без C_Timer)
		refreshButton:SetScale(0.95)
		local elapsed = 0
		local animFrame = CreateFrame("Frame")
		animFrame:SetScript("OnUpdate", function(self, delta)
			elapsed = elapsed + delta
			if elapsed >= 0.1 then
				refreshButton:SetScale(1.0)
				self:SetScript("OnUpdate", nil)
			end
		end)
	end)

	-- Создание панели настроек камней
	self:CreateGemSettingsPanel(frame)

	-- Scroll Frame для списка игроков (с отступом для панели настроек)
	local scrollFrame = CreateFrame("ScrollFrame", "RaiderCheckScrollFrame", frame, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", 12, -165) -- Увеличен отступ для новой панели (65 + 85 + 15)
	scrollFrame:SetPoint("BOTTOMRIGHT", -30, 12)

	-- Фон для области прокрутки
	local scrollBg = scrollFrame:CreateTexture(nil, "BACKGROUND")
	scrollBg:SetAllPoints()
	scrollBg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	scrollBg:SetVertexColor(0.02, 0.02, 0.05, 0.5)

	-- Контейнер для содержимого
	local scrollChild = CreateFrame("Frame", nil, scrollFrame)
	scrollChild:SetSize(570, 1)
	scrollFrame:SetScrollChild(scrollChild)

	self.scrollChild = scrollChild
	self.scrollFrame = scrollFrame
	self.playerFrames = {}
end

-- Переключение видимости окна
function RaiderCheck:ToggleGUI()
	if self.frame then
		if self.frame:IsShown() then
			self.frame:Hide()
		else
			self.frame:Show()
			self:UpdateGUI()
		end
	end
end

-- Обновление GUI
function RaiderCheck:UpdateGUI()
	if not self.frame or not self.frame:IsShown() then
		return
	end

	-- Обновляем свои данные
	if self.UpdateOwnData then
		self:UpdateOwnData()
	end

	-- Очистка старых фреймов
	for _, frame in ipairs(self.playerFrames) do
		frame:Hide()
		frame:SetParent(nil)
	end
	self.playerFrames = {}

	-- Получаем список игроков в группе
	local players = self:GetGroupPlayers()

	if #players == 0 then
		-- Показываем сообщение, что нет группы
		local noGroupText = self.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		noGroupText:SetPoint("TOP", 0, -10)
		noGroupText:SetText("Вы не в группе или рейде")
		table.insert(self.playerFrames, noGroupText)
		return
	end

	-- Создаем фреймы для каждого игрока
	local yOffset = -10
	for i, playerName in ipairs(players) do
		local playerFrame = self:CreatePlayerFrame(playerName, i)
		playerFrame:SetPoint("TOPLEFT", 5, yOffset)
		playerFrame:SetParent(self.scrollChild)
		playerFrame:Show()

		table.insert(self.playerFrames, playerFrame)
		yOffset = yOffset - 98 -- Новый размер карточки (90 + отступ 8)
	end

	-- Обновляем размер scrollChild
	self.scrollChild:SetHeight(math.abs(yOffset))
end

-- Создание фрейма для отображения информации об игроке
function RaiderCheck:CreatePlayerFrame(playerName, index)
	local frame = CreateFrame("Frame", nil, self.scrollChild)
	frame:SetSize(580, 90)

	-- Получаем класс игрока для градиента
	local className = self:GetPlayerClass(playerName)
	local classColor
	if not className then
		classColor = { r = 0.3, g = 0.3, b = 0.3 }
	else
		classColor = RAID_CLASS_COLORS[className] or { r = 0.3, g = 0.3, b = 0.3 }
	end

	-- Основной фон с закругленными краями (эмуляция через backdrop)
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

	-- Градиентная полоска по классу слева
	local classStripe = frame:CreateTexture(nil, "ARTWORK")
	classStripe:SetPoint("TOPLEFT", 3, -3)
	classStripe:SetPoint("BOTTOMLEFT", 3, 3)
	classStripe:SetWidth(4)
	classStripe:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	classStripe:SetVertexColor(classColor.r, classColor.g, classColor.b, 1)

	-- Имя игрока (больше и ярче)
	local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	nameText:SetPoint("TOPLEFT", 15, -12)
	nameText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
	nameText:SetTextColor(classColor.r * 1.2, classColor.g * 1.2, classColor.b * 1.2, 1)
	nameText:SetText(playerName)

	-- Проверка наличия аддона
	local hasAddon = self.players[playerName] == true or self.playerData[playerName] ~= nil

	-- Иконка статуса аддона
	local statusIcon = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
	statusIcon:SetPoint("TOPLEFT", 15, -34)
	statusIcon:SetFont("Fonts\\FRIZQT__.TTF", 16)

	if hasAddon then
		statusIcon:SetText("+")
		statusIcon:SetTextColor(0.2, 1, 0.3, 1)
	else
		statusIcon:SetText("-")
		statusIcon:SetTextColor(1, 0.3, 0.2, 1)
	end

	if hasAddon then
		-- Информация о снаряжении (компактный формат с иконками)
		local gearAnalysis = self:AnalyzePlayerGear(playerName)
		local gearText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		gearText:SetPoint("TOPLEFT", 40, -36)
		gearText:SetFont("Fonts\\FRIZQT__.TTF", 10)

		if gearAnalysis.hasData then
			local enchantRatio = string.format("%d/%d", gearAnalysis.enchantCount, gearAnalysis.totalSlots)
			local parts = { "Зачарованно: " .. enchantRatio }

			-- Пустые сокеты
			if gearAnalysis.emptySockets and #gearAnalysis.emptySockets > 0 then
				local totalEmpty = 0
				for _, socket in ipairs(gearAnalysis.emptySockets) do
					totalEmpty = totalEmpty + socket.emptyCount
				end
				table.insert(parts, "Пусто: " .. totalEmpty)
			end

			-- Устаревшие камни
			local oldGems = (gearAnalysis.bcGemsCount or 0)
				+ (gearAnalysis.wotlkGemsCount or 0)
				+ (gearAnalysis.rbcGemsCount or 0)
			if oldGems > 0 then
				table.insert(parts, "Старые: " .. oldGems)
			end

			gearText:SetText(table.concat(parts, "  "))

			-- Цвет зависит от проблем
			if
				#gearAnalysis.missingEnchants > 0
				or (#gearAnalysis.emptySockets > 0)
				or (gearAnalysis.lowQualityGemsCount and gearAnalysis.lowQualityGemsCount > 0)
			then
				gearText:SetTextColor(1, 0.6, 0.2, 1)
			else
				gearText:SetTextColor(0.3, 1, 0.4, 1)
			end
		else
			gearText:SetText("Загрузка...")
			gearText:SetTextColor(0.6, 0.6, 0.6, 1)
		end

		-- Информация о талантах (компактный формат)
		local talentAnalysis = self:AnalyzePlayerTalents(playerName)
		local talentText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		talentText:SetPoint("TOPLEFT", 40, -54)
		talentText:SetFont("Fonts\\FRIZQT__.TTF", 10)

		if talentAnalysis.hasData then
			local specInfo = string.format("%s (%s)", talentAnalysis.specName, talentAnalysis.distribution)
			talentText:SetText(specInfo)
			talentText:SetTextColor(0.5, 0.8, 1, 1)
		else
			talentText:SetText("Загрузка...")
			talentText:SetTextColor(0.6, 0.6, 0.6, 1)
		end

		-- Информация о профессиях (компактный формат)
		local profText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		profText:SetPoint("TOPLEFT", 170, -36)
		profText:SetFont("Fonts\\FRIZQT__.TTF", 10)

		local profText2 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		profText2:SetPoint("TOPLEFT", 170, -54)
		profText2:SetFont("Fonts\\FRIZQT__.TTF", 10)

		if self.AnalyzePlayerProfessions then
			local profAnalysis = self:AnalyzePlayerProfessions(playerName)
			if profAnalysis.hasData and profAnalysis.count > 0 then
				local profNames = {}
				for _, prof in ipairs(profAnalysis.professions) do
					-- Добавляем название профессии с рангом
					local profStr = string.format("%s (%d)", prof.name, prof.rank)
					table.insert(profNames, profStr)
				end

				-- Если профессий больше 2, разбиваем на две строки
				if #profNames > 2 then
					profText:SetText(table.concat({ profNames[1], profNames[2] }, " | "))
					profText:SetTextColor(0.9, 0.7, 0.3, 1)

					local remainingProfs = {}
					for i = 3, #profNames do
						table.insert(remainingProfs, profNames[i])
					end
					profText2:SetText(table.concat(remainingProfs, " | "))
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
		end

		-- === СОВРЕМЕННЫЕ КНОПКИ С HOVER-ЭФФЕКТАМИ ===

		-- Функция создания красивой кнопки
		local function CreateModernButton(parent, width, height, text, color, xPos, yPos)
			local btn = CreateFrame("Button", nil, parent)
			btn:SetSize(width, height)
			btn:SetPoint("TOPRIGHT", xPos, yPos)

			local bg = btn:CreateTexture(nil, "BACKGROUND")
			bg:SetAllPoints()
			bg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
			bg:SetVertexColor(color.r, color.g, color.b, 0.8)
			btn.bg = bg
			btn.originalColor = color

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

		-- Кнопка детального осмотра (синяя)
		local inspectButton = CreateModernButton(frame, 75, 24, "Осмотр", { r = 0.2, g = 0.5, b = 0.8 }, -10, -3)
		inspectButton:SetScript("OnClick", function()
			if RaiderCheck.ShowInspectFrame then
				local playerData = RaiderCheck.playerData[playerName]
				if not playerData or not playerData.items then
					print(
						"|cFFFF0000RaiderCheck:|r Нет данных для "
							.. playerName
							.. ". Нажмите 'Обновить'."
					)
				else
					RaiderCheck:ShowInspectFrame(playerName)
				end
			end
		end)

		-- Кнопка талантов (фиолетовая)
		local talentsButton =
			CreateModernButton(frame, 75, 24, "Таланты", { r = 0.6, g = 0.3, b = 0.8 }, -10, -31)
		talentsButton:SetScript("OnClick", function()
			RaiderCheck:ShowTalentsInspect(playerName)
		end)

		-- Кнопка деталей (зелёная)
		local detailsButton = CreateModernButton(frame, 75, 24, "Детали", { r = 0.2, g = 0.7, b = 0.4 }, -10, -59)
		detailsButton:SetScript("OnClick", function()
			RaiderCheck:ShowPlayerDetails(playerName)
		end)
	else
		-- Нет аддона - показываем текст
		local noAddonText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		noAddonText:SetPoint("TOPLEFT", 40, -50)
		noAddonText:SetText("Аддон не установлен - данные недоступны")
		noAddonText:SetTextColor(0.8, 0.4, 0.4, 1)
	end

	return frame
end

-- Показать детальную информацию об игроке
function RaiderCheck:ShowPlayerDetails(playerName)
	local playerData = self.playerData[playerName]
	if not playerData then
		print("|cFF00FF00RaiderCheck:|r Данные для " .. playerName .. " еще не получены.")
		return
	end

	-- Создаем окно с детальной информацией
	print("|cFF00FF00=== Детали для " .. playerName .. " ===|r")

	-- Таланты
	local talentAnalysis = self:AnalyzePlayerTalents(playerName)
	if talentAnalysis.hasData then
		print("|cFF00FF00Специализация:|r " .. talentAnalysis.specName)
		print("|cFF00FF00Распределение:|r " .. talentAnalysis.distribution)
		print("|cFF00FF00Всего очков:|r " .. talentAnalysis.totalPoints)
	end

	-- Профессии
	if self.AnalyzePlayerProfessions then
		local profAnalysis = self:AnalyzePlayerProfessions(playerName)
		if profAnalysis.hasData and profAnalysis.count > 0 then
			print("|cFF00FF00Профессии:|r")
			for _, prof in ipairs(profAnalysis.professions) do
				local color = (prof.rank >= prof.maxRank) and "|cFF00FF00" or "|cFFFFAA00"
				print(string.format("  %s%s|r: %d/%d", color, prof.name, prof.rank, prof.maxRank))
			end
		else
			print("|cFF888888Профессии:|r нет данных")
		end
	end

	-- Снаряжение
	local gearAnalysis = self:AnalyzePlayerGear(playerName)
	if gearAnalysis.hasData then
		print(
			"|cFF00FF00Зачаровано слотов:|r "
				.. gearAnalysis.enchantCount
				.. "/"
				.. gearAnalysis.totalSlots
		)

		if #gearAnalysis.missingEnchants > 0 then
			print("|cFFFF0000Отсутствуют зачарования:|r")
			for _, slotName in ipairs(gearAnalysis.missingEnchants) do
				print("  - " .. slotName)
			end
		else
			print("|cFF00FF00Все слоты зачарованы!|r")
		end

		-- Проверка пустых сокетов
		if gearAnalysis.emptySockets and #gearAnalysis.emptySockets > 0 then
			print("|cFFFF8800Пустые сокеты:|r")
			for _, socketInfo in ipairs(gearAnalysis.emptySockets) do
				if socketInfo.itemLink then
					-- Выводим с игровой ссылкой на предмет
					print(
						string.format(
							"  - %s: %d/%d пустых",
							socketInfo.itemLink,
							socketInfo.emptyCount,
							socketInfo.totalSockets
						)
					)
				else
					print(
						string.format(
							"  - %s: %d/%d пустых",
							socketInfo.slotName,
							socketInfo.emptyCount,
							socketInfo.totalSockets
						)
					)
				end
			end
		end

		-- Проверка устаревших камней (новая система качества)
		if gearAnalysis.lowQualityGems and #gearAnalysis.lowQualityGems > 0 then
			print("|cFFFF0000Устаревшие камни:|r")
			for _, gemInfo in ipairs(gearAnalysis.lowQualityGems) do
				-- Подсчитываем камни по типам
				local gemTypeCounts = {}
				for _, gem in ipairs(gemInfo.gems) do
					gemTypeCounts[gem.type] = (gemTypeCounts[gem.type] or 0) + 1
				end

				-- Формируем строку с количеством камней каждого типа
				local gemCounts = {}
				for gemType, count in pairs(gemTypeCounts) do
					table.insert(gemCounts, string.format("%s: %d", gemType, count))
				end
				local countStr = table.concat(gemCounts, ", ")

				if gemInfo.itemLink then
					print(string.format("  - %s: %s", gemInfo.itemLink, countStr))
				else
					print(string.format("  - %s: %s", gemInfo.slotName, countStr))
				end
			end

			-- Выводим общее количество устаревших камней по типам
			local totalTypeCounts = {}
			for _, gemInfo in ipairs(gearAnalysis.lowQualityGems) do
				for _, gem in ipairs(gemInfo.gems) do
					totalTypeCounts[gem.type] = (totalTypeCounts[gem.type] or 0) + 1
				end
			end

			local totalCounts = {}
			for gemType, count in pairs(totalTypeCounts) do
				table.insert(totalCounts, string.format("%s: %d", gemType, count))
			end

			if #totalCounts > 0 then
				print(
					string.format(
						"|cFFFFAA00Всего устаревших камней: %s|r",
						table.concat(totalCounts, " | ")
					)
				)
			end
		end
	else
		print("|cFF888888Снаряжение:|r нет данных")
	end
	print("|cFF00FF00========================|r")
end

-- Получить список игроков в группе (отсортированный)
function RaiderCheck:GetGroupPlayers()
	local players = {}
	local myName = UnitName("player")

	-- В WoW 3.3.5 используем GetNumRaidMembers и GetNumPartyMembers
	local isInRaid = (GetNumRaidMembers() > 0)
	local numMembers = isInRaid and GetNumRaidMembers() or GetNumPartyMembers()

	if isInRaid then
		for i = 1, numMembers do
			local name, rank, subgroup, level, class, fileName, zone, online, isDead = GetRaidRosterInfo(i)
			if name then
				table.insert(players, name)
			end
		end
	else
		-- Добавляем себя
		if myName then
			table.insert(players, myName)
		end

		-- Добавляем членов группы (в группе numMembers не включает вас)
		for i = 1, numMembers do
			local name = UnitName("party" .. i)
			if name then
				table.insert(players, name)
			end
		end
	end

	-- Сортируем: 1) Сам игрок, 2) С аддоном, 3) Без аддона
	local sorted = {}
	local withAddon = {}
	local withoutAddon = {}

	for _, playerName in ipairs(players) do
		if playerName == myName then
			-- Основной игрок идет в начало
			table.insert(sorted, playerName)
		else
			local hasAddon = self.players[playerName] == true or self.playerData[playerName] ~= nil
			if hasAddon then
				table.insert(withAddon, playerName)
			else
				table.insert(withoutAddon, playerName)
			end
		end
	end

	-- Объединяем: основной игрок + с аддоном + без аддона
	for _, playerName in ipairs(withAddon) do
		table.insert(sorted, playerName)
	end
	for _, playerName in ipairs(withoutAddon) do
		table.insert(sorted, playerName)
	end

	return sorted
end

-- Создание панели настроек требуемого качества камней
function RaiderCheck:CreateGemSettingsPanel(parentFrame)
	-- Современная панель для настроек камней
	local settingsPanel = CreateFrame("Frame", nil, parentFrame)
	settingsPanel:SetPoint("TOPLEFT", 15, -65)
	settingsPanel:SetPoint("TOPRIGHT", -15, -65)
	settingsPanel:SetHeight(85)

	-- Темный фон с градиентом (без BackdropTemplate - WoW 3.3.5)
	settingsPanel:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	settingsPanel:SetBackdropColor(0.08, 0.08, 0.12, 0.8)
	settingsPanel:SetBackdropBorderColor(0.3, 0.4, 0.6, 0.8)

	-- Заголовок с иконкой
	local title = settingsPanel:CreateFontString(nil, "OVERLAY")
	title:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
	title:SetPoint("TOPLEFT", 12, -10)
	title:SetText("Требуемое качество камней:")
	title:SetTextColor(0.2, 0.8, 1.0)

	-- Подзаголовок (пояснение)
	local hint = settingsPanel:CreateFontString(nil, "OVERLAY")
	hint:SetFont("Fonts\\FRIZQT__.TTF", 9)
	hint:SetPoint("TOPLEFT", 12, -25)
	hint:SetText("Камни выше выбранного качества считаются приемлемыми")
	hint:SetTextColor(0.6, 0.6, 0.7)

	-- Радио-кнопки для выбора качества (современный вид)
	local gemTypes = { "БК", "ЛК", "РБК", "РБК+", "НРБК", "ННРБК", "Донатные" }
	local gemColors = {
		["БК"] = { 0.5, 0.5, 0.5 }, -- Серый
		["ЛК"] = { 0.3, 0.7, 0.3 }, -- Зеленый
		["РБК"] = { 0.3, 0.5, 0.9 }, -- Синий
		["РБК+"] = { 0.6, 0.3, 0.9 }, -- Фиолетовый
		["НРБК"] = { 0.9, 0.5, 0.2 }, -- Оранжевый
		["ННРБК"] = { 0.9, 0.3, 0.3 }, -- Красный
		["Донатные"] = { 1.0, 0.8, 0.0 }, -- Золотой
	}

	local checkboxes = {}
	local xOffset = 12

	for i, gemType in ipairs(gemTypes) do
		-- Контейнер для радио-кнопки
		local radioBtn = CreateFrame("Button", nil, settingsPanel)
		radioBtn:SetSize(18, 18)
		radioBtn:SetPoint("TOPLEFT", xOffset, -45)

		-- Фон кнопки
		local bg = radioBtn:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetTexture("Interface\\Buttons\\WHITE8X8")
		bg:SetVertexColor(0.1, 0.1, 0.15, 0.8)
		radioBtn.bg = bg

		-- Бордер кнопки
		local border = radioBtn:CreateTexture(nil, "BORDER")
		border:SetPoint("TOPLEFT", -1, 1)
		border:SetPoint("BOTTOMRIGHT", 1, -1)
		border:SetTexture("Interface\\Buttons\\WHITE8X8")
		border:SetVertexColor(0.3, 0.3, 0.4, 1)
		radioBtn.border = border

		-- Индикатор выбора
		local check = radioBtn:CreateTexture(nil, "ARTWORK")
		check:SetPoint("CENTER")
		check:SetSize(10, 10)
		local r, g, b = unpack(gemColors[gemType])
		check:SetTexture("Interface\\Buttons\\WHITE8X8")
		check:SetVertexColor(r, g, b, 1)
		check:Hide()
		radioBtn.check = check

		-- Текст кнопки с цветом качества
		local label = radioBtn:CreateFontString(nil, "OVERLAY")
		label:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
		label:SetPoint("LEFT", radioBtn, "RIGHT", 6, 0)
		label:SetText(gemType)
		label:SetTextColor(r, g, b)
		radioBtn.label = label

		-- Hover эффект
		radioBtn:SetScript("OnEnter", function(self)
			self.bg:SetVertexColor(0.15, 0.15, 0.2, 1)
			self.border:SetVertexColor(r * 1.3, g * 1.3, b * 1.3, 1)
		end)

		radioBtn:SetScript("OnLeave", function(self)
			self.bg:SetVertexColor(0.1, 0.1, 0.15, 0.8)
			self.border:SetVertexColor(0.3, 0.3, 0.4, 1)
		end)

		-- Обработчик клика
		radioBtn:SetScript("OnClick", function(self)
			-- Снимаем выбор с других кнопок
			for _, cb in pairs(checkboxes) do
				cb.check:Hide()
			end

			-- Показываем выбор на этой кнопке
			self.check:Show()

			-- Устанавливаем новое минимальное качество
			RaiderCheck:SetMinGemQuality(gemType)

			-- Обновляем GUI с новыми критериями
			RaiderCheck:UpdateGUI()
		end)

		checkboxes[gemType] = radioBtn

		-- Расчет следующей позиции
		xOffset = xOffset + 78
	end

	-- Сохраняем ссылки для обновления
	self.gemCheckboxes = checkboxes

	self:UpdateGemSettingsPanel()
end

-- Обновление состояния панели настроек камней
function RaiderCheck:UpdateGemSettingsPanel()
	if not self.gemCheckboxes then
		return
	end

	-- Инициализируем настройки если нужно
	if not self.gemSettings then
		self:InitGemSettings()
	end

	local currentQuality = self:GetMinGemQuality()

	-- Обновляем радио-кнопки - только одна показывает индикатор
	for gemType, radioBtn in pairs(self.gemCheckboxes) do
		if gemType == currentQuality then
			radioBtn.check:Show()
		else
			radioBtn.check:Hide()
		end
	end
end

-- Сообщение об успешной загрузке модуля
print("|cFF00FF00RaiderCheck GUI:|r Модуль загружен успешно")
