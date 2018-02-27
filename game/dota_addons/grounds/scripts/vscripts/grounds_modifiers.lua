LinkLuaModifier("modifier_bonus_max_mana", "grounds_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bonus_vision", "grounds_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bonus_damage", "grounds_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bonus_ms", "grounds_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bonus_true_sight", "grounds_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bonus_flying_vision", "grounds_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bonus_unobstructed_movement", "grounds_modifiers.lua", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_spectator", "grounds_modifiers.lua", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_aegis", "grounds_modifiers.lua", LUA_MODIFIER_MOTION_NONE)

modifier_spectator = class({})

function modifier_spectator:IsHidden()
    return true
end

function modifier_spectator:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_spectator:CheckState()
    local state = {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_INVISIBLE] = false,
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_SILENCED] = true,
        [MODIFIER_STATE_FLYING] = true
    }

    return state
end

function modifier_spectator:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_MODEL_CHANGE
  }

  return funcs
end

function modifier_spectator:GetModifierMoveSpeedBonus_Constant()
    return 150
end

function modifier_spectator:OnCreated()
    local skins = {}
    table.insert(skins, "models/items/beastmaster/hawk/legacy_of_the_nords_legacy_of_the_nords_owl/legacy_of_the_nords_legacy_of_the_nords_owl.vmdl")
    table.insert(skins, "models/items/beastmaster/hawk/beast_heart_marauder_beast_heart_marauder_raven/beast_heart_marauder_beast_heart_marauder_raven.vmdl")
    table.insert(skins, "models/items/beastmaster/hawk/fotw_eagle/fotw_eagle.vmdl")

    self.skin = skins[math.random(1,3)]

    self:StartIntervalThink(0.5)
end

if IsServer() then
    function modifier_spectator:OnIntervalThink()
        local parent = self:GetParent()
        AddFOWViewer(parent:GetTeam(), parent:GetAbsOrigin(), 1000, 0.5, false)
    end
end

function modifier_spectator:GetModifierModelChange()
    return self.skin
end

modifier_bonus_generic = class({})

function modifier_bonus_generic:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_EXTRA_MANA_BONUS,
    MODIFIER_PROPERTY_MANA_BONUS,
    MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_MANACOST_PERCENTAGE,
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_PROPERTY_COOLDOWN_REDUCTION_CONSTANT,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_BONUS_DAY_VISION,
    MODIFIER_PROPERTY_BONUS_NIGHT_VISION,
  }

  return funcs
end

function modifier_bonus_generic:IsHidden()
	return true
end

function modifier_bonus_generic:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

-- modifier_bonus_max_mana

modifier_bonus_max_mana = class(modifier_bonus_generic)

function modifier_bonus_max_mana:GetModifierExtraManaBonus()
  return self:GetStackCount()
end

function modifier_bonus_max_mana:GetModifierManaBonus()
	return self:GetStackCount()
end

-- modifier_bonus_vision

modifier_bonus_vision = class(modifier_bonus_generic)

function modifier_bonus_vision:GetBonusDayVision()
	return self:GetStackCount()
end

function modifier_bonus_vision:GetBonusNightVision()
	return self:GetStackCount()
end

-- modifier_bonus_damage

modifier_bonus_damage = class(modifier_bonus_generic)

function modifier_bonus_damage:GetModifierPreAttack_BonusDamage()
	return self:GetStackCount()
end

-- modifier_bonus_ms

modifier_bonus_ms = class(modifier_bonus_generic)

function modifier_bonus_ms:GetModifierMoveSpeedBonus_Constant()
	return self:GetStackCount()
end

-- modifier_bonus_flying_vision

modifier_bonus_flying_vision = class(modifier_bonus_generic)

function modifier_bonus_flying_vision:OnCreated()
	self:StartIntervalThink(1.0)
end

function modifier_bonus_flying_vision:OnIntervalThink()
	local caster = self:GetParent()
	AddFOWViewer(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster:GetDayTimeVisionRange(), 1.0, false)
end

-- modifier_bonus_unobstructed_movement

modifier_bonus_unobstructed_movement = class(modifier_bonus_generic)

function modifier_bonus_unobstructed_movement:CheckState()
    local state = {
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true
    }

    return state
end

-- modifier_bonus_true_sight
-- modifier_bonus_true_sight = class(modifier_bonus_generic)

-- Copyright (C) 2018  The Dota IMBA Development Team
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
-- http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Editors:
--

--[[
        By: AtroCty
        Date: 11.05.2017
        Updated:  11.05.2017
    ]]

modifier_aegis = class({})
-- Passive modifier
function modifier_aegis:OnCreated()
    -- Parameters
    local item = self:GetAbility()
    -- self:SetDuration(item:GetSpecialValueFor("disappear_time"),true)
    self.reincarnate_time = 5
    self.vision_radius = 256
end

-- function modifier_aegis:OnRefresh()
--     self:SetDuration(self:GetAbility():GetSpecialValueFor("disappear_time"),true)
-- end

function modifier_aegis:DeclareFunctions()
    local decFuncs =
        {
            MODIFIER_PROPERTY_REINCARNATION,
            MODIFIER_EVENT_ON_DEATH
        }
    return decFuncs
end

function modifier_aegis:GetTexture()
    return "skeleton_king_reincarnation"
end

function modifier_aegis:GetPriority()
    return 100
end

function modifier_aegis:ReincarnateTime()
    if IsServer() then
        local parent = self:GetParent()
        parent:SetTimeUntilRespawn(self.reincarnate_time)
        parent:SetRespawnsDisabled(false)
        -- Refresh all your abilities
        for i = 0, 15 do
            local current_ability = parent:GetAbilityByIndex(i)

            -- Refresh
            if current_ability then
                current_ability:EndCooldown()
            end
        end
        AddFOWViewer(parent:GetTeam(), parent:GetAbsOrigin(), self.vision_radius, self.reincarnate_time, true)
        local particle = ParticleManager:CreateParticle("particles/items_fx/aegis_respawn_timer.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
        ParticleManager:SetParticleControl(particle, 1, Vector(self.reincarnate_time,0,0))
        ParticleManager:SetParticleControl(particle, 3, parent:GetAbsOrigin())
        ParticleManager:ReleaseParticleIndex(particle)
    end

    return self.reincarnate_time
end

function modifier_aegis:OnDeath(keys)
    if keys.unit == self:GetParent() then
        Timers:CreateTimer(FrameTime(), function()
            self:Destroy()
        end)
    end
end

function modifier_aegis:IsDebuff() return false end
function modifier_aegis:IsHidden() return false end
function modifier_aegis:IsPurgable() return false end
function modifier_aegis:IsPurgeException() return false end
function modifier_aegis:IsStunDebuff() return false end
function modifier_aegis:RemoveOnDeath() return false end

-- function modifier_aegis:OnDestroy()
--     if IsServer() then
--         local item = self:GetAbility()

--         UTIL_Remove(item:GetContainer())
--         UTIL_Remove(item)
--     end
-- end