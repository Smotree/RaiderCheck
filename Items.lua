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

-- Старые массивы камней удалены, используется GemsEnchantMapping.lua

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

-- Проверка, является ли ID настоящим камнем (а не зачарованием)
local function IsValidGemID(gemID)
	if not gemID or gemID == 0 then
		return false
	end

	-- Получаем информацию о предмете
	local itemName, itemLink, itemQuality, itemLevel, _, itemType, itemSubType = GetItemInfo(gemID)

	-- Проверяем что это камень
	if not itemName then
		return false -- Предмет не существует
	end

	if itemType ~= "Самоцветы" then
		return false -- Не камень
	end

	if not itemLevel or itemLevel <= 1 then
		return false -- Зачарования имеют ilvl = 0 или 1
	end

	-- Дополнительная проверка: камни должны иметь цвет
	local validColors = {
		["Красные"] = true,
		["Синие"] = true,
		["Желтые"] = true,
		["Оранжевые"] = true,
		["Зеленые"] = true,
		["Фиолетовые"] = true,
		["Мета"] = true,
		["Призматические"] = true,
	}

	if itemSubType and not validColors[itemSubType] then
		return false -- Неизвестный цвет
	end

	return true
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

	-- Получаем реальное количество сокетов через Socket API
	SocketInventoryItem(slotId)
	totalSockets = GetNumSockets() or 0

	-- Получаем item ID каждого вставленного камня через Socket API
	for i = 1, totalSockets do
		local gemLink = GetExistingSocketLink(i)
		if gemLink then
			-- Парсим gemLink: |Hitem:itemId:0:0:0:0:0:0:0:80[Name]
			local parts = { strsplit(":", gemLink) }
			-- parts[1] = "|Hitem", parts[2] = item ID камня
			local gemItemId = parts[2]
			if gemItemId and gemItemId ~= "" and gemItemId ~= "0" then
				local gemItemIdNum = tonumber(gemItemId)
				if gemItemIdNum then
					table.insert(gemIds, gemItemIdNum)
				end
			end
		end
	end

	CloseSocketInfo()

	return gemIds, totalSockets
end -- Парсинг данных о предметах
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

