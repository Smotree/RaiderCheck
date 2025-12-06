-- RaiderCheck TalentsInspect Module
-- Отображение всех талантов на одном окне

if not RaiderCheck then
	RaiderCheck = {}
end

local TALENT_BUTTON_SIZE = 32
local TALENT_SPACING = 1

-- Создать окно просмотра талантов
function RaiderCheck:CreateTalentVisualFrame()
	if self.talentVisualFrame then
		return
	end

	local frame = CreateFrame("Frame", "RaiderCheckTalentFrame", UIParent)
	frame:SetSize(460, 480)
	frame:SetPoint("TOPLEFT")
	frame:SetFrameStrata("HIGH")
	frame:Hide()

	-- Современный фон
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
	frame:SetScript("OnDragStart", function(f)
		f:StartMoving()
	end)
	frame:SetScript("OnDragStop", function(f)
		f:StopMovingOrSizing()
	end)

	-- Градиентный заголовок
	local header = frame:CreateTexture(nil, "ARTWORK")
	header:SetPoint("TOPLEFT", 4, -4)
	header:SetPoint("TOPRIGHT", -4, -4)
	header:SetHeight(50)
	header:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	header:SetGradientAlpha("VERTICAL", 0.1, 0.3, 0.5, 0.8, 0.05, 0.15, 0.25, 0.8)

	-- Разделитель
	local headerLine = frame:CreateTexture(nil, "OVERLAY")
	headerLine:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 0)
	headerLine:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, 0)
	headerLine:SetHeight(2)
	headerLine:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	headerLine:SetVertexColor(0.3, 0.7, 1, 0.8)

	-- Заголовок
	local title = frame:CreateFontString(nil, "OVERLAY")
	title:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
	title:SetPoint("TOPLEFT", 15, -18)
	title:SetTextColor(0.3, 0.8, 1, 1)
	frame.title = title

	-- Подзаголовок
	local subtitle = frame:CreateFontString(nil, "OVERLAY")
	subtitle:SetFont("Fonts\\FRIZQT__.TTF", 10)
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
	subtitle:SetText("Распределение талантов")
	subtitle:SetTextColor(0.7, 0.7, 0.7, 1)

	-- Современная кнопка закрытия
	local closeBtn = CreateFrame("Button", nil, frame)
	closeBtn:SetSize(24, 24)
	closeBtn:SetPoint("TOPRIGHT", -8, -8)

	local closeBg = closeBtn:CreateTexture(nil, "BACKGROUND")
	closeBg:SetAllPoints()
	closeBg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	closeBg:SetVertexColor(0.8, 0.2, 0.2, 0.6)

	local closeText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	closeText:SetPoint("CENTER")
	closeText:SetText("×")
	closeText:SetTextColor(1, 1, 1, 1)

	closeBtn:SetScript("OnEnter", function(self)
		closeBg:SetVertexColor(1, 0.3, 0.3, 0.9)
		self:SetScale(1.1)
	end)
	closeBtn:SetScript("OnLeave", function(self)
		closeBg:SetVertexColor(0.8, 0.2, 0.2, 0.6)
		self:SetScale(1.0)
	end)
	closeBtn:SetScript("OnClick", function()
		frame:Hide()
	end)

	-- Контейнер для всех деревьев (горизонтальный)
	local contentFrame = CreateFrame("Frame", nil, frame)
	contentFrame:SetPoint("TOPLEFT", 10, -65)
	contentFrame:SetPoint("BOTTOMRIGHT", -10, 10)
	frame.contentFrame = contentFrame

	self.talentVisualFrame = frame
end

