-- RaiderCheck Core
RaiderCheck = {}

local ADDON_PREFIX = "RaiderCheck"
local VERSION = "1.1.0"

-- Типы сообщений
local MSG_PING = "PING" -- Проверка наличия аддона
local MSG_PONG = "PONG" -- Ответ на проверку
local MSG_REQUEST = "REQUEST" -- Запрос данных
local MSG_ITEMS1 = "ITEMS1" -- Отправка данных о предметах (часть 1)
local MSG_ITEMS2 = "ITEMS2" -- Отправка данных о предметах (часть 2)
local MSG_ITEMS3 = "ITEMS3" -- Отправка данных о предметах (часть 3)
local MSG_TALENTS = "TALENTS" -- Отправка данных о талантах
local MSG_PROFESSIONS = "PROFESSIONS" -- Отправка данных о профессиях

-- База данных игроков с аддоном
RaiderCheck.players = {} -- true или тип клиента ("RC", "WA")
RaiderCheck.playerData = {}
RaiderCheck.eventFrame = nil

-- Кеш данных для отслеживания изменений
-- Структура: ownDataCache = {itemsHash, talentsHash, professionsHash, timestamp}
RaiderCheck.ownDataCache = {
	itemsHash = nil,
	talentsHash = nil,
	professionsHash = nil,
	timestamp = 0,
	changeDetected = false,
}
function RaiderCheck:OnInitialize()
	-- Инициализация базы данных
	self.db = RaiderCheckDB or {}
	RaiderCheckDB = self.db

	-- Инициализация настроек камней (если модуль загружен)
	if self.InitGemSettings then
		self:InitGemSettings()
	end

	-- Создание фрейма для событий
	self.eventFrame = CreateFrame("Frame")
	self.eventFrame:SetScript("OnEvent", function(_, event, ...)
		if self[event] then
			self[event](self, ...)
		end
	end)

	-- Регистрация префикса для коммуникации (опционально для WoW 3.3.5)
	-- В некоторых версиях эта функция не требуется
	if RegisterAddonPrefix then
		pcall(RegisterAddonPrefix, ADDON_PREFIX)
	end

	-- Создание GUI
	if self.CreateGUI then
		self:CreateGUI()
	end

	print(
		"|cFF00FF00RaiderCheck|r v"
			.. VERSION
			.. " загружен. Используйте /rc для открытия окна."
	)
end

function RaiderCheck:OnEnable()
	-- Добавляем себя в список игроков с аддоном
	local playerName = UnitName("player")
	if playerName then
		self.players[playerName] = true
		-- Сохраняем свои данные при входе в мир
		self:UpdateOwnData()
	end

	-- Регистрация событий
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("CHAT_MSG_ADDON")
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED") -- Для отслеживания смены экипировки
	self:RegisterEvent("PLAYER_TALENT_UPDATE") -- Для отслеживания смены спека

	-- Slash команды
	SLASH_RAIDERCHECK1 = "/rc"
	SLASH_RAIDERCHECK2 = "/raidercheck"
	SlashCmdList["RAIDERCHECK"] = function(msg)
		self:HandleSlashCommand(msg)
	end
end

function RaiderCheck:RegisterEvent(event)
	if self.eventFrame then
		self.eventFrame:RegisterEvent(event)
	end
end

function RaiderCheck:UnregisterEvent(event)
	if self.eventFrame then
		self.eventFrame:UnregisterEvent(event)
	end
end

function RaiderCheck:SendCommMessage(prefix, message, chatType, target)
	if target then
		SendAddonMessage(prefix, message, "WHISPER", target)
	else
		SendAddonMessage(prefix, message, chatType)
	end
end

function RaiderCheck:HandleSlashCommand(msg)
	msg = msg:lower():trim()

	if msg == "" or msg == "show" then
		if self.ToggleGUI then
			self:ToggleGUI()
		end
	elseif msg == "check" then
		self:ScanGroup()
	elseif msg == "talents" then
		-- Открыть окно талантов для себя
		if self.ShowTalentsInspectFrame then
			local playerName = UnitName("player")
			if playerName then
				self:UpdateOwnData(true) -- Форсированное обновление
				self:ShowTalentsInspectFrame(playerName)
			end
		else
			print("|cFFFF0000RaiderCheck:|r Модуль талантов не загружен")
		end
	elseif msg == "debug talents" then
		-- Включить дебаг талантов
		self.debugTalents = not self.debugTalents
		print(
			"|cFF00FF00RaiderCheck:|r Дебаг талантов: " .. (self.debugTalents and "ВКЛ" or "ВЫКЛ")
		)
		if self.debugTalents then
			-- Запустить одну проверку
			print("--- Данные талантов: ---")
			local talentData = self:GetTalentsData()
			print("Результат: " .. talentData:sub(1, 150) .. "...")
		end
	elseif msg == "help" then
		print("|cFF00FF00RaiderCheck Команды:|r")
		print("/rc show - Показать/скрыть окно")
		print("/rc check - Проверить группу/рейд")
		print("/rc talents - Просмотреть свои таланты")
		print("/rc debug talents - Включить/выключить дебаг талантов")
		print("/rc help - Показать эту справку")
	else
		print("|cFF00FF00RaiderCheck:|r Неизвестная команда. Используйте /rc help")
	end
