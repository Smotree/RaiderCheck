-- RaiderCheck Data Constants
-- Single source of truth for slot lists, class rules, enchant rules, gem priorities

local _, RC = ...
RC.Data = RC.Data or {}
RC.Data.Constants = {}
local C = RC.Data.Constants

-- ============================================
-- VERSION
-- ============================================
C.VERSION = "2.0.0"
C.ADDON_PREFIX = "RaiderCheck"

-- ============================================
-- MESSAGE TYPES FOR COMMUNICATION
-- ============================================
C.MSG = {
	PING = "PING",
	PONG = "PONG",
	REQUEST = "REQUEST",
	ITEMS1 = "ITEMS1",
	ITEMS2 = "ITEMS2",
	ITEMS3 = "ITEMS3",
	TALENTS = "TALENTS",
	PROFESSIONS = "PROFESSIONS",
	UPDATE = "UPDATE",
}

-- ============================================
-- TIMING CONSTANTS
-- ============================================
C.SCAN_COOLDOWN = 30
C.UPDATE_DEBOUNCE_TIME = 3
C.CACHE_EXPIRE_TIME = 300

-- ============================================
-- INVENTORY SLOTS
-- ============================================
C.INVENTORY_SLOTS = {
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

-- Slots that can be enchanted by default
C.ENCHANTABLE_SLOTS = {
	"HeadSlot",
	"ShoulderSlot",
	"BackSlot",
	"ChestSlot",
	"WristSlot",
	"HandsSlot",
	"LegsSlot",
	"FeetSlot",
	"MainHandSlot",
}

-- Slot ID to name mapping (localized RU)
C.SLOT_NAMES = {
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

-- ============================================
-- NON-ENCHANTABLE SUBTYPES (relics, etc)
-- ============================================
C.NON_ENCHANTABLE_SUBTYPES = {
	-- Idols (Druid)
	["Идолы"] = true,
	["Идол"] = true,
	["Idols"] = true,
	["Idol"] = true,
	-- Librams (Paladin)
	["Либрамы"] = true,
	["Либрам"] = true,
	["Librams"] = true,
	["Libram"] = true,
	-- Totems (Shaman)
	["Тотемы"] = true,
	["Тотем"] = true,
	["Totems"] = true,
	["Totem"] = true,
	-- Sigils (Death Knight)
	["Символы"] = true,
	["Символ"] = true,
	["Sigils"] = true,
	["Sigil"] = true,
	-- Miscellaneous (off-hand manuscripts)
	["Разное"] = true,
	["Miscellaneous"] = true,
}

-- Ranged weapons that cannot be enchanted
C.RANGED_NON_ENCHANTABLE = {
	"Wands",
	"Wand",
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

-- Ranged weapons that are OPTIONAL for non-hunters (bows, crossbows, guns)
C.RANGED_OPTIONAL = {
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

-- ============================================
-- PROFESSION ENCHANT IDS
-- ============================================

-- Fur Lining for Leatherworkers (wrist enchants)
C.LEATHERWORKING_ENCHANTS = {
	[3756] = true, -- +130 attack power
	[3757] = true, -- +102 stamina
	[3758] = true, -- +76 spell power
	[3759] = true, -- +70 fire resist
	[3760] = true, -- +70 frost resist
	[3761] = true, -- +70 shadow resist
	[3762] = true, -- +70 nature resist
	[3763] = true, -- +70 arcane resist
}

-- Engineering enchants (gloves, belt, boots)
C.ENGINEERING_ENCHANTS = {
	gloves = {
		[3604] = true, -- Hyperspeed Accelerators
		[3603] = true, -- Hand-Mounted Pyro Rocket
		[3860] = true, -- +885 armor
	},
	belt = {
		[3601] = true, -- Frag Belt
	},
	boots = {
		[3606] = true, -- +24 crit rating
	},
}

-- Master's Inscription for Scribes (shoulder enchants)
C.INSCRIPTION_ENCHANTS = {
	[3835] = true, -- +120 AP and +15 crit
	[3836] = true, -- +70 SP and +8 mp5
	[3837] = true, -- +60 dodge and +15 defense
	[3838] = true, -- +70 SP and +15 crit
}

-- Embroidery for Tailors (cloak enchants)
C.TAILORING_ENCHANTS = {
	[3728] = true, -- Darkglow Embroidery
	[3722] = true, -- Lightweave Embroidery
	[3730] = true, -- Swordguard Embroidery
}

-- ============================================
-- JEWELCRAFTING GEMS (Dragon's Eye)
-- ============================================
C.JEWELCRAFTING_GEMS = {
	[42142] = true, -- Bold Dragon's Eye (Str)
	[42143] = true, -- Delicate Dragon's Eye (Agi)
	[42144] = true, -- Brilliant Dragon's Eye (Int)
	[42145] = true, -- Subtle Dragon's Eye (Dodge)
	[42146] = true, -- Flashing Dragon's Eye (Parry)
	[42148] = true, -- Smooth Dragon's Eye (Crit)
	[42149] = true, -- Rigid Dragon's Eye (Hit)
	[42150] = true, -- Thick Dragon's Eye (Def)
	[42151] = true, -- Mystic Dragon's Eye (Resilience)
	[42152] = true, -- Quick Dragon's Eye (Haste)
	[42153] = true, -- Sovereign Dragon's Eye
	[42154] = true, -- Shifting Dragon's Eye
	[42155] = true, -- Glinting Dragon's Eye
	[42156] = true, -- Solid Dragon's Eye (Stam)
	[42157] = true, -- Sparkling Dragon's Eye (Spirit)
	[42158] = true, -- Stormy Dragon's Eye (SP Pen)
	[36767] = true, -- Scarlet Commander's Star (Agi/Crit)
}

-- ============================================
-- GEM QUALITY PRIORITIES
-- Higher = better quality
-- ============================================
C.GEM_PRIORITIES = {
	["БК"] = 1, -- Burning Crusade (outdated)
	["ЛК"] = 2, -- Lich King (WotLK base)
	["РБК"] = 3, -- RBK (Sirus custom tier 1)
	["РБК+"] = 4, -- RBK+ (Sirus custom tier 2)
	["НРБК"] = 5, -- NRBK (Sirus custom tier 3)
	["ННРБК"] = 6, -- NNRBK (Sirus custom tier 4)
	["Донатные"] = 7, -- Donation gems (best)
}

C.GEM_PRIORITY_ORDER = { "БК", "ЛК", "РБК", "РБК+", "НРБК", "ННРБК", "Донатные" }

-- Default minimum gem quality
C.DEFAULT_MIN_GEM_QUALITY = "ЛК"

-- ============================================
-- SPEC NAMES BY CLASS
-- ============================================
C.SPEC_NAMES = {
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

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Get slot name by ID
function C.GetSlotName(slotId)
	return C.SLOT_NAMES[slotId] or ("Слот #" .. tostring(slotId))
end

-- Get spec name by class and index
function C.GetSpecName(className, specIndex)
	if not className or not specIndex then
		return "Неизвестно"
	end
	local specs = C.SPEC_NAMES[className]
	if not specs or not specs[specIndex] then
		return "Неизвестно"
	end
	return specs[specIndex]
end

-- Get gem priority value by type name
function C.GetGemPriorityValue(gemType)
	return C.GEM_PRIORITIES[gemType] or 0
end

-- Check if subtype matches any in a list
function C.MatchesSubtype(subtype, subtypeList)
	if not subtype then
		return false
	end
	for _, v in ipairs(subtypeList) do
		if subtype == v or string.find(subtype, v, 1, true) then
			return true
		end
	end
	return false
end

-- Check if subtype is non-enchantable
function C.IsNonEnchantableSubtype(subtype)
	return C.NON_ENCHANTABLE_SUBTYPES[subtype] or false
end

return C
