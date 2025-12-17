-- RaiderCheck Core Init Module
-- Main addon initialization, events, and base functionality

local ADDON_NAME, RC = ...
RaiderCheck = RC

-- Initialize module tables
RC.Core = {}
RC.Data = RC.Data or {}
RC.Logic = RC.Logic or {}
RC.UI = RC.UI or {}

local Core = RC.Core
local C -- Will be set after constants load
local Settings -- Will be set after settings load
local Items -- Will be set after items load
local GA -- Will be set after gear analysis load

-- ============================================
-- STATE
-- ============================================
Core.players = {} -- {playerName = "RC"|"WA"|true}
Core.playerData = {} -- {playerName = {items, talents, professions, class, timestamp}}
Core.eventFrame = nil
Core.initialized = false

-- Own data cache for change detection
Core.ownDataCache = {
	itemsHash = nil,
	talentsHash = nil,
	professionsHash = nil,
	timestamp = 0,
}

-- ============================================
-- INITIALIZATION
-- ============================================

function Core.OnInitialize()
	if Core.initialized then
		return
	end

	-- Get references to loaded modules
	C = RC.Data.Constants
	Settings = RC.Data.Settings
	Items = RC.Data.Items
	GA = RC.Logic.GearAnalysis

	-- Initialize saved variables
	Settings.Initialize()

	-- Create event frame
	Core.eventFrame = CreateFrame("Frame")
	Core.eventFrame:SetScript("OnEvent", function(_, event, ...)
		if Core[event] then
			Core[event](Core, ...)
		end
	end)

	-- Register addon message prefix (optional for WoW 3.3.5)
	if RegisterAddonPrefix then
		pcall(RegisterAddonPrefix, C.ADDON_PREFIX)
	end

	Core.initialized = true

	print(
		"|cFF00FF00RaiderCheck|r v"
			.. C.VERSION
			.. " загружен. Используйте /rc для открытия окна."
	)
end

function Core.OnEnable()
	local playerName = UnitName("player")
	if playerName then
		Core.players[playerName] = "RC"
		Core.UpdateOwnData(true)
	end

	-- Register events
	Core.RegisterEvent("GROUP_ROSTER_UPDATE")
	Core.RegisterEvent("CHAT_MSG_ADDON")
	Core.RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	Core.RegisterEvent("PLAYER_TALENT_UPDATE")

	-- Slash commands
	SLASH_RAIDERCHECK1 = "/rc"
	SLASH_RAIDERCHECK2 = "/raidercheck"
	SlashCmdList["RAIDERCHECK"] = function(msg)
		Core.HandleSlashCommand(msg)
	end
end

-- ============================================
-- EVENT REGISTRATION
-- ============================================

function Core.RegisterEvent(event)
	if Core.eventFrame then
		Core.eventFrame:RegisterEvent(event)
	end
end

function Core.UnregisterEvent(event)
	if Core.eventFrame then
		Core.eventFrame:UnregisterEvent(event)
	end
end

-- ============================================
-- SLASH COMMANDS
-- ============================================

function Core.HandleSlashCommand(msg)
	msg = msg:lower():trim()

	if msg == "" or msg == "show" then
		if RC.UI.GUI and RC.UI.GUI.Toggle then
			RC.UI.GUI.Toggle()
		end
	elseif msg == "check" then
		Core.ScanGroup()
	elseif msg == "talents" then
		local playerName = UnitName("player")
		if playerName then
			Core.UpdateOwnData(true)
			if RC.UI.TalentsInspect and RC.UI.TalentsInspect.Show then
				RC.UI.TalentsInspect.Show(playerName)
			end
		end
	elseif msg == "debug" then
		local current = Settings.GetDebugMode()
		Settings.SetDebugMode(not current)
		print("|cFF00FF00RaiderCheck:|r Дебаг: " .. (Settings.GetDebugMode() and "ВКЛ" or "ВЫКЛ"))
	elseif msg == "report" then
		if RC.UI.ErrorReport and RC.UI.ErrorReport.Show then
			if RaiderCheck_UnknownGems and #RaiderCheck_UnknownGems > 0 then
				RC.UI.ErrorReport.Show()
			else
				print("|cFF00FF00RaiderCheck:|r Неизвестных камней не найдено")
			end
		end
	elseif msg == "help" then
		print("|cFF00FF00RaiderCheck Команды:|r")
		print("/rc show - Показать/скрыть окно")
		print("/rc check - Проверить группу/рейд")
		print("/rc talents - Просмотреть свои таланты")
		print("/rc report - Сообщить об ошибке (неизвестные камни)")
		print("/rc debug - Включить/выключить дебаг")
		print("/rc help - Показать эту справку")
	else
		print("|cFF00FF00RaiderCheck:|r Неизвестная команда. Используйте /rc help")
	end