-- Проверить, может ли предмет быть зачарован
function RaiderCheck:CanItemBeEnchanted(itemId)
	if not itemId then
		return false
	end

	-- Получаем информацию о предмете
	local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture =
		GetItemInfo(itemId)

	if not itemType or not itemSubType then
		return true -- По умолчанию считаем, что может быть зачарован
	end

	-- Предметы, которые НЕ могут быть зачарованы
	local nonEnchantableSubTypes = {
		-- Реликвии (Relics)
		["Идолы"] = true,
		["Идол"] = true,
		["Idols"] = true,
		["Idol"] = true,

		["Либрамы"] = true,
		["Либрам"] = true,
		["Librams"] = true,
		["Libram"] = true,

		["Тотемы"] = true,
		["Тотем"] = true,
		["Totems"] = true,
		["Totem"] = true,

		["Символы"] = true,
		["Символ"] = true,
		["Sigils"] = true,
		["Sigil"] = true,

		-- Манускрипты и другие левые руки, не являющиеся оружием
		["Разное"] = true,
		["Miscellaneous"] = true,
	}

	-- Проверяем подтип
	if nonEnchantableSubTypes[itemSubType] then
		return false
	end

	-- Дополнительная проверка для левой руки - если это не щит и не оружие
	if itemEquipLoc == "INVTYPE_HOLDABLE" then
		-- Это "левая рука" (манускрипты и т.д.) - не зачаровываются
		return false
	end

	return true
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

	-- Проверяем вторую руку только если есть предмет И он может быть зачарован
	if playerData and playerData.items then
		local secondarySlot = GetInventorySlotInfo("SecondaryHandSlot")
		if playerData.items[secondarySlot] and playerData.items[secondarySlot].itemId then
			-- Проверяем, может ли этот предмет быть зачарован
			if self:CanItemBeEnchanted(playerData.items[secondarySlot].itemId) then
				table.insert(slots, secondarySlot)
			end
		end

		-- Проверяем дальнее оружие только если это не идол/тотем/либрам
		local rangedSlot = GetInventorySlotInfo("RangedSlot")
		if playerData.items[rangedSlot] and playerData.items[rangedSlot].itemId then
			-- Получаем информацию о предмете
			local _, _, _, _, _, _, itemSubType = GetItemInfo(playerData.items[rangedSlot].itemId)
			-- Проверяем что это оружие (луки, арбалеты, ружья, метательное), а не реликвии
			if
				itemSubType
				and (itemSubType == "Bows" or itemSubType == "Crossbows" or itemSubType == "Guns" or itemSubType == "Thrown" or itemSubType == "Wands" or itemSubType == "Луки" or itemSubType == "Арбалеты" or itemSubType == "Огнестрельное оружие" or itemSubType == "Метательное оружие" or itemSubType == "Жезлы")
				-- Исключаем реликвии (идолы, тотемы, либрамы, печати)
				and itemSubType ~= "Idols"
				and itemSubType ~= "Totems"
				and itemSubType ~= "Librams"
				and itemSubType ~= "Sigils"
				and itemSubType ~= "Идолы"
				and itemSubType ~= "Тотемы"
				and itemSubType ~= "Либрамы"
				and itemSubType ~= "Символы смерти"
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
			outdatedGems = {},
			bcGemsCount = 0,
			wotlkGemsCount = 0,
			rbcGemsCount = 0,
			lowQualityGems = {},
			lowQualityGemsCount = 0,
		}
	end

	local missingEnchants = self:GetMissingEnchants(playerData)
	local emptySockets = self:GetEmptySockets(playerData)
	local enchantableSlots = self:GetEnchantableSlots(playerData)
	local enchantCount = #enchantableSlots - #missingEnchants
	local lowQualityGems, lowQualityGemsCount = self:CheckGemQuality(playerData)

	return {
		hasData = true,
		missingEnchants = missingEnchants,
		emptySockets = emptySockets,
		enchantCount = enchantCount,
		totalSlots = #enchantableSlots,
		lowQualityGems = lowQualityGems,
		lowQualityGemsCount = lowQualityGemsCount,
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

	-- Специальная проверка для пояса - он должен иметь хотя бы 1 сокет (поясная пряжка)
	local waistSlot = GetInventorySlotInfo("WaistSlot")
	if playerData.items[waistSlot] then
		local beltItem = playerData.items[waistSlot]
		if not beltItem.totalSockets or beltItem.totalSockets == 0 then
			-- У пояса нет сокета - нет поясной пряжки
			table.insert(emptySockets, {
				slotId = waistSlot,
				slotName = self:GetSlotName(waistSlot),
				emptyCount = 1,
				totalSockets = 0,
				itemLink = beltItem.itemLink,
				isBeltWithoutBuckle = true, -- Флаг для специального сообщения
			})
		end
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

-- Функция CheckOutdatedGems удалена, используется CheckGemQuality с настройками

-- Проверить качество камней согласно настройкам
-- ВАЖНО: проверяются реальные GEM_ID (item ID камня), а не enchant ID!
-- Система приоритетов: БК=1, ЛК=2, РБК=3, РБК+=4, НРБК=5, ННРБК=6, Донатные=7
-- Камень считается плохим если его приоритет НИЖЕ минимального (gemPriority < minPriority)
function RaiderCheck:CheckGemQuality(playerData)
	local lowQualityGems = {}
	local lowQualityCount = 0

	if not playerData or not playerData.items then
		return lowQualityGems, lowQualityCount
	end

	-- Если настройки не инициализированы или нет маппинга, пропускаем проверку
	if not self.gemSettings or not RaiderCheck_GemItemToType then
		print(
			"|cFFFF0000RaiderCheck Debug:|r Настройки камней или маппинг не загружены"
		)
		return lowQualityGems, lowQualityCount
	end

	local minQuality = self:GetMinGemQuality()
	local minPriority = self:GetGemPriorityValue(minQuality)

	print(
		"|cFF00FF00RaiderCheck Debug:|r Минимальное качество:",
		minQuality,
		"приоритет:",
		minPriority
	)

	-- Проверяем все предметы на наличие камней
	for slotId, itemInfo in pairs(playerData.items) do
		if itemInfo.gems and #itemInfo.gems > 0 then
			local lowQualityGemsInItem = {}

			for _, gemId in ipairs(itemInfo.gems) do
				local gemIdNum = tonumber(gemId)

				if gemIdNum then
					-- Получаем тип камня через маппинг item_id -> gem_type
					local gemType = RaiderCheck_GetGemTypeFromItemId(gemIdNum)

					if gemType then
						-- Получаем приоритет камня
						local gemPriority = RaiderCheck_GetGemPriorityFromItemId(gemIdNum)

						-- Проверяем соответствует ли камень требованиям (больший приоритет = лучше)
						if gemPriority and gemPriority < minPriority then
							lowQualityCount = lowQualityCount + 1

							table.insert(lowQualityGemsInItem, {
								id = gemIdNum,
								type = gemType,
								priority = gemPriority,
							})
						end
					else
						-- Камень не найден в маппинге - логируем ошибку
						print("|cFFFF0000RaiderCheck:|r Неизвестный самоцвет ID: " .. gemIdNum)
						if itemInfo.itemLink then
							print("  В предмете: " .. itemInfo.itemLink)
						end
					end
				end
			end

			if #lowQualityGemsInItem > 0 then
				table.insert(lowQualityGems, {
					slotId = slotId,
					slotName = self:GetSlotName(slotId),
					gems = lowQualityGemsInItem,
					itemLink = itemInfo.itemLink,
				})
			end
		end
	end
	if lowQualityCount > 0 then
		print(
			"|cFFFF0000RaiderCheck Debug:|r Найдено низкокачественных камней:",
			lowQualityCount
		)
	end
	return lowQualityGems, lowQualityCount
end

-- Сообщение об успешной загрузке модуля
print("|cFF00FF00RaiderCheck Items:|r Модуль загружен успешно")
