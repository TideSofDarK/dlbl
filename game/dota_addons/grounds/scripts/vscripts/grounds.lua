_G.AbilitiesKV = LoadKeyValues("scripts/npc/npc_abilities.txt")
_G.AbilitiesCount = GetTableLength(AbilitiesKV)

_G.HeroesKV = LoadKeyValues("scripts/npc/npc_heroes.txt")

_G.HeroAbilities = {}
for heroName,data in pairs(HeroesKV) do
	if heroName == "npc_dota_hero_base" or heroName == "npc_dota_hero_wisp" or heroName == "npc_dota_hero_target_dummy" then

	else
		for i=1,24 do
			local ab = HeroesKV[heroName]["Ability"..tostring(i)]
			if ab then
				local isUltimate = AbilitiesKV[ab].AbilityType and string.match(AbilitiesKV[ab].AbilityType, "DOTA_ABILITY_TYPE_ULTIMATE")
				if not isUltimate and not string.match(ab, "special_bonus_") and not string.match(ab, "generic_hidden") then
					HeroAbilities[heroName] = HeroAbilities[heroName] or {}
					table.insert(HeroAbilities[heroName], ab)
				end
			end
		end
	end
end

_G.LootTable = {}
_G.LootTableOverride = LoadKeyValues("scripts/kv/loot.kv")

LootTable.Abilities = {}
LootTable.Abilities.Common = {}
LootTable.Abilities.Uncommon = {}
LootTable.Abilities.Rare = {}
-- Fill with all hero skills
for _,t in pairs(HeroAbilities) do
	for __,ability in pairs(t) do
		if not LootTableOverride.Abilities.Banned[ability] then
			LootTable.Abilities.Common[ability] = 1
		end
	end
end

LootTable.Items = LootTableOverride.Items
LootTable.Gifts = LootTableOverride.Gifts
LootTable.Bonuses = LootTableOverride.Bonuses
for k,v in pairs(LootTableOverride.Abilities.Uncommon) do
	LootTable.Abilities.Common[k] = nil
	LootTable.Abilities.Uncommon[k] = 1
end
for k,v in pairs(LootTableOverride.Abilities.Rare) do
	LootTable.Abilities.Common[k] = nil
	LootTable.Abilities.Rare[k] = 1
end

_G.GROUNDS_MAX_ABILITIES = 12

_G.PlayerStates = {}
for i=0,DOTA_MAX_PLAYERS do
	PlayerStates[i] = {}
	PlayerStates[i].Abilities = shallowcopy(LootTable.Abilities)
	PlayerStates[i].RemovedAbilities = 0
	PlayerStates[i].MarkAsUsed = (function (self, quality, ability)
		print("MarkAsUsed", quality, ability)
		self.Abilities[quality][ability] = nil

		self.RemovedAbilities = self.RemovedAbilities + 1
		if AbilitiesCount - self.RemovedAbilities <= 20 then
			self:ResetKV()
		end
	end)
	PlayerStates[i].ResetKV = (function (self)
		PlayerStates[i].Abilities = shallowcopy(LootTable.Abilities)
	end)
end

function GetRandomAbility( owner, allContents, ignore )
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

	local function CheckAbility(ability)
		-- Check if there is no KV to this ability
		-- if not PlayerStates[pID].Abilities[ability] then
		-- 	return false
		-- end
		-- Check duplicates (hero)
		for k,v in pairs(ownerAbilities) do
			if v == ability then
				return false
			end
		end
		-- Check if passive-only mode
		if forcePassive >= 6 then
			if not string.match(AbilitiesKV[ability].AbilityBehavior, "DOTA_ABILITY_BEHAVIOR_PASSIVE") then
				return false
			end
		end
		-- Check ignore list
		for k,v in pairs(ignore) do
			if v == ability then
				return false
			end
		end

		return true
	end

	return GetRandomElement(allContents, CheckAbility)
end

function OnAbilityCratePicked( owner )
	local loot = {}

	local pID = owner:GetPlayerOwnerID()

	local quality = GetRandomQuality()
	if quality == "Rare" and GetTableLength(PlayerStates[pID].Abilities[quality]) < 3 then
		quality = "Uncommon"
	end
	if GetTableLength(PlayerStates[pID].Abilities[quality]) < 3 then
		quality = "Common"
	end

	local upgradableAbilities = {}
	for k,v in pairs(owner:GetAllAbilities()) do
		if v:GetLevel() < v:GetMaxLevel() then
			upgradableAbilities[v:GetName()] = 1
		end
	end

	-- List of all abilities
	local allContents = {}
	for k,v in pairs(PlayerStates[pID].Abilities[quality]) do
		table.insert(allContents, k)
	end

	local contents = {}

	for i=1,3 do
		local isUpgrade = math.random(0,1) == 0

		if GetTableLength(upgradableAbilities) > 0 and isUpgrade then
			local ability = GetRandomElement(upgradableAbilities, nil, true)
			table.insert(contents, ability)

			upgradableAbilities[ability] = nil
		else
			local ability = GetRandomAbility( owner, allContents, contents )
			table.insert(contents, ability)

			-- Remove ability from list
			PlayerStates[pID]:MarkAsUsed(quality, ability)
		end
	end

	for k,v in pairs(contents) do
		table.insert(loot, { lootType = 1, content = v })
	end

	owner.currentLoot = loot
	CustomGameEventManager:Send_ServerToPlayer(owner:GetPlayerOwner(), "grounds_loot_picked", loot)
