-- RaiderCheck UI TalentsInspect Module
-- Visual talent tree display

local _, RC = ...
RC.UI = RC.UI or {}
RC.UI.TalentsInspect = {}
local TI = RC.UI.TalentsInspect
local Core = RC.Core
local C = RC.Data.Constants
local Talents = RC.Logic.Talents

-- ============================================
-- CONSTANTS
-- ============================================
local TALENT_BUTTON_SIZE = 32
local TALENT_SPACING = 1
local TREE_WIDTH = 150
local TREE_HEIGHT = 420

-- ============================================
-- STATE
-- ============================================
local talentFrame = nil
local currentPlayer = nil

-- ============================================
-- FRAME CREATION
-- ============================================

function TI.Create()
	if talentFrame then
		return talentFrame
	end

	local frame = CreateFrame("Frame", "RaiderCheckTalentFrame", UIParent)
	frame:SetSize(460, 480)
	frame:SetPoint("TOPLEFT")
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
	subtitle:SetText("Распределение талантов")
	subtitle:SetTextColor(0.7, 0.7, 0.7, 1)

	-- Close button
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

	-- Content frame for trees
	local contentFrame = CreateFrame("Frame", nil, frame)
	contentFrame:SetPoint("TOPLEFT", 10, -65)
	contentFrame:SetPoint("BOTTOMRIGHT", -10, 10)
	frame.contentFrame = contentFrame

	talentFrame = frame
	return frame
end

-- ============================================
-- TREE SUBFRAME CREATION
-- ============================================

function TI.CreateTreeSubFrame(parent, tabIndex, xOffset, className, playerData)
	-- Calculate points spent
	local pointsSpent = 0
	if playerData and playerData.talentsDetailed and playerData.talentsDetailed[tabIndex] then
		for _, talentData in pairs(playerData.talentsDetailed[tabIndex]) do
			pointsSpent = pointsSpent + (talentData.rank or 0)
		end
	end

	local specName = C.GetSpecName(className, tabIndex)

	-- Create subframe
	local subFrame = CreateFrame("Frame", nil, parent)
	subFrame:SetPoint("TOPLEFT", xOffset - 8, 8)
	subFrame:SetSize(TREE_WIDTH, TREE_HEIGHT)

	-- Background
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

	-- Header (spec name)
	local headerText = subFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	headerText:SetPoint("TOP", 0, -10)
	headerText:SetText(specName)
	headerText:SetTextColor(1, 0.82, 0)

	-- Points text
	local pointsText = subFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	pointsText:SetPoint("TOP", 0, -28)
	pointsText:SetText(pointsSpent .. " очков")
	pointsText:SetTextColor(0.8, 0.8, 0.8)

	-- Content area for talents
	local contentArea = CreateFrame("Frame", nil, subFrame)
	contentArea:SetPoint("TOPLEFT", 10, -45)
	contentArea:SetPoint("BOTTOMRIGHT", -10, 10)

	-- Display talents
	if playerData and playerData.talentsDetailed and playerData.talentsDetailed[tabIndex] then
		for talentIndex, talentData in pairs(playerData.talentsDetailed[tabIndex]) do
			if talentData then
				TI.CreateTalentButton(contentArea, talentData, tabIndex, className)
			end
		end
	end

	return subFrame
end

-- ============================================
-- TALENT BUTTON CREATION
-- ============================================

function TI.CreateTalentButton(parent, talentData, tabIndex, className)
	if not talentData or not talentData.talentIndex then
		return
	end

	local talentIndex = talentData.talentIndex
	local rank = talentData.rank or 0

	-- Get data from database
	local dbTalent = nil
	if RaiderCheck_GetTalentFromDB then
		dbTalent = RaiderCheck_GetTalentFromDB(className, tabIndex, talentIndex)
	end

	if not dbTalent then
		return
	end

	local tier = dbTalent.tier
	local col = dbTalent.column
	local icon = dbTalent.icon
	local name = dbTalent.name or "Талант"
	local maxRank = dbTalent.maxRank or 1

	-- Validate position
	if not tier or not col or tier == 0 or col == 0 then
		return
	end
	if not icon then
		return
	end

	-- Calculate position
	local xOffset = (col - 1) * (TALENT_BUTTON_SIZE + TALENT_SPACING)
	local yOffset = (tier - 1) * (TALENT_BUTTON_SIZE + TALENT_SPACING)

	local btn = CreateFrame("Button", nil, parent)
	btn:SetSize(TALENT_BUTTON_SIZE, TALENT_BUTTON_SIZE)
	btn:SetPoint("TOPLEFT", xOffset, -yOffset)

	-- Background
	local bg = btn:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetTexture("Interface\\Buttons\\UI-Quickslot2")

	-- Icon
	local iconTex = btn:CreateTexture(nil, "ARTWORK")
	iconTex:SetAllPoints()
	iconTex:SetTexture(icon)
	iconTex:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	-- Rank text
	if rank > 0 then
		local rankText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		rankText:SetPoint("BOTTOMRIGHT", 2, 2)
		rankText:SetText(rank .. "/" .. maxRank)
		rankText:SetTextColor(0, 1, 0)
	else
		iconTex:SetDesaturated(true)
		iconTex:SetAlpha(1)
	end

	-- Tooltip
	btn:SetScript("OnEnter", function(s)
		GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
		GameTooltip:SetText(name, 1, 1, 1)
		GameTooltip:AddLine("Уровень: " .. rank .. "/" .. maxRank, 1, 1, 1)
		if dbTalent.spellID then
			local desc = GetSpellDescription and GetSpellDescription(dbTalent.spellID) or ""
			if desc and desc ~= "" then
				GameTooltip:AddLine(desc, nil, nil, nil, true)
			end
			GameTooltip:AddLine("ID: " .. dbTalent.spellID, 0.5, 0.5, 0.5)
		end
		GameTooltip:Show()
	end)

	btn:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
end

-- ============================================
-- UPDATE ALL TREES
-- ============================================

function TI.UpdateAllTrees(playerName, className)
	local contentFrame = talentFrame.contentFrame

	-- Clear old content
	local children = { contentFrame:GetChildren() }
	for _, child in ipairs(children) do
		child:Hide()
		child:SetParent(nil)
	end

	local playerData = Core.playerData[playerName]
	local xOffset = 0

	-- Create 3 tree subframes
	for tabIndex = 1, 3 do
		local subFrame = TI.CreateTreeSubFrame(contentFrame, tabIndex, xOffset, className, playerData)
		xOffset = xOffset + 152
	end
end

-- ============================================
-- SHOW / HIDE
-- ============================================

function TI.Show(playerName)
	if not talentFrame then
		TI.Create()
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
	talentFrame.title:SetText("Таланты: " .. playerName)
	talentFrame.title:SetTextColor(classColor.r, classColor.g, classColor.b)

	-- Update content
	TI.UpdateAllTrees(playerName, className)

	talentFrame:Show()
end

function TI.Hide()
	if talentFrame then
		talentFrame:Hide()
	end
end

-- Export
RaiderCheck.UI = RaiderCheck.UI or {}
RaiderCheck.UI.TalentsInspect = TI

-- Legacy alias
RaiderCheck.ShowTalentsInspectFrame = function(self, playerName)
	TI.Show(playerName)
end

RaiderCheck.ShowTalentVisualFrame = function(self, playerName)
	TI.Show(playerName)
end