end

function RaiderCheck:PLAYER_ENTERING_WORLD()
	-- Проверка группы при входе в мир
	local frame = CreateFrame("Frame")
	local elapsed = 0
	frame:SetScript("OnUpdate", function(f, delta)
		elapsed = elapsed + delta
		if elapsed >= 2 then
			f:SetScript("OnUpdate", nil)
			if GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0 then
				RaiderCheck:ScanGroup()
			end
		end
	end)
end

function RaiderCheck:GROUP_ROSTER_UPDATE()
	-- Проверка группы при изменении состава
	local frame = CreateFrame("Frame")
	local elapsed = 0
	frame:SetScript("OnUpdate", function(f, delta)
		elapsed = elapsed + delta
		if elapsed >= 1 then
			f:SetScript("OnUpdate", nil)
			if GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0 then
				RaiderCheck:ScanGroup()
			else
				-- Очистка данных если не в группе
				RaiderCheck.players = {}
				RaiderCheck.playerData = {}
			end
		end
	end)
end

function RaiderCheck:ScanGroup()
	-- Сохраняем свои данные перед очисткой
	local playerName = UnitName("player")
	local myData = nil
	if playerName and self.playerData[playerName] then
		myData = self.playerData[playerName]
	end

	-- Очистка старых данных
	self.players = {}
	if playerName then
		self.players[playerName] = true
	end
	self.playerData = {}

	-- Восстанавливаем свои данные
	if myData then
		self.playerData[playerName] = myData
	end

	-- Обновляем свои данные (форсированно)
	self:UpdateOwnData(true)

	-- В WoW 3.3.5 используем GetNumRaidMembers и GetNumPartyMembers
	local numRaid = GetNumRaidMembers()
	local numParty = GetNumPartyMembers()
	local numMembers = (numRaid > 0) and numRaid or numParty

	if numMembers == 0 then
		print("|cFF00FF00RaiderCheck:|r Вы не в группе/рейде.")
		return
	end

	print("|cFF00FF00RaiderCheck:|r Сканирование группы...")

	-- Отправка ping сообщения
	local channel = (numRaid > 0) and "RAID" or "PARTY"
	self:SendMessage(MSG_PING, VERSION, channel)

	-- Запрос данных через 2 секунды
	local requestFrame = CreateFrame("Frame")
	local requestElapsed = 0
	requestFrame:SetScript("OnUpdate", function(frame, delta)
		requestElapsed = requestElapsed + delta
		if requestElapsed >= 2 then
			frame:SetScript("OnUpdate", nil)
			self:RequestPlayerData()
		end
	end)

	-- Обновление GUI через 4 секунды
	local guiFrame = CreateFrame("Frame")
	local guiElapsed = 0
	guiFrame:SetScript("OnUpdate", function(frame, delta)
		guiElapsed = guiElapsed + delta
		if guiElapsed >= 4 then
			frame:SetScript("OnUpdate", nil)
			if self.UpdateGUI then
				self:UpdateGUI()
			end
		end
	end)
end

function RaiderCheck:RequestPlayerData(specificPlayer)
	local channel = (GetNumRaidMembers() > 0) and "RAID" or "PARTY"

	-- Запрос данных только у игроков с аддоном
	if specificPlayer then
		-- Запрос у конкретного игрока
		if self.players[specificPlayer] then
			self:SendMessage(MSG_REQUEST, "", channel, specificPlayer)
		end
	else
		-- Запрос у всех игроков
		for player, _ in pairs(self.players) do
			self:SendMessage(MSG_REQUEST, "", channel, player)
		end

		local count = 0
		for _ in pairs(self.players) do
			count = count + 1
		end
		print("|cFF00FF00RaiderCheck:|r Найдено игроков с аддоном: " .. count)
	end
end

