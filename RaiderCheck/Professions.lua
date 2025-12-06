-- RaiderCheck Professions Module
-- Модуль для сбора информации о профессиях

if not RaiderCheck then
	RaiderCheck = {}
end

-- Собрать данные о профессиях игрока
function RaiderCheck:CollectProfessionsData()
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

-- Парсинг данных о профессиях
function RaiderCheck:ParseProfessions(data)
	local professions = {}

	if not data or data == "" then
		return professions
	end

	for profData in data:gmatch("[^;]+") do
		local name, rank, maxRank = profData:match("^([^:]+):(%d+):(%d+)$")
		if name then
			table.insert(professions, {
				name = name,
				rank = tonumber(rank) or 0,
				maxRank = tonumber(maxRank) or 0,
			})
		end
	end

	return professions
end

-- Анализ профессий игрока
function RaiderCheck:AnalyzePlayerProfessions(playerName)
	local playerData = self.playerData[playerName]

	if not playerData or not playerData.professions then
		return {
			hasData = false,
			professions = {},
			count = 0,
		}
	end

	local professions = playerData.professions
	local maxedProfessions = {}

	for _, prof in ipairs(professions) do
		if prof.rank >= prof.maxRank then
			table.insert(maxedProfessions, prof.name)
		end
	end

	return {
		hasData = true,
		professions = professions,
		count = #professions,
		maxedProfessions = maxedProfessions,
	}
end

-- Проверить наличие определенной профессии
function RaiderCheck:HasProfession(playerName, professionName)
	local analysis = self:AnalyzePlayerProfessions(playerName)

	if not analysis.hasData then
		return false
	end

	for _, prof in ipairs(analysis.professions) do
		if prof.name == professionName then
			return true, prof.rank, prof.maxRank
		end
	end

	return false
end

-- Получить список важных профессий (для зачарований)
function RaiderCheck:GetImportantProfessions()
	return {
		"Enchanting", -- Наложение чар
		"Blacksmithing", -- Кузнечное дело
		"Leatherworking", -- Кожевничество
		"Tailoring", -- Портняжное дело
		"Engineering", -- Инженерное дело
		"Jewelcrafting", -- Ювелирное дело
		"Inscription", -- Начертание
	}
end

-- Сообщение об успешной загрузке модуля
print("|cFF00FF00RaiderCheck Professions:|r Модуль загружен успешно")
