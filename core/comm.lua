-- RaiderCheck Core Communication Module
-- Addon communication, group scanning, message handling

local _, RC = ...
RC.Core = RC.Core or {}
local Core = RC.Core
local C = RC.Data.Constants
local Items = RC.Data.Items
local Settings = RC.Data.Settings

-- ============================================
-- STATE
-- ============================================
local lastScanTime = 0
local pendingUpdate = false
local updateDebounceFrame = nil
local knownGroupMembers = {}

-- ============================================
-- MESSAGE SENDING
-- ============================================

function Core.SendCommMessage(prefix, message, chatType, target)
	if target then
		SendAddonMessage(prefix, message, "WHISPER", target)
	else
		SendAddonMessage(prefix, message, chatType)
	end
end

function Core.SendMessage(msgType, data, channel, target)
	local message = msgType .. ":" .. (data or "")

	if target then
		Core.SendCommMessage(C.ADDON_PREFIX, message, "WHISPER", target)
	else
		Core.SendCommMessage(C.ADDON_PREFIX, message, channel)
	end
end

-- ============================================
-- GROUP SCANNING
-- ============================================

function Core.ScanGroup()
	-- Check cooldown
	local now = GetTime()
	local remaining = C.SCAN_COOLDOWN - (now - lastScanTime)
	if remaining > 0 then
		print(string.format("|cFFFF9900RaiderCheck:|r Подождите %d сек.", math.ceil(remaining)))
		return
	end
	lastScanTime = now

	local playerName = UnitName("player")

	-- Save own data
	local myData = Core.playerData[playerName]

	-- Clear data (except own)
	Core.players = {}
	Core.playerData = {}

	if playerName then
		Core.players[playerName] = "RC"
		if myData then
			Core.playerData[playerName] = myData
		end
	end

	-- Update own data
	Core.UpdateOwnData(true)

	local numRaid = GetNumRaidMembers()
	local numParty = GetNumPartyMembers()

	if numRaid == 0 and numParty == 0 then
		print("|cFF00FF00RaiderCheck:|r Вы не в группе/рейде.")
		return
	end

	print("|cFF00FF00RaiderCheck:|r Сканирование группы...")

	-- Send PING to all group members
	local channel = (numRaid > 0) and "RAID" or "PARTY"

	Core.SendMessage(C.MSG.PING, C.VERSION, channel)

	-- Update known members cache
	knownGroupMembers = {}
	if numRaid > 0 then
		for i = 1, numRaid do
			local name = GetRaidRosterInfo(i)
			if name then
				knownGroupMembers[name] = true
			end
		end
	else
		if playerName then
			knownGroupMembers[playerName] = true
		end
		for i = 1, numParty do
			local name = UnitName("party" .. i)
			if name then
				knownGroupMembers[name] = true
			end
		end
	end

	-- Update GUI after delay
	local guiFrame = CreateFrame("Frame")
	local guiElapsed = 0
	guiFrame:SetScript("OnUpdate", function(frame, delta)
		guiElapsed = guiElapsed + delta
		if guiElapsed >= 3 then
			frame:SetScript("OnUpdate", nil)
			local count = 0
			for _ in pairs(Core.players) do
				count = count + 1
			end
			print("|cFF00FF00RaiderCheck:|r Найдено игроков с аддоном: " .. count)
			if RC.UI.GUI and RC.UI.GUI.Update then
				RC.UI.GUI.Update()
			end
		end
	end)
end

function Core.RequestPlayerData(specificPlayer)
	local channel = (GetNumRaidMembers() > 0) and "RAID" or "PARTY"

	if specificPlayer then
		if Core.players[specificPlayer] then
			Core.SendMessage(C.MSG.REQUEST, "", channel, specificPlayer)
		end
	else
		for player, _ in pairs(Core.players) do
			Core.SendMessage(C.MSG.REQUEST, "", channel, player)
		end
	end
end

-- ============================================
-- EVENT HANDLERS
-- ============================================

