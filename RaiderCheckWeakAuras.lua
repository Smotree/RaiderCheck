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

	for slot = 1, 19 do
		local itemID = GetInventoryItemID("player", slot)
		if itemID then
			local _, _, quality, ilvl = GetItemInfo(itemID)
			table.insert(items, slot .. "~" .. itemID .. "~" .. (quality or 0) .. "~" .. (ilvl or 0))
		end
	end

	return table.concat(items, ";")
end

function RaiderCheckWeakAuras:CollectTalentsData()
	local talents = {}

	for tab = 1, 3 do
		local talentString = ""
		for tier = 1, 7 do
			for column = 1, 3 do
				local talentID, name, _, _, rank = GetTalentInfo(tab, tier, column)
				if talentID and rank and rank > 0 then
					if talentString ~= "" then
						talentString = talentString .. ","
					end
					talentString = talentString .. talentID .. "~" .. rank
				end
			end
		end
		table.insert(talents, talentString)
	end

	return table.concat(talents, "|")
end

function RaiderCheckWeakAuras:CollectProfessionsData()
	local profs = {}

	for i = 1, GetNumSkills() do
		local skillName, skillType, skillRank, skillMaxRank = GetSkillLineInfo(i)

		if skillType == "PROFESSION" and skillName then
			table.insert(profs, skillName .. "~" .. skillRank .. "~" .. skillMaxRank)
		end
	end

	return table.concat(profs, ";")
end

function RaiderCheckWeakAuras:SendOwnData(target)
	local playerName = UnitName("player")
	if not playerName then
		return
	end

	local itemsData = self:CollectItemsData()
	local talentsData = self:CollectTalentsData()
	local professionsData = self:CollectProfessionsData()

	self:SendMessage("ITEMS", itemsData, target)
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
	elseif msgType == "REQUEST" then
		if self.isActive then
			-- Отправляем свои данные
			self:SendOwnData(sender)
		end
	end

	-- Получение данных от других
	if msgType == "ITEMS" or msgType == "TALENTS" or msgType == "PROFESSIONS" then
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

if RaiderCheckWeakAuras._instanceCount == 1 then
	print("|cFF00FF00RaiderCheckWeakAuras:|r v" .. RaiderCheckWeakAuras.VERSION .. " загружен")
	if RaiderCheckWeakAuras:IsRaiderCheckLoaded() then
		print("|cFF00FF00RaiderCheckWeakAuras:|r RaiderCheck обнаружен")
	else
		print(
			"|cFFFF9900RaiderCheckWeakAuras:|r RaiderCheck не обнаружен (будет работать в режиме WA)"
		)
	end
else
	print("|cFFFF9900RaiderCheckWeakAuras:|r Дубль #" .. RaiderCheckWeakAuras._instanceCount .. " отключен")
end
