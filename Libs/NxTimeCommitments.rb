
class NxTimeCommitments

    # NxTimeCommitments::icon()
    def self.icon()
        "⏱️"
    end

    # NxTimeCommitments::toString(item)
    def self.toString(item)
        "#{NxTimeCommitments::icon()} #{item["description"]}"
    end

    # NxTimeCommitments::listingItems()
    def self.listingItems()
        Blades::mikuType("NxTimeCommitment")
            .select{|item| Bank::getValueAtDate(item["uuid"], CommonUtils::today()) < item["tx31"]*3600 }
    end
end
