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

_G.GROUNDS_MAX_CRATES_X = 16
_G.GROUNDS_MAX_CRATES_Y = 16

_G.SPAWN_POINTS = {}

_G.POINT_TO_CRATE = {}
_G.CRATE_TO_POINT = {}

function InitGrounds()
	for k,v in pairs(Entities:FindAllByName("grounds_player_spawn")) do
		table.insert(SPAWN_POINTS, v:GetAbsOrigin())
	end
	SPAWN_POINTS = ShuffledList( SPAWN_POINTS )

	SpawnCrates()
end

function SpawnCrates()
	local startX = GetWorldMinX()
	local startY = GetWorldMinY()
	local endX = GetWorldMaxX()
	local endY = GetWorldMaxY()
	local rateX = (math.abs(startX) + math.abs(endX)) / GROUNDS_MAX_CRATES_X
	local rateY = (math.abs(startY) + math.abs(endY)) / GROUNDS_MAX_CRATES_Y

	for x=1,GROUNDS_MAX_CRATES_X do
		for y=1,GROUNDS_MAX_CRATES_Y do
			local pos = Vector(startX + (rateX * x), startY + (rateY * y), 0)

			pos = pos + RandomPointInsideCircle(0, 0, rateX / 2)

			if GridNav:CanFindPath(Vector(-576, -424, 0), pos) then
				print("Spawning crate at: ", pos)

				local crates = { "item_loot_abilities", "item_loot_abilities","item_loot_abilities", "item_loot_bonuses", "item_loot_supply", }
				local newItem = CreateItem( GetRandomElement(crates), nil, nil )
				local drop = CreateItemOnPositionForLaunch( pos, newItem )

				newItem:LaunchLootInitialHeight(false, 1024, 128, 3.0, pos)
				AddFOWViewer(2, pos, 256, 25.0, false)

				POINT_TO_CRATE[pos] = drop
				CRATE_TO_POINT[drop] = pos
				-- Timers:CreateTimer(30, function (  )
					
				-- end)
			end
		end	
	end
end

function ShrinkingCricle(hero)
	local idleTime = 30
	local shrinkingTime = 30
	local rounds = 3

	local function CreateStaticCircle(origin, radius, time, callback)
		local dummy = CreateUnitByName("npc_grounds_circle_dummy", origin, false, nil, nil, DOTA_TEAM_NEUTRALS)
		dummy:SetAbsOrigin(GetGroundPosition(origin, dummy))

		Timers:CreateTimer(function (  )
			if not IsValidEntity(dummy) then
			else
				AddFOWViewer(2, origin, 256, 0.5, false)
				return 0.5
			end
		end)

		local rangeParticle = ParticleManager:CreateParticle("particles/grounds_circlev2.vpcf", PATTACH_ABSORIGIN, dummy)
		ParticleManager:SetParticleControlEnt(rangeParticle, 0, dummy, PATTACH_ABSORIGIN_FOLLOW, "attach_origin", dummy:GetAbsOrigin(), true)
		ParticleManager:SetParticleControl(rangeParticle, 1, Vector(radius, 1, 1))
		-- ParticleManager:SetParticleControl(rangeParticle, 4, Vector(255, 255, 255))

		Timers:CreateTimer(time, function (  )
			ParticleManager:DestroyParticle(rangeParticle, true)
			UTIL_Remove(dummy)

			callback()
		end)

		return rangeParticle
	end

	function CreateShrinkingCircle(origin, radius, targetRadius, time, callback)
		local dummy = CreateUnitByName("npc_grounds_circle_dummy", origin, false, nil, nil, DOTA_TEAM_NEUTRALS)
		dummy:SetAbsOrigin(GetGroundPosition(origin, dummy))
		
		Timers:CreateTimer(function (  )
			if not IsValidEntity(dummy) then
			else
				AddFOWViewer(2, origin, 256, 0.5, false)
				return 0.5
			end
		end)

		local rangeParticle = ParticleManager:CreateParticle("particles/grounds_circlev2_shrinking.vpcf", PATTACH_ABSORIGIN, dummy)
		ParticleManager:SetParticleControlEnt(rangeParticle, 0, dummy, PATTACH_ABSORIGIN_FOLLOW, "attach_origin", dummy:GetAbsOrigin(), true)
		ParticleManager:SetParticleControl(rangeParticle, 1, Vector(radius, 1, targetRadius / -time))
		-- ParticleManager:SetParticleControl(rangeParticle, 4, Vector(0, 153, 204))
		
		Timers:CreateTimer(time, function (  )
			ParticleManager:DestroyParticle(rangeParticle, true)
			UTIL_Remove(dummy)

			callback()
		end)

		return rangeParticle
	end

	-- if hero then
	-- 	CreateShrinkingCircle(hero:GetAbsOrigin(), 1024, 128, 12, function (  )
			
	-- 	end)
	-- 	return
	-- end

	local pos = GetWorldCenter()
	local radius = GetWorldMaxX()/2
	local currentRadius = radius
	local count = 1
	local function ShrinkingRoutine()
		local isOver = count > rounds
		if isOver then
			idleTime = 99999
		end
		currentRadius = radius
		CreateStaticCircle(pos, radius, idleTime, function ()
			if isOver then
				return
			end
			currentRadius = radius
			radius = radius / 2
			pos = RandomPointInsideCircle(pos.x, pos.y, radius, 0)
			local t = Timers:CreateTimer(function ()
				currentRadius = currentRadius - (radius / shrinkingTime)
				return 1.0
			end)
			CreateShrinkingCircle(pos, radius * 2, radius, shrinkingTime, function ()
				count = count + 1
				Timers:RemoveTimer(t)
				ShrinkingRoutine()
			end)
		end)
	end

	ShrinkingRoutine()

	Timers:CreateTimer(function ()
		for k,v in pairs(HeroList:GetAllHeroes()) do
			-- DebugDrawSphere(pos, Vector(255,0,0), currentRadius, currentRadius, true, 1.0)
			if not IsPointInsideCircle(pos, currentRadius, v:GetAbsOrigin()) then
				local damage_table = {
					victim = v,
					attacker = v,
					damage = v:GetMaxHealth() / 100 * 5,
					damage_type = DAMAGE_TYPE_PURE
				}
				ApplyDamage(damage_table)
			end
		end
		return 1.0
	end)