function RaiderCheck:SendMessage(msgType, data, channel, target)
	local message = msgType .. ":" .. data

	-- Отправляем как есть (разбивку делаем отдельно для больших данных)
	if target then
		self:SendCommMessage(ADDON_PREFIX, message, "WHISPER", target)
	else
		self:SendCommMessage(ADDON_PREFIX, message, channel)
	end
end

function RaiderCheck:CHAT_MSG_ADDON(prefix, message, distribution, sender)
	if prefix ~= ADDON_PREFIX then
		return
	end
	if sender == UnitName("player") then
		return
	end -- Игнорируем свои сообщения

	local msgType, data = message:match("^([^:]+):(.*)$")
	if not msgType then
		return
	end

	if msgType == MSG_PING then
		-- Ответ на ping
		self:SendMessage(MSG_PONG, VERSION .. "-rc", "WHISPER", sender)
	elseif msgType == MSG_PONG then
		-- Регистрация игрока с аддоном и определение типа
		if data and string.find(data, "%-wa") then
			self.players[sender] = "WA"
		elseif data and string.find(data, "%-rc") then
			self.players[sender] = "RC"
		else
			self.players[sender] = "RC" -- По умолчанию RC (старые версии)
		end

		-- Определяем тип клиента по версии (если содержит "-module" или "-external" - это не основной аддон)
		if data and string.find(data, "%-module") then
			-- Это встроенный модуль
			if RaiderCheckDataProvider then
				RaiderCheckDataProvider.clientInfo[sender] = {
					type = "module",
					clientName = "Unknown Module",
					version = data,
					timestamp = GetTime(),
				}
			end
		elseif data and string.find(data, "%-external") then
			-- Это внешний аддон
			if RaiderCheckDataProvider then
				RaiderCheckDataProvider.clientInfo[sender] = {
					type = "external",
					clientName = "Unknown External",
					version = data,
					timestamp = GetTime(),
				}
			end
		else
			-- Это основной аддон RaiderCheck
			if RaiderCheckDataProvider then
				RaiderCheckDataProvider.clientInfo[sender] = {
					type = "addon",
					clientName = "RaiderCheck",
					version = data,
					timestamp = GetTime(),
				}
			end
		end
	elseif msgType == MSG_REQUEST then
		-- Отправка своих данных несколькими сообщениями
		local itemsData = self:GetItemsData()
		local talentsData = self:GetTalentsData()
		local professionsData = self:GetProfessionsData()

		-- Разбиваем данные о предметах на 3 части
		local itemsParts = {}
		for part in itemsData:gmatch("[^;]+") do
			table.insert(itemsParts, part)
		end

		local itemsCount = #itemsParts
		local part1Size = math.ceil(itemsCount / 3)
		local part2Size = math.ceil((itemsCount - part1Size) / 2)

		local items1 = {}
		local items2 = {}
		local items3 = {}

		for i = 1, itemsCount do
			if i <= part1Size then
				table.insert(items1, itemsParts[i])
			elseif i <= part1Size + part2Size then
				table.insert(items2, itemsParts[i])
			else
				table.insert(items3, itemsParts[i])
			end
		end

		-- Отправляем каждый тип данных отдельно
		self:SendMessage(MSG_ITEMS1, table.concat(items1, ";"), "WHISPER", sender)
		self:SendMessage(MSG_ITEMS2, table.concat(items2, ";"), "WHISPER", sender)
		self:SendMessage(MSG_ITEMS3, table.concat(items3, ";"), "WHISPER", sender)
		self:SendMessage(MSG_TALENTS, talentsData, "WHISPER", sender)
		self:SendMessage(MSG_PROFESSIONS, professionsData, "WHISPER", sender)
	elseif msgType == MSG_ITEMS1 or msgType == MSG_ITEMS2 or msgType == MSG_ITEMS3 then
		-- Получение данных о предметах (собираем по частям)
		if not self.playerData[sender] then
			self.playerData[sender] = { itemsParts = {} }
		end
		if not self.playerData[sender].itemsParts then
			self.playerData[sender].itemsParts = {}
		end

		-- Сохраняем часть данных
		if msgType == MSG_ITEMS1 then
			self.playerData[sender].itemsParts[1] = data
		elseif msgType == MSG_ITEMS2 then
			self.playerData[sender].itemsParts[2] = data
		elseif msgType == MSG_ITEMS3 then
			self.playerData[sender].itemsParts[3] = data
		end

		-- Когда все 3 части получены, парсим
		if
			self.playerData[sender].itemsParts[1]
			and self.playerData[sender].itemsParts[2]
			and self.playerData[sender].itemsParts[3]
		then
			local fullItemsData = self.playerData[sender].itemsParts[1]
				.. ";"
				.. self.playerData[sender].itemsParts[2]
				.. ";"
				.. self.playerData[sender].itemsParts[3]
			self.playerData[sender].items = self:ParseItemsData(fullItemsData)

			self.playerData[sender].itemsParts = nil
		end
	elseif msgType == MSG_TALENTS then
		-- Получение данных о талантах (детальный формат с позициями)
		if not self.playerData[sender] then
			self.playerData[sender] = {}
		end

		-- Сохраняем сырые данные
		self.playerData[sender].talents = data

		-- Парсим подробные таланты (с позициями)
		if self.ParseDetailedTalents then
			self.playerData[sender].talentsDetailed = self:ParseDetailedTalents(data)

			-- Вычисляем простую сумму очков для каждого дерева для отображения
			-- v5.0: считаем сумму рангов всех талантов
			local talentsSimple = { 0, 0, 0 }
			for treeIndex = 1, 3 do
				if self.playerData[sender].talentsDetailed[treeIndex] then
					for _, talentData in pairs(self.playerData[sender].talentsDetailed[treeIndex]) do
						-- Суммируем ранги (v5.0 формат: talentIndex + rank)
						talentsSimple[treeIndex] = talentsSimple[treeIndex] + (talentData.rank or 0)
					end
				end
			end
			self.playerData[sender].talentsSimple = talentsSimple
		end

		-- Также сохраняем класс если доступен
		local _, className = UnitClass(sender)
		if className then
			self.playerData[sender].class = className
		end

		self:UpdateGUI()
	elseif msgType == MSG_PROFESSIONS then
		-- Получение данных о профессиях
		if not self.playerData[sender] then
			self.playerData[sender] = {}
		end
		self.playerData[sender].professions = self:ParseProfessionsData(data)
		self.playerData[sender].timestamp = time()

		-- Обновляем GUI когда получены все данные
		if self.UpdateGUI then
			self:UpdateGUI()
		end
	end
