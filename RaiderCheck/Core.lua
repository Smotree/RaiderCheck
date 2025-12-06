-- RaiderCheck Core
RaiderCheck = {}

local ADDON_PREFIX = "RaiderCheck"
local VERSION = "1.0.0"

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
RaiderCheck.players = {}
RaiderCheck.playerData = {}
RaiderCheck.eventFrame = nil

function RaiderCheck:OnInitialize()
	-- Инициализация базы данных
	self.db = RaiderCheckDB or {}
	RaiderCheckDB = self.db

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
		-- Сохраняем свои данные
		self:UpdateOwnData()
	end

	-- Регистрация событий
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("CHAT_MSG_ADDON")

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
	elseif msg == "help" then
		print("|cFF00FF00RaiderCheck Команды:|r")
		print("/rc show - Показать/скрыть окно")
		print("/rc check - Проверить группу/рейд")
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
	-- Очистка старых данных (но сохраняем себя)
	local playerName = UnitName("player")
	self.players = {}
	if playerName then
		self.players[playerName] = true
	end
	self.playerData = {}

	-- Обновляем свои данные
	self:UpdateOwnData()

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
		self:SendMessage(MSG_PONG, VERSION, "WHISPER", sender)
	elseif msgType == MSG_PONG then
		-- Регистрация игрока с аддоном
		self.players[sender] = true
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
		-- Получение данных о талантах
		if not self.playerData[sender] then
			self.playerData[sender] = {}
		end
		self.playerData[sender].talents = self:ParseTalentsData(data)
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
	if self.CollectTalentsData then
		return self:CollectTalentsData()
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

-- Обновление своих данных
function RaiderCheck:UpdateOwnData()
	local playerName = UnitName("player")
	if not playerName then
		return
	end

	local itemsData = self:GetItemsData()
	local talentsData = self:GetTalentsData()
	local professionsData = self:GetProfessionsData()

	self.playerData[playerName] = {
		items = self:ParseItemsData(itemsData),
		talents = self:ParseTalentsData(talentsData),
		professions = self:ParseProfessionsData(professionsData),
		timestamp = time(),
	}
end

-- Вспомогательные функции
function string:trim()
	return self:match("^%s*(.-)%s*$")
end

-- Инициализация аддона при загрузке
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