end

function GetRandomAbility( owner, allContents, ignore )
	local ownerAbilities = {}
	local forcePassive = 0
	local forceActive = 0
	for k,ab in pairs(owner:GetAllAbilities()) do
		if bit.band( ab:GetBehavior(), DOTA_ABILITY_BEHAVIOR_PASSIVE ) ~= DOTA_ABILITY_BEHAVIOR_PASSIVE then
			forcePassive = forcePassive + 1
		else
			forceActive = forceActive + 1
		end
		table.insert(ownerAbilities, ab:GetName())
	end

	local function CheckAbility(ability)
		-- Check if there is no KV to this ability
		if not AbilitiesKV[ability] then
			print("Error: no KV to ability "..ability)
			return false
		end
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
		-- Check if active-only mode
		if forceActive >= 6 then
			if string.match(AbilitiesKV[ability].AbilityBehavior, "DOTA_ABILITY_BEHAVIOR_PASSIVE") then
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

	local atLeastOneUpgrade = false

	for i=1,3 do
		--local isUpgrade = PlayerStates[pID].bCompleteBuild or math.random(0,1) == 0	
		if isUpgrade then
			atLeastOneUpgrade = true
		end

		if i == 3 and not atLeastOneUpgrade then
			isUpgrade = true
		end

		local isUpgrade = false
		
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

function OnSupplyCratePicked( owner, forcedRarity )
	local loot = {}

	local quality = forcedRarity or GetRandomQuality()

	local allContents = {}
	local uids = {}
	for k,v in pairs(LootTable.Items[quality]) do
		if type(v) == "table" and v.UID then
			uids[v.UID] = uids[v.UID] or {}
			table.insert(uids[v.UID], k)
		else
			table.insert(allContents, k)
		end
	end

	for k,v in pairs(uids) do
		table.insert(allContents, GetRandomElement(v))
	end

	local contents = GetRandomElements(allContents, 3, nil)

	for k,v in pairs(contents) do
		table.insert(loot, { lootType = 2, content = v, value = LootTable.Items[quality][v], quality = quality })
	end

	owner.currentLoot = loot
	CustomGameEventManager:Send_ServerToPlayer(owner:GetPlayerOwner(), "grounds_loot_picked", loot)
