-- RaiderCheck Items Module
-- Модуль для сбора и анализа информации о предметах

-- ============================================
-- КЭШИРОВАНИЕ
-- ============================================

-- Кэш для GetItemStats (дорогая операция)
local itemStatsCache = {}
local CACHE_EXPIRE_TIME = 300 -- 5 минут

local function GetCachedItemStats(itemLink)
	if not itemLink then
		return nil
	end

	local cached = itemStatsCache[itemLink]
	if cached and (GetTime() - cached.time) < CACHE_EXPIRE_TIME then
		return cached.stats
	end

	local stats = GetItemStats and GetItemStats(itemLink) or nil
	itemStatsCache[itemLink] = {
		stats = stats,
		time = GetTime(),
	}
	return stats
end

-- Очистка устаревшего кэша (вызывать периодически)
local function CleanupItemStatsCache()
	local now = GetTime()
	for link, data in pairs(itemStatsCache) do
		if (now - data.time) > CACHE_EXPIRE_TIME then
			itemStatsCache[link] = nil
		end
	end
end

-- Подсчёт сокетов из статов предмета (убираем дублирование кода)
local function CountSocketsFromStats(stats)
	if not stats then
		return 0
	end
	return (stats["EMPTY_SOCKET_RED"] or 0)
		+ (stats["EMPTY_SOCKET_YELLOW"] or 0)
		+ (stats["EMPTY_SOCKET_BLUE"] or 0)
		+ (stats["EMPTY_SOCKET_META"] or 0)
		+ (stats["EMPTY_SOCKET_PRISMATIC"] or 0)
		+ (stats["EMPTY_SOCKET_DOMINATION"] or 0)
		+ (stats["EMPTY_SOCKET_PRIMORDIAL"] or 0)
end

-- ============================================
-- КОНСТАНТЫ
-- ============================================

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

