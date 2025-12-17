-- RaiderCheck Logic Gear Analysis Module
-- Unified analysis functions for player gear

local _, RC = ...
RC.Logic = RC.Logic or {}
RC.Logic.GearAnalysis = {}
local GA = RC.Logic.GearAnalysis
local C = RC.Data.Constants
local Items = RC.Data.Items
local Settings = RC.Data.Settings

-- ============================================
-- ENCHANTABLE SLOTS DETECTION
-- ============================================

-- Get list of slots that should be enchanted for a player
-- Takes into account class, professions, and item types
function GA.GetEnchantableSlots(playerData, className)
	local slots = {}

	-- Base enchantable slots
	for _, slotName in ipairs(C.ENCHANTABLE_SLOTS) do
		local slotId = GetInventorySlotInfo(slotName)
		if slotId then
			table.insert(slots, slotId)
		end
	end

	-- Check secondary hand
	if playerData and playerData.items then
		local secondarySlot = GetInventorySlotInfo("SecondaryHandSlot")
		if secondarySlot and playerData.items[secondarySlot] then
			local itemInfo = playerData.items[secondarySlot]
			if itemInfo.itemId and Items.CanItemBeEnchanted(itemInfo.itemId) then
				table.insert(slots, secondarySlot)
			end
		end

		-- Check ranged weapon
		local rangedSlot = GetInventorySlotInfo("RangedSlot")
		if rangedSlot and playerData.items[rangedSlot] then
			local itemInfo = playerData.items[rangedSlot]
			if itemInfo.itemId then
				local shouldEnchant = Items.ShouldEnchantRanged(itemInfo.itemId, className)
				if shouldEnchant == true then
					table.insert(slots, rangedSlot)
				end
				-- nil (optional) and false are not added
			end
		end
	end

	-- Add rings for enchanters (level 400+)
	if playerData and playerData.professions then
		for _, prof in ipairs(playerData.professions) do
			if (prof.name == "Enchanting" or prof.name == "Наложение чар") and prof.rank >= 400 then
				local ring1 = GetInventorySlotInfo("Finger0Slot")
				local ring2 = GetInventorySlotInfo("Finger1Slot")
				if ring1 then
					table.insert(slots, ring1)
				end
				if ring2 then
					table.insert(slots, ring2)
				end
				break
			end
		end
	end

	return slots
end

-- Check if a slot is enchanted
function GA.IsSlotEnchanted(slotId, playerData)
	if not playerData or not playerData.items then
		return false
	end
	local itemInfo = playerData.items[slotId]
	if not itemInfo then
		return false
	end
	return itemInfo.enchant ~= nil
end

-- Get list of missing enchants
function GA.GetMissingEnchants(playerData, className)
	local missing = {}
	local enchantableSlots = GA.GetEnchantableSlots(playerData, className)

	for _, slotId in ipairs(enchantableSlots) do
		-- Check if slot has an item
		if playerData and playerData.items and playerData.items[slotId] then
			if not GA.IsSlotEnchanted(slotId, playerData) then
				local slotName = C.GetSlotName(slotId)
				table.insert(missing, {
					slotId = slotId,
					slotName = slotName,
				})
			end
		end
	end

	return missing
end

-- ============================================
-- SOCKET ANALYSIS
-- ============================================

-- Get list of items with empty sockets
function GA.GetEmptySockets(playerData)
	local emptySockets = {}

	if not playerData or not playerData.items then
		return emptySockets
	end

	-- Special check for belt (should have belt buckle socket)
	local waistSlot = GetInventorySlotInfo("WaistSlot")
	if waistSlot and playerData.items[waistSlot] then
		local beltItem = playerData.items[waistSlot]

		-- Check for actual gems using GetItemGem
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

		-- Belt without sockets and no gems = no belt buckle
		if (not beltItem.totalSockets or beltItem.totalSockets == 0) and not hasActualGem then
			table.insert(emptySockets, {
				slotId = waistSlot,
				slotName = C.GetSlotName(waistSlot),
				emptyCount = 1,
				totalSockets = 0,
				itemLink = beltItem.itemLink,
				isBeltWithoutBuckle = true,
			})
		end
	end

	-- Check all items for empty sockets
	for slotId, itemInfo in pairs(playerData.items) do
		if itemInfo.totalSockets and itemInfo.totalSockets > 0 then
			local filledSockets = 0

			-- Count filled sockets using GetItemGem (most reliable)
			if itemInfo.itemLink then
				for i = 1, 3 do
					local _, gemLink = GetItemGem(itemInfo.itemLink, i)
					if gemLink and gemLink ~= "" then
						filledSockets = filledSockets + 1
					end
				end
			else
				-- Fallback to gems array
				if itemInfo.gems then
					filledSockets = #itemInfo.gems
				end
			end

			if filledSockets < itemInfo.totalSockets then
				local emptyCount = itemInfo.totalSockets - filledSockets
				table.insert(emptySockets, {
					slotId = slotId,
					slotName = C.GetSlotName(slotId),
					emptyCount = emptyCount,
					totalSockets = itemInfo.totalSockets,
					itemLink = itemInfo.itemLink,
				})
			end
		end
	end

	return emptySockets
