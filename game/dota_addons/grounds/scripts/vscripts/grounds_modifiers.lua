LinkLuaModifier("modifier_bonus_max_mana", "grounds_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bonus_vision", "grounds_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bonus_damage", "grounds_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bonus_ms", "grounds_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bonus_true_sight", "grounds_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bonus_flying_vision", "grounds_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bonus_unobstructed_movement", "grounds_modifiers.lua", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_no_hero", "grounds_modifiers.lua", LUA_MODIFIER_MOTION_NONE)

modifier_no_hero = class({})

function modifier_no_hero:IsHidden()
    return true
end

function modifier_no_hero:CheckState()
    local state = {
        [MODIFIER_STATE_PASSIVES_DISABLED] = true,
        [MODIFIER_STATE_PROVIDES_VISION] = false,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    }

    return state
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