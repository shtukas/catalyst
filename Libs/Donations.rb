
class Donations
    # Donations::interactivelySetDonation(item) -> Item
    def self.interactivelySetDonation(item)
        target = Donations::interactivelySelectTargetForDonationOrNull()
        return item if target.nil?
        Items::setAttribute(item["uuid"], "donation-1205", target["uuid"])
        Items::itemOrNull(item["uuid"])
    end

    # Donations::donationSuffix(item)
    def self.donationSuffix(item)
        return "" if item["mikuType"] == "NxTask" # we have dedicated display for NxTask
        return "" if item["donation-1205"].nil?
        " #{"(d: #{PolyFunctions::get_name_of_donation_target_or_identity(item["donation-1205"])})".yellow}"
    end

    # Donations::interactivelySelectTargetForDonationOrNull()
    def self.interactivelySelectTargetForDonationOrNull()
        targets = NxCores::coresInRatioOrder()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("donation target", targets, lambda{|item| PolyFunctions::toString(item) })
    end
end
