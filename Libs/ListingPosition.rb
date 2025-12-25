
class ListingPosition

    # ---------------------------------------------------------------
    # Functions & Data

    # ListingPosition::realLineTo01Increasing(x)
    def self.realLineTo01Increasing(x)
        (2 + Math.atan(x)).to_f/10
    end

    # ListingPosition::firstNegativeListingPosition()
    def self.firstNegativeListingPosition()
        positions = Items::items()
            .select{|item| item["nx42"] }
            .map{|item| item["nx42"] }
        ([-1] + positions).min
    end

    # ListingPosition::firstPositiveListingPosition()
    def self.firstPositiveListingPosition()
        positions = Items::items()
            .select{|item| item["nx42"] }
            .map{|item| item["nx42"] }
        ([0.500] + positions).min
    end

    # ListingPosition::decideItemListingPosition(item)
    def self.decideItemListingPosition(item)
        if item["nx42"] then
            return item["nx42"]
        end

        # (sorted)      : (negatives)
        # priorities    : (negatives)
        # Interruptions : 0.300
        # NxOndate      : 0.500
        # Today         : 0.800
        # Wave          : 1.000 (parked at 3.500 after 2 hours)
        # NxInProgress  : 1.300
        # BufferIn      : 1.500 (parked at 4.000 after 1 hour)
        # NxTask        : 2.000

        if item["mikuType"] == "Wave" and item["interruption"] then
            return 0.300
        end

        if item["mikuType"] == "NxOndate" then
            return 0.500
        end

        if item["mikuType"] == "NxToday" then
            return 0.800
        end

        if item["mikuType"] == "Wave" then
            increase = 1.5
            hours    = 2.5
            rt = BankDerivedData::recoveredAverageHoursPerDayCached("wave-general-fd3c4ac4-1300")
            return 3.500 if rt > 2.0
            return 1.000 + increase * (rt.to_f/hours)
        end

        if item["mikuType"] == "NxInProgress" then
            return 1.300
        end

        if item["mikuType"] == "BufferIn" then
            increase = 1.5
            hours    = 1.0
            rt = BankDerivedData::recoveredAverageHoursPerDayCached("0a8ca68f-d931-4110-825c-8fd290ad7853")
            return 4 if rt > 1.0
            return 1.5
        end

        if item["mikuType"] == "NxTask" then
            return 2.000 + ListingPosition::realLineTo01Increasing(item["parenting-13"]["position"]).to_f/1000
        end

        raise "[error: 4DC6AEBD] I do not know how to decide the listing position for item: #{item}"
    end

    # ListingPosition::delist(item)
    def self.delist(item)
        Items::setAttribute(item["uuid"], "nx42", nil)
    end
end