-- Показать окно талантов
function RaiderCheck:ShowTalentVisualFrame(playerName)
	if not self.talentVisualFrame then
		self:CreateTalentVisualFrame()
	end

	local playerData = self.playerData[playerName]
	if not playerData then
		print("|cFF00FF00RaiderCheck:|r Нет данных для " .. playerName)
		return
	end

	self.inspectedPlayer = playerName

	-- Устанавливаем заголовок
	local className = self:GetPlayerClass(playerName)
	local classColor = RAID_CLASS_COLORS[className] or { r = 1, g = 1, b = 1 }
	self.talentVisualFrame.title:SetText("Таланты: " .. playerName)
	self.talentVisualFrame.title:SetTextColor(classColor.r, classColor.g, classColor.b)

	-- Обновляем содержимое
	self:UpdateAllTalentTrees(playerName, className)

	self.talentVisualFrame:Show()
end

-- Создать отдельное мини-окно для дерева талантов
function RaiderCheck:CreateTreeSubFrame(parent, tabIndex, xOffset, className, playerData)
	local treeWidth = 150

	-- Подсчёт потраченных очков
	local pointsSpent = 0
	local maxTier = 0
	if playerData and playerData.talentsDetailed and playerData.talentsDetailed[tabIndex] then
		for talentIndex, talentData in pairs(playerData.talentsDetailed[tabIndex]) do
			pointsSpent = pointsSpent + (talentData.rank or 0)

			-- Получаем tier из базы для расчёта высоты
			local dbTalent = RaiderCheck_GetTalentFromDB(className, tabIndex, talentIndex)
			if dbTalent and dbTalent.tier and dbTalent.tier > maxTier then
				maxTier = dbTalent.tier
			end
		end
	end

	local specName = self:GetSpecName(className, tabIndex)

	-- Создаём мини-окно для дерева
	local subFrame = CreateFrame("Frame", nil, parent)
	subFrame:SetPoint("TOPLEFT", xOffset - 8, 8)
	subFrame:SetSize(treeWidth, 420)

	-- Рамка с темным фоном
	subFrame:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 12,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	subFrame:SetBackdropColor(0.05, 0.08, 0.12, 0.9)
	subFrame:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)

	-- Заголовок (название специализации)
	local headerText = subFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	headerText:SetPoint("TOP", 0, -10)
	headerText:SetText(specName)
	headerText:SetTextColor(1, 0.82, 0)

	-- Количество очков
	local pointsText = subFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	pointsText:SetPoint("TOP", 0, -28)
	pointsText:SetText(pointsSpent .. " очков")
	pointsText:SetTextColor(0.8, 0.8, 0.8)

	-- Контейнер для талантов внутри мини-окна
	local contentArea = CreateFrame("Frame", nil, subFrame)
	contentArea:SetPoint("TOPLEFT", 10, -45)
	contentArea:SetPoint("BOTTOMRIGHT", -10, 10)

	-- Отображаем таланты, которые есть в данных playerData
	-- v5.0 формат: {talentIndex, rank} - остальное из TalentsDatabase
	-- Показываем ВСЕ таланты для полноты древа класса
	local talentCount = 0
	if playerData and playerData.talentsDetailed and playerData.talentsDetailed[tabIndex] then
		for talentIndex, talentData in pairs(playerData.talentsDetailed[tabIndex]) do
			-- Показываем все таланты (даже rank=0)
			if talentData then
				talentCount = talentCount + 1
				self:CreateTalentButtonFromData(contentArea, talentData, tabIndex, className)
			end
		end
	end

	if RaiderCheck and RaiderCheck.debugTalents then
		print(string.format("CreateTreeSubFrame Tree %d: %d talents to display", tabIndex, talentCount))
	end

	return subFrame
end

-- Обновить все деревья талантов
function RaiderCheck:UpdateAllTalentTrees(playerName, className)
	local contentFrame = self.talentVisualFrame.contentFrame

	-- Очистка старого содержимого
	local children = { contentFrame:GetChildren() }
	for _, child in ipairs(children) do
		child:Hide()
		child:SetParent(nil)
	end

	local playerData = self.playerData[playerName]
	local xOffset = 0

	-- Создаём 3 мини-окна для деревьев (слева направо)
	for tabIndex = 1, 3 do
		local subFrame = self:CreateTreeSubFrame(contentFrame, tabIndex, xOffset, className, playerData)
		xOffset = xOffset + 152 -- ширина + отступ
	end
