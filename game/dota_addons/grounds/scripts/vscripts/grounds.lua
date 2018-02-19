_G.AbilitiesKV = LoadKeyValues("scripts/npc/npc_abilities.txt")

function GetRandomAbility( owner, allContents )
	local ownerAbilities = {}
	local forcePassive = 0
	for i=0,23 do
		local ab = owner:GetAbilityByIndex(i)
		if ab then
			if bit.band( ab:GetBehavior(), DOTA_ABILITY_BEHAVIOR_PASSIVE ) ~= DOTA_ABILITY_BEHAVIOR_PASSIVE then
				forcePassive = forcePassive + 1
			end
			table.insert(ownerAbilities, ab:GetName())
		end
	end

	local content

	local function CheckAbility(content)
		if not AbilitiesKV[content] then
			return false
		end
		for k,v in pairs(ownerAbilities) do
			if v == content then
				return false
			end
		end
		if forcePassive >= 6 then
			if not string.match(AbilitiesKV[content].AbilityBehavior, "DOTA_ABILITY_BEHAVIOR_PASSIVE") then
				return false
			end
		end
		return true
	end

	content = GetRandomElement(allContents, CheckAbility)

	return content
end

function OnLootChannelSucceeded( owner )
	local lootTable = LoadKeyValues("scripts/kv/loot.kv")
	local heroes = LoadKeyValues("scripts/npc/npc_heroes.txt")
	local loot = {}

	if owner.currentLoot then
		CustomGameEventManager:Send_ServerToPlayer(owner:GetPlayerOwner(), "grounds_loot_picked", owner.currentLoot)
		
		return
	end

	if not tPlayerStates[owner:GetPlayerID()].bHeroPicked then
		tPlayerStates[owner:GetPlayerID()].bHeroPicked = true

		local hero = ""

		local function CheckHero(hero)
			if not heroes[hero] or hero == "npc_dota_hero_base" or hero == "npc_dota_hero_wisp" or hero == "npc_dota_hero_target_dummy" then
				return false
			end
			if GetTableLength(loot) == 0 then
				if heroes[hero].AttributePrimary ~= "DOTA_ATTRIBUTE_STRENGTH" then
					return false
				end
			end
			if GetTableLength(loot) == 1 then
				if heroes[hero].AttributePrimary ~= "DOTA_ATTRIBUTE_AGILITY" then
					return false
				end
			end
			if GetTableLength(loot) == 2 then
				if heroes[hero].AttributePrimary ~= "DOTA_ATTRIBUTE_INTELLECT" then
					return false
				end
			end
			for k,v in pairs(HeroList:GetAllHeroes()) do
				if IsValidEntity(v) and v:IsRealHero() then
					if v:GetUnitName() == hero then
						return false
					end
				end
			end

			-- for k,v in pairs(loot) do
			-- 	if v and v.content == hero then
			-- 		return false
			-- 	end
			-- end

			return true
		end

		for i=1,3 do
			hero = GetRandomElement(heroes, CheckHero, true)
			print("Hero:", hero)
			table.insert(loot, { lootType = 4, content = hero })
		end
	elseif not tPlayerStates[owner:GetPlayerID()].bGiftPicked then
		tPlayerStates[owner:GetPlayerID()].bGiftPicked = true

		local function CheckGift( gift )
			for k,v in pairs(loot) do
				if v.content == gift then
					return false
				end
			end

			return true
		end
		for i=1,3 do
			local gift = GetRandomElement(lootTable.Gifts, CheckGift)
			print("Gift:", gift)
			table.insert(loot, { lootType = 5, content = gift })
		end
	elseif not tPlayerStates[owner:GetPlayerID()].bStartingAbilityPicked then
		tPlayerStates[owner:GetPlayerID()].bStartingAbilityPicked = true

		for i=1,3 do
			table.insert(loot, { lootType = 1, content = GetRandomAbility( owner, lootTable["1"] ) })
		end
	else
		local function CheckDuplicates(newOption)
			for k,v in pairs(loot) do
				if v.lootType == newOption.lootType and v.content == newOption.content then
					return false
				end
			end

			return true
		end

		for i=1,3 do
			local function RegularDropOption()
				local loot = {}
				local lootType = math.random(1, 3)
				local allContents = lootTable[tostring(lootType)]
				local content = allContents[tostring(math.random(1, GetTableLength(allContents)))]

				if lootType == 1 then
					content = GetRandomAbility( owner, allContents )
					if content == "xp" then
						lootType = 3
					end
				elseif lootType == 2 then
					local function Check()
						for i=0,14 do
							local item = owner:GetItemInSlot(i)
							if item then
								if item:GetName() == content then
									return false
								end
							end
						end
						return true
					end

					local limit = 30
					repeat
						limit = limit - 1
						if limit == 0 then
							lootType = 3
							content = "gold"
							break
						end
						content = allContents[tostring(math.random(1, GetTableLength(allContents)))]
					until
						Check()
				end

				loot.lootType = lootType
				loot.content = content

				return loot
			end

			local newOption

			repeat
				newOption = RegularDropOption()
			until
				CheckDuplicates(newOption)
				
			table.insert(loot, newOption)
		end
	end
	owner.currentLoot = loot
	CustomGameEventManager:Send_ServerToPlayer(owner:GetPlayerOwner(), "grounds_loot_picked", loot)
