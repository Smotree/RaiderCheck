-- RaiderCheck TalentTree Module

if not RaiderCheck then
	RaiderCheck = {}
end

RaiderCheck.talentCache = {}

-- Получить информацию о таланте
function RaiderCheck:GetTalentInfo(tabIdx, talIdx)
	if not tabIdx or not talIdx then
		return nil
	end
	local key = tabIdx .. "_" .. talIdx
	if self.talentCache[key] then
		return self.talentCache[key]
	end

	local name, icon, tier, col, rank, maxRank = GetTalentInfo(tabIdx, talIdx)
	if not name then
		return nil
	end

	local info = {
		name = name,
		icon = icon,
		tier = tier,
		column = col,
		rank = rank,
		maxRank = maxRank,
	}
	self.talentCache[key] = info
	return info
end

-- Получить структуру дерева талантов
function RaiderCheck:GetTalentTreeStructure(tabIdx)
	if not tabIdx then
		return {}, 0, 4
	end

	local num = GetNumTalents(tabIdx)
	if not num or num == 0 then
		return {}, 0, 4
	end

	local maxTier = 0
	local structure = {}

	-- Найти максимальный tier
	for i = 1, num do
		local info = self:GetTalentInfo(tabIdx, i)
		if info and (info.tier or 0) > maxTier then
			maxTier = info.tier
		end
	end

	-- Инициализировать структуру
	for t = 1, maxTier do
		structure[t] = {}
		for c = 1, 4 do
			structure[t][c] = {}
		end
	end

	-- Заполнить структуру
	for i = 1, num do
		local info = self:GetTalentInfo(tabIdx, i)
		if info and info.tier and info.column then
			structure[info.tier][info.column] = {
				index = i,
				name = info.name,
				icon = info.icon,
				maxRank = info.maxRank,
			}
		end
	end

	return structure, maxTier, 4
end

-- Очистить кэш
function RaiderCheck:ClearTalentCache()
	self.talentCache = {}
end

print("|cFF00FF00RaiderCheck TalentTree:|r OK")
