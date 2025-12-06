-- RaiderCheck Gem Quality Settings
-- Модуль для настройки требуемого качества камней

-- Проверяем, что RaiderCheck существует
if not RaiderCheck then
	error("RaiderCheck core not loaded! Check Core.lua")
end

-- Инициализация настроек по умолчанию
function RaiderCheck:InitGemSettings()
	if not RaiderCheckDB then
		RaiderCheckDB = {}
	end

	if not RaiderCheckDB.gemSettings then
		RaiderCheckDB.gemSettings = {
			minQuality = "ЛК", -- Минимально допустимое качество (по умолчанию ЛК)
		}
	end

	-- Миграция старых настроек
	if RaiderCheckDB.gemSettings.acceptableGemTypes and not RaiderCheckDB.gemSettings.minQuality then
		-- Конвертируем из множественного выбора в минимальный порог
		local priorities = {
			["БК"] = 1,
			["ЛК"] = 2,
			["РБК"] = 3,
			["РБК+"] = 4,
			["НРБК"] = 5,
			["ННРБК"] = 6,
			["Донатные"] = 7,
		}

		local minPriority = 999
		local minType = "ЛК"

		for gemType, enabled in pairs(RaiderCheckDB.gemSettings.acceptableGemTypes) do
			if enabled and priorities[gemType] and priorities[gemType] < minPriority then
				minPriority = priorities[gemType]
				minType = gemType
			end
		end

		RaiderCheckDB.gemSettings.minQuality = minType
		RaiderCheckDB.gemSettings.acceptableGemTypes = nil
	end

	self.gemSettings = RaiderCheckDB.gemSettings
end

-- Получить минимальное требуемое качество
function RaiderCheck:GetMinGemQuality()
	return self.gemSettings.minQuality or "ЛК"
end

-- Установить минимальное требуемое качество
function RaiderCheck:SetMinGemQuality(quality)
	self.gemSettings.minQuality = quality
	RaiderCheckDB.gemSettings = self.gemSettings

	-- Обновляем GUI если открыто
	if self.frame and self.frame:IsShown() then
		self:UpdateGUI()
	end
end

-- Проверить соответствует ли камень требованиям
function RaiderCheck:IsGemQualityAcceptable(itemID)
	if not itemID or itemID == 0 then
		return false
	end

	-- Загружаем маппинг если еще не загружен
	if not RaiderCheck_GetGemTypeFromItemId then
		return nil -- Неизвестно
	end

	local gemType = RaiderCheck_GetGemTypeFromItemId(itemID)
	if not gemType then
		return nil -- Неизвестный камень
	end

	local minQuality = self:GetMinGemQuality()
	local minPriority = self:GetGemPriorityValue(minQuality)
	local gemPriority = RaiderCheck_GetGemPriorityFromItemId(itemID)

	-- Камень приемлем если его приоритет >= минимального
	return gemPriority >= minPriority
end

-- Получить числовое значение приоритета для типа
function RaiderCheck:GetGemPriorityValue(gemType)
	local priorities = {
		["Донатные"] = 7,
		["ННРБК"] = 6,
		["НРБК"] = 5,
		["РБК+"] = 4,
		["РБК"] = 3,
		["ЛК"] = 2,
		["БК"] = 1,
	}
	return priorities[gemType] or 0
end

-- Получить цвет для отображения качества камня
function RaiderCheck:GetGemQualityColor(gemType)
	local colors = {
		["Донатные"] = { 1.0, 0.5, 0.0 }, -- Оранжевый (легендарный)
		["ННРБК"] = { 0.64, 0.21, 0.93 }, -- Фиолетовый (эпик)
		["НРБК"] = { 0.0, 0.44, 0.87 }, -- Синий (редкий)
		["РБК+"] = { 0.0, 0.8, 0.0 }, -- Зеленый (необычный+)
		["РБК"] = { 0.0, 0.8, 0.0 }, -- Зеленый (необычный)
		["ЛК"] = { 0.0, 1.0, 0.0 }, -- Светло-зеленый
		["БК"] = { 0.6, 0.6, 0.6 }, -- Серый (обычный)
	}
	return colors[gemType] or { 1, 1, 1 }
end

-- Получить текстовое описание требований
function RaiderCheck:GetGemRequirementText()
	local minQuality = self:GetMinGemQuality()
	return "Минимальное качество: " .. minQuality .. " (или выше)"
end
