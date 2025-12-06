-- ============================================
-- RaiderCheck Data Provider - Standalone Module
-- Полностью независимый модуль, работает без Core.lua
-- Минималистичный: приём PING, отправка данных
-- ============================================
-- Версия: 2.0.0 (Standalone)
-- Использование:
--   1. Скопируйте этот файл в папку вашего аддона
--   2. Добавьте в .toc файл:
--      RaiderCheckDataProvider_Standalone.lua
--   3. Модуль автоматически отвечает на PING и REQUEST
-- ============================================

RaiderCheckDataProvider = RaiderCheckDataProvider or {}
RaiderCheckDataProvider.VERSION = "2.0.0"

-- Локальные переменные
local playerDataCache = {}
local lastPingResponse = 0

-- Счетчик экземпляров для защиты от дублей
RaiderCheckDataProvider._instanceCount = (RaiderCheckDataProvider._instanceCount or 0) + 1
RaiderCheckDataProvider.isActive = (RaiderCheckDataProvider._instanceCount == 1)

-- ============================================
-- ИНИЦИАЛИЗАЦИЯ
-- ============================================

-- Создаем фрейм для обработки событий
if not RaiderCheckDataProvider.eventFrame then
	RaiderCheckDataProvider.eventFrame = CreateFrame("Frame")
	RaiderCheckDataProvider.eventFrame:SetScript("OnEvent", function(_, event, ...)
		if RaiderCheckDataProvider[event] then
			RaiderCheckDataProvider[event](RaiderCheckDataProvider, ...)
		end
	end)

	RaiderCheckDataProvider.eventFrame:RegisterEvent("CHAT_MSG_ADDON")
	RaiderCheckDataProvider.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

	if RegisterAddonPrefix then
		pcall(RegisterAddonPrefix, "RaiderCheck")
	end
end

-- ============================================
-- ОТПРАВКА СООБЩЕНИЙ
-- ============================================

function RaiderCheckDataProvider:SendMessage(msgType, data, target)
	local fullMessage = msgType .. ":" .. (data or "")

	if target then
		SendAddonMessage("RaiderCheck", fullMessage, "WHISPER", target)
	else
		local channel = (GetNumRaidMembers() > 0) and "RAID" or "PARTY"
		SendAddonMessage("RaiderCheck", fullMessage, channel)
	end
end

-- ============================================
-- СБОР ДАННЫХ
-- ============================================

function RaiderCheckDataProvider:CollectItemsData()
	-- Если есть Core.lua - используем его
	if RaiderCheck and RaiderCheck.GetItemsData then
		return RaiderCheck:GetItemsData()
	end

	-- Иначе собираем минимально
	local items = {}
	for slot = 1, 19 do
		local itemID = GetInventoryItemID("player", slot)
		if itemID then
			table.insert(items, slot .. "~" .. itemID)
		end
	end
	return table.concat(items, ";")
end

function RaiderCheckDataProvider:CollectTalentsData()
	if RaiderCheck and RaiderCheck.GetTalentsData then
		return RaiderCheck:GetTalentsData()
	end

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

function RaiderCheckDataProvider:CollectProfessionsData()
	if RaiderCheck and RaiderCheck.GetProfessionsData then
		return RaiderCheck:GetProfessionsData()
	end

	local profs = {}
	for i = 1, GetNumSkills() do
		local skillName, skillType, skillRank, skillMaxRank = GetSkillLineInfo(i)
		if skillType == "PROFESSION" and skillName then
			table.insert(profs, skillName .. "~" .. skillRank .. "~" .. skillMaxRank)
		end
	end
	return table.concat(profs, ";")
end

function RaiderCheckDataProvider:SendOwnData(target)
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

	playerDataCache[playerName] = {
		items = itemsData,
		talents = talentsData,
		professions = professionsData,
		timestamp = GetTime(),
	}
end

-- ============================================
-- ОБРАБОТКА СООБЩЕНИЙ
-- ============================================

function RaiderCheckDataProvider:CHAT_MSG_ADDON(prefix, message, distribution, sender)
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

	if msgType == "PING" then
		if self.isActive then
			lastPingResponse = GetTime()
			self:SendMessage("PONG", self.VERSION .. "-module", sender)
		end
	elseif msgType == "REQUEST" then
		if self.isActive then
			self:SendOwnData(sender)
		end
	elseif msgType == "ITEMS" or msgType == "TALENTS" or msgType == "PROFESSIONS" then
		if not playerDataCache[sender] then
			playerDataCache[sender] = {}
		end

		if msgType == "ITEMS" then
			playerDataCache[sender].items = data
		elseif msgType == "TALENTS" then
			playerDataCache[sender].talents = data
		elseif msgType == "PROFESSIONS" then
			playerDataCache[sender].professions = data
		end

		playerDataCache[sender].timestamp = GetTime()
	end
end

function RaiderCheckDataProvider:PLAYER_ENTERING_WORLD()
	-- Обновляем свои данные при входе
	local playerName = UnitName("player")
	if playerName and self.isActive then
		self:SendOwnData(playerName)
	end
end

-- ============================================
-- API ФУНКЦИИ (минимальные)
-- ============================================

function RaiderCheckDataProvider:GetPlayerData(playerName)
	if RaiderCheck and RaiderCheck.playerData and RaiderCheck.playerData[playerName] then
		return RaiderCheck.playerData[playerName]
	end
	return playerDataCache[playerName]
end

function RaiderCheckDataProvider:GetAllPlayerData()
	if RaiderCheck and RaiderCheck.playerData then
		return RaiderCheck.playerData
	end
	return playerDataCache
end

function RaiderCheckDataProvider:GetVersion()
	return self.VERSION
end

function RaiderCheckDataProvider:IsAvailable()
	return self.isActive
end

function RaiderCheckDataProvider:IsRaiderCheckLoaded()
	return RaiderCheck ~= nil
end

-- ============================================
-- ИНИЦИАЛИЗАЦИЯ
-- ============================================

if RaiderCheckDataProvider._instanceCount == 1 then
	print("|cFF00FF00RaiderCheckDataProvider:|r v" .. RaiderCheckDataProvider.VERSION .. " (Standalone)")
else
	print(
		"|cFFFF9900RaiderCheckDataProvider:|r Дубль #"
			.. RaiderCheckDataProvider._instanceCount
			.. " отключен"
	)
end