function Core.GROUP_ROSTER_UPDATE(self)
	local numRaid = GetNumRaidMembers()
	local numParty = GetNumPartyMembers()

	if numRaid == 0 and numParty == 0 then
		-- Not in group - clear data
		Core.players = {}
		Core.playerData = {}
		knownGroupMembers = {}
		return
	end

	-- Collect current members
	local currentMembers = {}
	local newMembers = {}

	if numRaid > 0 then
		for i = 1, numRaid do
			local name = GetRaidRosterInfo(i)
			if name then
				currentMembers[name] = true
				if not knownGroupMembers[name] then
					table.insert(newMembers, name)
				end
			end
		end
	else
		local playerName = UnitName("player")
		if playerName then
			currentMembers[playerName] = true
		end
		for i = 1, numParty do
			local name = UnitName("party" .. i)
			if name then
				currentMembers[name] = true
				if not knownGroupMembers[name] then
					table.insert(newMembers, name)
				end
			end
		end
	end

	-- Remove data for players who left
	for name in pairs(knownGroupMembers) do
		if not currentMembers[name] then
			Core.players[name] = nil
			Core.playerData[name] = nil
		end
	end

	-- Update cache
	knownGroupMembers = currentMembers

	-- Ping new members
	if #newMembers > 0 then
		local channel = (numRaid > 0) and "RAID" or "PARTY"
		local frame = CreateFrame("Frame")
		local elapsed = 0
		frame:SetScript("OnUpdate", function(f, delta)
			elapsed = elapsed + delta
			if elapsed >= 1 then
				f:SetScript("OnUpdate", nil)
				for _, name in ipairs(newMembers) do
					if name ~= UnitName("player") then
						Core.SendMessage(C.MSG.PING, C.VERSION, "WHISPER", name)
					end
				end
			end
		end)
	end
end

function Core.CHAT_MSG_ADDON(self, prefix, message, distribution, sender)
	if prefix ~= C.ADDON_PREFIX then
		return
	end
	if sender == UnitName("player") then
		return
	end

	local msgType, data = message:match("^([^:]+):(.*)$")
	if not msgType then
		return
	end

	if msgType == C.MSG.PING then
		-- Reply to ping
		Core.SendMessage(C.MSG.PONG, C.VERSION .. "-rc", "WHISPER", sender)
	elseif msgType == C.MSG.PONG then
		-- Register player with addon
		if data and string.find(data, "%-wa") then
			Core.players[sender] = "WA"
		else
			Core.players[sender] = "RC"
		end

		-- Request data from new player
		Core.SendMessage(C.MSG.REQUEST, "", "WHISPER", sender)
	elseif msgType == C.MSG.REQUEST then
		-- Send own data
		local itemsData = Items and Items.CollectPlayerItems() or ""
		local talentsData = Core.GetTalentsData() or ""
		local professionsData = Core.GetProfessionsData() or ""

		if itemsData == "" and talentsData == "" and professionsData == "" then
			return
		end

		-- Split items data into 3 parts
		local itemsParts = {}
		for part in itemsData:gmatch("[^;]+") do
			table.insert(itemsParts, part)
		end

		local itemsCount = #itemsParts
		local part1Size = math.ceil(itemsCount / 3)
		local part2Size = math.ceil((itemsCount - part1Size) / 2)

		local items1, items2, items3 = {}, {}, {}

		for i = 1, itemsCount do
			if i <= part1Size then
				table.insert(items1, itemsParts[i])
			elseif i <= part1Size + part2Size then
				table.insert(items2, itemsParts[i])
			else
				table.insert(items3, itemsParts[i])
			end
		end

		Core.SendMessage(C.MSG.ITEMS1, table.concat(items1, ";"), "WHISPER", sender)
		Core.SendMessage(C.MSG.ITEMS2, table.concat(items2, ";"), "WHISPER", sender)
		Core.SendMessage(C.MSG.ITEMS3, table.concat(items3, ";"), "WHISPER", sender)
		Core.SendMessage(C.MSG.TALENTS, talentsData, "WHISPER", sender)
		Core.SendMessage(C.MSG.PROFESSIONS, professionsData, "WHISPER", sender)
	elseif msgType == C.MSG.ITEMS1 or msgType == C.MSG.ITEMS2 or msgType == C.MSG.ITEMS3 then
		-- Receive items data (collect parts)
		if not Core.playerData[sender] then
			Core.playerData[sender] = { itemsParts = {} }
		end
		if not Core.playerData[sender].itemsParts then
			Core.playerData[sender].itemsParts = {}
		end

		if msgType == C.MSG.ITEMS1 then
			Core.playerData[sender].itemsParts[1] = data
		elseif msgType == C.MSG.ITEMS2 then
			Core.playerData[sender].itemsParts[2] = data
		elseif msgType == C.MSG.ITEMS3 then
			Core.playerData[sender].itemsParts[3] = data
		end

		-- Parse when all parts received
		if
			Core.playerData[sender].itemsParts[1]
			and Core.playerData[sender].itemsParts[2]
			and Core.playerData[sender].itemsParts[3]
		then
			local fullItemsData = table.concat({
				Core.playerData[sender].itemsParts[1],
				Core.playerData[sender].itemsParts[2],
				Core.playerData[sender].itemsParts[3],
			}, ";")

			Core.playerData[sender].items = Items and Items.ParseItemsData(fullItemsData) or {}
			Core.playerData[sender].itemsParts = nil
		end
	elseif msgType == C.MSG.TALENTS then
		-- Receive talents data
		if not Core.playerData[sender] then
			Core.playerData[sender] = {}
		end

		Core.playerData[sender].talents = data

		-- Parse detailed talents
		if Core.ParseDetailedTalents then
			Core.playerData[sender].talentsDetailed = Core.ParseDetailedTalents(data)

			-- Calculate simple totals
			local talentsSimple = { 0, 0, 0 }
			for treeIndex = 1, 3 do
				if Core.playerData[sender].talentsDetailed[treeIndex] then
					for _, talentData in pairs(Core.playerData[sender].talentsDetailed[treeIndex]) do
						talentsSimple[treeIndex] = talentsSimple[treeIndex] + (talentData.rank or 0)
					end
				end
			end
			Core.playerData[sender].talentsSimple = talentsSimple
		end

		-- Save class if available
		local _, className = UnitClass(sender)
		if className then
			Core.playerData[sender].class = className
		end

		if RC.UI.GUI and RC.UI.GUI.Update then
			RC.UI.GUI.Update()
		end
	elseif msgType == C.MSG.PROFESSIONS then
		-- Receive professions data
		if not Core.playerData[sender] then
			Core.playerData[sender] = {}
		end

		Core.playerData[sender].professions = Core.ParseProfessionsData(data)
		Core.playerData[sender].timestamp = time()
		Core.playerData[sender].name = sender

		if RC.UI.GUI and RC.UI.GUI.Update then
			RC.UI.GUI.Update()
		end
	elseif msgType == C.MSG.UPDATE then
		-- Player sent update notification - request their data
		Core.SendMessage(C.MSG.REQUEST, "", "WHISPER", sender)
	end
