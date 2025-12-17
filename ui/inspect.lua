-- RaiderCheck UI Inspect Module
-- Detailed item inspection window

local _, RC = ...
RC.UI = RC.UI or {}
RC.UI.Inspect = {}
local Inspect = RC.UI.Inspect
local Core = RC.Core
local C = RC.Data.Constants
local Items = RC.Data.Items
local GA = RC.Logic.GearAnalysis
local Settings = RC.Data.Settings

-- ============================================
-- STATE
-- ============================================
local inspectFrame = nil
local currentPlayer = nil

-- Slot layout configuration
local SLOT_LAYOUT = {
	-- Left side
	{ name = "HeadSlot", x = 6, y = -60 },
	{ name = "NeckSlot", x = 6, y = -100 },
	{ name = "ShoulderSlot", x = 6, y = -140 },
	{ name = "BackSlot", x = 6, y = -180 },
	{ name = "ChestSlot", x = 6, y = -220 },
	{ name = "ShirtSlot", x = 6, y = -260 },
	{ name = "TabardSlot", x = 6, y = -300 },
	{ name = "WristSlot", x = 6, y = -340 },

	-- Right side
	{ name = "HandsSlot", x = 170, y = -60 },
	{ name = "WaistSlot", x = 170, y = -100 },
	{ name = "LegsSlot", x = 170, y = -140 },
	{ name = "FeetSlot", x = 170, y = -180 },
	{ name = "Finger0Slot", x = 170, y = -220 },
	{ name = "Finger1Slot", x = 170, y = -260 },
	{ name = "Trinket0Slot", x = 170, y = -300 },
	{ name = "Trinket1Slot", x = 170, y = -340 },

	-- Weapons at bottom
	{ name = "MainHandSlot", x = 48, y = -380 },
	{ name = "SecondaryHandSlot", x = 88, y = -380 },
	{ name = "RangedSlot", x = 128, y = -380 },
}

-- Default enchantable slots
local ENCHANTABLE_SLOTS = {
	HeadSlot = true,
	ShoulderSlot = true,
	BackSlot = true,
	ChestSlot = true,
	WristSlot = true,
	HandsSlot = true,
	LegsSlot = true,
	FeetSlot = true,
	MainHandSlot = true,
	SecondaryHandSlot = true,
	RangedSlot = true,
}

-- ============================================
-- FRAME CREATION
-- ============================================

