-- ============================================
-- RaiderCheck WeakAuras Module
-- Минималистичный модуль для WeakAuras
-- Функции: Приём PING, отправка данных
-- ============================================
-- Версия: 1.4.0
-- Использование: Вставить в WeakAuras как Custom Code
-- ============================================

-- Предотвращаем повторную инициализацию
if RaiderCheckWeakAuras and RaiderCheckWeakAuras.initialized then
	return
end

RaiderCheckWeakAuras = RaiderCheckWeakAuras or {}
RaiderCheckWeakAuras.VERSION = "1.4.0"

-- Локальные данные
local playerData = {}

-- Debounce система для отправки UPDATE при изменении экипировки
local pendingUpdate = false
local UPDATE_DEBOUNCE = 3 -- секунды

-- ============================================
-- ВСЕ ФУНКЦИИ ОПРЕДЕЛЯЕМ СНАЧАЛА
-- ============================================

-- Отправка сообщений
function RaiderCheckWeakAuras:SendMessage(msgType, data, target)
	local fullMessage = msgType .. ":" .. (data or "")

	if target then
		SendAddonMessage("RaiderCheck", fullMessage, "WHISPER", target)
	else
		local channel = (GetNumRaidMembers() > 0) and "RAID" or "PARTY"
		SendAddonMessage("RaiderCheck", fullMessage, channel)
	end
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

	-- Используем GetItemGem для получения камней (не открывает UI)
	for i = 1, 3 do
		local gemName, gemLink = GetItemGem(itemLink, i)
		if gemLink and gemLink ~= "" then
			-- Парсим gem link чтобы получить item ID камня
			local gemItemId = gemLink:match("item:(%d+)")
			if gemItemId then
				local gemItemIdNum = tonumber(gemItemId)
				if gemItemIdNum then
					table.insert(gemIds, gemItemIdNum)
				end
			end
		end
	end

	-- Получаем количество сокетов через GetItemStats (не открывает UI)
	local stats = GetItemStats and GetItemStats(itemLink) or nil
	if stats then
		totalSockets = (stats["EMPTY_SOCKET_RED"] or 0)
			+ (stats["EMPTY_SOCKET_YELLOW"] or 0)
			+ (stats["EMPTY_SOCKET_BLUE"] or 0)
			+ (stats["EMPTY_SOCKET_META"] or 0)
			+ (stats["EMPTY_SOCKET_PRISMATIC"] or 0)
	end

	return gemIds, totalSockets
end

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

function RaiderCheckWeakAuras:CollectTalentsData()
	local treesData = {}

	for tabIndex = 1, 3 do
		local numTalents = GetNumTalents(tabIndex)
		local talentsInfo = {}

		for talentIndex = 1, numTalents do
			local name, icon, tier, column, rank = GetTalentInfo(tabIndex, talentIndex)
			local rankVal = rank or 0
			table.insert(talentsInfo, talentIndex .. "~" .. rankVal)
		end

		table.insert(treesData, table.concat(talentsInfo, ","))
	end

	return table.concat(treesData, "|")
end

function RaiderCheckWeakAuras:CollectProfessionsData()
	local professionsData = {}
	local numSkills = GetNumSkillLines()

	for i = 1, numSkills do
		local skillName, isHeader, isExpanded, skillRank, numTempPoints, skillModifier, skillMaxRank, isAbandonable =
			GetSkillLineInfo(i)

		if skillName and not isHeader and isAbandonable and skillMaxRank and skillMaxRank > 1 then
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

-- Отправка UPDATE в группу (push-модель)
function RaiderCheckWeakAuras:SendUpdate()
	-- Проверяем что мы в группе
	local numRaid = GetNumRaidMembers()
	local numParty = GetNumPartyMembers()
	if numRaid == 0 and numParty == 0 then
		return
	end

	-- Отправляем UPDATE всем в группе
	self:SendMessage("UPDATE", self.VERSION)

	-- Сразу отправляем свои данные
	self:SendOwnData()
end

-- Запланировать отправку UPDATE с debounce
function RaiderCheckWeakAuras:ScheduleUpdate()
	if pendingUpdate then
		return -- Уже запланировано
	end

	pendingUpdate = true

	-- Используем C_Timer если доступен, иначе OnUpdate
	if C_Timer and C_Timer.After then
		C_Timer.After(UPDATE_DEBOUNCE, function()
			pendingUpdate = false
			RaiderCheckWeakAuras:SendUpdate()
		end)
	else
		-- Fallback через OnUpdate
		local timerFrame = CreateFrame("Frame")
		local elapsed = 0
		timerFrame:SetScript("OnUpdate", function(self, delta)
			elapsed = elapsed + delta
			if elapsed >= UPDATE_DEBOUNCE then
				self:SetScript("OnUpdate", nil)
				pendingUpdate = false
				RaiderCheckWeakAuras:SendUpdate()
			end
		end)
	end
