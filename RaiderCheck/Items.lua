-- RaiderCheck Items Module
-- Модуль для сбора и анализа информации о предметах

-- Специальные камни ювелиров (Dragon's Eye и Chimera's Eye)
local JEWELCRAFTING_GEMS = {
	36767, -- Runed Dragon's Eye
	42145, -- Runed Dragon's Eye (alternative)
	42146, -- Bright Dragon's Eye
	42155, -- Sparkling Dragon's Eye
	36766, -- Solid Dragon's Eye
	42142, -- Subtle Dragon's Eye
	42143, -- Flashing Dragon's Eye
	42144, -- Rigid Dragon's Eye
	42151, -- Mystic Dragon's Eye
	42152, -- Quick Dragon's Eye
	42153, -- Smooth Dragon's Eye
	42154, -- Precise Dragon's Eye
	42148, -- Thick Dragon's Eye
	42149, -- Brilliant Dragon's Eye
	42150, -- Lustrous Dragon's Eye
	42156, -- Stormy Dragon's Eye
	42157, -- Checker Dragon's Eye
	42158, -- Great Dragon's Eye
}

-- Fur Lining для кожевников (зачарования запястий)
local LEATHERWORKING_ENCHANTS = {
	3756, -- +130 к силе атаки
	3757, -- +102 к выносливости
	3758, -- +76 к силе заклинаний
	3759, -- +70 к сопротивлению огню
	3760, -- +70 к сопротивлению магии льда
	3761, -- +70 к сопротивлению темной магии
	3762, -- +70 к сопротивлению силам природы
	3763, -- +70 к сопротивлению тайной магии
}

-- Инженерные усиления (перчатки и пояс)
local ENGINEERING_ENCHANTS = {
	gloves = {
		3604, -- Гиперскоростные ускорители
		3603, -- Нарукавная зажигательная ракетница
		3860, -- +885 к броне
	},
	belt = {
		3601, -- Наременные осколочные бомбы
	},
	boots = {
		3606, -- +24 к рейтингу критического удара
	},
}

-- Master's Inscription для начертателей (зачарования плеч)
local INSCRIPTION_ENCHANTS = {
	3835, -- +120 к силе атаки и +15 к рейтингу критического эффекта
	3836, -- +70 к силе заклинаний и +8 к мане каждые 5 секунд
	3837, -- +60 к рейтингу уклонения и +15 к защите
	3838, -- +70 к силе заклинаний и +15 к рейтингу критического эффекта
}

-- Вышивка для портных (зачарования плаща)
local TAILORING_ENCHANTS = {
	3728, -- Вышивка темного сияния
	3722, -- Светлотканая вышивка
	3730, -- Вышивка в виде рукояти меча
}

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
function RaiderCheck:GetEnchantableSlots(playerData)
	local slots = {
		(GetInventorySlotInfo("HeadSlot")), -- Голова (Arcanum)
		(GetInventorySlotInfo("ShoulderSlot")), -- Плечи (Inscription)
		(GetInventorySlotInfo("BackSlot")), -- Плащ
		(GetInventorySlotInfo("ChestSlot")), -- Грудь
		(GetInventorySlotInfo("WristSlot")), -- Запястья
		(GetInventorySlotInfo("HandsSlot")), -- Руки
		(GetInventorySlotInfo("LegsSlot")), -- Ноги (Armor Kit)
		(GetInventorySlotInfo("FeetSlot")), -- Ступни
		(GetInventorySlotInfo("MainHandSlot")), -- Главная рука
	}

	-- Проверяем вторую руку только если есть предмет (не двуручное оружие)
	if playerData and playerData.items then
		local secondarySlot = GetInventorySlotInfo("SecondaryHandSlot")
		if playerData.items[secondarySlot] then
			table.insert(slots, secondarySlot)
		end

		-- Проверяем дальнее оружие только если это не идол/тотем/либрам
		local rangedSlot = GetInventorySlotInfo("RangedSlot")
		if playerData.items[rangedSlot] and playerData.items[rangedSlot].itemId then
			-- Получаем информацию о предмете
			local _, _, _, _, _, _, itemSubType = GetItemInfo(playerData.items[rangedSlot].itemId)
			-- Проверяем что это оружие (луки, арбалеты, ружья), а не реликвии
			if
				itemSubType
				and (
					itemSubType == "Bows"
					or itemSubType == "Crossbows"
					or itemSubType == "Guns"
					or itemSubType == "Луки"
					or itemSubType == "Арбалеты"
					or itemSubType == "Огнестрельное оружие"
				)
			then
				table.insert(slots, rangedSlot)
			end
		end
	end

	-- Проверяем профессии для дополнительных зачарований
	if playerData and playerData.professions then
		for _, prof in ipairs(playerData.professions) do
			-- Энчантеры должны зачаровывать кольца (требуется уровень 400+)
			if (prof.name == "Enchanting" or prof.name == "Наложение чар") and prof.rank >= 400 then
				table.insert(slots, (GetInventorySlotInfo("Finger0Slot")))
				table.insert(slots, (GetInventorySlotInfo("Finger1Slot")))
			end
		end
	end

	return slots