-- Dragon's Eye камни для ювелиров (WotLK)
local JEWELCRAFTING_GEMS = {
	-- Стандартные Dragon's Eye
	42142, -- Bold Dragon's Eye (Str)
	42143, -- Delicate Dragon's Eye (Agi)
	42144, -- Brilliant Dragon's Eye (Int)
	42145, -- Subtle Dragon's Eye (Dodge)
	42146, -- Flashing Dragon's Eye (Parry)
	42148, -- Smooth Dragon's Eye (Crit)
	42149, -- Rigid Dragon's Eye (Hit)
	42150, -- Thick Dragon's Eye (Def)
	42151, -- Mystic Dragon's Eye (Resilience)
	42152, -- Quick Dragon's Eye (Haste)
	42153, -- Sovereign Dragon's Eye
	42154, -- Shifting Dragon's Eye
	42155, -- Glinting Dragon's Eye
	42156, -- Solid Dragon's Eye (Stam)
	42157, -- Sparkling Dragon's Eye (Spirit)
	42158, -- Stormy Dragon's Eye (SP Pen)
	36767, -- Scarlet Commander's Star (Agi/Crit)
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
			local parsed = self:ParseItemLink(itemLink)
			if parsed == nil then
				return
			end
			local enchantId = parsed.enchant or "0"
			local itemId = parsed.itemId or "0"
			local gemIds = parsed.gems or {}
			local totalSockets = parsed.totalSockets or 0

			-- Формат: slotId:itemId:enchantId:totalSockets:gem1,gem2,gem3:itemLink
			-- itemLink кодируем чтобы избежать проблем с разделителями
			local encodedLink = itemLink:gsub(":", "~")

			table.insert(
				itemsData,
				string.format(
					"%d:%s:%s:%d:%s:%s",
					slotId,
					tostring(itemId),
					tostring(enchantId),
					totalSockets,
					(#gemIds > 0) and table.concat(gemIds, ",") or "0",
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
	local parsed = self:ParseItemLink(itemLink)
	if parsed and parsed.enchant and parsed.enchant ~= "0" then
		return tostring(parsed.enchant)
	end
	return nil
end

-- Получить ID предмета из ссылки
function RaiderCheck:GetItemId(itemLink)
	if not itemLink then
		return nil
	end

	local parsed = self:ParseItemLink(itemLink)
	return parsed and parsed.itemId or nil
end

-- Helper: split string by separator
-- Parse an item link into fields: itemId, enchant, gems array, linkLevel
function RaiderCheck:ParseItemLink(itemLink)
	if not itemLink then
		return nil
	end
	-- item link format: |Hitem:itemId:enchantId:gem1:gem2:gem3:gem4:suffixId:uniqueId:linkLevel|h[name]|h
	local itemString = itemLink:match("|Hitem:([-%d:]+)")
	if not itemString then
		return nil
	end
	local parts = {}
	for part in string.gmatch(itemString, "[^:]+") do
		table.insert(parts, part)
	end

	local parsed = {}
	parsed.itemId = tonumber(parts[1])
	parsed.enchant = parts[2] and tonumber(parts[2]) or nil
	parsed.gems = {}
	for i = 3, 6 do
		if parts[i] and parts[i] ~= "0" and parts[i] ~= "" then
			local n = tonumber(parts[i])
			if n then
				table.insert(parsed.gems, n)
			end
		end
	end
	parsed.suffixId = parts[7] and tonumber(parts[7]) or nil
	parsed.uniqueId = parts[8] and tonumber(parts[8]) or nil
	parsed.linkLevel = parts[9] and tonumber(parts[9]) or nil

	-- safe socket count via GetItemStats (используем кэш)
	local stats = GetCachedItemStats(itemLink)
	parsed.totalSockets = CountSocketsFromStats(stats)

	return parsed
end

-- Получить ID камней в предмете и общее количество сокетов
function RaiderCheck:GetGemIds(slotId, itemLink)
	local gemIds = {}
	local totalSockets = 0

	if not itemLink then
		itemLink = GetInventoryItemLink("player", slotId)
	end

	if not itemLink then
		return gemIds, totalSockets
	end
	-- Use GetItemGem(itemLink, index) for equipped items — non-intrusive and reliable
	for i = 1, 3 do
		local gemName, gemLink = GetItemGem(itemLink, i)
		if gemLink and gemLink ~= "" then
			local gParsed = self:ParseItemLink(gemLink)
			if gParsed and gParsed.itemId then
				table.insert(gemIds, gParsed.itemId)
			end
		end
	end

	-- total sockets from item stats (используем кэш)
	local stats = GetCachedItemStats(itemLink)
	totalSockets = CountSocketsFromStats(stats)
	if totalSockets == 0 then
		local parsed = self:ParseItemLink(itemLink)
		totalSockets = parsed and parsed.totalSockets or 0
	end

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

			---@diagnostic disable-next-line: need-check-nil
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
function RaiderCheck:GetEnchantableSlots(playerData, playerName)
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

		-- Проверяем дальнее оружие только если это не реликвия и зачарование требуется
		local rangedSlot = GetInventorySlotInfo("RangedSlot")
		if playerData.items[rangedSlot] and playerData.items[rangedSlot].itemId then
			-- Получаем информацию о предмете
			local _, _, _, _, _, itemType, itemSubType = GetItemInfo(playerData.items[rangedSlot].itemId)
			local className = playerName and self:GetPlayerClass(playerName)

			local function matches(sub, variants)
				if not sub then
					return false
				end
				for _, v in ipairs(variants) do
					if sub == v or string.find(sub, v, 1, true) then
						return true
					end
				end
				return false
			end

			local nonEnchantableSubs = {
				"Wands",
				"Thrown",
				"Idol",
				"Idols",
				"Libram",
				"Librams",
				"Sigil",
				"Sigils",
				"Totem",
				"Totems",
				"Relic",
				"Жезл",
				"Жезлы",
				"Метательное",
				"Метательное оружие",
				"Идол",
				"Идолы",
				"Манускрипт",
				"Манускрипты",
				"Печать",
				"Печати",
			}

			local optionalRangedSubs = {
				"Bow",
				"Bows",
				"Crossbow",
				"Crossbows",
				"Gun",
				"Guns",
				"Лук",
				"Луки",
				"Арбалет",
				"Арбалеты",
				"Огнестрельное",
				"Огнестрельное оружие",
			}

			if matches(itemSubType, nonEnchantableSubs) then
				-- не зачаровывается
			elseif matches(itemSubType, optionalRangedSubs) then
				-- для охотников обязательно, для остальных опционально (не считаем незачарованным)
				if className == "HUNTER" then
					table.insert(slots, rangedSlot)
				end
			else
				-- прочие (например, метательное, жезлы) уже отфильтрованы; сюда могут попасть спец-случаи оружия дальнего боя
				-- по умолчанию учитываем только если CanItemBeEnchanted говорит да
				if self:CanItemBeEnchanted(playerData.items[rangedSlot].itemId) then
					table.insert(slots, rangedSlot)
				end
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
function RaiderCheck:GetMissingEnchants(playerData, playerName)
	local missing = {}
	local enchantableSlots = self:GetEnchantableSlots(playerData, playerName)

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

	local missingEnchants = self:GetMissingEnchants(playerData, playerName)
	local emptySockets = self:GetEmptySockets(playerData)
	local enchantableSlots = self:GetEnchantableSlots(playerData, playerName)
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
		-- Если статистика не показывает сокеты, но фактически вставлен камень (через пряжку), не считаем пустым
		local hasActualGem = false
		if beltItem.itemLink then
			for i = 1, 3 do
				local _, gemLink = GetItemGem(beltItem.itemLink, i)
				if gemLink and gemLink ~= "" then
					hasActualGem = true
					break
				end
			end
		end

		if (not beltItem.totalSockets or beltItem.totalSockets == 0) and not hasActualGem then
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
			local filledSockets = 0
			-- Надежно считаем вставленные камни через GetItemGem
			if itemInfo.itemLink then
				for i = 1, 3 do
					local _, gemLink = GetItemGem(itemInfo.itemLink, i)
					if gemLink and gemLink ~= "" then
						filledSockets = filledSockets + 1
					end
				end
			else
				-- Фолбэк: используем массив gems, если ссылки нет
				if itemInfo.gems then
					filledSockets = #itemInfo.gems
				else
					filledSockets = 0
				end
			end

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
		return lowQualityGems, lowQualityCount
	end

	local minQuality = self:GetMinGemQuality()
	local minPriority = self:GetGemPriorityValue(minQuality)

	local unknownGemsFound = false

	-- Проверяем все предметы на наличие камней
	for slotId, itemInfo in pairs(playerData.items) do
		if itemInfo.itemLink then
			local lowQualityGemsInItem = {}

			-- Используем GetItemGem для получения реальных gem links из экипированных предметов
			for i = 1, 3 do
				local gemName, gemLink = GetItemGem(itemInfo.itemLink, i)
				if gemLink and gemLink ~= "" then
					-- Парсим gem link чтобы получить item ID камня
					local gParsed = self:ParseItemLink(gemLink)
					if gParsed and gParsed.itemId then
						local gemIdNum = gParsed.itemId

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
							-- Камень не найден в маппинге - добавляем в неизвестные
							if RaiderCheck_AddUnknownGem then
								local wasAdded = RaiderCheck_AddUnknownGem(
									gemIdNum,
									gemName,
									gemLink,
									self:GetSlotName(slotId),
									playerData.name
								)
								if wasAdded then
									unknownGemsFound = true
								end
							end
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

	-- Если найдены неизвестные камни - показать уведомление
	if unknownGemsFound and self.NotifyUnknownGems then
		self:NotifyUnknownGems()
	end

	return lowQualityGems, lowQualityCount
end

-- ============================================
-- GEM QUALITY SETTINGS (из GemSettings.lua)
-- ============================================

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
	return self.gemSettings and self.gemSettings.minQuality or "ЛК"
end

-- Установить минимальное требуемое качество
function RaiderCheck:SetMinGemQuality(quality)
	self.gemSettings.minQuality = quality
	RaiderCheckDB.gemSettings = self.gemSettings

	if self.frame and self.frame:IsShown() then
		self:UpdateGUI()
	end
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
		["Донатные"] = { 1.0, 0.5, 0.0 },
		["ННРБК"] = { 0.64, 0.21, 0.93 },
		["НРБК"] = { 0.0, 0.44, 0.87 },
		["РБК+"] = { 0.0, 0.8, 0.0 },
		["РБК"] = { 0.0, 0.8, 0.0 },
		["ЛК"] = { 0.0, 1.0, 0.0 },
		["БК"] = { 0.6, 0.6, 0.6 },
	}
	return colors[gemType] or { 1, 1, 1 }
end

-- Проверить соответствует ли камень требованиям
-- Возвращает: true = OK, false = низкое качество, nil = неизвестный камень
function RaiderCheck:IsGemQualityAcceptable(itemID)
	if not itemID or itemID == 0 then
		return false
	end

	-- Проверяем маппинг
	if not RaiderCheck_GetGemTypeFromItemId then
		return nil
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

-- ============================================
-- PROFESSIONS (из Professions.lua)
-- ============================================

-- Собрать данные о профессиях игрока
function RaiderCheck:CollectProfessionsData()
	local professionsData = {}
	local numSkills = GetNumSkillLines()

	for i = 1, numSkills do
		local skillName, isHeader, isExpanded, skillRank, numTempPoints, skillModifier, skillMaxRank, isAbandonable =
			GetSkillLineInfo(i)

		if skillName and not isHeader and isAbandonable and skillMaxRank and skillMaxRank > 1 then
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
		return { hasData = false, professions = {}, count = 0 }
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
