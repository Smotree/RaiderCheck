-- RaiderCheck Talents Module
-- Модуль для сбора и анализа информации о талантах
--
-- СИСТЕМА СЕРИАЛИЗАЦИИ ТАЛАНТОВ (v5.0):
-- =====================================
-- Формат передачи: "tree1|tree2|tree3"
-- где каждое дерево: "idx~rank,idx~rank,idx~rank,..."
--
-- Пример: "1~0,2~0,3~5,4~2,5~3|1~1,2~0,3~2|1~0,2~0,3~0"
--
-- УПРОЩЁННАЯ СИСТЕМА:
-- - Передаём только talentIndex и rank
-- - Вся информация (tier, column, icon, name, spellID) хранится в TalentsDatabase.lua
-- - Заполняется вручную для каждого класса
-- - Размер сообщения: ~20-40 байт на дерево (очень компактно!)
--
-- v5.0: Минимальная передача данных + статическая база талантов
-- - База: TalentsDatabase.lua (заполняется вручную)
-- - Иконка/имя берутся из базы по className + tabIndex + talentIndex
-- - Позиция (tier, column) тоже из базы
-- - Передаём только изменяемые данные: rank

-- Проверяем, что RaiderCheck существует
if not RaiderCheck then
	error("RaiderCheck core not loaded! Check Core.lua")
end

-- v5.0: Кодировка не нужна - передаём только числа

-- Сериализовать данные о талантах в формат v5.0
-- Передаём ТОЛЬКО talentIndex и rank для всех талантов (от 1 до GetNumTalents)
-- Формат: tree1|tree2|tree3
-- где tree = idx~rank,idx~rank,idx~rank,...
--
-- Пример: "1~0,2~0,3~5,4~2|1~1,2~0,3~2|1~0,2~0"
-- Остальные данные (tier, column, icon, name) берутся из TalentsDatabase.lua
function RaiderCheck:SerializeTalentsData()
	local treesData = {}
	local totalTalents = 0

	for tabIndex = 1, 3 do
		local numTalents = GetNumTalents(tabIndex)
		local talentsInfo = {}

		-- DEBUG
		if self.debugTalents then
			print(string.format("[Talents v5.0] Tree %d: numTalents=%d", tabIndex, numTalents))
		end

		-- Собираем только индекс и ранг для каждого таланта
		for talentIndex = 1, numTalents do
			local name, icon, tier, column, rank = GetTalentInfo(tabIndex, talentIndex)

			-- DEBUG первые 5 талантов
			if self.debugTalents and talentIndex <= 5 then
				print(
					string.format(
						"  [v5.0] Talent %d: rank=%s (name=%s)",
						talentIndex,
						tostring(rank or 0),
						tostring(name or "Unknown")
					)
				)
			end

			-- Формат: talentIndex~rank
			local rankVal = rank or 0
			table.insert(talentsInfo, talentIndex .. "~" .. rankVal)
			totalTalents = totalTalents + 1
		end

		-- Объединяем таланты через запятую
		table.insert(treesData, table.concat(talentsInfo, ","))
	end

	-- Формат: tree1|tree2|tree3
	local result = table.concat(treesData, "|")
	if self.debugTalents then
		print("[Talents v5.0] Total talents: " .. totalTalents)
		print("[Talents v5.0] Serialized:", result:sub(1, 100) .. "...")
	end
	return result
end

-- Собрать детальные данные о талантах (с TalentLink, спеллами и иконками)
function RaiderCheck:CollectDetailedTalentsData()
	-- Используем новую систему сериализации v4.0
	return self:SerializeTalentsData()
end

-- Получить TalentLink для таланта (прямая ссылка на талант в гриде)
function RaiderCheck:GetTalentLinkData(tabIndex, talentIndex)
	-- GetTalentLink берёт 2 параметра в WoW 3.3.5
	local talentLink = GetTalentLink(tabIndex, talentIndex)

	-- Также получаем информацию о таланте (tier=row, column, rank)
	local name, icon, tier, column, rank = GetTalentInfo(tabIndex, talentIndex)

	-- Возвращаем объект с полной информацией
	return {
		talentLink = talentLink,
		name = name,
		icon = icon,
		tier = tier,
		column = column,
		rank = rank,
		tabIndex = tabIndex,
		talentIndex = talentIndex,
	}
end

