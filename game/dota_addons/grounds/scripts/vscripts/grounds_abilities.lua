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