end

-- Создать кнопку таланта используя данные полученные от другого игрока (v5.0 формат)
-- talentData структура: {talentIndex, rank}
-- Остальные данные (tier, column, icon, name, maxRank) берутся из TalentsDatabase
function RaiderCheck:CreateTalentButtonFromData(parent, talentData, tabIndex, className)
	if not talentData or not talentData.talentIndex then
		return
	end

	local talentIndex = talentData.talentIndex
	local rank = talentData.rank or 0

	-- Получаем данные из базы
	local dbTalent = RaiderCheck_GetTalentFromDB(className, tabIndex, talentIndex)
	if not dbTalent then
		-- Талант не найден в базе - пропускаем
		if RaiderCheck.debugTalents then
			print(
				string.format(
					"[TalentsInspect v5.0] Talent not found in DB: class=%s, tab=%d, idx=%d",
					className,
					tabIndex,
					talentIndex
				)
			)
		end
		return
	end

	local tier = dbTalent.tier
	local col = dbTalent.column
	local icon = dbTalent.icon
	local name = dbTalent.name or "Талант"
	local maxRank = dbTalent.maxRank or 1

	-- Проверяем валидность позиции
	if not tier or not col or tier == 0 or col == 0 then
		return
	end

	-- Проверяем наличие иконки
	if not icon then
		return
	end

	local rank = talentData.rank or 0

	-- Позиция в гриде на основе tier и column из базы данных
	local xOffset = (col - 1) * (TALENT_BUTTON_SIZE + TALENT_SPACING)
	local yOffset = (tier - 1) * (TALENT_BUTTON_SIZE + TALENT_SPACING)

	local btn = CreateFrame("Button", nil, parent)
	btn:SetSize(TALENT_BUTTON_SIZE, TALENT_BUTTON_SIZE)
	btn:SetPoint("TOPLEFT", xOffset, -yOffset)

	-- Фон
	local bg = btn:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetTexture("Interface\\Buttons\\UI-Quickslot2")

	-- Иконка
	local iconTex = btn:CreateTexture(nil, "ARTWORK")
	iconTex:SetAllPoints()
	iconTex:SetTexture(icon)
	iconTex:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	-- -- Рамка
	-- local border = btn:CreateTexture(nil, "OVERLAY")
	-- border:SetAllPoints()
	-- border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
	-- border:SetBlendMode("ADD")
	-- border:Show()

	-- Текст с рангом (если изучен)
	if rank > 0 then
		local rankText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		rankText:SetPoint("BOTTOMRIGHT", 2, 2)
		rankText:SetText(rank .. "/" .. maxRank)
		rankText:SetTextColor(0, 1, 0)
	else
		iconTex:SetDesaturated(true)
		iconTex:SetAlpha(1)
	end

	-- Тултип
	btn:SetScript("OnEnter", function(s)
		GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
		GameTooltip:SetText(name, 1, 1, 1)
		GameTooltip:AddLine("Уровень: " .. rank .. "/" .. maxRank, 1, 1, 1)
		GameTooltip:AddLine(GetSpellDescription(dbTalent.spellID) or "", nil, nil, nil, true)
		GameTooltip:AddLine("ID: " .. dbTalent.spellID)
		GameTooltip:Show()
	end)

	btn:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
end

-- Алиас для совместимости
RaiderCheck.ShowTalentsInspectFrame = RaiderCheck.ShowTalentVisualFrame

-- Сообщение об успешной загрузке модуля
print("|cFF00FF00RaiderCheck TalentsInspect:|r Загружен (3 мини-окна для деревьев)")