end

function OnBonusCratePicked( owner, forcedRarity )
	local loot = {}

	local quality = forcedRarity or GetRandomQuality()

	local allContents = LootTable.Bonuses[quality]
	for k,v in pairs(LootTable.Bonuses.Unclassified) do
		allContents[k] = v
	end

	for k,v in pairs(allContents) do
		if type(v) == "table" and v.Unique then
			if owner:HasModifier(k) then
				allContents[k] = nil
			end
		end
	end

	local contents = GetRandomElements(LootTable.Bonuses[quality], 3, nil, true)

	for k,v in pairs(contents) do
		table.insert(loot, { lootType = 3, content = v, value = allContents[v], quality = quality })
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
		-- PlayerStates[pID].bStartingAbilityPicked = true

		-- local abilities = GetRandomElements(HeroAbilities[owner:GetUnitName()], 3)
		-- for k,v in pairs(abilities) do
		-- 	table.insert(loot, { lootType = 1, content = v })
		-- end
		OnAbilityCratePicked( owner )
		return
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

		local grounds_loot_notification =
		{
			heroID = hero:GetClassname(),
			content = loot.content,
			lootType = loot.lootType
		}
		
		if loot.lootType == 1 then
			if hero:HasAbility(loot.content) then
				-- Level up owned ability
				local ab = hero:FindAbilityByName(loot.content)
				ab:UpgradeAbility(true)
				PopupHealthTome(hero, 1)
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
				for k,v in pairs(HeroAbilities) do
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

				-- We won't add any more abilities
				if GetTableLength(hero:GetAllAbilities()) >= GROUNDS_MAX_ABILITIES then
					PlayerStates[pID].bCompleteBuild = true
				end

				CustomGameEventManager:Send_ServerToAllClients( "grounds_loot_notification", grounds_loot_notification )
			end
		elseif loot.lootType == 2 then
			hero:AddItem(CreateItem(loot.content, hero, hero))
			CustomGameEventManager:Send_ServerToAllClients( "grounds_loot_notification", grounds_loot_notification )
		elseif loot.lootType == 3 then
			hero:EmitSound("DOTA_Item.Hand_Of_Midas")
			if loot.content == "xp" then
				if hero:GetLevel() < 25 then
					local number, _ = string.gsub(loot.value, '%W', '')	
					PopupExperience(hero, hero:AddExperiencePercent( tonumber(number) / 100 ))
				end
			elseif loot.content == "gold" then
				local gold = tonumber(loot.value)
				PlayerResource:ModifyGold(pID, gold, true, DOTA_ModifyGold_Unspecified)
				PopupGoldGain(hero, gold)
			elseif loot.content == "illusions" then
				CreateIllusions(hero,2,120,200,50,128)
			elseif string.match(loot.content, "modifier_") then
				local modifierTable = {}
				local unique = false
				local stacks
				if type(loot.value) == 'table' then
					if loot.value.Duration then
						modifierTable.duration = tonumber(loot.value.Duration)
					end
					if loot.value.Unique then
						unique = true
					end					
				else
					stacks = tonumber(loot.value)
				end
				
				if unique and hero:HasModifier(loot.content) then
				else
					local modifier = hero:FindModifierByName(loot.content)
					if not modifier then
						modifier = hero:AddNewModifier(hero, nil, loot.content, modifierTable)
					elseif modifierTable.duration then
						modifier:SetDuration(modifierTable.duration, true)
					end
					if stacks then
						modifier:SetStackCount(modifier:GetStackCount() + stacks)
					end
				end
			end
		elseif loot.lootType == 4 then
			local newHero = PlayerResource:ReplaceHeroWith(pID, loot.content, 0, 0)
		elseif loot.lootType == 5 then
			hero:AddItemByName(loot.content)
		end

		hero.currentLoot = nil
	end
end