end

-- ============================================
-- GEM QUALITY ANALYSIS
-- ============================================

-- Check gem quality against minimum settings
-- Returns: lowQualityGems[], count
function GA.CheckGemQuality(playerData)
	local lowQualityGems = {}
	local lowQualityCount = 0

	if not playerData or not playerData.items then
		return lowQualityGems, lowQualityCount
	end

	-- Check if gem mapping is available
	if not RaiderCheck_GemItemToType then
		return lowQualityGems, lowQualityCount
	end

	local minPriority = Settings.GetMinGemPriority()
	local unknownGemsFound = false

	for slotId, itemInfo in pairs(playerData.items) do
		if itemInfo.itemLink then
			local lowQualityInItem = {}

			-- Check each gem in the item
			for i = 1, 3 do
				local gemName, gemLink = GetItemGem(itemInfo.itemLink, i)
				if gemLink and gemLink ~= "" then
					local gParsed = Items.ParseItemLink(gemLink)
					if gParsed and gParsed.itemId then
						local gemIdNum = gParsed.itemId

						-- Get gem type from mapping
						local gemType = RaiderCheck_GetGemTypeFromItemId and RaiderCheck_GetGemTypeFromItemId(gemIdNum)

						if gemType then
							local gemPriority = RaiderCheck_GetGemPriorityFromItemId
									and RaiderCheck_GetGemPriorityFromItemId(gemIdNum)
								or 0

							if gemPriority < minPriority then
								lowQualityCount = lowQualityCount + 1
								table.insert(lowQualityInItem, {
									id = gemIdNum,
									type = gemType,
									priority = gemPriority,
									name = gemName,
								})
							end
						else
							-- Unknown gem - add to error report
							if RaiderCheck_AddUnknownGem then
								local wasAdded = RaiderCheck_AddUnknownGem(
									gemIdNum,
									gemName,
									gemLink,
									C.GetSlotName(slotId),
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

			if #lowQualityInItem > 0 then
				table.insert(lowQualityGems, {
					slotId = slotId,
					slotName = C.GetSlotName(slotId),
					gems = lowQualityInItem,
					itemLink = itemInfo.itemLink,
				})
			end
		end
	end

	return lowQualityGems, lowQualityCount, unknownGemsFound
end

-- ============================================
-- PROFESSION BONUS CHECKS
-- ============================================

-- Check profession-specific bonuses
function GA.CheckProfessionBonuses(playerData)
	local missing = {}

	if not playerData or not playerData.professions or not playerData.items then
		return missing
	end

	for _, prof in ipairs(playerData.professions) do
		local profName = prof.name

		-- Blacksmith sockets check
		if profName == "Blacksmithing" or profName == "Кузнечное дело" then
			local handsSlot = GetInventorySlotInfo("HandsSlot")
			local wristSlot = GetInventorySlotInfo("WristSlot")

			if playerData.items[handsSlot] then
				local item = playerData.items[handsSlot]
				if not item.totalSockets or item.totalSockets == 0 then
					table.insert(missing, "Кузнец: нет сокета на руках")
				end
			end

			if playerData.items[wristSlot] then
				local item = playerData.items[wristSlot]
				if not item.totalSockets or item.totalSockets == 0 then
					table.insert(missing, "Кузнец: нет сокета на запястьях")
				end
			end

		-- Jewelcrafter Dragon's Eye check
		elseif profName == "Jewelcrafting" or profName == "Ювелирное дело" then
			local dragonEyeCount = 0

			for slotId, itemInfo in pairs(playerData.items) do
				if itemInfo.itemLink then
					for i = 1, 3 do
						local _, gemLink = GetItemGem(itemInfo.itemLink, i)
						if gemLink and gemLink ~= "" then
							local gParsed = Items.ParseItemLink(gemLink)
							if gParsed and gParsed.itemId then
								if C.JEWELCRAFTING_GEMS[gParsed.itemId] then
									dragonEyeCount = dragonEyeCount + 1
								end
							end
						end
					end
				end
			end

			if dragonEyeCount < 3 then
				table.insert(
					missing,
					string.format("Ювелир: используется %d/3 Dragon's Eye", dragonEyeCount)
				)
			end

		-- Leatherworker Fur Lining check
		elseif profName == "Leatherworking" or profName == "Кожевничество" then
			local wristSlot = GetInventorySlotInfo("WristSlot")
			if playerData.items[wristSlot] then
				local enchant = playerData.items[wristSlot].enchant
				if not enchant or not C.LEATHERWORKING_ENCHANTS[enchant] then
					table.insert(missing, "Кожевник: нет Fur Lining на запястьях")
				end
			end

		-- Scribe Master's Inscription check
		elseif profName == "Inscription" or profName == "Начертание" then
			local shoulderSlot = GetInventorySlotInfo("ShoulderSlot")
			if playerData.items[shoulderSlot] then
				local enchant = playerData.items[shoulderSlot].enchant
				if not enchant or not C.INSCRIPTION_ENCHANTS[enchant] then
					table.insert(missing, "Начертатель: нет Master's Inscription на плечах")
				end
			end

		-- Tailor Embroidery check
		elseif profName == "Tailoring" or profName == "Портняжное дело" then
			local backSlot = GetInventorySlotInfo("BackSlot")
			if playerData.items[backSlot] then
				local enchant = playerData.items[backSlot].enchant
				if not enchant or not C.TAILORING_ENCHANTS[enchant] then
					table.insert(missing, "Портной: нет Вышивки на плаще")
				end
			end

		-- Engineer enhancements (optional)
		elseif profName == "Engineering" or profName == "Инженерное дело" then
			-- Check gloves
			local handsSlot = GetInventorySlotInfo("HandsSlot")
			if playerData.items[handsSlot] then
				local enchant = playerData.items[handsSlot].enchant
				local hasEng = false
				if enchant then
					for engId in pairs(C.ENGINEERING_ENCHANTS.gloves) do
						if enchant == engId then
							hasEng = true
							break
						end
					end
				end
				if not hasEng then
					table.insert(
						missing,
						"Инженер: нет усиления на перчатках (опционально)"
					)
				end
			end

			-- Check belt
			local waistSlot = GetInventorySlotInfo("WaistSlot")
			if playerData.items[waistSlot] then
				local enchant = playerData.items[waistSlot].enchant
				local hasEng = false
				if enchant then
					for engId in pairs(C.ENGINEERING_ENCHANTS.belt) do
						if enchant == engId then
							hasEng = true
							break
						end
					end
				end
				if not hasEng then
					table.insert(
						missing,
						"Инженер: нет усиления на поясе (опционально)"
					)
				end
			end
		end
	end

	return missing
end

-- ============================================
-- UNIFIED ANALYSIS FUNCTION
-- ============================================

-- Analyze all aspects of player gear
-- Returns unified payload with all analysis results
function GA.AnalyzePlayerGear(playerData, className)
	-- Default empty result
	local result = {
		hasData = false,
		enchantCount = 0,
		totalSlots = 0,
		missingEnchants = {},
		emptySockets = {},
		lowQualityGems = {},
		lowQualityGemsCount = 0,
		professionIssues = {},
		unknownGemsFound = false,
	}

	if not playerData or not playerData.items then
		return result
	end

	result.hasData = true

	-- Enchant analysis
	local enchantableSlots = GA.GetEnchantableSlots(playerData, className)
	result.missingEnchants = GA.GetMissingEnchants(playerData, className)
	result.totalSlots = #enchantableSlots
	result.enchantCount = result.totalSlots - #result.missingEnchants

	-- Socket analysis
	result.emptySockets = GA.GetEmptySockets(playerData)

	-- Gem quality analysis
	result.lowQualityGems, result.lowQualityGemsCount, result.unknownGemsFound = GA.CheckGemQuality(playerData)

	-- Profession bonuses analysis
	result.professionIssues = GA.CheckProfessionBonuses(playerData)

	return result
end

return GA
