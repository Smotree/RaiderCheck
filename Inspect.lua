-- RaiderCheck Inspect Module
-- Модуль для отображения детального окна с предметами игрока

if not RaiderCheck then
	RaiderCheck = {}
end

-- Создать окно детального осмотра игрока
function RaiderCheck:CreateInspectFrame()
	if self.inspectFrame then
		return
	end

	local frame = CreateFrame("Frame", "RaiderCheckInspectFrame", UIParent)
	frame:SetSize(212, 450)
	frame:SetPoint("BOTTOMLEFT")
	frame:SetFrameStrata("HIGH")
	frame:Hide()

	-- Современный фон с темной темой
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

	-- Градиентный заголовок
	local header = frame:CreateTexture(nil, "ARTWORK")
	header:SetPoint("TOPLEFT", 4, -4)
	header:SetPoint("TOPRIGHT", -4, -4)
	header:SetHeight(50)
	header:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	header:SetGradientAlpha("VERTICAL", 0.1, 0.3, 0.5, 0.8, 0.05, 0.15, 0.25, 0.8)

	-- Разделитель под заголовком
	local headerLine = frame:CreateTexture(nil, "OVERLAY")
	headerLine:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 0)
	headerLine:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, 0)
	headerLine:SetHeight(2)
	headerLine:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	headerLine:SetVertexColor(0.3, 0.7, 1, 0.8)

	-- Заголовок с названием игрока
	local title = frame:CreateFontString(nil, "OVERLAY")
	title:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
	title:SetPoint("TOPLEFT", 15, -18)
	title:SetTextColor(0.3, 0.8, 1, 1)
	frame.title = title

	-- Подзаголовок
	local subtitle = frame:CreateFontString(nil, "OVERLAY")
	subtitle:SetFont("Fonts\\FRIZQT__.TTF", 10)
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
	subtitle:SetText("Осмотр снаряжения")
	subtitle:SetTextColor(0.7, 0.7, 0.7, 1)

	-- Современная кнопка закрытия
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

	-- Слоты для предметов
	local slots = {
		-- Левая сторона
		{ name = "HeadSlot", x = 6, y = -60 },
		{ name = "NeckSlot", x = 6, y = -100 },
		{ name = "ShoulderSlot", x = 6, y = -140 },
		{ name = "BackSlot", x = 6, y = -180 },
		{ name = "ChestSlot", x = 6, y = -220 },
		{ name = "ShirtSlot", x = 6, y = -260 },
		{ name = "TabardSlot", x = 6, y = -300 },
		{ name = "WristSlot", x = 6, y = -340 },

		-- Правая сторона
		{ name = "HandsSlot", x = 170, y = -60 },
		{ name = "WaistSlot", x = 170, y = -100 },
		{ name = "LegsSlot", x = 170, y = -140 },
		{ name = "FeetSlot", x = 170, y = -180 },
		{ name = "Finger0Slot", x = 170, y = -220 },
		{ name = "Finger1Slot", x = 170, y = -260 },
		{ name = "Trinket0Slot", x = 170, y = -300 },
		{ name = "Trinket1Slot", x = 170, y = -340 },

		-- Оружие внизу
		{ name = "MainHandSlot", x = 48, y = -380 },
		{ name = "SecondaryHandSlot", x = 88, y = -380 },
		{ name = "RangedSlot", x = 128, y = -380 },
	}

	frame.itemSlots = {}

	for _, slotInfo in ipairs(slots) do
		local slotFrame = CreateFrame("Button", nil, frame)
		slotFrame:SetSize(37, 37)
		slotFrame:SetPoint("TOPLEFT", slotInfo.x, slotInfo.y)

		-- Фон слота4
		slotFrame:SetNormalTexture("Interface\\PaperDoll\\UI-PaperDoll-Slot-" .. slotInfo.name)

		-- Иконка предмета
		local icon = slotFrame:CreateTexture(nil, "ARTWORK")
		icon:SetAllPoints()
		slotFrame.icon = icon

		-- Индикатор зачарования (зеленая рамка если зачаровано)
		local enchantBorder = slotFrame:CreateTexture(nil, "OVERLAY")
		enchantBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
		enchantBorder:SetBlendMode("ADD")
		enchantBorder:SetAllPoints()
		enchantBorder:SetPoint("TOPLEFT", -11, 12)
		enchantBorder:SetPoint("BOTTOMRIGHT", 12, -11)
		enchantBorder:Hide()
		slotFrame.enchantBorder = enchantBorder

		-- Индикатор отсутствия зачарования (красная рамка)
		local noEnchantBorder = slotFrame:CreateTexture(nil, "OVERLAY")
		noEnchantBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
		noEnchantBorder:SetBlendMode("ADD")
		noEnchantBorder:SetVertexColor(1, 0, 0)
		noEnchantBorder:SetAllPoints()
		noEnchantBorder:SetPoint("TOPLEFT", -11, 12)
		noEnchantBorder:SetPoint("BOTTOMRIGHT", 12, -11)
		noEnchantBorder:Hide()
		slotFrame.noEnchantBorder = noEnchantBorder

		-- Индикатор пустых сокетов (желтая рамка)
		local socketBorder = slotFrame:CreateTexture(nil, "OVERLAY")
		socketBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
		socketBorder:SetBlendMode("ADD")
		socketBorder:SetVertexColor(1, 1, 0)
		socketBorder:SetAllPoints()
		socketBorder:SetPoint("TOPLEFT", -11, 12)
		socketBorder:SetPoint("BOTTOMRIGHT", 12, -11)
		socketBorder:Hide()
		slotFrame.socketBorder = socketBorder

		-- Индикатор комбинации проблем (оранжевая рамка: нет энчанта + пустые сокеты)
		local combinedBorder = slotFrame:CreateTexture(nil, "OVERLAY")
		combinedBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
		combinedBorder:SetBlendMode("ADD")
		combinedBorder:SetVertexColor(1, 0.5, 0)
		combinedBorder:SetAllPoints()
		combinedBorder:SetPoint("TOPLEFT", -11, 12)
		combinedBorder:SetPoint("BOTTOMRIGHT", 12, -11)
		combinedBorder:Hide()
		slotFrame.combinedBorder = combinedBorder

		-- Индикатор устаревших камней (фиолетовая рамка)
		local gemBorder = slotFrame:CreateTexture(nil, "OVERLAY")
		gemBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
		gemBorder:SetBlendMode("ADD")
		gemBorder:SetVertexColor(0.7, 0, 1)
		gemBorder:SetAllPoints()
		gemBorder:SetPoint("TOPLEFT", -11, 12)
		gemBorder:SetPoint("BOTTOMRIGHT", 12, -11)
		gemBorder:Hide()
		slotFrame.gemBorder = gemBorder -- Тултип
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
		frame.itemSlots[slotInfo.name] = slotFrame
	end

	local talentsButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	talentsButton:SetSize(150, 25)
	talentsButton:SetPoint("TOP", 0, -420)
	talentsButton:SetText("Детальные таланты")
	talentsButton:SetScript("OnClick", function()
		if RaiderCheck.ShowTalentsInspectFrame then
			RaiderCheck:ShowTalentsInspectFrame(RaiderCheck.inspectFrame.currentPlayer)
		end
	end)
	frame.talentsButton = talentsButton

	self.inspectFrame = frame
