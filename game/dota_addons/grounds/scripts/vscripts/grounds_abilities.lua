grounds_open_crate = {}

if IsServer() then
    function grounds_open_crate:OnSpellStart()

    end

    function grounds_open_crate:OnChannelFinish(bInterrupted)
    	if not bInterrupted and IsValidEntity(self.target) then
    		self:GetOwner():PickupDroppedItem(self.target:GetContainer())
    	end
    end
end

function grounds_open_crate:IsHiddenAbilityCastable() return true end

function OnUpgradeMana( keys )
	local caster = keys.caster
	local ability = keys.ability
	print(caster:GetModifierStackCount("modifier_mana_passive", caster) + 1)
	caster:SetModifierStackCount("modifier_mana_passive", caster, caster:GetModifierStackCount("modifier_mana_passive", caster) + 1)
end