end

function OnSupplyCratePicked( owner )
	local loot = {}

	local quality = GetRandomQuality()

	local contents = GetRandomElements(LootTable.Items[quality], 3, nil, true)

	for k,v in pairs(contents) do
		table.insert(loot, { lootType = 2, content = v })
	end

	owner.currentLoot = loot
	CustomGameEventManager:Send_ServerToPlayer(owner:GetPlayerOwner(), "grounds_loot_picked", loot)
end

function OnBonusCratePicked( owner )
	local loot = {}

	local quality = GetRandomQuality()

	local allConents = LootTable.Bonuses[quality]
	for k,v in pairs(LootTable.Bonuses.Unclassified) do
		allConents[k] = v
	end

	local contents = GetRandomElements(LootTable.Items[quality], 3, nil, true)

	for k,v in pairs(contents) do
		table.insert(loot, { lootType = 3, content = v })
	end

	owner.currentLoot = loot
	CustomGameEventManager:Send_ServerToPlayer(owner:GetPlayerOwner(), "grounds_loot_picked", loot)
end

function OnStartingCratePicked( owner )
	local heroes = LoadKeyValues("scripts/npc/npc_heroes.txt")
	local loot = {}

	local pID = owner:GetPlayerID()

	if not PlayerStates[pID].bHeroPicked then
		PlayerStates[pID].bHeroPicked = true

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

		for k,v in pairs(GetRandomElements(heroes, 3, CheckHero, true)) do
			print("Hero:", v)
			table.insert(loot, { lootType = 4, content = v })
		end
	elseif not PlayerStates[pID].bGiftPicked then
		PlayerStates[pID].bGiftPicked = true

		local function CheckGift( gift )
			for k,v in pairs(loot) do
				if v.content == gift then
					return false
				end
			end

			return true
		end

		local gifts = GetRandomElements(LootTable.Gifts, 3, CheckGift, true)
		for k,gift in pairs(gifts) do
			print("Gift:", gift)
			table.insert(loot, { lootType = 5, content = gift })
		end

	elseif not PlayerStates[pID].bStartingAbilityPicked then
		PlayerStates[pID].bStartingAbilityPicked = true

		local abilities = GetRandomElements(HeroAbilities[owner:GetUnitName()], 3)
		for k,v in pairs(abilities) do
			table.insert(loot, { lootType = 1, content = v })
		end
	end

	owner.currentLoot = loot
	CustomGameEventManager:Send_ServerToPlayer(owner:GetPlayerOwner(), "grounds_loot_picked", loot)
end

function OnLootChannelSucceeded( owner )
	local heroes = LoadKeyValues("scripts/npc/npc_heroes.txt")
	local loot = {}

	local pID = owner:GetPlayerID()

	if owner.currentLoot then
		CustomGameEventManager:Send_ServerToPlayer(owner:GetPlayerOwner(), "grounds_loot_picked", owner.currentLoot)
		
		return
	end


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
			local lootType = math.random(1, 3)

			if not PlayerStates[pID].bCompleteBuild then
				local count = 0
				for i=0,23 do
					local ab = owner:GetAbilityByIndex(i)
					if IsValidEntity(ab) and not string.match(ab:GetName(), "barebones") then
						count = count + 1
						if count == GROUNDS_MAX_ABILITIES then
							PlayerStates[pID].bCompleteBuild = true
							break
						end
					end
				end
			end

			if PlayerStates[pID].bCompleteBuild then
				lootType = math.random(2, 3)
			end

			local loot = {}
			local allContents = lootTable[tostring(lootType)]
			local content

			if lootType == 1 then
				content = GetRandomAbility( owner, allContents )
				if content == "xp" then
					lootType = 3
				end
			elseif lootType == 2 then
				local function CheckItem(content)
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

				content = GetRandomElement(allContents, CheckItem)
			else
				content = GetRandomElement(allContents)
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
			if hero:HasAbility(loot.content) then
				-- Level up owned ability
				local ab = hero:FindAbilityByName(loot.content)
				ab:UpgradeAbility(true)
			else
				-- Find slot for active ability
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
					hero:AddAbility(loot.content):SetLevel(1)
				end

				if hero:GetLevel() == 1 and hero:GetAbilityPoints() == 1 then
					hero:FindAbilityByName(loot.content):SetLevel(1)
					hero:SetAbilityPoints(0)
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
			end
		elseif loot.lootType == 2 then
			hero:AddItemByName(loot.content)
			local overthrow_item_drop =
			{
				hero_id = hero:GetClassname(),
				dropped_item = loot.content
			}
			CustomGameEventManager:Send_ServerToAllClients( "overthrow_item_drop", overthrow_item_drop )
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