function OnGroundsItemPickUp( event )
	local item = EntIndexToHScript( event.ItemEntityIndex )
	local owner = EntIndexToHScript( event.HeroEntityIndex )
	local pID = owner:GetPlayerOwnerID()

	local forcedRarity

	-- Give bonus or supply crate if everything is maxed out
	if PlayerStates[pID].bMaxedOut and event.itemname == "item_loot_abilities" then
		forcedRarity = "Rare"

		if RandomInt(0, 1) == 0 then
			event.itemname = "item_loot_bonuses"
		else
			event.itemname = "item_loot_supply"
		end
	end

	if event.itemname == "item_loot_abilities" then
		OnAbilityCratePicked( owner )
		UTIL_Remove( item )
	elseif event.itemname == "item_loot_supply" then
		OnSupplyCratePicked( owner, forcedRarity )
		UTIL_Remove( item )
	elseif event.itemname == "item_loot_bonuses" then
		OnBonusCratePicked( owner, forcedRarity )
		UTIL_Remove( item )
	elseif event.itemname == "item_loot_starting" then
		OnStartingCratePicked( owner )
		UTIL_Remove( item )
	end
end

function COverthrowGameMode:OnPlayerLearnedAbility( keys)
	local player = EntIndexToHScript(keys.player)
	local abilityname = keys.abilityname

	local pID = player:GetPlayerID()

	local hero = player:GetAssignedHero()

	-- Track whether hero have all abilities maxed
	if PlayerStates[pID].bCompleteBuild then
		for k,v in pairs(hero:GetAllAbilities()) do
			if v and v:GetLevel() < v:GetMaxLevel() then
				return
			end
		end
		print("Hero "..hero:GetUnitName().." maxed out all abilities")
		PlayerStates[pID].bMaxedOut = true
	end
end

function COverthrowGameMode:FilterExecuteOrder( filterTable )
    local units = filterTable["units"]
    local order_type = filterTable["order_type"]
    local issuer = filterTable["issuer_player_id_const"]
    local abilityIndex = filterTable["entindex_ability"]
    local targetIndex = filterTable["entindex_target"]
    local x = tonumber(filterTable["position_x"])
    local y = tonumber(filterTable["position_y"])
    local z = tonumber(filterTable["position_z"])
    local point = Vector(x,y,z)
    local queue = filterTable["queue"] == 1

    local unit
    local numUnits = 0
    local numBuildings = 0
    if units and units["0"] then
        unit = EntIndexToHScript(units["0"])
        if unit then
            if unit.skip then
                unit.skip = false
                return true
            end
        end
    end

    if issuer ~= -1 then
        unit._vLastOrderFilterTable = filterTable
    end

    if order_type == DOTA_UNIT_ORDER_RADAR or order_type == DOTA_UNIT_ORDER_GLYPH then return end

    if order_type == DOTA_UNIT_ORDER_PICKUP_ITEM then
    	local container = EntIndexToHScript(targetIndex)
    	local item = container:GetContainedItem()
    	if item and string.match(item:GetName(), "item_loot_") then
		    Timers:CreateTimer(function()
		        local o = unit:GetAbsOrigin()
		        if not IsValidEntity(unit) then return end
		        if not IsValidEntity(container) or not IsValidEntity(item) then return end
		        if unit._vLastOrderFilterTable ~= filterTable then return end
		        if (o-container:GetAbsOrigin()):Length2D() < 64 then
		        	if not unit:IsRealHero() then
		        		return nil
		        	end
		        	-- Check if player has selected a hero
		        	if not PlayerStates[unit:GetPlayerOwnerID()].bHeroPicked and item:GetName() ~= "item_loot_starting" then
		        		return nil
		        	end
		        	-- Check if player has crate opened
		        	if not unit.currentLoot then
			            local ability = unit:FindAbilityByName("grounds_open_crate")
			            if not ability then
			            	ability = unit:AddAbility("grounds_open_crate")
			            end
			            ability:SetLevel(1)
			            unit:CastAbilityNoTarget(ability, unit:GetPlayerOwnerID())
			            ability.target = item
			        else
			        	unit:EmitSound("General.InvalidTarget_Invulnerable")
			        end
		            return nil
		        else
		        	-- unit:MoveToNPC(item:GetContainer()) 
		            ExecuteOrderFromTable({
		                UnitIndex = unit:entindex(),
		                OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
		                Position = container:GetAbsOrigin(),

					 --    UnitIndex = unit:entindex(),
					 --    OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
						-- TargetIndex = targetIndex
		            })
		            return 0.03
		        end
		    end)
			return false
    	end
    end

    return true
end