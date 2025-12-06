-- ============================================
-- RaiderCheck WeakAuras Module
-- Минималистичный модуль для WeakAuras
-- Функции: Приём PING, отправка данных
-- ============================================
-- Версия: 1.0.0
-- Использование: Вставить в WeakAuras как Custom Code
-- ============================================

RaiderCheckWeakAuras = RaiderCheckWeakAuras or {}
RaiderCheckWeakAuras.VERSION = "1.0.0"

-- Локальные данные
local playerData = {}
local pendingRequests = {}
local lastPingResponse = 0

-- Счетчик экземпляров для защиты от дублей
RaiderCheckWeakAuras._instanceCount = (RaiderCheckWeakAuras._instanceCount or 0) + 1
RaiderCheckWeakAuras.isActive = (RaiderCheckWeakAuras._instanceCount == 1)

-- ============================================
-- ИНИЦИАЛИЗАЦИЯ
-- ============================================

-- Создаем фрейм для обработки событий
if not RaiderCheckWeakAuras.frame then
	RaiderCheckWeakAuras.frame = CreateFrame("Frame")
	RaiderCheckWeakAuras.frame:SetScript("OnEvent", function(_, event, ...)
		if RaiderCheckWeakAuras[event] then
			RaiderCheckWeakAuras[event](RaiderCheckWeakAuras, ...)
		end
	end)

	-- Регистрируем события
	RaiderCheckWeakAuras.frame:RegisterEvent("CHAT_MSG_ADDON")
	RaiderCheckWeakAuras.frame:RegisterEvent("PLAYER_ENTERING_WORLD")

	-- Регистрируем префикс
	if RegisterAddonPrefix then
		pcall(RegisterAddonPrefix, "RaiderCheck")
	end
end

-- ============================================
-- ОТПРАВКА СООБЩЕНИЙ
-- ============================================

function RaiderCheckWeakAuras:SendMessage(msgType, data, target)
	local fullMessage = msgType .. ":" .. (data or "")

	if target then
		SendAddonMessage("RaiderCheck", fullMessage, "WHISPER", target)
	else
		local channel = (GetNumRaidMembers() > 0) and "RAID" or "PARTY"
		SendAddonMessage("RaiderCheck", fullMessage, channel)
	end
end

-- ============================================
-- СБОР И ОТПРАВКА ДАННЫХ
-- ============================================

function RaiderCheckWeakAuras:CollectItemsData()
	local items = {}

	local INVENTORY_SLOTS = {
		"HeadSlot",
		"NeckSlot",
		"ShoulderSlot",
		"BackSlot",
		"ChestSlot",
		"WristSlot",
		"HandsSlot",
		"WaistSlot",
		"LegsSlot",
		"FeetSlot",
		"Finger0Slot",
		"Finger1Slot",
		"Trinket0Slot",
		"Trinket1Slot",
		"MainHandSlot",
		"SecondaryHandSlot",
		"RangedSlot",
	}

	for _, slotName in ipairs(INVENTORY_SLOTS) do
		local slotId = GetInventorySlotInfo(slotName)
		local itemLink = GetInventoryItemLink("player", slotId)

		if itemLink then
			local enchantId = self:GetEnchantId(itemLink)
			local itemId = self:GetItemId(itemLink)
			local gemIds, totalSockets = self:GetGemIds(slotId, itemLink)

			-- Кодируем itemLink
			local encodedLink = itemLink:gsub(":", "~")

			table.insert(
				items,
				string.format(
					"%d:%s:%s:%d:%s:%s",
					slotId,
					itemId or "0",
					enchantId or "0",
					totalSockets or 0,
					table.concat(gemIds, ",") or "0",
					encodedLink
				)
			)
		end
	end

	return table.concat(items, ";")
end

-- Вспомогательные функции для парсинга предметов
function RaiderCheckWeakAuras:GetItemId(itemLink)
	if not itemLink then
		return nil
	end
	local itemId = itemLink:match("item:(%d+)")
	return itemId
end