function Inspect.Create()
	if inspectFrame then
		return inspectFrame
	end

	local frame = CreateFrame("Frame", "RaiderCheckInspectFrame", UIParent)
	frame:SetSize(212, 450)
	frame:SetPoint("BOTTOMLEFT")
	frame:SetFrameStrata("HIGH")
	frame:Hide()

	-- Background
	frame:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	frame:SetBackdropColor(0.05, 0.05, 0.08, 0.95)
	frame:SetBackdropBorderColor(0.2, 0.6, 0.8, 1)

	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

	-- Header gradient
	local header = frame:CreateTexture(nil, "ARTWORK")
	header:SetPoint("TOPLEFT", 4, -4)
	header:SetPoint("TOPRIGHT", -4, -4)
	header:SetHeight(50)
	header:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	header:SetGradientAlpha("VERTICAL", 0.1, 0.3, 0.5, 0.8, 0.05, 0.15, 0.25, 0.8)

	-- Header line
	local headerLine = frame:CreateTexture(nil, "OVERLAY")
	headerLine:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 0)
	headerLine:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, 0)
	headerLine:SetHeight(2)
	headerLine:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	headerLine:SetVertexColor(0.3, 0.7, 1, 0.8)

	-- Title
	local title = frame:CreateFontString(nil, "OVERLAY")
	title:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
	title:SetPoint("TOPLEFT", 15, -18)
	title:SetTextColor(0.3, 0.8, 1, 1)
	frame.title = title

	-- Subtitle
	local subtitle = frame:CreateFontString(nil, "OVERLAY")
	subtitle:SetFont("Fonts\\FRIZQT__.TTF", 10)
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
	subtitle:SetText("Осмотр снаряжения")
	subtitle:SetTextColor(0.7, 0.7, 0.7, 1)

	-- Close button
	local closeButton = CreateFrame("Button", nil, frame)
	closeButton:SetSize(24, 24)
	closeButton:SetPoint("TOPRIGHT", -8, -8)

	local closeBg = closeButton:CreateTexture(nil, "BACKGROUND")
	closeBg:SetAllPoints()
	closeBg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	closeBg:SetVertexColor(0.8, 0.2, 0.2, 0.6)

	local closeText = closeButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	closeText:SetPoint("CENTER")
	closeText:SetText("×")
	closeText:SetTextColor(1, 1, 1, 1)

	closeButton:SetScript("OnEnter", function(self)
		closeBg:SetVertexColor(1, 0.3, 0.3, 0.9)
		self:SetScale(1.1)
	end)
	closeButton:SetScript("OnLeave", function(self)
		closeBg:SetVertexColor(0.8, 0.2, 0.2, 0.6)
		self:SetScale(1.0)
	end)
	closeButton:SetScript("OnClick", function()
		frame:Hide()
	end)

	-- Create item slots
	frame.itemSlots = {}

	for _, slotInfo in ipairs(SLOT_LAYOUT) do
		local slotFrame = Inspect.CreateSlotFrame(frame, slotInfo)
		frame.itemSlots[slotInfo.name] = slotFrame
	end

	-- Talents button
	local talentsButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	talentsButton:SetSize(150, 25)
	talentsButton:SetPoint("TOP", 0, -420)
	talentsButton:SetText("Детальные таланты")
	talentsButton:SetScript("OnClick", function()
		if RC.UI.TalentsInspect and RC.UI.TalentsInspect.Show then
			RC.UI.TalentsInspect.Show(currentPlayer)
		end
	end)
	frame.talentsButton = talentsButton

	inspectFrame = frame
	return frame
end

function Inspect.CreateSlotFrame(parent, slotInfo)
	local slotFrame = CreateFrame("Button", nil, parent)
	slotFrame:SetSize(37, 37)
	slotFrame:SetPoint("TOPLEFT", slotInfo.x, slotInfo.y)

	-- Slot background
	slotFrame:SetNormalTexture("Interface\\PaperDoll\\UI-PaperDoll-Slot-" .. slotInfo.name)

	-- Item icon
	local icon = slotFrame:CreateTexture(nil, "ARTWORK")
	icon:SetAllPoints()
	slotFrame.icon = icon

	-- Enchant border (green)
	local enchantBorder = slotFrame:CreateTexture(nil, "OVERLAY")
	enchantBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
	enchantBorder:SetBlendMode("ADD")
	enchantBorder:SetPoint("TOPLEFT", -11, 12)
	enchantBorder:SetPoint("BOTTOMRIGHT", 12, -11)
	enchantBorder:SetVertexColor(0, 1, 0)
	enchantBorder:Hide()
	slotFrame.enchantBorder = enchantBorder

	-- No enchant border (red)
	local noEnchantBorder = slotFrame:CreateTexture(nil, "OVERLAY")
	noEnchantBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
	noEnchantBorder:SetBlendMode("ADD")
	noEnchantBorder:SetVertexColor(1, 0, 0)
	noEnchantBorder:SetPoint("TOPLEFT", -11, 12)
	noEnchantBorder:SetPoint("BOTTOMRIGHT", 12, -11)
	noEnchantBorder:Hide()
	slotFrame.noEnchantBorder = noEnchantBorder

	-- Empty socket border (yellow)
	local socketBorder = slotFrame:CreateTexture(nil, "OVERLAY")
	socketBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
	socketBorder:SetBlendMode("ADD")
	socketBorder:SetVertexColor(1, 1, 0)
	socketBorder:SetPoint("TOPLEFT", -11, 12)
	socketBorder:SetPoint("BOTTOMRIGHT", 12, -11)
	socketBorder:Hide()
	slotFrame.socketBorder = socketBorder

	-- Combined border (orange)
	local combinedBorder = slotFrame:CreateTexture(nil, "OVERLAY")
	combinedBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
	combinedBorder:SetBlendMode("ADD")
	combinedBorder:SetVertexColor(1, 0.5, 0)
	combinedBorder:SetPoint("TOPLEFT", -11, 12)
	combinedBorder:SetPoint("BOTTOMRIGHT", 12, -11)
	combinedBorder:Hide()
	slotFrame.combinedBorder = combinedBorder

	-- Low quality gem border (purple)
	local gemBorder = slotFrame:CreateTexture(nil, "OVERLAY")
	gemBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
	gemBorder:SetBlendMode("ADD")
	gemBorder:SetVertexColor(0.7, 0, 1)
	gemBorder:SetPoint("TOPLEFT", -11, 12)
	gemBorder:SetPoint("BOTTOMRIGHT", 12, -11)
	gemBorder:Hide()
	slotFrame.gemBorder = gemBorder

	-- Tooltip
	slotFrame:SetScript("OnEnter", function(self)
		if self.itemLink then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetHyperlink(self.itemLink)
			GameTooltip:Show()
		end
	end)

	slotFrame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	slotFrame.slotName = slotInfo.name

	return slotFrame