-- Получить spellID таланта через UI фреймы PlayerTalentFrame
-- Структура: PlayerTalentFramePanel[tabIndex]Talent[talentIndex]["spellID"]
function RaiderCheck:GetTalentSpellIDFromUI(tabIndex, talentIndex)
	if not tabIndex or not talentIndex then
		return 0
	end

	local frameName = "PlayerTalentFramePanel" .. tabIndex .. "Talent" .. talentIndex
	local talentFrame = _G[frameName]

	if talentFrame and talentFrame.spellID then
		return talentFrame.spellID
	end

	return 0
end

-- Получить полный набор данных таланта (включая spellID из UI фреймов если доступно)
function RaiderCheck:GetTalentDataWithSpellID(tabIndex, talentIndex)
	local name, icon, tier, column, rank = GetTalentInfo(tabIndex, talentIndex)

	-- Пытаемся получить spellID из UI фреймов
	local spellID = self:GetTalentSpellIDFromUI(tabIndex, talentIndex)

	return {
		name = name,
		icon = icon,
		tier = tier,
		column = column,
		rank = rank,
		spellID = spellID,
		tabIndex = tabIndex,
		talentIndex = talentIndex,
	}
end

-- Получить иконку таланта через спеллID
function RaiderCheck:GetTalentIcon(spellID)
	if not spellID or spellID == 0 then
		return nil
	end

	local _, _, icon = GetSpellInfo(spellID)
	return icon
end

-- Парсинг данных о талантах
function RaiderCheck:ParseTalents(data)
	local talents = {}

	if not data or data == "" then
		return talents
	end

	local index = 1
	for points in data:gmatch("[^,]+") do
		talents[index] = tonumber(points) or 0
		index = index + 1
	end

	return talents
end

-- Определить основную специализацию
function RaiderCheck:GetMainSpec(talents)
	if not talents or #talents < 3 then
		return 0, "Неизвестно"
	end

	local maxPoints = 0
	local mainSpec = 0

	for i = 1, 3 do
		local points = talents[i] or 0
		if points > maxPoints then
			maxPoints = points
			mainSpec = i
		end
	end

	return mainSpec, maxPoints
end

-- Получить название специализации по классу и номеру дерева
function RaiderCheck:GetSpecName(className, specIndex)
	local specNames = {
		["WARRIOR"] = { "Оружие", "Неистовство", "Защита" },
		["PALADIN"] = { "Свет", "Защита", "Возмездие" },
		["HUNTER"] = { "Чувство зверя", "Стрельба", "Выживание" },
		["ROGUE"] = { "Ликвидация", "Бой", "Скрытность" },
		["PRIEST"] = { "Послушание", "Свет", "Тьма" },
		["DEATHKNIGHT"] = { "Кровь", "Лед", "Нечестивость" },
		["SHAMAN"] = { "Стихии", "Совершенствование", "Исцеление" },
		["MAGE"] = { "Тайная магия", "Огонь", "Лед" },
		["WARLOCK"] = { "Колдовство", "Демонология", "Разрушение" },
		["DRUID"] = { "Баланс", "Сила зверя", "Исцеление" },
	}

	if not className or not specIndex then
		return "Неизвестно"
	end

	local specs = specNames[className]
	if not specs or not specs[specIndex] then
		return "Неизвестно"
	end

	return specs[specIndex]
end

-- Получить распределение талантов в формате "X/Y/Z"
function RaiderCheck:GetTalentDistribution(talents)
	if not talents then
		return "0/0/0"
	end

	return string.format("%d/%d/%d", talents[1] or 0, talents[2] or 0, talents[3] or 0)
end

-- Анализ талантов игрока
function RaiderCheck:AnalyzePlayerTalents(playerName)
	local playerData = self.playerData[playerName]

	if not playerData or not playerData.talentsSimple then
		return {
			hasData = false,
			mainSpec = 0,
			specName = "Неизвестно",
			distribution = "0/0/0",
			totalPoints = 0,
		}
	end

	local talents = playerData.talentsSimple
	local mainSpec, maxPoints = self:GetMainSpec(talents)

	-- Получаем класс игрока
	local className = self:GetPlayerClass(playerName)
	local specName = self:GetSpecName(className, mainSpec)
	local distribution = self:GetTalentDistribution(talents)

	local totalPoints = 0
	for i = 1, 3 do
		totalPoints = totalPoints + (talents[i] or 0)
	end

	return {
		hasData = true,
		mainSpec = mainSpec,
		specName = specName,
		distribution = distribution,
		totalPoints = totalPoints,
		talents = talents,
	}