function RaiderCheckWeakAuras:GetEnchantId(itemLink)
	if not itemLink then
		return nil
	end
	local enchantId = itemLink:match("item:%d+:(%d+)")
	return enchantId ~= "0" and enchantId or nil
end

function RaiderCheckWeakAuras:GetGemIds(slotId, itemLink)
	if not itemLink then
		return {}, 0
	end

	local gemIds = {}
	local totalSockets = 0

	-- Используем Socket API для точного определения сокетов
	SocketInventoryItem(slotId)
	totalSockets = GetNumSockets() or 0

	-- Получаем ID каждого вставленного камня
	for i = 1, totalSockets do
		local gemLink = GetExistingSocketLink(i)
		if gemLink then
			-- Парсим gemLink: |Hitem:itemId:0:0:0:0:0:0:0:80
			local parts = { strsplit(":", gemLink) }
			local gemItemId = parts[2]
			if gemItemId and gemItemId ~= "" and gemItemId ~= "0" then
				local gemItemIdNum = tonumber(gemItemId)
				if gemItemIdNum then
					table.insert(gemIds, gemItemIdNum)
				end
			end
		end
	end

	CloseSocketInfo()

	return gemIds, totalSockets
end

function RaiderCheckWeakAuras:CollectTalentsData()
	local treesData = {}

	for tabIndex = 1, 3 do
		local numTalents = GetNumTalents(tabIndex)
		local talentsInfo = {}

		-- Собираем только индекс и ранг для каждого таланта
		for talentIndex = 1, numTalents do
			local name, icon, tier, column, rank = GetTalentInfo(tabIndex, talentIndex)

			-- Формат: talentIndex~rank (как в основном аддоне)
			local rankVal = rank or 0
			table.insert(talentsInfo, talentIndex .. "~" .. rankVal)
		end

		-- Объединяем таланты через запятую
		table.insert(treesData, table.concat(talentsInfo, ","))
	end

	-- Формат: tree1|tree2|tree3
	return table.concat(treesData, "|")
end

function RaiderCheckWeakAuras:CollectProfessionsData()
	local professionsData = {}

	-- В WoW 3.3.5 используем GetNumSkillLines() и GetSkillLineInfo()
	local numSkills = GetNumSkillLines()

	-- Список профессий по категориям
	local professionCategories = {
		["Профессии"] = true,
		["Профессия"] = true,
		["Вторичные навыки"] = true,
		["Secondary Skills"] = true,
		["Professions"] = true,
	}

	for i = 1, numSkills do
		local skillName, isHeader, isExpanded, skillRank, numTempPoints, skillModifier, skillMaxRank, isAbandonable, stepCost, rankCost, minLevel, skillCostType, skillDescription =
			GetSkillLineInfo(i)

		-- Проверяем что это профессия (не заголовок и можно забыть)
		if skillName and not isHeader and isAbandonable and skillMaxRank and skillMaxRank > 1 then
			-- Форматируем: название:текущий_уровень:максимальный_уровень
			table.insert(professionsData, string.format("%s:%d:%d", skillName, skillRank or 0, skillMaxRank or 0))
		end
	end

	return table.concat(professionsData, ";")
end

function RaiderCheckWeakAuras:SendOwnData(target)
	local playerName = UnitName("player")
	if not playerName then
		return
	end

	local itemsData = self:CollectItemsData()
	local talentsData = self:CollectTalentsData()
	local professionsData = self:CollectProfessionsData()

	-- Разбиваем данные о предметах на 3 части (как в основном аддоне)
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
	self:SendMessage("ITEMS1", table.concat(items1, ";"), target)
	self:SendMessage("ITEMS2", table.concat(items2, ";"), target)
	self:SendMessage("ITEMS3", table.concat(items3, ";"), target)
	self:SendMessage("TALENTS", talentsData, target)
	self:SendMessage("PROFESSIONS", professionsData, target)

	playerData[playerName] = {
		items = itemsData,
		talents = talentsData,
		professions = professionsData,
		timestamp = GetTime(),
	}
end

-- ============================================
-- ОБРАБОТКА СООБЩЕНИЙ
-- ============================================