end

function RaiderCheck:GetItemsData()
	if self.CollectItemsData then
		return self:CollectItemsData()
	end
	return ""
end

function RaiderCheck:GetTalentsData()
	-- Используем детальный формат с информацией о позициях талантов
	if self.CollectDetailedTalentsData then
		return self:CollectDetailedTalentsData()
	end
	return ""
end

function RaiderCheck:GetProfessionsData()
	if self.CollectProfessionsData then
		return self:CollectProfessionsData()
	end
	return ""
end

function RaiderCheck:ParseItemsData(data)
	if self.ParseItems then
		return self:ParseItems(data)
	end
	return {}
end

function RaiderCheck:ParseTalentsData(data)
	if self.ParseTalents then
		return self:ParseTalents(data)
	end
	return {}
end

function RaiderCheck:ParseProfessionsData(data)
	if self.ParseProfessions then
		return self:ParseProfessions(data)
	end
	return {}
end

-- Вспомогательная функция: простой хеш для сравнения
local function SimpleHash(str)
	if not str or str == "" then
		return 0
	end
	local hash = 0
	for i = 1, #str do
		hash = (hash * 31 + string.byte(str, i)) % 10000000
	end
	return hash
end

-- Проверить, изменились ли данные игрока
function RaiderCheck:HasOwnDataChanged()
	local itemsData = self:GetItemsData()
	local talentsData = self:GetTalentsData()
	local professionsData = self:GetProfessionsData()

	local itemsHash = SimpleHash(itemsData)
	local talentsHash = SimpleHash(talentsData)
	local professionsHash = SimpleHash(professionsData)

	-- Проверяем каждый хеш
	local changed = false
	if itemsHash ~= self.ownDataCache.itemsHash then
		print("|cFFFFFF00RaiderCheck Debug:|r Обнаружено изменение экипировки")
		changed = true
	end
	if talentsHash ~= self.ownDataCache.talentsHash then
		print("|cFFFFFF00RaiderCheck Debug:|r Обнаружено изменение талантов")
		changed = true
	end
	if professionsHash ~= self.ownDataCache.professionsHash then
		print("|cFFFFFF00RaiderCheck Debug:|r Обнаружено изменение профессий")
		changed = true
	end

	if changed then
		-- Обновляем кеш
		self.ownDataCache.itemsHash = itemsHash
		self.ownDataCache.talentsHash = talentsHash
		self.ownDataCache.professionsHash = professionsHash
		self.ownDataCache.timestamp = time()
		self.ownDataCache.changeDetected = true
	end

	return changed
end