end

-- ============================================
-- SHOW / HIDE
-- ============================================

function Inspect.Show(playerName)
	if not inspectFrame then
		Inspect.Create()
	end

	local playerData = Core.playerData[playerName]
	if not playerData then
		print("|cFF00FF00RaiderCheck:|r Нет данных для " .. playerName)
		return
	end

	currentPlayer = playerName

	-- Set title with class color
	local className = Core.GetPlayerClass(playerName)
	local classColor = RAID_CLASS_COLORS[className] or { r = 1, g = 1, b = 1 }
	inspectFrame.title:SetText(playerName)
	inspectFrame.title:SetTextColor(classColor.r, classColor.g, classColor.b)

	-- Update items
	Inspect.UpdateItems(playerName, playerData)

	inspectFrame:Show()
end

function Inspect.Hide()
	if inspectFrame then
		inspectFrame:Hide()
	end
end

-- ============================================
-- UPDATE ITEMS
-- ============================================

function Inspect.UpdateItems(playerName, playerData)
	-- Determine enchantable slots based on professions
	local enchantableSlots = {}
	for k, v in pairs(ENCHANTABLE_SLOTS) do
		enchantableSlots[k] = v
	end

	-- Add rings for enchanters
	if playerData and playerData.professions then
		for _, prof in ipairs(playerData.professions) do
			if (prof.name == "Enchanting" or prof.name == "Наложение чар") and prof.rank >= 400 then
				enchantableSlots.Finger0Slot = true
				enchantableSlots.Finger1Slot = true
				break
			end
		end
	end

	local className = Core.GetPlayerClass(playerName)
	local minPriority = Settings.GetMinGemPriority()

	for slotName, slotFrame in pairs(inspectFrame.itemSlots) do
		-- Clear slot
		slotFrame.icon:SetTexture(nil)
		slotFrame.enchantBorder:Hide()
		slotFrame.noEnchantBorder:Hide()
		slotFrame.socketBorder:Hide()
		slotFrame.combinedBorder:Hide()
		slotFrame.gemBorder:Hide()
		slotFrame.itemLink = nil

		local slotId = GetInventorySlotInfo(slotName)

		if slotId and playerData.items and playerData.items[slotId] then
			local itemInfo = playerData.items[slotId]
			local itemId = itemInfo.itemId
			local decodedLink = nil

			-- Decode item link
			if itemInfo.itemLink then
				decodedLink = itemInfo.itemLink:gsub("~", ":")
				slotFrame.itemLink = decodedLink

				if not itemId then
					itemId = tonumber(decodedLink:match("item:(%d+)"))
				end
			end

			-- Set icon
			if itemId then
				local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture =
					GetItemInfo(itemId)

				if itemTexture then
					slotFrame.icon:SetTexture(itemTexture)
				else
					-- Try to load item info
					GetItemInfo(itemId)
					Inspect.DelayedIconLoad(slotFrame, itemId)
				end
			end

			-- Determine if slot should be enchanted
			local shouldBeEnchanted = enchantableSlots[slotName]

			-- Special handling for ranged slot
			if slotName == "RangedSlot" and itemId then
				local _, _, _, _, _, itemType, itemSubType = GetItemInfo(itemId)
				local shouldEnchant = Items.ShouldEnchantRanged(itemId, className)

				if shouldEnchant == false then
					shouldBeEnchanted = false
				elseif shouldEnchant == nil then
					-- Optional - don't mark as missing
					shouldBeEnchanted = false
				end
			end

			-- Check secondary hand enchantability
			if slotName == "SecondaryHandSlot" and itemId then
				if not Items.CanItemBeEnchanted(itemId) then
					shouldBeEnchanted = false
				end
			end

			-- Check enchant status
			local hasEnchant = itemInfo.enchant ~= nil

			-- Check socket status
			local hasEmptySockets = false
			local filledSockets = 0
			local totalSockets = itemInfo.totalSockets or 0

			if decodedLink then
				for i = 1, 3 do
					local _, gemLink = GetItemGem(decodedLink, i)
					if gemLink and gemLink ~= "" then
						filledSockets = filledSockets + 1
					end
				end
			elseif itemInfo.gems then
				filledSockets = #itemInfo.gems
			end

			if totalSockets > 0 and filledSockets < totalSockets then
				hasEmptySockets = true
			end

			-- Check gem quality
			local hasLowQualityGems = false
			if decodedLink and RaiderCheck_GetGemPriorityFromItemId then
				for i = 1, 3 do
					local gemName, gemLink = GetItemGem(decodedLink, i)
					if gemLink and gemLink ~= "" then
						local gParsed = Items.ParseItemLink(gemLink)
						if gParsed and gParsed.itemId then
							local gemPriority = RaiderCheck_GetGemPriorityFromItemId(gParsed.itemId)
							if gemPriority and gemPriority < minPriority then
								hasLowQualityGems = true
								break
							end
						end
					end
				end
			end

			-- Set appropriate border
			local missingEnchant = shouldBeEnchanted and not hasEnchant

			if missingEnchant and hasEmptySockets then
				slotFrame.combinedBorder:Show()
			elseif missingEnchant then
				slotFrame.noEnchantBorder:Show()
			elseif hasEmptySockets then
				slotFrame.socketBorder:Show()
			elseif hasLowQualityGems then
				slotFrame.gemBorder:Show()
			elseif shouldBeEnchanted and hasEnchant then
				slotFrame.enchantBorder:Show()
			end
		end
	end
end

function Inspect.DelayedIconLoad(slotFrame, itemId)
	local waitFrame = CreateFrame("Frame")
	local elapsed = 0
	local attempts = 0
	local maxAttempts = 3

	waitFrame:SetScript("OnUpdate", function(self, delta)
		elapsed = elapsed + delta

		if elapsed >= 0.5 then
			elapsed = 0
			attempts = attempts + 1

			local _, _, _, _, _, _, _, _, _, tex = GetItemInfo(itemId)

			if tex and slotFrame.icon then
				slotFrame.icon:SetTexture(tex)
				self:SetScript("OnUpdate", nil)
			elseif attempts >= maxAttempts then
				self:SetScript("OnUpdate", nil)
			else
				GetItemInfo(itemId)
			end
		end
	end)
end

-- Export
RaiderCheck.UI = RaiderCheck.UI or {}
RaiderCheck.UI.Inspect = Inspect
