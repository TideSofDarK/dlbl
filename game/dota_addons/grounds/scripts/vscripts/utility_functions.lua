--[[ utility_functions.lua ]]

function PrintTable(t, indent, done)
  --print ( string.format ('PrintTable type %s', type(keys)) )
  if type(t) ~= "table" then return end

  done = done or {}
  done[t] = true
  indent = indent or 0

  local l = {}
  for k, v in pairs(t) do
    table.insert(l, k)
  end

  table.sort(l)
  for k, v in ipairs(l) do
    -- Ignore FDesc
    if v ~= 'FDesc' then
      local value = t[v]

      if type(value) == "table" and not done[value] then
        done [value] = true
        print(string.rep ("\t", indent)..tostring(v)..":")
        PrintTable (value, indent + 2, done)
      elseif type(value) == "userdata" and not done[value] then
        done [value] = true
        print(string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
        PrintTable ((getmetatable(value) and getmetatable(value).__index) or getmetatable(value), indent + 2, done)
      else
        if t.FDesc and t.FDesc[v] then
          print(string.rep ("\t", indent)..tostring(t.FDesc[v]))
        else
          print(string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
        end
      end
    end
  end
end

---------------------------------------------------------------------------
-- Handle messages
---------------------------------------------------------------------------
function BroadcastMessage( sMessage, fDuration )
    local centerMessage = {
        message = sMessage,
        duration = fDuration
    }
    FireGameEvent( "show_center_message", centerMessage )
end

function PickRandomShuffle( reference_list, bucket )
    if ( #reference_list == 0 ) then
        return nil
    end
    
    if ( #bucket == 0 ) then
        -- ran out of options, refill the bucket from the reference
        for k, v in pairs(reference_list) do
            bucket[k] = v
        end
    end

    -- pick a value from the bucket and remove it
    local pick_index = RandomInt( 1, #bucket )
    local result = bucket[ pick_index ]
    table.remove( bucket, pick_index )
    return result
end

function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function ShuffledList( orig_list )
	local list = shallowcopy( orig_list )
	local result = {}
	local count = #list
	for i = 1, count do
		local pick = RandomInt( 1, #list )
		result[ #result + 1 ] = list[ pick ]
		table.remove( list, pick )
	end
	return result
end

function TableCount( t )
	local n = 0
	for _ in pairs( t ) do
		n = n + 1
	end
	return n
end

function TableFindKey( table, val )
	if table == nil then
		print( "nil" )
		return nil
	end

	for k, v in pairs( table ) do
		if v == val then
			return k
		end
	end
	return nil
end

function CountdownTimer()
    nCOUNTDOWNTIMER = nCOUNTDOWNTIMER - 1
    local t = nCOUNTDOWNTIMER
    --print( t )
    local minutes = math.floor(t / 60)
    local seconds = t - (minutes * 60)
    local m10 = math.floor(minutes / 10)
    local m01 = minutes - (m10 * 10)
    local s10 = math.floor(seconds / 10)
    local s01 = seconds - (s10 * 10)
    local broadcast_gametimer = 
        {
            timer_minute_10 = m10,
            timer_minute_01 = m01,
            timer_second_10 = s10,
            timer_second_01 = s01,
        }
    CustomGameEventManager:Send_ServerToAllClients( "countdown", broadcast_gametimer )
    if t <= 120 then
        CustomGameEventManager:Send_ServerToAllClients( "time_remaining", broadcast_gametimer )
    end
end

function SetTimer( cmdName, time )
    print( "Set the timer to: " .. time )
    nCOUNTDOWNTIMER = time
end

function PrintKV(t, indent, done)
  --print ( string.format ('PrintTable type %s', type(keys)) )
  if type(t) ~= "table" then return end

  done = done or {}
  done[t] = true
  indent = indent or 0

  local l = {}
  for k, v in pairs(t) do
    table.insert(l, k)
  end

  table.sort(l)
  for k, v in ipairs(l) do
    -- Ignore FDesc
    if v ~= 'FDesc' then
      local value = t[v]

      if type(value) == "table" and not done[value] then
        done [value] = true
        print(string.rep ("\t", indent).."\""..tostring(v).."\"".." ")
        print(string.rep ("\t", indent)..tostring("{"))
        PrintKV (value, indent + 1, done)
        print(string.rep ("\t", indent)..tostring("}"))
      elseif type(value) == "userdata" and not done[value] then
        done [value] = true
        print(string.rep ("\t", indent).."\""..tostring(v).."\"".."  "..tostring(value))
        print(string.rep ("\t", indent)..tostring("{"))
        PrintKV ((getmetatable(value) and getmetatable(value).__index) or getmetatable(value), indent + 1, done)
        print(string.rep ("\t", indent)..tostring("}"))
      else
        if t.FDesc and t.FDesc[v] then
          print(string.rep ("\t", indent)..tostring(t.FDesc[v]))
        else
          print(string.rep ("\t", indent).."\""..tostring(v).."\"".."  ".."\""..tostring(value).."\"")
        end
      end
      
    end
  end
end

function GetTableLength( t )
  if not t then return 0 end
  local length = 0

  for k,v in pairs(t) do
    if v then
      length = length + 1
    end
  end

  return length
end

function GetRandomElement(list, checker, return_key)
  local new_table = {}

  for k,v in pairs(list) do
    local skip = false
    if checker then
      if return_key then
        skip = not checker(k)
      else
        skip = not checker(v)
      end
    end
    if skip then

    else
      new_table[k] = v
    end
  end

  local count = GetTableLength(new_table)
  local seed = math.random(1, count)
  local i = 1

  for k,v in pairs(new_table) do
    if i == seed then
      if return_key then
        return k
      end
      return v
    end
    i = i + 1
  end
end

function GetRandomElements(list, count, checker, return_key)
  local newTable = {}

  for k,v in pairs(list) do
    local skip = false
    if checker then
      if return_key then
        skip = not checker(k)
      else
        skip = not checker(v)
      end
    end
    if skip then

    else
      newTable[k] = v
    end
  end

  local tableLength = GetTableLength(newTable)
  local seeds = {}

  local function Check(number)
    for k,v in pairs(seeds) do
      if v == number then
        return false
      end
    end
    return true
  end

  for i=1,count do
    local newSeed
    
    repeat
      newSeed = math.random(1, tableLength)
    until
      Check(newSeed)

    table.insert(seeds, newSeed)
  end
  local i = 1

  local returnTable = {}
  local counter = 0

  for k,v in pairs(newTable) do
    if not Check(i) then
      if return_key then
        table.insert(returnTable, k)
      else
        table.insert(returnTable, v)
      end
      counter = counter + 1
      if counter == count then
        break  
      end
    end
    i = i + 1
  end

  return returnTable
end

function GetRandomQuality()
  local seed = math.random(1, 10)
  if seed == 10 then
    return "Rare"
  elseif seed > 6 then
    return "Uncommon"
  else
    return "Common"
  end
end

function CDOTA_BaseNPC:GetAllAbilities()
  local abilities = {}
  for i=0,23 do
    local ab = self:GetAbilityByIndex(i)
    if IsValidEntity(ab) and not string.match(ab:GetName(), "barebones") and ab:GetName() ~= "grounds_open_crate" then
      table.insert(abilities, ab)
    end
  end

  return abilities
end

function CDOTA_BaseNPC_Hero:AddExperiencePercent( percent )
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
  local level = self:GetLevel()
  local exp = self:GetCurrentXP()

  local nextLevelExp = expTable[level+1]
  local diff1 = (expTable[level+1] - expTable[level])
  local diff2 = (expTable[level+2] - expTable[level+1])

  local result = 0
  if (exp - expTable[level]) > (diff1 * percent) then
    result = ((percent - ((expTable[level+1] - exp) / diff1)) * diff2) + (expTable[level+1] - exp)
  else
    result = (diff1 * percent)
  end
  print("XP:", result)
  self:AddExperience(result, DOTA_ModifyXP_Unspecified, false, true)

  return result
end

function CreateIllusions(hTarget,nIllusions,flDuration,flIncomingDamage,flOutgoingDamage,flRadius)
  local caster = hTarget
  local ability = nil
  local player = caster:GetPlayerOwnerID()
  if not flRadius then flRadius = 50 end
  local illusions = {}
  local vRandomSpawnPos = {
      Vector( flRadius, 0, 0 ),
      Vector( 0, flRadius, 0 ),
      Vector( -flRadius, 0, 0 ),
      Vector( 0, -flRadius, 0 ),
  }

  for i=#vRandomSpawnPos, 2, -1 do
    local j = RandomInt( 1, i )
    vRandomSpawnPos[i], vRandomSpawnPos[j] = vRandomSpawnPos[j], vRandomSpawnPos[i]
  end
  for i =1, nIllusions do
      if not vRandomSpawnPos or #vRandomSpawnPos == 0 then
          vRandomSpawnPos[1] = RandomVector(flRadius)
      end
      local illusion = CreateUnitByName(hTarget:GetUnitName(),hTarget:GetAbsOrigin() +vRandomSpawnPos[1],true,caster,caster:GetOwner(),caster:GetTeamNumber())
      table.remove(vRandomSpawnPos, 1)
      illusion:MakeIllusion()
      illusion:SetControllableByPlayer(player,true)
      illusion:SetPlayerID(player)
      illusion:SetHealth(hTarget:GetHealth())
      illusion:SetMana(hTarget:GetMana())
      illusion:AddNewModifier(caster, ability, "modifier_illusion", {duration = flDuration, outgoing_damage=flOutgoingDamage, incoming_damage = flIncomingDamage})

      --make sure this unit actually has stats
      if illusion.GetStrength then
          --copy over all the stat modifiers from the original hero
          for k,v in pairs(hTarget:FindAllModifiersByName("modifier_stats_tome")) do
              local instance = illusion:AddNewModifier(illusion, v:GetAbility(), "modifier_stats_tome", {stat = v.stat})
              instance:SetStackCount(v:GetStackCount())
          end
      end

      local level = hTarget:GetLevel()
      for i=1,level-1 do
          illusion:HeroLevelUp(false)
      end

      for abilitySlot=0,23 do
          local abilityTemp = caster:GetAbilityByIndex(abilitySlot)

          if abilityTemp then
              illusion:RemoveAbility(abilityTemp:GetAbilityName())
          end
      end

      illusion:SetAbilityPoints(0)
      for abilitySlot=0,23 do
          local abilityTemp = hTarget:GetAbilityByIndex(abilitySlot)

          if abilityTemp then
              illusion:AddAbility(abilityTemp:GetAbilityName())
              local abilityLevel = abilityTemp:GetLevel()
              if abilityLevel > 0 then
                  local abilityName = abilityTemp:GetAbilityName()
                  local illusionAbility = illusion:FindAbilityByName(abilityName)
                  if illusionAbility then
                      illusionAbility:SetLevel(abilityLevel)
                  end
              end
          end
      end

      for itemSlot=0,8 do
          local item = hTarget:GetItemInSlot(itemSlot)
          if item then
              local itemName = item:GetName()
              local newItem = CreateItem(itemName, illusion,illusion)
              illusion:AddItem(newItem)
          end
      end
      table.insert(illusions,illusion)
  end
  ResolveNPCPositions(hTarget:GetAbsOrigin(),flRadius*1.05)
  return illusions
end

function GetWorldCenter()
  local centerX = math.max(GetWorldMaxX(), GetWorldMinX()) + (math.abs(GetWorldMaxX()) + math.abs(GetWorldMinX())) / -2
  local centerY = math.max(GetWorldMaxY(), GetWorldMinY()) + (math.abs(GetWorldMaxY()) + math.abs(GetWorldMinY())) / -2

  return Vector(centerX, centerY, 256)
end

function GetRandomWorldPoint(percent)
  local centerX = GetWorldCenter().x
  local centerY = GetWorldCenter().y

  local radius = GetWorldMaxX() * percent

  return RandomPointInsideCircle(centerX, centerY, radius, 128)
end

function RandomPointInsideCircle(x, y, radius, min_length)
  local dist = math.random((min_length or 0), radius)
  local angle = math.random(0, math.pi * 2)

  local xOffset = dist * math.cos(angle)
  local yOffset = dist * math.sin(angle)

  return Vector(x + xOffset, y + yOffset, 0)
end

function IsPointInsideCircle(origin, radius, point)
  return (point.x - origin.x)^2 + (point.y - origin.y)^2 < radius^2
end

function IsPointReachable( pos )
  return GridNav:CanFindPath(Vector(-6538.12, 103.942, 520), pos)
end

function AddFOWViewerAllTeams( origin, radius, time )
  for i=2,13 do
    AddFOWViewer(i, origin, radius, time, false)
  end
end