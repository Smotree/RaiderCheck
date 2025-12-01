-- RaiderCheck Talents Module
-- Модуль для сбора и анализа информации о талантах

-- Собрать данные о талантах игрока
function RaiderCheck:CollectTalentsData()
	local talentsData = {}

	-- Получаем информацию о всех трех деревьях талантов
	for tabIndex = 1, 3 do
		local numTalents = GetNumTalents(tabIndex)
		local pointsSpent = 0

		for talentIndex = 1, numTalents do
			local name, iconTexture, tier, column, rank, maxRank = GetTalentInfo(tabIndex, talentIndex)
			if rank and rank > 0 then
				pointsSpent = pointsSpent + rank
			end
		end

		table.insert(talentsData, tostring(pointsSpent))
	end

	-- Формат: points_tab1,points_tab2,points_tab3
	return table.concat(talentsData, ",")
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
		if talents[i] > maxPoints then
			maxPoints = talents[i]
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
	if not talents or #talents < 3 then
		return "0/0/0"
	end

	return string.format("%d/%d/%d", talents[1] or 0, talents[2] or 0, talents[3] or 0)
end

-- Анализ талантов игрока
function RaiderCheck:AnalyzePlayerTalents(playerName)
	local playerData = self.playerData[playerName]

	if not playerData or not playerData.talents then
		return {
			hasData = false,
			mainSpec = 0,
			specName = "Неизвестно",
			distribution = "0/0/0",
			totalPoints = 0,
		}
	end

	local talents = playerData.talents
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
print("|cFF00FF00RaiderCheck Talents:|r Модуль загружен успешно")
