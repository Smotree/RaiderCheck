-- RaiderCheck Items Module
-- Модуль для сбора и анализа информации о предметах

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

-- Собрать данные о предметах игрока
function RaiderCheck:CollectItemsData()
	local itemsData = {}

	for _, slotName in ipairs(INVENTORY_SLOTS) do
		local slotId = GetInventorySlotInfo(slotName)
		local itemLink = GetInventoryItemLink("player", slotId)

		if itemLink then
			local enchantId = self:GetEnchantId(itemLink)
			local itemId = self:GetItemId(itemLink)
			local gemIds, totalSockets = self:GetGemIds(slotId, itemLink)

			-- Формат: slotId:itemId:enchantId:totalSockets:gem1,gem2,gem3:itemLink
			-- itemLink кодируем чтобы избежать проблем с разделителями
			local encodedLink = itemLink:gsub(":", "~")

			table.insert(
				itemsData,
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

	return table.concat(itemsData, ";")
end

-- Получить ID зачарования из ссылки на предмет
function RaiderCheck:GetEnchantId(itemLink)
	if not itemLink then
		return nil
	end

	-- Формат: |Hitem:itemId:enchantId:gem1:gem2:gem3:gem4:...
	local enchantId = itemLink:match("item:%d+:(%d+)")

	if enchantId and enchantId ~= "0" then
		return enchantId
	end

	return nil
end

-- Получить ID предмета из ссылки
function RaiderCheck:GetItemId(itemLink)
	if not itemLink then
		return nil
	end

	local itemId = itemLink:match("item:(%d+)")
	return itemId
end

-- Получить ID камней в предмете и общее количество сокетов
function RaiderCheck:GetGemIds(slotId, itemLink)
	local gemIds = {}
	local totalSockets = 0

	-- Получаем itemLink если не передан
	if not itemLink then
		itemLink = GetInventoryItemLink("player", slotId)
	end

	if not itemLink then
		return gemIds, totalSockets
	end

	-- Парсинг камней из itemLink
	-- Формат: |Hitem:itemId:enchantId:gem1:gem2:gem3:gem4:...
	local parts = { itemLink:match("item:(%d+):(%d+):(%d*):(%d*):(%d*):(%d*)") }

	-- Собираем ID установленных камней
	for i = 3, 6 do
		if parts[i] and parts[i] ~= "" and parts[i] ~= "0" then
			table.insert(gemIds, parts[i])
		end
	end

	-- Подсчитываем общее количество сокетов в предмете
	-- Используем GetItemGem API для точного подсчёта
	for i = 1, 4 do
		local gemName = GetItemGem(itemLink, i)
		if gemName then
			totalSockets = i
		end
	end

	return gemIds, totalSockets
end

-- Парсинг данных о предметах
function RaiderCheck:ParseItems(data)
	local items = {}

	if not data or data == "" then
		return items
	end

	for itemData in data:gmatch("[^;]+") do
		-- Формат: slotId:itemId:enchantId:totalSockets:gems:itemLink
		-- Парсим только первые 5 полей, остальное - itemLink (может содержать :)
		local slotId, itemId, enchantId, totalSockets, gemsStr, encodedLink =
			itemData:match("^(%d+):(%d+):([^:]*):(%d+):([^:]*):(.*)$")

		if slotId then
			slotId = tonumber(slotId)
			itemId = tonumber(itemId)
			totalSockets = tonumber(totalSockets) or 0
			encodedLink = encodedLink or ""

			-- Декодируем itemLink
			local itemLink = encodedLink:gsub("~", ":")

			local gems = {}
			if gemsStr and gemsStr ~= "" and gemsStr ~= "0" then
				for gemId in gemsStr:gmatch("[^,]+") do
					table.insert(gems, gemId)
				end
			end

			items[slotId] = {
				itemId = (itemId and itemId ~= 0) and itemId or nil,
				enchant = (enchantId and enchantId ~= "0") and enchantId or nil,
				gems = gems,
				totalSockets = totalSockets,
				itemLink = (itemLink ~= "") and itemLink or nil,
			}
		end
	end

	return items
end

-- Проверить, зачарован ли слот
function RaiderCheck:IsSlotEnchanted(slotId, playerData)
	if not playerData or not playerData.items then
		return false
	end

	local itemInfo = playerData.items[slotId]
	if not itemInfo then
		return false
	end

	return itemInfo.enchant ~= nil
end

-- Получить слоты, которые должны быть зачарованы
function RaiderCheck:GetEnchantableSlots()
	return {
		GetInventorySlotInfo("HeadSlot"), -- Голова (Arcanum)
		GetInventorySlotInfo("ShoulderSlot"), -- Плечи (Inscription)
		GetInventorySlotInfo("BackSlot"), -- Плащ
		GetInventorySlotInfo("ChestSlot"), -- Грудь
		GetInventorySlotInfo("WristSlot"), -- Запястья
		GetInventorySlotInfo("HandsSlot"), -- Руки
		GetInventorySlotInfo("LegsSlot"), -- Ноги (Armor Kit)
		GetInventorySlotInfo("FeetSlot"), -- Ступни
		GetInventorySlotInfo("MainHandSlot"), -- Главная рука
		-- Кольца не включаем в обязательные, так как это только для энчантеров
	}
end

-- Получить информацию о незачарованных слотах
function RaiderCheck:GetMissingEnchants(playerData)
	local missing = {}
	local enchantableSlots = self:GetEnchantableSlots()

	for _, slotId in ipairs(enchantableSlots) do
		if not self:IsSlotEnchanted(slotId, playerData) then
			local slotName = self:GetSlotName(slotId)
			table.insert(missing, slotName)
		end
	end

	return missing
end

-- Получить название слота по ID
function RaiderCheck:GetSlotName(slotId)
	if not slotId then
		return "Неизвестно"
	end

	local slotNames = {
		[1] = "Голова",
		[2] = "Шея",
		[3] = "Плечи",
		[4] = "Рубашка",
		[5] = "Грудь",
		[6] = "Пояс",
		[7] = "Ноги",
		[8] = "Ступни",
		[9] = "Запястья",
		[10] = "Руки",
		[11] = "Палец 1",
		[12] = "Палец 2",
		[13] = "Аксессуар 1",
		[14] = "Аксессуар 2",
		[15] = "Плащ",
		[16] = "Главная рука",
		[17] = "Вторая рука",
		[18] = "Дальний бой",
		[19] = "Гербовая накидка",
	}

	return slotNames[slotId] or ("Слот #" .. tostring(slotId))
end

-- Анализ снаряжения игрока
function RaiderCheck:AnalyzePlayerGear(playerName)
	local playerData = self.playerData[playerName]
	if not playerData then
		return {
			hasData = false,
			missingEnchants = {},
			emptySockets = {},
			enchantCount = 0,
			totalSlots = 0,
		}
	end

	local missingEnchants = self:GetMissingEnchants(playerData)
	local emptySockets = self:GetEmptySockets(playerData)
	local enchantableSlots = self:GetEnchantableSlots()
	local enchantCount = #enchantableSlots - #missingEnchants

	return {
		hasData = true,
		missingEnchants = missingEnchants,
		emptySockets = emptySockets,
		enchantCount = enchantCount,
		totalSlots = #enchantableSlots,
	}
end

-- Получить список предметов с пустыми сокетами
function RaiderCheck:GetEmptySockets(playerData)
	local emptySockets = {}

	if not playerData or not playerData.items then
		return emptySockets
	end

	for slotId, itemInfo in pairs(playerData.items) do
		if itemInfo.totalSockets and itemInfo.totalSockets > 0 then
			local filledSockets = #itemInfo.gems
			if filledSockets < itemInfo.totalSockets then
				local emptyCount = itemInfo.totalSockets - filledSockets
				table.insert(emptySockets, {
					slotId = slotId,
					slotName = self:GetSlotName(slotId),
					emptyCount = emptyCount,
					totalSockets = itemInfo.totalSockets,
					itemLink = itemInfo.itemLink,
				})
			end
		end
	end

	return emptySockets
end

-- Сообщение об успешной загрузке модуля
print("|cFF00FF00RaiderCheck Items:|r Модуль загружен успешно")
