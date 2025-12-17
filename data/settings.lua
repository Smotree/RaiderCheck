-- RaiderCheck Data Settings Module
-- Gem settings, saved variables management

local _, RC = ...
RC.Data = RC.Data or {}
RC.Data.Settings = {}
local Settings = RC.Data.Settings
local C = RC.Data.Constants

-- ============================================
-- SAVED VARIABLES INITIALIZATION
-- ============================================

-- Initialize settings with defaults and migrations
function Settings.Initialize()
	if not RaiderCheckDB then
		RaiderCheckDB = {}
	end

	-- Initialize gem settings
	if not RaiderCheckDB.gemSettings then
		RaiderCheckDB.gemSettings = {
			minQuality = C.DEFAULT_MIN_GEM_QUALITY,
		}
	end

	-- Migration from old format (acceptableGemTypes -> minQuality)
	if RaiderCheckDB.gemSettings.acceptableGemTypes and not RaiderCheckDB.gemSettings.minQuality then
		local minPriority = 999
		local minType = C.DEFAULT_MIN_GEM_QUALITY

		for gemType, enabled in pairs(RaiderCheckDB.gemSettings.acceptableGemTypes) do
			if enabled then
				local priority = C.GEM_PRIORITIES[gemType]
				if priority and priority < minPriority then
					minPriority = priority
					minType = gemType
				end
			end
		end

		RaiderCheckDB.gemSettings.minQuality = minType
		RaiderCheckDB.gemSettings.acceptableGemTypes = nil
	end

	-- Initialize window positions
	if not RaiderCheckDB.windowPositions then
		RaiderCheckDB.windowPositions = {}
	end

	-- Initialize debug settings
	if RaiderCheckDB.debug == nil then
		RaiderCheckDB.debug = false
	end
end

-- ============================================
-- GEM QUALITY SETTINGS
-- ============================================

-- Get minimum required gem quality
function Settings.GetMinGemQuality()
	return RaiderCheckDB.gemSettings and RaiderCheckDB.gemSettings.minQuality or C.DEFAULT_MIN_GEM_QUALITY
end

-- Set minimum required gem quality
function Settings.SetMinGemQuality(quality)
	if not RaiderCheckDB.gemSettings then
		RaiderCheckDB.gemSettings = {}
	end
	RaiderCheckDB.gemSettings.minQuality = quality
end

-- Get numeric priority value for min quality
function Settings.GetMinGemPriority()
	local minQuality = Settings.GetMinGemQuality()
	return C.GetGemPriorityValue(minQuality)
end

-- Check if a gem type meets minimum quality
function Settings.GemMeetsMinQuality(gemType)
	local gemPriority = C.GetGemPriorityValue(gemType)
	local minPriority = Settings.GetMinGemPriority()
	return gemPriority >= minPriority
end

-- ============================================
-- WINDOW POSITION SETTINGS
-- ============================================

-- Save window position
function Settings.SaveWindowPosition(windowName, point, relativeTo, relativePoint, x, y)
	if not RaiderCheckDB.windowPositions then
		RaiderCheckDB.windowPositions = {}
	end
	RaiderCheckDB.windowPositions[windowName] = {
		point = point,
		relativeTo = relativeTo,
		relativePoint = relativePoint,
		x = x,
		y = y,
	}
end

-- Get saved window position
function Settings.GetWindowPosition(windowName)
	if RaiderCheckDB.windowPositions and RaiderCheckDB.windowPositions[windowName] then
		return RaiderCheckDB.windowPositions[windowName]
	end
	return nil
end

-- ============================================
-- DEBUG SETTINGS
-- ============================================

-- Get debug mode
function Settings.GetDebugMode()
	return RaiderCheckDB.debug or false
end

-- Set debug mode
function Settings.SetDebugMode(enabled)
	RaiderCheckDB.debug = enabled
end

-- Debug print (only if debug mode enabled)
function Settings.DebugPrint(...)
	if Settings.GetDebugMode() then
		print("|cFF00FFFF[RC Debug]|r", ...)
	end
end

-- ============================================
-- GENERAL SETTINGS ACCESS
-- ============================================

-- Get a setting value
function Settings.Get(key, default)
	if RaiderCheckDB[key] ~= nil then
		return RaiderCheckDB[key]
	end
	return default
end

-- Set a setting value
function Settings.Set(key, value)
	RaiderCheckDB[key] = value
end

return Settings