function RaiderCheckWeakAuras:CHAT_MSG_ADDON(prefix, message, distribution, sender)
	if prefix ~= "RaiderCheck" then
		return
	end
	if sender == UnitName("player") then
		return
	end

	local msgType, data = message:match("^([^:]+):(.*)$")
	if not msgType then
		return
	end

	-- PING - проверка наличия модуля
	if msgType == "PING" then
		if self.isActive then
			lastPingResponse = GetTime()
			-- Отправляем PONG с информацией что это WA модуль
			self:SendMessage("PONG", self.VERSION .. "-wa", sender)
		end
	end

	-- REQUEST - запрос данных
	if msgType == "REQUEST" then
		-- Отправляем свои данные
		self:SendOwnData(sender)
	end

	-- Получение данных от других
	if msgType == "ITEMS1" or msgType == "ITEMS2" or msgType == "ITEMS3" then
		if not playerData[sender] then
			playerData[sender] = { itemsParts = {} }
		end
		if not playerData[sender].itemsParts then
			playerData[sender].itemsParts = {}
		end

		-- Сохраняем часть данных
		if msgType == "ITEMS1" then
			playerData[sender].itemsParts[1] = data
		elseif msgType == "ITEMS2" then
			playerData[sender].itemsParts[2] = data
		elseif msgType == "ITEMS3" then
			playerData[sender].itemsParts[3] = data
		end

		-- Когда все 3 части получены, объединяем
		if
			playerData[sender].itemsParts[1]
			and playerData[sender].itemsParts[2]
			and playerData[sender].itemsParts[3]
		then
			local fullItemsData = playerData[sender].itemsParts[1]
				.. ";"
				.. playerData[sender].itemsParts[2]
				.. ";"
				.. playerData[sender].itemsParts[3]
			playerData[sender].items = fullItemsData
			playerData[sender].itemsParts = nil -- Очищаем временные данные
		end

		playerData[sender].timestamp = GetTime()
	elseif msgType == "TALENTS" or msgType == "PROFESSIONS" then
		if not playerData[sender] then
			playerData[sender] = {}
		end

		if msgType == "ITEMS" then
			playerData[sender].items = data
		elseif msgType == "TALENTS" then
			playerData[sender].talents = data
		elseif msgType == "PROFESSIONS" then
			playerData[sender].professions = data
		end

		playerData[sender].timestamp = GetTime()
	end
end

-- ============================================
-- API ФУНКЦИИ
-- ============================================

-- Получить данные игрока
function RaiderCheckWeakAuras:GetPlayerData(playerName)
	return playerData[playerName]
end

-- Получить данные всех игроков
function RaiderCheckWeakAuras:GetAllPlayerData()
	return playerData
end

-- Получить список игроков в рейде/группе
function RaiderCheckWeakAuras:GetGroupMembers()
	local members = {}

	local numRaid = GetNumRaidMembers()
	if numRaid > 0 then
		for i = 1, numRaid do
			local name = GetRaidRosterInfo(i)
			if name then
				table.insert(members, name)
			end
		end
	else
		local numParty = GetNumPartyMembers()
		table.insert(members, UnitName("player"))
		for i = 1, numParty do
			local name = UnitName("party" .. i)
			if name then
				table.insert(members, name)
			end
		end
	end

	return members
end

-- Получить версию
function RaiderCheckWeakAuras:GetVersion()
	return self.VERSION
end

-- Проверить загружен ли основной RaiderCheck
function RaiderCheckWeakAuras:IsRaiderCheckLoaded()
	return RaiderCheck ~= nil
end

-- ============================================
-- ИНИЦИАЛИЗАЦИЯ ПРИ ЗАГРУЗКЕ
-- ============================================

print("|cFF00FF00RaiderCheckWeakAuras:|r v" .. RaiderCheckWeakAuras.VERSION .. " загружен")
if RaiderCheckWeakAuras:IsRaiderCheckLoaded() then
	print("|cFF00FF00RaiderCheckWeakAuras:|r RaiderCheck обнаружен")
else
	print(
		"|cFFFF9900RaiderCheckWeakAuras:|r RaiderCheck не обнаружен (будет работать в режиме WA)"
	)
end