end

-- API функции
function RaiderCheckWeakAuras:GetPlayerData(playerName)
	return playerData[playerName]
end

function RaiderCheckWeakAuras:GetAllPlayerData()
	return playerData
end

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

function RaiderCheckWeakAuras:GetVersion()
	return self.VERSION
end

function RaiderCheckWeakAuras:IsRaiderCheckLoaded()
	return RaiderCheck ~= nil
end

-- ============================================
-- ОБРАБОТЧИК СОБЫТИЙ (определяем ДО создания фрейма)
-- ============================================

local function OnEvent(self, event, ...)
	if event == "CHAT_MSG_ADDON" then
		local prefix, message, distribution, sender = ...

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
			-- Отправляем PONG с информацией что это WA модуль
			RaiderCheckWeakAuras:SendMessage("PONG", RaiderCheckWeakAuras.VERSION .. "-wa", sender)
		end

		-- REQUEST - запрос данных
		if msgType == "REQUEST" then
			RaiderCheckWeakAuras:SendOwnData(sender)
		end

		-- UPDATE - другой игрок изменил экипировку (принимаем его данные)
		if msgType == "UPDATE" then
			-- Данные придут следом через ITEMS1/2/3, TALENTS, PROFESSIONS
			-- Ничего дополнительно делать не нужно
		end

		-- Получение данных от других
		if msgType == "ITEMS1" or msgType == "ITEMS2" or msgType == "ITEMS3" then
			if not playerData[sender] then
				playerData[sender] = { itemsParts = {} }
			end
			if not playerData[sender].itemsParts then
				playerData[sender].itemsParts = {}
			end

			if msgType == "ITEMS1" then
				playerData[sender].itemsParts[1] = data
			elseif msgType == "ITEMS2" then
				playerData[sender].itemsParts[2] = data
			elseif msgType == "ITEMS3" then
				playerData[sender].itemsParts[3] = data
			end

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
				playerData[sender].itemsParts = nil
			end

			playerData[sender].timestamp = GetTime()
		elseif msgType == "TALENTS" then
			if not playerData[sender] then
				playerData[sender] = {}
			end
			playerData[sender].talents = data
			playerData[sender].timestamp = GetTime()
		elseif msgType == "PROFESSIONS" then
			if not playerData[sender] then
				playerData[sender] = {}
			end
			playerData[sender].professions = data
			playerData[sender].timestamp = GetTime()
		end
	elseif event == "PLAYER_EQUIPMENT_CHANGED" or event == "ACTIVE_TALENT_GROUP_CHANGED" then
		-- Push-модель: уведомляем группу об изменении экипировки/талантов
		RaiderCheckWeakAuras:ScheduleUpdate()
	end
end

-- ============================================
-- ИНИЦИАЛИЗАЦИЯ (в самом конце, после всех функций)
-- ============================================

-- Регистрируем префикс
if RegisterAddonPrefix then
	pcall(RegisterAddonPrefix, "RaiderCheck")
end

-- Удаляем старый фрейм если есть
if RaiderCheckWeakAuras.frame then
	RaiderCheckWeakAuras.frame:UnregisterAllEvents()
	RaiderCheckWeakAuras.frame:SetScript("OnEvent", nil)
	RaiderCheckWeakAuras.frame = nil
end

-- Создаем новый фрейм
RaiderCheckWeakAuras.frame = CreateFrame("Frame")

-- Устанавливаем обработчик напрямую (функция уже определена выше!)
RaiderCheckWeakAuras.frame:SetScript("OnEvent", OnEvent)

-- Регистрируем события
RaiderCheckWeakAuras.frame:RegisterEvent("CHAT_MSG_ADDON")
RaiderCheckWeakAuras.frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
RaiderCheckWeakAuras.frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")

-- Помечаем как инициализированный
RaiderCheckWeakAuras.initialized = true

print(
	"|cFF00FF00RaiderCheckWeakAuras:|r v"
		.. RaiderCheckWeakAuras.VERSION
		.. " загружен и готов к работе"
)

if RaiderCheckWeakAuras:IsRaiderCheckLoaded() then
	print("|cFF00FF00RaiderCheckWeakAuras:|r RaiderCheck обнаружен")
else
	print("|cFFFF9900RaiderCheckWeakAuras:|r RaiderCheck не обнаружен (работает автономно)")
end