-- Обновление своих данных
function RaiderCheck:UpdateOwnData(forceUpdate)
	local playerName = UnitName("player")
	if not playerName then
		return
	end

	-- Проверяем изменились ли данные (если не форсировано обновление)
	if not forceUpdate and not self:HasOwnDataChanged() then
		print(
			"|cFF00FF00RaiderCheck Debug:|r Данные не изменились, пропускаем обновление"
		)
		return
	end

	print("|cFF00FF00RaiderCheck Debug:|r Обновление данных игрока...")

	local itemsData = self:GetItemsData()
	local talentsData = self:GetTalentsData()
	local professionsData = self:GetProfessionsData()

	-- Парсим данные о талантах
	local detailedTalents = {}
	local talentsSimple = { 0, 0, 0 }

	if talentsData and talentsData ~= "" then
		detailedTalents = self:ParseDetailedTalents(talentsData)

		if self.debugTalents then
			print("UpdateOwnData: ParseDetailedTalents completed")
			for treeIndex = 1, 3 do
				if detailedTalents[treeIndex] then
					local count = 0
					for _ in pairs(detailedTalents[treeIndex]) do
						count = count + 1
					end
					print(string.format("  Tree %d: %d talents", treeIndex, count))
				else
					print(string.format("  Tree %d: nil", treeIndex))
				end
			end
		end

		-- Вычисляем сумму рангов для каждого дерева
		for treeIndex = 1, 3 do
			if detailedTalents[treeIndex] then
				for _, talentData in pairs(detailedTalents[treeIndex]) do
					talentsSimple[treeIndex] = talentsSimple[treeIndex] + (talentData.rank or 0)
				end
			end
		end
	end

	self.playerData[playerName] = {
		items = self:ParseItemsData(itemsData),
		talentsDetailed = detailedTalents,
		talentsSimple = talentsSimple,
		talents = talentsData, -- Сырая строка для совместимости
		professions = self:ParseProfessionsData(professionsData),
		class = select(2, UnitClass("player")),
		timestamp = time(),
	}

	-- Сброс флага изменений
	self.ownDataCache.changeDetected = false
end

-- Получить класс игрока
function RaiderCheck:GetPlayerClass(playerName)
	if not playerName then
		return nil
	end

	-- Сначала пробуем получить через UnitClass
	local _, className = UnitClass(playerName)
	if className then
		return className
	end

	-- Если не получилось, пробуем из кэша данных
	if self.playerData[playerName] and self.playerData[playerName].class then
		return self.playerData[playerName].class
	end

	-- Пробуем через raid/party unit
	local unit = self:GetUnitFromName(playerName)
	if unit then
		local _, class = UnitClass(unit)
		if class then
			-- Сохраняем в кэш
			if not self.playerData[playerName] then
				self.playerData[playerName] = {}
			end
			self.playerData[playerName].class = class
			return class
		end
	end

	return nil
end

-- Получить цвет класса игрока
function RaiderCheck:GetPlayerClassColor(playerName)
	local className = self:GetPlayerClass(playerName)
	if className and RAID_CLASS_COLORS[className] then
		return RAID_CLASS_COLORS[className]
	end
	return { r = 0.5, g = 0.5, b = 0.5 } -- Серый цвет по умолчанию
end

-- Получить unit ID по имени игрока
function RaiderCheck:GetUnitFromName(playerName)
	if not playerName then
		return nil
	end

	-- Проверяем сам игрок
	if UnitName("player") == playerName then
		return "player"
	end

	-- Проверяем рейд
	local numRaidMembers = GetNumRaidMembers()
	if numRaidMembers > 0 then
		for i = 1, numRaidMembers do
			local unit = "raid" .. i
			if UnitName(unit) == playerName then
				return unit
			end
		end
	end

	-- Проверяем группу
	local numPartyMembers = GetNumPartyMembers()
	if numPartyMembers > 0 then
		for i = 1, numPartyMembers do
			local unit = "party" .. i
			if UnitName(unit) == playerName then
				return unit
			end
		end
	end

	return nil
end

-- Вспомогательные функции
function string:trim()
	return self:match("^%s*(.-)%s*$")
end

-- Инициализация аддона при загрузке
-- Функция для открытия окна просмотра талантов
function RaiderCheck:ShowTalentsInspect(playerName)
	if self.ShowTalentVisualFrame then
		self:ShowTalentVisualFrame(playerName)
	end
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(_, event, addonName)
	if event == "ADDON_LOADED" and addonName == "RaiderCheck" then
		RaiderCheck:OnInitialize()
	elseif event == "PLAYER_LOGIN" then
		RaiderCheck:OnEnable()
	end
end)