end

-- Получить класс игрока по имени
function RaiderCheck:GetPlayerClass(playerName)
	-- Проверяем в группе/рейде (WoW 3.3.5)
	local numRaid = GetNumRaidMembers()
	local numParty = GetNumPartyMembers()

	if numRaid > 0 then
		-- В рейде
		for i = 1, numRaid do
			local name, _, _, _, className = GetRaidRosterInfo(i)
			if name == playerName then
				return className
			end
		end
	else
		-- В группе или соло
		if playerName == UnitName("player") then
			local _, className = UnitClass("player")
			return className
		end

		for i = 1, numParty do
			local unit = "party" .. i
			if UnitName(unit) == playerName then
				local _, className = UnitClass(unit)
				return className
			end
		end
	end

	return nil
end

-- Проверить, является ли специализация подходящей для роли
function RaiderCheck:IsSpecForRole(className, specIndex, role)
	local roleSpecs = {
		["TANK"] = {
			["WARRIOR"] = { 3 }, -- Защита
			["PALADIN"] = { 2 }, -- Защита
			["DEATHKNIGHT"] = { 1, 2 }, -- Кровь, Лед
			["DRUID"] = { 2 }, -- Сила зверя (танк)
		},
		["HEALER"] = {
			["PALADIN"] = { 1 }, -- Свет
			["PRIEST"] = { 1, 2 }, -- Послушание, Свет
			["SHAMAN"] = { 3 }, -- Исцеление
			["DRUID"] = { 3 }, -- Исцеление
		},
		["DPS"] = {
			-- Все остальные комбинации
		},
	}

	if not role or not className or not specIndex then
		return false
	end

	local specs = roleSpecs[role]
	if not specs or not specs[className] then
		return role == "DPS" -- Если не указано, считаем DPS
	end

	for _, validSpec in ipairs(specs[className]) do
		if validSpec == specIndex then
			return true
		end
	end

	return false
end

-- Сообщение об успешной загрузке модуля
print("|cFF00FF00RaiderCheck Talents:|r Модуль загружен успешно (v5.0 - Database-based)")

-- Десериализовать данные о талантах из формата v5.0
-- Формат: tree1|tree2|tree3
-- где tree = idx~rank,idx~rank,idx~rank,...
-- Пример: "1~0,2~0,3~5|1~1,2~0|1~0,2~0"
-- Остальные данные (tier, column, icon, name) берём из TalentsDatabase.lua
function RaiderCheck:DeserializeTalentsData(data)
	local talents = {}

	if not data or data == "" then
		return talents
	end

	local tabIndex = 1
	for tabData in data:gmatch("[^|]+") do
		talents[tabIndex] = {}
		local treeCount = 0

		if tabData ~= "" then
			for talentInfo in tabData:gmatch("[^,]+") do
				-- Парсим v5.0 (idx~rank)
				local talentIndex, rank = talentInfo:match("(%d+)~(%d+)")

				if talentIndex and rank then
					local tierNum = tonumber(tier)
					local columnNum = tonumber(column)
					local talentIdxNum = tonumber(talentIndex)
					local rankNum = tonumber(rank) or 0
					local spellIDNum = tonumber(spellID) or 0

					-- Декодируем talentLink (если был передан)
					local decodedLink = nil
					if encodedLink and encodedLink ~= "" then
						decodedLink = self:DecodeTalentLink(encodedLink)
					end

					-- Передаём ВСЕ таланты, чтобы показать полное древо
					-- Даже если tier=0 (пустой слот) или rank=0 (неучённый талант)
					talents[tabIndex][talentIdxNum] = {
						tier = tierNum,
						column = columnNum,
						talentIndex = talentIdxNum,
						rank = rankNum,
						spellID = spellIDNum,
						talentLink = decodedLink,
					}
					treeCount = treeCount + 1
				end
			end
		end

		if RaiderCheck and RaiderCheck.debugTalents then
			print(string.format("DeserializeTalentsData Tree %d: %d talents", tabIndex, treeCount))
		end

		tabIndex = tabIndex + 1
	end

	if RaiderCheck and RaiderCheck.debugTalents then
		print("DeserializeTalentsData total trees:", tabIndex - 1)
	end

	return talents
end

-- Парсить детальные данные о талантах (v4.0 формат)
function RaiderCheck:ParseDetailedTalents(data)
	if not data or data == "" then
		return {}
	end

	return self:DeserializeTalentsData(data)
end
