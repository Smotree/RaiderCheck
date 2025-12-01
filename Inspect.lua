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
	frame:SetSize(384, 512)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("HIGH")
	frame:Hide()

	-- Фон
	frame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = { left = 11, right = 12, top = 12, bottom = 11 },
	})

	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

	-- Заголовок
	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOP", 0, -15)
	frame.title = title

	-- Кнопка закрытия
	local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	closeButton:SetPoint("TOPRIGHT", -5, -5)

	-- Слоты для предметов
	local slots = {
		-- Левая сторона
		{ name = "HeadSlot", x = 40, y = -50 },
		{ name = "NeckSlot", x = 40, y = -90 },
		{ name = "ShoulderSlot", x = 40, y = -130 },
		{ name = "BackSlot", x = 40, y = -170 },
		{ name = "ChestSlot", x = 40, y = -210 },
		{ name = "ShirtSlot", x = 40, y = -250 },
		{ name = "TabardSlot", x = 40, y = -290 },
		{ name = "WristSlot", x = 40, y = -330 },

		-- Правая сторона
		{ name = "HandsSlot", x = 344, y = -50 },
		{ name = "WaistSlot", x = 344, y = -90 },
		{ name = "LegsSlot", x = 344, y = -130 },
		{ name = "FeetSlot", x = 344, y = -170 },
		{ name = "Finger0Slot", x = 344, y = -210 },
		{ name = "Finger1Slot", x = 344, y = -250 },
		{ name = "Trinket0Slot", x = 344, y = -290 },
		{ name = "Trinket1Slot", x = 344, y = -330 },

		-- Оружие внизу
		{ name = "MainHandSlot", x = 40, y = -410 },
		{ name = "SecondaryHandSlot", x = 192, y = -410 },
		{ name = "RangedSlot", x = 344, y = -410 },
	}

	frame.itemSlots = {}

	for _, slotInfo in ipairs(slots) do
		local slotFrame = CreateFrame("Button", nil, frame)
		slotFrame:SetSize(37, 37)
		slotFrame:SetPoint("TOPLEFT", slotInfo.x, slotInfo.y)

		-- Фон слота
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
		enchantBorder:Hide()
		slotFrame.enchantBorder = enchantBorder

		-- Индикатор отсутствия зачарования (красная рамка)
		local noEnchantBorder = slotFrame:CreateTexture(nil, "OVERLAY")
		noEnchantBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
		noEnchantBorder:SetBlendMode("ADD")
		noEnchantBorder:SetVertexColor(1, 0, 0)
		noEnchantBorder:SetAllPoints()
		noEnchantBorder:Hide()
		slotFrame.noEnchantBorder = noEnchantBorder

		-- Индикатор пустых сокетов (желтая рамка)
		local socketBorder = slotFrame:CreateTexture(nil, "OVERLAY")
		socketBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
		socketBorder:SetBlendMode("ADD")
		socketBorder:SetVertexColor(1, 1, 0)
		socketBorder:SetAllPoints()
		socketBorder:Hide()
		slotFrame.socketBorder = socketBorder

		-- Тултип
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

	-- Информация о талантах
	local talentLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	talentLabel:SetPoint("TOP", 0, -455)
	talentLabel:SetText("Специализация:")

	local talentText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	talentText:SetPoint("TOP", talentLabel, "BOTTOM", 0, -2)
	frame.talentText = talentText

	-- Информация о профессиях
	local profLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	profLabel:SetPoint("TOP", talentText, "BOTTOM", 0, -5)
	profLabel:SetText("Профессии:")

	local profText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	profText:SetPoint("TOP", profLabel, "BOTTOM", 0, -2)
	profText:SetWidth(350)
	profText:SetJustifyH("CENTER")
	frame.profText = profText

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

	-- Устанавливаем заголовок
	local className = self:GetPlayerClass(playerName)
	local classColor = RAID_CLASS_COLORS[className] or { r = 1, g = 1, b = 1 }
	self.inspectFrame.title:SetText(playerName)
	self.inspectFrame.title:SetTextColor(classColor.r, classColor.g, classColor.b)

	-- Обновляем предметы
	self:UpdateInspectFrameItems(playerName, playerData)

	-- Обновляем таланты
	local talentAnalysis = self:AnalyzePlayerTalents(playerName)
	if talentAnalysis.hasData then
		self.inspectFrame.talentText:SetText(
			string.format("%s (%s)", talentAnalysis.specName, talentAnalysis.distribution)
		)
	else
		self.inspectFrame.talentText:SetText("Нет данных")
	end

	-- Обновляем профессии
	if self.AnalyzePlayerProfessions then
		local profAnalysis = self:AnalyzePlayerProfessions(playerName)
		if profAnalysis.hasData and profAnalysis.count > 0 then
			local profStrings = {}
			for _, prof in ipairs(profAnalysis.professions) do
				table.insert(profStrings, string.format("%s (%d)", prof.name, prof.rank))
			end
			self.inspectFrame.profText:SetText(table.concat(profStrings, ", "))
		else
			self.inspectFrame.profText:SetText("Нет профессий")
		end
	else
		self.inspectFrame.profText:SetText("Нет данных о профессиях")
	end

	self.inspectFrame:Show()
end

-- Обновить предметы в окне осмотра
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
	}

	-- DEBUG: Проверяем количество слотов
	local slotCount = 0
	for _ in pairs(self.inspectFrame.itemSlots) do
		slotCount = slotCount + 1
	end
	print(string.format("[DEBUG] Всего слотов в окне: %d", slotCount))

	-- DEBUG: Выводим имена всех слотов
	for slotName, _ in pairs(self.inspectFrame.itemSlots) do
		local slotId = GetInventorySlotInfo(slotName)
		print(string.format("[DEBUG] Окно имеет слот: %s (ID %d)", slotName, slotId or 0))
	end

	for slotName, slotFrame in pairs(self.inspectFrame.itemSlots) do
		print(string.format("[DEBUG LOOP] Начало обработки слота: %s", slotName))

		local success, err = pcall(function()
			-- Очищаем слот
			slotFrame.icon:SetTexture(nil)
			slotFrame.enchantBorder:Hide()
			slotFrame.noEnchantBorder:Hide()
			slotFrame.socketBorder:Hide()
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

				-- Проверяем зачарование
				if enchantableSlots[slotName] then
					if itemInfo.enchant then
						slotFrame.enchantBorder:Show()
						slotFrame.enchantBorder:SetVertexColor(0, 1, 0)
					else
						slotFrame.noEnchantBorder:Show()
					end
				end

				-- Проверяем пустые сокеты
				if itemInfo.totalSockets and itemInfo.totalSockets > 0 then
					local filledSockets = #itemInfo.gems
					if filledSockets < itemInfo.totalSockets then
						slotFrame.socketBorder:Show()
					end
				end
			end
		end) -- конец pcall

		if not success then
			print(string.format("[DEBUG ERROR] Ошибка в слоте %s: %s", slotName, tostring(err)))
		end
	end
end

-- Сообщение об успешной загрузке модуля
print("|cFF00FF00RaiderCheck Inspect:|r Модуль загружен успешно")