end

-- ============================================
-- PUSH SYSTEM: PLAYER BROADCASTS UPDATES
-- ============================================

function Core.BroadcastUpdate()
	local numRaid = GetNumRaidMembers()
	local numParty = GetNumPartyMembers()

	if numRaid == 0 and numParty == 0 then
		return
	end

	local channel = (numRaid > 0) and "RAID" or "PARTY"
	Core.SendMessage(C.MSG.UPDATE, "equipment", channel)

	-- Update own local data
	Core.UpdateOwnData(true)
end

function Core.PLAYER_EQUIPMENT_CHANGED(self, slotId, hasItem)
	if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
		return
	end

	-- Debounce
	pendingUpdate = true

	if not updateDebounceFrame then
		updateDebounceFrame = CreateFrame("Frame")
	end

	local elapsed = 0
	updateDebounceFrame:SetScript("OnUpdate", function(f, delta)
		elapsed = elapsed + delta
		if elapsed >= C.UPDATE_DEBOUNCE_TIME then
			f:SetScript("OnUpdate", nil)
			if pendingUpdate then
				pendingUpdate = false
				Core.BroadcastUpdate()
			end
		end
	end)
end

function Core.PLAYER_TALENT_UPDATE(self)
	if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
		return
	end

	pendingUpdate = true

	if not updateDebounceFrame then
		updateDebounceFrame = CreateFrame("Frame")
	end

	local elapsed = 0
	updateDebounceFrame:SetScript("OnUpdate", function(f, delta)
		elapsed = elapsed + delta
		if elapsed >= C.UPDATE_DEBOUNCE_TIME then
			f:SetScript("OnUpdate", nil)
			if pendingUpdate then
				pendingUpdate = false
				Core.BroadcastUpdate()
			end
		end
	end)
end
