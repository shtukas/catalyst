
class Donations

    # Donations::interactivelySelectDonationTargetorNull()
    def self.interactivelySelectDonationTargetorNull()
        Cx18s::interactivelySelectCx18OrNull()
    end

    # Donations::interactivelyAttachDonationOrNothing(item)
    def self.interactivelyAttachDonationOrNothing(item)
        cx18 = Donations::interactivelySelectDonationTargetorNull()
        return if cx18.nil?
        Items::setAttribute(item["uuid"], "donation-08", cx18["uuid"])
    end

    # Donations::donationSuffix(item)
    def self.donationSuffix(item)
        return "" if item["donation-08"].nil?
        target = Items::objectOrNull(item["donation-08"])
        return "" if target.nil?
        " (d: #{target["description"]})"
    end
end
