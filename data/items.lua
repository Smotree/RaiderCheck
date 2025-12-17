-- RaiderCheck Data Items Module
-- Item parsing, caching, socket/gem detection

local _, RC = ...
RC.Data = RC.Data or {}
RC.Data.Items = {}
local Items = RC.Data.Items
local C = RC.Data.Constants

-- ============================================
-- ITEM STATS CACHE
-- ============================================
local itemStatsCache = {}

local function GetCachedItemStats(itemLink)
	if not itemLink then
		return nil
	end

	local cached = itemStatsCache[itemLink]
	if cached and (GetTime() - cached.time) < C.CACHE_EXPIRE_TIME then
		return cached.stats
	end

	local stats = GetItemStats and GetItemStats(itemLink) or nil
	itemStatsCache[itemLink] = {
		stats = stats,
		time = GetTime(),
	}
	return stats
end

-- Cleanup expired cache entries
function Items.CleanupCache()
	local now = GetTime()
	for link, data in pairs(itemStatsCache) do
		if (now - data.time) > C.CACHE_EXPIRE_TIME then
			itemStatsCache[link] = nil
		end
	end
end

-- ============================================
-- SOCKET COUNTING
-- ============================================
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
-- ITEM LINK PARSING
-- ============================================

-- Parse an item link into structured data
-- Returns: {itemId, enchant, gems[], suffixId, uniqueId, linkLevel, totalSockets}
function Items.ParseItemLink(itemLink)
	if not itemLink then
		return nil
	end

	-- Format: |Hitem:itemId:enchantId:gem1:gem2:gem3:gem4:suffixId:uniqueId:linkLevel|h[name]|h
	local itemString = itemLink:match("|Hitem:([-%d:]+)")
	if not itemString then
		return nil
	end

	local parts = {}
	for part in string.gmatch(itemString, "[^:]+") do
		table.insert(parts, part)
	end

	local parsed = {
		itemId = tonumber(parts[1]),
		enchant = parts[2] and tonumber(parts[2]) or nil,
		gems = {},
		suffixId = parts[7] and tonumber(parts[7]) or nil,
		uniqueId = parts[8] and tonumber(parts[8]) or nil,
		linkLevel = parts[9] and tonumber(parts[9]) or nil,
	}

	-- Extract gems (positions 3-6)
	for i = 3, 6 do
		if parts[i] and parts[i] ~= "0" and parts[i] ~= "" then
			local n = tonumber(parts[i])
			if n then
				table.insert(parsed.gems, n)
			end
		end
	end

	-- Get socket count from item stats (cached)
	local stats = GetCachedItemStats(itemLink)
	parsed.totalSockets = CountSocketsFromStats(stats)

	return parsed
end

-- Get enchant ID from item link
function Items.GetEnchantId(itemLink)
	if not itemLink then
		return nil
	end
	local parsed = Items.ParseItemLink(itemLink)
	if parsed and parsed.enchant and parsed.enchant ~= 0 then
		return parsed.enchant
	end
	return nil
end

-- Get item ID from item link
function Items.GetItemId(itemLink)
	if not itemLink then
		return nil
	end
	local parsed = Items.ParseItemLink(itemLink)
	return parsed and parsed.itemId or nil
end

-- ============================================
-- GEM EXTRACTION
-- ============================================

-- Get gems from an item using GetItemGem API (most reliable for equipped items)
-- Returns: gemIds[], totalSockets
function Items.GetGemsFromItem(itemLink)
	local gemIds = {}
	local totalSockets = 0

	if not itemLink then
		return gemIds, totalSockets
	end

	-- Use GetItemGem for equipped items
	for i = 1, 3 do
		local gemName, gemLink = GetItemGem(itemLink, i)
		if gemLink and gemLink ~= "" then
			local gParsed = Items.ParseItemLink(gemLink)
			if gParsed and gParsed.itemId then
				table.insert(gemIds, gParsed.itemId)
			end
		end
	end

	-- Get total sockets from item stats
	local stats = GetCachedItemStats(itemLink)
	totalSockets = CountSocketsFromStats(stats)

	-- Fallback to parsed link if stats don't show sockets
	if totalSockets == 0 then
		local parsed = Items.ParseItemLink(itemLink)
		totalSockets = parsed and parsed.totalSockets or 0
	end

	return gemIds, totalSockets
