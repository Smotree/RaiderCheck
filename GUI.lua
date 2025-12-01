-- RaiderCheck GUI Module
-- Модуль для отображения интерфейса

local GUI = {}

-- Создание главного окна
function RaiderCheck:CreateGUI()
	-- Создаем основной фрейм
	local frame = CreateFrame("Frame", "RaiderCheckFrame", UIParent)
	frame:SetSize(600, 400)
	frame:SetPoint("CENTER")
	frame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = { left = 11, right = 12, top = 12, bottom = 11 },
	})
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:Hide()

	self.frame = frame

	-- Заголовок
	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOP", 0, -15)
	title:SetText("RaiderCheck - Проверка группы")

	-- Кнопка закрытия
	local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	closeButton:SetPoint("TOPRIGHT", -5, -5)

	-- Кнопка обновления
	local refreshButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	refreshButton:SetSize(120, 25)
	refreshButton:SetPoint("TOPLEFT", 15, -40)
	refreshButton:SetText("Обновить")
	refreshButton:SetScript("OnClick", function()
		self:ScanGroup()
	end)

	-- Scroll Frame для списка игроков
	local scrollFrame = CreateFrame("ScrollFrame", "RaiderCheckScrollFrame", frame, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", 15, -70)
	scrollFrame:SetPoint("BOTTOMRIGHT", -30, 15)

	-- Контейнер для содержимого
	local scrollChild = CreateFrame("Frame", nil, scrollFrame)
	scrollChild:SetSize(550, 1)
	scrollFrame:SetScrollChild(scrollChild)

	self.scrollChild = scrollChild
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
		yOffset = yOffset - 60
	end

	-- Обновляем размер scrollChild
	self.scrollChild:SetHeight(math.abs(yOffset))
end

-- Создание фрейма для отображения информации об игроке
function RaiderCheck:CreatePlayerFrame(playerName, index)
	local frame = CreateFrame("Frame", nil, self.scrollChild)
	frame:SetSize(530, 50)
	frame:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 16,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	frame:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
	frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

	-- Имя игрока
	local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	nameText:SetPoint("TOPLEFT", 10, -8)

	-- Получаем класс игрока для цвета
	local className = self:GetPlayerClass(playerName)
	local classColor = RAID_CLASS_COLORS[className] or { r = 1, g = 1, b = 1 }
	nameText:SetTextColor(classColor.r, classColor.g, classColor.b)
	nameText:SetText(playerName)

	-- Статус аддона
	local hasAddon = self.players[playerName] == true
	local addonText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	addonText:SetPoint("TOPLEFT", 10, -28)

	if hasAddon then
		addonText:SetTextColor(0, 1, 0)
		addonText:SetText("✓ Аддон установлен")

		-- Информация о снаряжении
		local gearAnalysis = self:AnalyzePlayerGear(playerName)
		local gearText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		gearText:SetPoint("TOPLEFT", 200, -8)

		if gearAnalysis.hasData then
			local enchantRatio = string.format("%d/%d", gearAnalysis.enchantCount, gearAnalysis.totalSlots)
			local socketsInfo = ""
			if gearAnalysis.emptySockets and #gearAnalysis.emptySockets > 0 then
				local totalEmpty = 0
				for _, socket in ipairs(gearAnalysis.emptySockets) do
					totalEmpty = totalEmpty + socket.emptyCount
				end
				socketsInfo = string.format(" | Пустых сокетов: %d", totalEmpty)
			end
			gearText:SetText("Зачаровано: " .. enchantRatio .. socketsInfo)

			if #gearAnalysis.missingEnchants > 0 or (#gearAnalysis.emptySockets > 0) then
				gearText:SetTextColor(1, 0.5, 0)
			else
				gearText:SetTextColor(0, 1, 0)
			end
		else
			gearText:SetText("Загрузка...")
			gearText:SetTextColor(0.7, 0.7, 0.7)
		end

		-- Информация о талантах
		local talentAnalysis = self:AnalyzePlayerTalents(playerName)
		local talentText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		talentText:SetPoint("TOPLEFT", 200, -24)

		if talentAnalysis.hasData then
			local specInfo = string.format("%s (%s)", talentAnalysis.specName, talentAnalysis.distribution)
			talentText:SetText("Спек: " .. specInfo)
			talentText:SetTextColor(0.5, 0.8, 1)
		else
			talentText:SetText("Загрузка...")
			talentText:SetTextColor(0.7, 0.7, 0.7)
		end

		-- Информация о профессиях
		local profText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		profText:SetPoint("TOPLEFT", 200, -38)

		if self.AnalyzePlayerProfessions then
			local profAnalysis = self:AnalyzePlayerProfessions(playerName)
			if profAnalysis.hasData and profAnalysis.count > 0 then
				local profNames = {}
				for _, prof in ipairs(profAnalysis.professions) do
					table.insert(profNames, prof.name)
				end
				profText:SetText("Проф: " .. table.concat(profNames, ", "))
				profText:SetTextColor(0.8, 0.8, 0.5)
			else
				profText:SetText("Проф: нет")
				profText:SetTextColor(0.5, 0.5, 0.5)
			end
		else
			profText:SetText("Проф: недоступно")
			profText:SetTextColor(0.5, 0.5, 0.5)
		end

		-- Кнопка осмотра
		local inspectButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		inspectButton:SetSize(80, 20)
		inspectButton:SetPoint("TOPRIGHT", -95, -15)
		inspectButton:SetText("Осмотреть")
		inspectButton:SetScript("OnClick", function()
			if RaiderCheck.ShowInspectFrame then
				-- Проверяем наличие данных
				local playerData = RaiderCheck.playerData[playerName]
				if not playerData or not playerData.items then
					print(
						"|cFFFF0000RaiderCheck:|r Нет данных для "
							.. playerName
							.. ". Нажмите 'Обновить' для запроса данных."
					)
				else
					RaiderCheck:ShowInspectFrame(playerName)
				end
			else
				print("|cFFFF0000RaiderCheck:|r Функция осмотра недоступна")
			end
		end)

		-- Кнопка детальной информации
		local detailsButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		detailsButton:SetSize(80, 20)
		detailsButton:SetPoint("TOPRIGHT", -10, -15)
		detailsButton:SetText("Детали")
		detailsButton:SetScript("OnClick", function()
			RaiderCheck:ShowPlayerDetails(playerName)
		end)
	else
		addonText:SetTextColor(1, 0, 0)
		addonText:SetText("✗ Аддон не установлен")
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
	end

	print("|cFF00FF00========================|r")
end

-- Получить список игроков в группе
function RaiderCheck:GetGroupPlayers()
	local players = {}

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
		local playerName = UnitName("player")
		if playerName then
			table.insert(players, playerName)
		end

		-- Добавляем членов группы (в группе numMembers не включает вас)
		for i = 1, numMembers do
			local name = UnitName("party" .. i)
			if name then
				table.insert(players, name)
			end
		end
	end

	return players
end

-- Сообщение об успешной загрузке модуля
print("|cFF00FF00RaiderCheck GUI:|r Модуль загружен успешно")
