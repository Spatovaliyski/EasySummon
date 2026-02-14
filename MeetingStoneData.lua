EasySummonMeetingStoneData = {}

local GetAreaInfo = (C_Map and C_Map.GetAreaInfo) or GetAreaInfo

local function RegisterStone(stoneAreaId, stoneMapId, acceptedMapIds, acceptedAreaIds)
	local stoneName = GetAreaInfo(stoneAreaId)
	if not stoneName then
		return
	end

	local mapsIdx, zonesIdx = {}, { [stoneName] = true }
	for _, mapId in ipairs(acceptedMapIds) do
		mapsIdx[mapId] = true
	end
	for _, areaId in ipairs(acceptedAreaIds) do
		local zoneName = GetAreaInfo(areaId)
		if zoneName then
			zonesIdx[zoneName] = true
		end
	end

	EasySummonMeetingStoneData[stoneName] = {
		name = stoneName,
		stoneMapId = stoneMapId,
		maps = mapsIdx,
		zones = zonesIdx,
	}
end

-- Ragefire Chasm
RegisterStone(2437, 1, { 389 }, { 1637 })

-- Blackfathom Deeps
RegisterStone(719, 1, { 48 }, { 414, 2797 })

-- Wailing Caverns
RegisterStone(718, 1, { 43 }, { 387, 718 })

-- Maraudon
RegisterStone(2100, 1, { 349 }, { 607, 2100 })

-- Dire Maul
RegisterStone(2557, 1, { 429 }, { 2577 })

-- Razorfen Kraul
RegisterStone(491, 1, { 47 }, { 1717 })

-- Razorfen Downs
RegisterStone(722, 1, { 129 }, { 1316 })

-- Onyxia's Lair
RegisterStone(2159, 1, { 249 }, { 511, 2159 })

-- Zul'Farrak
RegisterStone(1176, 1, { 209 }, { 978, 979 })

-- The Ahn'Qiraj gates
RegisterStone(3428, 1, { 509, 531 }, { 2737, 2741, 3478 })

-- Scarlet Monastery
RegisterStone(796, 0, { 189 }, { 160, 796 })

-- Scholomance
RegisterStone(2057, 0, { 289 }, { 2298, 2057 })

-- Stratholme
RegisterStone(2017, 0, { 329 }, { 2625, 2277, 2627, 2279 })

-- Shadowfang Keep
RegisterStone(209, 0, { 33 }, { 130 })

-- Gnomeregan
RegisterStone(721, 0, { 90 }, { 133 })

-- Uldaman
RegisterStone(1337, 0, { 70 }, { 1517, 1897 })

-- Blackrock Depths / Spire entrance
RegisterStone(1584, 0, { 230, 229, 409, 469 }, { 25, 254, 1445 })

-- Blackrock Spire entrance
RegisterStone(1583, 0, { 230, 229, 409, 469 }, { 25, 254, 1445 })

-- The Stockade
RegisterStone(717, 0, { 34 }, { 1519 })

-- The Deadmines
RegisterStone(1581, 0, { 36 }, { 1581, 20 })

-- Sunken Temple
RegisterStone(1477, 0, { 109 }, { 74, 1477 })

-- Zul'Gurub
RegisterStone(1977, 0, { 309 }, { 19 })

if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then
	-- Hellfire Citadel (shared stone name across wings)
	RegisterStone(3545, 530, { 543, 542, 540, 544 }, { 3545, 3955 })

	-- Auchindoun (all wings covered)
	RegisterStone(3688, 530, { 557, 558, 556, 555 }, { 3688, 3893 })

	-- Black Temple
	RegisterStone(3959, 530, { 564 }, { 3520, 3756, 3757 })

	-- Serpentshrine Cavern
	RegisterStone(3607, 530, { 547, 545, 546, 548 }, { 3905 })

	-- Gruul's Lair
	RegisterStone(3522, 530, { 565 }, { 3774 })

	-- Tempest Keep & co
	RegisterStone(3523, 530, { 553, 554, 552, 550 }, { 3728, 3731, 3721, 3724, 3842 })

	-- Caverns of Time
	RegisterStone(2300, 1, { 560, 269, 534 }, { 2300 })

	-- Zul'Aman
	RegisterStone(3805, 530, { 568 }, { 3508, 3805 })

	-- Karazhan
	RegisterStone(3457, 0, { 532 }, { 2562, 2837 })

	-- Magisters' Terrace
	RegisterStone(4131, 530, { 585 }, { 4095, 4080, 4088, 4086, 4087 })

	-- Sunwell Plateau
	RegisterStone(4075, 530, { 580 }, { 4094, 4080, 4089, 4090 })
end