end

-- Показать окно осмотра игрока
function RaiderCheck:ShowInspectFrame(playerName)
	if not self.inspectFrame then
		self:CreateInspectFrame()
	end

	local playerData = self.playerData[playerName]
	if not playerData then
		print("|cFF00FF00RaiderCheck:|r Нет данных для " .. playerName)
		return
	end

	-- Сохраняем текущего игрока
	self.inspectFrame.currentPlayer = playerName

	-- Устанавливаем заголовок
	local className = self:GetPlayerClass(playerName)
	local classColor = RAID_CLASS_COLORS[className] or { r = 1, g = 1, b = 1 }
	self.inspectFrame.title:SetText(playerName)
	self.inspectFrame.title:SetTextColor(classColor.r, classColor.g, classColor.b)

	-- Обновляем предметы
	self:UpdateInspectFrameItems(playerName, playerData)

	-- Проверяем наличие неизвестных гемов (вызовет окно ошибки если найдены)
	if playerData and self.CheckGemQuality then
		self:CheckGemQuality(playerData)
	end

	self.inspectFrame:Show()
end -- Обновить предметы в окне осмотра
function RaiderCheck:UpdateInspectFrameItems(playerName, playerData)
	local enchantableSlots = {
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

	-- Добавляем кольца для энчантеров
	if playerData and playerData.professions then
		for _, prof in ipairs(playerData.professions) do
			if (prof.name == "Enchanting" or prof.name == "Наложение чар") and prof.rank >= 400 then
				enchantableSlots.Finger0Slot = true
				enchantableSlots.Finger1Slot = true
				break
			end
		end
	end

	local slotCount = 0
	for _ in pairs(self.inspectFrame.itemSlots) do
		slotCount = slotCount + 1
	end

	for slotName, _ in pairs(self.inspectFrame.itemSlots) do
		local slotId = GetInventorySlotInfo(slotName)
	end

	for slotName, slotFrame in pairs(self.inspectFrame.itemSlots) do
		local success, err = pcall(function()
			-- Очищаем слот
			slotFrame.icon:SetTexture(nil)
			slotFrame.enchantBorder:Hide()
			slotFrame.noEnchantBorder:Hide()
			slotFrame.socketBorder:Hide()
			slotFrame.gemBorder:Hide()
			slotFrame.itemLink = nil

			-- Получаем ID слота
			local slotId = GetInventorySlotInfo(slotName)

			if slotId and playerData.items and playerData.items[slotId] then
				local itemInfo = playerData.items[slotId]

				-- Используем itemId напрямую если itemLink пустая
				local itemId = itemInfo.itemId
				local decodedLink = nil

				-- Устанавливаем иконку предмета
				if itemInfo.itemLink then
					-- Декодируем itemLink
					decodedLink = itemInfo.itemLink:gsub("~", ":")
					slotFrame.itemLink = decodedLink

					-- Парсим itemId из itemLink если не было
					if not itemId then
						itemId = decodedLink:match("item:(%d+)")
						itemId = itemId and tonumber(itemId)
					end
				end

				-- Если есть itemId (из данных или из itemLink), показываем предмет
				if itemId then
					-- Пробуем получить информацию о предмете
					local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture =
						GetItemInfo(itemId)

					if itemTexture then
						slotFrame.icon:SetTexture(itemTexture)
					else
						-- Предмет не закеширован, запрашиваем и делаем несколько попыток
						GetItemInfo(itemId)

						-- Повторяем попытки с увеличивающейся задержкой
						local slot = slotFrame
						local id = itemId
						local slotDebugName = slotName

						local waitFrame = CreateFrame("Frame")
						local elapsed = 0
						local attempts = 0
						local maxAttempts = 3

						waitFrame:SetScript("OnUpdate", function(self, delta)
							elapsed = elapsed + delta

							if elapsed >= 0.5 then
								elapsed = 0
								attempts = attempts + 1

								local iName, iLink, iRarity, iLevel, iMinLevel, iType, iSubType, iStackCount, iEquipLoc, tex =
									GetItemInfo(id)

								if tex and slot.icon then
									slot.icon:SetTexture(tex)
									self:SetScript("OnUpdate", nil)
								elseif attempts >= maxAttempts then
									-- После 3 попыток прекращаем
									self:SetScript("OnUpdate", nil)
								else
									-- Запрашиваем снова
									GetItemInfo(id)
								end
							end
						end)
					end
				end -- конец if itemId

				-- Проверяем зачарование и сокеты
				local dynamicEnchantable = enchantableSlots[slotName]
				if slotName == "RangedSlot" and itemId then
					local _, _, _, _, _, itemType, itemSubType = GetItemInfo(itemId)
					local className = self:GetPlayerClass(playerName)

					-- Помощник для проверки подтипа (учитываем ru/eng подстроки)
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

					-- Не зачаровываем жезлы/идолы/манускрипты/печати/метательное
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

					-- Луки/арбалеты/огнестрельное обязательны только для охотника
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
					}

					if matches(itemSubType, nonEnchantableSubs) then
						dynamicEnchantable = false
					elseif matches(itemSubType, optionalRangedSubs) and className ~= "HUNTER" then
						dynamicEnchantable = false
					end
				end

				local needsEnchant = dynamicEnchantable and not itemInfo.enchant
				local hasEmptySockets = false
				local hasLowQualityGems = false

				-- Проверяем качество камней (используем item ID напрямую)
				if itemInfo.gems and #itemInfo.gems > 0 then
					for _, gemId in ipairs(itemInfo.gems) do
						local gemIdNum = tonumber(gemId)
						if gemIdNum then
							local isAcceptable = self:IsGemQualityAcceptable(gemIdNum)
							-- isAcceptable: true = OK, false = низкое качество, nil = неизвестный гем
							if isAcceptable == false then
								hasLowQualityGems = true
								break
							end
						end
					end
				end

				-- Слоты, которые могут иметь сокеты (исключаем аксессуары)
				local socketableSlots = {
					["HeadSlot"] = true,
					["ShoulderSlot"] = true,
					["ChestSlot"] = true,
					["WristSlot"] = true,
					["HandsSlot"] = true,
					["WaistSlot"] = true,
					["LegsSlot"] = true,
					["FeetSlot"] = true,
					["MainHandSlot"] = true,
					["SecondaryHandSlot"] = true,
					["RangedSlot"] = true,
				}

				-- Проверяем пустые сокеты только для подходящих слотов
				if socketableSlots[slotName] and itemInfo.totalSockets and itemInfo.totalSockets > 0 then
					local filledSockets = #itemInfo.gems
					if filledSockets < itemInfo.totalSockets then
						hasEmptySockets = true
					end
				end

				-- Показываем соответствующую рамку
				if hasLowQualityGems then
					-- Фиолетовая рамка: устаревшие камни (приоритет выше всего)
					slotFrame.gemBorder:Show()
				elseif needsEnchant and hasEmptySockets then
					-- Оранжевая рамка: нет энчанта И пустые сокеты
					slotFrame.combinedBorder:Show()
				elseif needsEnchant then
					-- Красная рамка: только нет энчанта
					slotFrame.noEnchantBorder:Show()
				elseif hasEmptySockets then
					-- Желтая рамка: только пустые сокеты
					slotFrame.socketBorder:Show()
				elseif enchantableSlots[slotName] and itemInfo.enchant then
					-- Зеленая рамка: все хорошо (есть энчант)
					slotFrame.enchantBorder:Show()
					slotFrame.enchantBorder:SetVertexColor(0, 1, 0)
				end
			end
		end) -- конец pcall

		-- Ошибки молча игнорируем в продакшене
	end
end