end

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

-- Simple hash for comparison
local function SimpleHash(str)
	if not str or str == "" then
		return 0
	end
	local hash = 0
	for i = 1, #str do
		hash = (hash * 31 + string.byte(str, i)) % 10000000
	end
	return hash
end

-- Get unit ID from player name
function Core.GetUnitFromName(playerName)
	if not playerName then
		return nil
	end

	if UnitName("player") == playerName then
		return "player"
	end

	local numRaid = GetNumRaidMembers()
	if numRaid > 0 then
		for i = 1, numRaid do
			if UnitName("raid" .. i) == playerName then
				return "raid" .. i
			end
		end
	end

	local numParty = GetNumPartyMembers()
	if numParty > 0 then
		for i = 1, numParty do
			if UnitName("party" .. i) == playerName then
				return "party" .. i
			end
		end
	end

	return nil
end

-- Get player class
function Core.GetPlayerClass(playerName)
	if not playerName then
		return nil
	end

	-- Try UnitClass first
	local unit = Core.GetUnitFromName(playerName)
	if unit then
		local _, className = UnitClass(unit)
		if className then
			return className
		end
	end

	-- Fallback to cached data
	if Core.playerData[playerName] and Core.playerData[playerName].class then
		return Core.playerData[playerName].class
	end

	-- Try raid roster info
	local numRaid = GetNumRaidMembers()
	if numRaid > 0 then
		for i = 1, numRaid do
			local name, _, _, _, _, className = GetRaidRosterInfo(i)
			if name == playerName then
				return className
			end
		end
	end

	return nil
end

-- Get group players list
function Core.GetGroupPlayers()
	local players = {}
	local numRaid = GetNumRaidMembers()
	local numParty = GetNumPartyMembers()

	if numRaid > 0 then
		for i = 1, numRaid do
			local name = GetRaidRosterInfo(i)
			if name then
				table.insert(players, name)
			end
		end
	elseif numParty > 0 then
		local playerName = UnitName("player")
		if playerName then
			table.insert(players, playerName)
		end
		for i = 1, numParty do
			local name = UnitName("party" .. i)
			if name then
				table.insert(players, name)
			end
		end
	else
		-- Solo
		local playerName = UnitName("player")
		if playerName then
			table.insert(players, playerName)
		end
	end

	return players
end

-- ============================================
-- DATA MANAGEMENT
-- ============================================

-- Check if own data has changed
function Core.HasOwnDataChanged()
	if not Items then
		return true
	end

	local itemsData = Items.CollectPlayerItems()
	local talentsData = Core.GetTalentsData()
	local professionsData = Core.GetProfessionsData()

	local itemsHash = SimpleHash(itemsData)
	local talentsHash = SimpleHash(talentsData)
	local professionsHash = SimpleHash(professionsData)

	local changed = false
	if itemsHash ~= Core.ownDataCache.itemsHash then
		changed = true
	end
	if talentsHash ~= Core.ownDataCache.talentsHash then
		changed = true
	end
	if professionsHash ~= Core.ownDataCache.professionsHash then
		changed = true
	end

	if changed then
		Core.ownDataCache.itemsHash = itemsHash
		Core.ownDataCache.talentsHash = talentsHash
		Core.ownDataCache.professionsHash = professionsHash
		Core.ownDataCache.timestamp = time()
	end

	return changed
end

-- Update own player data
function Core.UpdateOwnData(forceUpdate)
	local playerName = UnitName("player")
	if not playerName then
		return
	end

	if not forceUpdate and not Core.HasOwnDataChanged() then
		return
	end

	local itemsData = Items and Items.CollectPlayerItems() or ""
	local talentsData = Core.GetTalentsData()
	local professionsData = Core.GetProfessionsData()

	-- Parse talents
	local talentsDetailed = {}
	local talentsSimple = { 0, 0, 0 }

	if talentsData and talentsData ~= "" and Core.ParseDetailedTalents then
		talentsDetailed = Core.ParseDetailedTalents(talentsData)

		for treeIndex = 1, 3 do
			if talentsDetailed[treeIndex] then
				for _, talentData in pairs(talentsDetailed[treeIndex]) do
					talentsSimple[treeIndex] = talentsSimple[treeIndex] + (talentData.rank or 0)
				end
			end
		end
	end

	Core.playerData[playerName] = {
		items = Items and Items.ParseItemsData(itemsData) or {},
		talentsDetailed = talentsDetailed,
		talentsSimple = talentsSimple,
		talents = talentsData,
		professions = Core.ParseProfessionsData(professionsData),
		class = select(2, UnitClass("player")),
		timestamp = time(),
		name = playerName,
	}