end -- Получить информацию о незачарованных слотах
function RaiderCheck:GetMissingEnchants(playerData)
	local missing = {}
	local enchantableSlots = self:GetEnchantableSlots(playerData)

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
	local enchantableSlots = self:GetEnchantableSlots(playerData)
	local enchantCount = #enchantableSlots - #missingEnchants

	return {
		hasData = true,
		missingEnchants = missingEnchants,
		emptySockets = emptySockets,
		enchantCount = enchantCount,
		totalSlots = #enchantableSlots,
	}
end

-- Проверить профессиональные бонусы
function RaiderCheck:CheckProfessionBonuses(playerData)
	local missing = {}

	if not playerData or not playerData.professions or not playerData.items then
		return missing
	end

	for _, prof in ipairs(playerData.professions) do
		-- Кузнецы должны иметь дополнительные сокеты на руках (Socket Bracer, Socket Gloves)
		if prof.name == "Blacksmithing" or prof.name == "Кузнечное дело" then
			local handsSlot = GetInventorySlotInfo("HandsSlot")
			local wristSlot = GetInventorySlotInfo("WristSlot")

			if
				playerData.items[handsSlot]
				and (not playerData.items[handsSlot].totalSockets or playerData.items[handsSlot].totalSockets == 0)
			then
				table.insert(missing, "Кузнец: нет сокета на руках")
			end
			if
				playerData.items[wristSlot]
				and (not playerData.items[wristSlot].totalSockets or playerData.items[wristSlot].totalSockets == 0)
			then
				table.insert(missing, "Кузнец: нет сокета на запястьях")
			end

		-- Ювелиры должны иметь специальные камни Dragon's Eye (максимум 3)
		elseif prof.name == "Jewelcrafting" or prof.name == "Ювелирное дело" then
			local dragonEyeCount = 0

			-- Проверяем все предметы на наличие Dragon's Eye камней
			for slotId, itemInfo in pairs(playerData.items) do
				if itemInfo.gems then
					for _, gemId in ipairs(itemInfo.gems) do
						local gemIdNum = tonumber(gemId)
						if gemIdNum then
							-- Проверяем, является ли камень Dragon's Eye
							for _, dragonEyeId in ipairs(JEWELCRAFTING_GEMS) do
								if gemIdNum == dragonEyeId then
									dragonEyeCount = dragonEyeCount + 1
									break
								end
							end
						end
					end
				end
			end

			-- Должно быть 3 Dragon's Eye камня
			if dragonEyeCount < 3 then
				table.insert(
					missing,
					string.format(
						"Ювелир: используется %d/3 Dragon's Eye камней",
						dragonEyeCount
					)
				)
			end

		-- Кожевники должны иметь Fur Lining на запястьях
		elseif prof.name == "Leatherworking" or prof.name == "Кожевничество" then
			local wristSlot = GetInventorySlotInfo("WristSlot")
			if playerData.items[wristSlot] then
				local enchantId = playerData.items[wristSlot].enchant
				local hasFurLining = false

				if enchantId then
					local enchantIdNum = tonumber(enchantId)
					if enchantIdNum then
						-- Проверяем, является ли зачарование Fur Lining
						for _, furLiningId in ipairs(LEATHERWORKING_ENCHANTS) do
							if enchantIdNum == furLiningId then
								hasFurLining = true
								break
							end
						end
					end
				end

				if not hasFurLining then
					table.insert(missing, "Кожевник: нет Fur Lining на запястьях")
				end
			end

		-- Инженеры должны иметь инженерные усиления (необязательно, но желательно)
		elseif prof.name == "Engineering" or prof.name == "Инженерное дело" then
			-- Проверяем перчатки
			local handsSlot = GetInventorySlotInfo("HandsSlot")
			if playerData.items[handsSlot] then
				local enchantId = playerData.items[handsSlot].enchant
				local hasEngGloves = false

				if enchantId then
					local enchantIdNum = tonumber(enchantId)
					if enchantIdNum then
						for _, engId in ipairs(ENGINEERING_ENCHANTS.gloves) do
							if enchantIdNum == engId then
								hasEngGloves = true
								break
							end
						end
					end
				end

				if not hasEngGloves then
					table.insert(
						missing,
						"Инженер: нет усиления на перчатках (опционально)"
					)
				end
			end

			-- Проверяем пояс
			local waistSlot = GetInventorySlotInfo("WaistSlot")
			if playerData.items[waistSlot] then
				local enchantId = playerData.items[waistSlot].enchant
				local hasEngBelt = false

				if enchantId then
					local enchantIdNum = tonumber(enchantId)
					if enchantIdNum then
						for _, engId in ipairs(ENGINEERING_ENCHANTS.belt) do
							if enchantIdNum == engId then
								hasEngBelt = true
								break
							end
						end
					end
				end

				if not hasEngBelt then
					table.insert(
						missing,
						"Инженер: нет усиления на поясе (опционально)"
					)
				end
			end

			-- Проверяем боты
			local feetSlot = GetInventorySlotInfo("FeetSlot")
			if playerData.items[feetSlot] then
				local enchantId = playerData.items[feetSlot].enchant
				local hasEngBoots = false

				if enchantId then
					local enchantIdNum = tonumber(enchantId)
					if enchantIdNum then
						for _, engId in ipairs(ENGINEERING_ENCHANTS.boots) do
							if enchantIdNum == engId then
								hasEngBoots = true
								break
							end
						end
					end
				end

				if not hasEngBoots then
					table.insert(
						missing,
						"Инженер: нет усиления на ботах (опционально)"
					)
				end
			end

		-- Начертатели должны иметь Master's Inscription на плечах
		elseif prof.name == "Inscription" or prof.name == "Начертание" then
			local shoulderSlot = GetInventorySlotInfo("ShoulderSlot")
			if playerData.items[shoulderSlot] then
				local enchantId = playerData.items[shoulderSlot].enchant
				local hasMasterInscription = false

				if enchantId then
					local enchantIdNum = tonumber(enchantId)
					if enchantIdNum then
						-- Проверяем, является ли зачарование Master's Inscription
						for _, inscriptionId in ipairs(INSCRIPTION_ENCHANTS) do
							if enchantIdNum == inscriptionId then
								hasMasterInscription = true
								break
							end
						end
					end
				end

				if not hasMasterInscription then
					table.insert(missing, "Начертатель: нет Master's Inscription на плечах")
				end
			end
		end

		-- Проверка вышивки для портных
		if prof.name == "Портняжное дело" then
			local backSlot = (GetInventorySlotInfo("BackSlot"))
			local backItem = playerData.items[backSlot]

			if backItem then
				local enchantId = tonumber(backItem.enchantId) or 0
				local hasEmbroidery = false

				if enchantId > 0 then
					for _, tailorEnchant in ipairs(TAILORING_ENCHANTS) do
						if enchantId == tailorEnchant then
							hasEmbroidery = true
							break
						end
					end
				end

				if not hasEmbroidery then
					table.insert(missing, "Портной: нет Вышивки на плаще")
				end
			end
		end
	end

	return missing
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
