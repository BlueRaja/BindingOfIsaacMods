local fixSpawns = RegisterMod("Fix Multiplayer Item Spawns", 2)

-- Called when a pickup is spawned
-- Make sure no active items spawn in boss room in multiplayer
function fixSpawns:postPickupInit(entity)
	local isCollectible = entity.Variant == PickupVariant.PICKUP_COLLECTIBLE
	local isBossRoom = Game():GetRoom():GetType() == RoomType.ROOM_BOSS
	local isGreedMode = Game():IsGreedMode()
	if isCollectible and isBossRoom and not isGreedMode then
		local numPlayers = fixSpawns:getNumLivingPlayers()
		if numPlayers > 1 then
			local itemConfig = Isaac:GetItemConfig()
			if itemConfig:GetCollectible(entity.SubType).Type == ItemType.ITEM_ACTIVE then
				entity:ToPickup():Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, 0, true)
				-- Can only call Morph() once or game crashes.  If it's still an active... oh well!
			end
		end
	end
end

-- Called when entering a room
-- Spawn extra items in the white treasure rooms
function fixSpawns:postNewRoom()
	if isWhiteTreasureRoom() and Game():GetRoom():IsFirstVisit() then
		local numPlayers = fixSpawns:getNumLivingPlayers()
		for i=1,numPlayers-1 do
			fixSpawns:spawnItem()
		end
	end
end

-- Spawns a random pedestal item in the current room
function fixSpawns:spawnItem()
	local room = Game():GetRoom()
	local pickupPos = room:FindFreePickupSpawnPosition(room:GetCenterPos(), 10, true)
	Game():Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, pickupPos, Vector(0,0), Nil, 0, Game():GetSeeds():GetNextSeed())
end

-- Returns the number players who are alive and not playing as babies
function fixSpawns:getNumLivingPlayers()
	local numPlayers = Game():GetNumPlayers()
	
	local numLivingPlayers = 0
	for i=1,numPlayers do
		local player = Game():GetPlayer(i)
		local isLivingPlayer = player.Type == EntityType.ENTITY_PLAYER and not player:IsDead()
		local isPrimaryCharacter = player:GetMainTwin().Index == player.Index -- Prevent Jacob/Esau from being double-counted
		local isBaby = player:GetBabySkin() ~= BabySubType.BABY_UNASSIGNED
		local isGhost = player:IsCoopGhost() -- Ghosts are not considered dead - lol?
		if isLivingPlayer and isPrimaryCharacter and not isBaby and not isGhost then
			numLivingPlayers = numLivingPlayers + 1
		end
	end
	
	return numLivingPlayers
end

-- Returns true if the current room is a white treasure room (the free ones in Greed mode)
function isWhiteTreasureRoom()
	local isGreedMode = Game():IsGreedMode()
	local room = Game():GetRoom()
	local isTreasureRoom = room:GetType() == RoomType.ROOM_TREASURE
	-- Use the position of the room to guess if it's a white treasure room
	-- This is extremely hacky, but I can't find a better way to determine it
	local isCorrectPosition = Game():GetLevel():GetCurrentRoomDesc().GridIndex == 98;
	return isGreedMode and isTreasureRoom and isCorrectPosition
end

fixSpawns:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, fixSpawns.postNewRoom)
fixSpawns:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, fixSpawns.postPickupInit)