end

function COverthrowGameMode:OnPlayerClaimedReward( keys )
	local pID = keys.PlayerID
	local hero = PlayerResource:GetPlayer(pID):GetAssignedHero()

	local option = tonumber(keys.option)

	assert(option >= 1 and (option < 4 or option == 4)) -- TODO
	
	if hero.currentLoot then
		local loot = hero.currentLoot[option]
		if loot.lootType == 1 then
			if not string.match(AbilitiesKV[loot.content].AbilityBehavior, "DOTA_ABILITY_BEHAVIOR_PASSIVE") then
				local free_slot = false
				for i=1,6 do
		 			local ab = hero:FindAbilityByName("barebones_empty"..tostring(i))
		 			if ab:IsHidden() == false then
		 				free_slot = ab:GetName()
		 				break
		 			end
		 		end 	

		 		if free_slot then
					hero:AddAbility(loot.content)
					hero:SwapAbilities(free_slot, loot.content, false, true)
		 		end
			else
				hero:AddAbility(loot.content)
			end
			local ownerOfAbility
			for k,v in pairs(LoadKeyValues("scripts/npc/npc_heroes.txt")) do
				for k1,v1 in pairs(v) do
					if v1 == loot.content then
						ownerOfAbility = k
						break
					end
				end
				if ownerOfAbility then
					break
				end
			end
			if ownerOfAbility then
				PrecacheUnitByNameAsync(ownerOfAbility, function ()
					
				end, hero:GetPlayerID())
			end
		elseif loot.lootType == 2 then
			hero:AddItemByName(loot.content)
		elseif loot.lootType == 3 then
			hero:EmitSound("DOTA_Item.Hand_Of_Midas")
			if loot.content == "xp" then
				if hero:GetLevel() < 25 then
					local expTable = {
						0,
						200,
						600,
						1080,
						1680,
						2300,
						2940,
						3600,
						4280,
						5080,
						5900,
						6740,
						7640,
						8865,
						10115,
						11390,
						12690,
						14015,
						15415,
						16905,
						18405,
						20155,
						22155,
						24405,
						26905
					}
					local level = hero:GetLevel()
					local exp = hero:GetCurrentXP()
					
					local nextLevelExp = expTable[level+1]
					local diff1 = (expTable[level+1] - expTable[level])
					local diff2 = (expTable[level+2] - expTable[level+1])
					
					local result = 0
					if (exp - expTable[level]) > (diff1 / 2) then
						result = ((0.5 - ((expTable[level+1] - exp) / diff1)) * diff2) + (expTable[level+1] - exp)
					else
						result = (diff1 / 2)
					end
					print("XP:", result)
					hero:AddExperience(result, DOTA_ModifyXP_Unspecified, false, true)
					PopupExperience(hero, result)
				end
			elseif loot.content == "ap" then
				hero:SetAbilityPoints(hero:GetAbilityPoints() + 1)
				PopupHealthTome(hero, 1)
			else
				local gold = 400 + math.random(0,100)
				PlayerResource:ModifyGold(pID, gold, true, DOTA_ModifyGold_Unspecified)
				PopupGoldGain(hero, gold)
			end
		elseif loot.lootType == 4 then
			local newHero = PlayerResource:ReplaceHeroWith(pID, loot.content, 0, 0)
			Timers:CreateTimer(1.0,function() 
		        newHero:AddItemByName('item_passive_xp')
		    end)
		elseif loot.lootType == 5 then
			hero:AddItemByName(loot.content)
		end
		hero.currentLoot = nil
	end
end