end

-- ============================================
-- ENCHANTABILITY CHECKS
-- ============================================

-- Check if an item can be enchanted based on its type
function Items.CanItemBeEnchanted(itemId)
	if not itemId then
		return false
	end

	local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture =
		GetItemInfo(itemId)

	if not itemType or not itemSubType then
		return true -- Default: assume enchantable
	end

	-- Check non-enchantable subtypes
	if C.IsNonEnchantableSubtype(itemSubType) then
		return false
	end

	-- Off-hand holdables (manuscripts, etc) cannot be enchanted
	if itemEquipLoc == "INVTYPE_HOLDABLE" then
		return false
	end

	return true
end

-- Check if ranged weapon should be enchanted for a given class
-- Returns: true (required), false (not enchantable), nil (optional)
function Items.ShouldEnchantRanged(itemId, className)
	if not itemId then
		return false
	end

	local _, _, _, _, _, itemType, itemSubType = GetItemInfo(itemId)

	-- Non-enchantable ranged (wands, thrown, relics)
	if C.MatchesSubtype(itemSubType, C.RANGED_NON_ENCHANTABLE) then
		return false
	end

	-- Optional ranged (bows, crossbows, guns)
	if C.MatchesSubtype(itemSubType, C.RANGED_OPTIONAL) then
		-- Required for hunters, optional for others
		if className == "HUNTER" then
			return true
		end
		return nil -- Optional
	end

	-- Other ranged weapons - check general enchantability
	return Items.CanItemBeEnchanted(itemId)
end

-- ============================================
-- DATA COLLECTION
-- ============================================

-- Collect all items data from player for transmission
-- Returns serialized string format
function Items.CollectPlayerItems()
	local itemsData = {}

	for _, slotName in ipairs(C.INVENTORY_SLOTS) do
		local slotId = GetInventorySlotInfo(slotName)
		local itemLink = GetInventoryItemLink("player", slotId)

		if itemLink then
			local parsed = Items.ParseItemLink(itemLink)
			if parsed then
				local enchantId = parsed.enchant or 0
				local itemId = parsed.itemId or 0

				-- Get actual gems using GetItemGem
				local gemIds, totalSockets = Items.GetGemsFromItem(itemLink)

				-- Encode item link (replace : with ~)
				local encodedLink = itemLink:gsub(":", "~")

				-- Format: slotId:itemId:enchantId:totalSockets:gem1,gem2,gem3:itemLink
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
	end

	return table.concat(itemsData, ";")
end

-- Parse received items data string into structured table
-- Returns: {[slotId] = {itemId, enchant, gems[], totalSockets, itemLink}}
function Items.ParseItemsData(data)
	local items = {}

	if not data or data == "" then
		return items
	end

	for itemData in data:gmatch("[^;]+") do
		-- Format: slotId:itemId:enchantId:totalSockets:gems:itemLink
		local slotId, itemId, enchantId, totalSockets, gemsStr, encodedLink =
			itemData:match("^(%d+):(%d+):([^:]*):(%d+):([^:]*):(.*)$")

		if slotId then
			slotId = tonumber(slotId)
			itemId = tonumber(itemId)
			totalSockets = tonumber(totalSockets) or 0
			encodedLink = encodedLink or ""

			-- Decode item link
			local itemLink = encodedLink:gsub("~", ":")

			local gems = {}
			if gemsStr and gemsStr ~= "" and gemsStr ~= "0" then
				for gemId in gemsStr:gmatch("[^,]+") do
					local gid = tonumber(gemId)
					if gid then
						table.insert(gems, gid)
					end
				end
			end

			items[slotId] = {
				itemId = (itemId and itemId ~= 0) and itemId or nil,
				enchant = (enchantId and enchantId ~= "0") and tonumber(enchantId) or nil,
				gems = gems,
				totalSockets = totalSockets,
				itemLink = (itemLink ~= "") and itemLink or nil,
			}
		end
	end

	return items
end

return Items
