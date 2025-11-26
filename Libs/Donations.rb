
class Donations

    # Donations::interactivelySelectDonationTargetorNull()
    def self.interactivelySelectDonationTargetorNull()
        NxProjects::interactivelySelectProjectOrNull()
    end

    # Donations::interactivelyAttachDonationOrNothing(item)
    def self.interactivelyAttachDonationOrNothing(item)
        target = Donations::interactivelySelectDonationTargetorNull()
        return if target.nil?
        Items::setAttribute(item["uuid"], "donation-08", target["uuid"])
    end

    # Donations::donationSuffix(item)
    def self.donationSuffix(item)
        return "" if item["donation-08"].nil?
        target = Items::objectOrNull(item["donation-08"])
        return "" if target.nil?
        " (d: #{target["description"]})"
    end
end