end

-- ============================================
-- TALENTS DATA (delegated to Talents module)
-- ============================================

function Core.GetTalentsData()
	if RC.Logic.Talents and RC.Logic.Talents.Serialize then
		return RC.Logic.Talents.Serialize()
	end
	return ""
end

function Core.ParseDetailedTalents(data)
	if RC.Logic.Talents and RC.Logic.Talents.ParseDetailed then
		return RC.Logic.Talents.ParseDetailed(data)
	end
	return {}
end

-- ============================================
-- PROFESSIONS DATA
-- ============================================

function Core.GetProfessionsData()
	local professions = {}

	-- Get professions (WoW 3.3.5 API)
	for i = 1, GetNumSkillLines() do
		local skillName, isHeader, _, skillRank, _, _, skillMaxRank = GetSkillLineInfo(i)
		if not isHeader and skillName then
			-- Check if it's a profession
			local isProfession = false
			local profList = {
				"Alchemy",
				"Алхимия",
				"Blacksmithing",
				"Кузнечное дело",
				"Enchanting",
				"Наложение чар",
				"Engineering",
				"Инженерное дело",
				"Herbalism",
				"Травничество",
				"Inscription",
				"Начертание",
				"Jewelcrafting",
				"Ювелирное дело",
				"Leatherworking",
				"Кожевничество",
				"Mining",
				"Горное дело",
				"Skinning",
				"Снятие шкур",
				"Tailoring",
				"Портняжное дело",
			}

			for _, profName in ipairs(profList) do
				if skillName == profName then
					isProfession = true
					break
				end
			end

			if isProfession then
				table.insert(professions, string.format("%s:%d:%d", skillName, skillRank, skillMaxRank))
			end
		end
	end

	return table.concat(professions, ";")
end

function Core.ParseProfessionsData(data)
	local professions = {}

	if not data or data == "" then
		return professions
	end

	for profData in data:gmatch("[^;]+") do
		local name, rank, maxRank = profData:match("([^:]+):(%d+):(%d+)")
		if name then
			table.insert(professions, {
				name = name,
				rank = tonumber(rank) or 0,
				maxRank = tonumber(maxRank) or 450,
			})
		end
	end

	return professions
end

-- ============================================
-- ANALYSIS API (delegates to GearAnalysis)
-- ============================================

function Core.AnalyzePlayerGear(playerName)
	local playerData = Core.playerData[playerName]
	local className = Core.GetPlayerClass(playerName)

	if GA and GA.AnalyzePlayerGear then
		return GA.AnalyzePlayerGear(playerData, className)
	end

	return {
		hasData = false,
		enchantCount = 0,
		totalSlots = 0,
		missingEnchants = {},
		emptySockets = {},
		lowQualityGems = {},
		lowQualityGemsCount = 0,
	}
end

function Core.AnalyzePlayerTalents(playerName)
	local playerData = Core.playerData[playerName]

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
	local maxPoints = 0
	local mainSpec = 0

	for i = 1, 3 do
		local points = talents[i] or 0
		if points > maxPoints then
			maxPoints = points
			mainSpec = i
		end
	end

	local className = Core.GetPlayerClass(playerName)
	local specName = C and C.GetSpecName(className, mainSpec) or "Неизвестно"
	local distribution = string.format("%d/%d/%d", talents[1] or 0, talents[2] or 0, talents[3] or 0)

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

function Core.AnalyzePlayerProfessions(playerName)
	local playerData = Core.playerData[playerName]

	if not playerData or not playerData.professions then
		return {
			hasData = false,
			count = 0,
			professions = {},
		}
	end

	return {
		hasData = true,
		count = #playerData.professions,
		professions = playerData.professions,
	}
end

-- ============================================
-- STRING UTILITIES
-- ============================================

if not string.trim then
	function string:trim()
		return self:match("^%s*(.-)%s*$")
	end
end

-- ============================================
-- ADDON LOAD HANDLING
-- ============================================

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(_, event, addonName)
	if event == "ADDON_LOADED" and addonName == ADDON_NAME then
		Core.OnInitialize()
	elseif event == "PLAYER_LOGIN" then
		Core.OnEnable()
	end
end)

-- Export for backwards compatibility
RaiderCheck.Core = Core
RaiderCheck.players = Core.players
RaiderCheck.playerData = Core.playerData
