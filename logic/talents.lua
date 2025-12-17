-- RaiderCheck Logic Talents Module
-- Talent serialization, parsing, and analysis

local _, RC = ...
RC.Logic = RC.Logic or {}
RC.Logic.Talents = {}
local Talents = RC.Logic.Talents
local C = RC.Data.Constants

-- ============================================
-- SERIALIZATION (v5.0 format)
-- ============================================

-- Format: tree1|tree2|tree3
-- Each tree: idx~rank,idx~rank,...
-- Example: "1~0,2~0,3~5,4~2|1~1,2~0,3~2|1~0,2~0"

function Talents.Serialize()
	local treesData = {}

	for tabIndex = 1, 3 do
		local numTalents = GetNumTalents(tabIndex)
		local talentsInfo = {}

		for talentIndex = 1, numTalents do
			local name, icon, tier, column, rank = GetTalentInfo(tabIndex, talentIndex)
			local rankVal = rank or 0
			table.insert(talentsInfo, talentIndex .. "~" .. rankVal)
		end

		table.insert(treesData, table.concat(talentsInfo, ","))
	end

	return table.concat(treesData, "|")
end

-- ============================================
-- PARSING
-- ============================================

-- Parse v5.0 format into detailed structure
-- Returns: {[treeIndex] = {[talentIndex] = {rank, ...}}}
function Talents.ParseDetailed(data)
	local result = {}

	if not data or data == "" then
		return result
	end

	local treeIndex = 1
	for treeData in data:gmatch("[^|]+") do
		result[treeIndex] = {}

		for talentEntry in treeData:gmatch("[^,]+") do
			local idx, rank = talentEntry:match("(%d+)~(%d+)")
			if idx and rank then
				local talentIndex = tonumber(idx)
				result[treeIndex][talentIndex] = {
					rank = tonumber(rank) or 0,
					talentIndex = talentIndex,
				}
			end
		end

		treeIndex = treeIndex + 1
	end

	return result
end

-- Parse simple format (just points per tree)
function Talents.ParseSimple(data)
	local talents = { 0, 0, 0 }

	if not data or data == "" then
		return talents
	end

	-- Try to parse as v5.0 detailed format first
	local detailed = Talents.ParseDetailed(data)

	for treeIndex = 1, 3 do
		if detailed[treeIndex] then
			for _, talentData in pairs(detailed[treeIndex]) do
				talents[treeIndex] = talents[treeIndex] + (talentData.rank or 0)
			end
		end
	end

	return talents
end

-- ============================================
-- ANALYSIS
-- ============================================

-- Get main spec (tree with most points)
function Talents.GetMainSpec(talents)
	if not talents then
		return 0, 0
	end

	local maxPoints = 0
	local mainSpec = 0

	for i = 1, 3 do
		local points = talents[i] or 0
		if points > maxPoints then
			maxPoints = points
			mainSpec = i
		end
	end

	return mainSpec, maxPoints
end

-- Get distribution string
function Talents.GetDistribution(talents)
	if not talents then
		return "0/0/0"
	end
	return string.format("%d/%d/%d", talents[1] or 0, talents[2] or 0, talents[3] or 0)
end

-- Get total points
function Talents.GetTotalPoints(talents)
	if not talents then
		return 0
	end
	return (talents[1] or 0) + (talents[2] or 0) + (talents[3] or 0)
end

-- Full analysis
function Talents.Analyze(playerData, className)
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
	local mainSpec, maxPoints = Talents.GetMainSpec(talents)
	local specName = C.GetSpecName(className, mainSpec)
	local distribution = Talents.GetDistribution(talents)
	local totalPoints = Talents.GetTotalPoints(talents)

	return {
		hasData = true,
		mainSpec = mainSpec,
		specName = specName,
		distribution = distribution,
		totalPoints = totalPoints,
		talents = talents,
	}
end

-- ============================================
-- TALENT INFO HELPERS
-- ============================================

-- Get talent info from database (uses TalentsDatabase.lua)
function Talents.GetTalentFromDatabase(className, treeIndex, talentIndex)
	if not RaiderCheck_TalentsDB then
		return nil
	end

	local classDB = RaiderCheck_TalentsDB[className]
	if not classDB then
		return nil
	end

	local treeDB = classDB[treeIndex]
	if not treeDB then
		return nil
	end

	return treeDB[talentIndex]
end

-- Get tree name from database
function Talents.GetTreeName(className, treeIndex)
	if not RaiderCheck_TalentsDB then
		return C.GetSpecName(className, treeIndex)
	end

	local classDB = RaiderCheck_TalentsDB[className]
	if classDB and classDB.treeName and classDB.treeName[treeIndex] then
		return classDB.treeName[treeIndex]
	end

	return C.GetSpecName(className, treeIndex)
end

return Talents
