
class ListingPosition

    # ---------------------------------------------------------------
    # Functions & Data

    # ListingPosition::realLineTo01Increasing(x)
    def self.realLineTo01Increasing(x)
        (2 + Math.atan(x)).to_f/10
    end

    # ListingPosition::firstNegativeListingPosition()
    def self.firstNegativeListingPosition()
        positions = Items::objects()
            .select{|item| item["nx42"] }
            .map{|item| item["nx42"] }
        ([-1] + positions).min
    end

    # ListingPosition::firstPositiveListingPosition()
    def self.firstPositiveListingPosition()
        positions = Items::objects()
            .select{|item| item["nx42"] }
            .map{|item| item["nx42"] }
        ([0.500] + positions).min
    end

    # ListingPosition::decideItemListingPosition(item)
    def self.decideItemListingPosition(item)
        if item["nx42"] then
            return item["nx42"]
        end

        # (sorted)            : (negatives)
        # priorities          : (negatives)
        # Interruptions       : 0.300
        # Today               : 0.800
        # Wave                : 1.000 -> 2.500 over 2.5 hours
        # NxInProgress        : 1.300
        # BufferIn            : 1.500 -> 3.000 over 1.0 hours
        # NxTask (cored)      : 1.500 -> 3.000 over 2.5 hours

        if item["mikuType"] == "Wave" and item["interruption"] then
            return 0.300
        end

        if item["mikuType"] == "NxToday" then
            return 0.800
        end

        if item["mikuType"] == "NxInProgress" then
            return 1.300
        end

        if item["mikuType"] == "Wave" then
            increase = 1.5
            hours    = 2.5
            rt = BankDerivedData::recoveredAverageHoursPerDayCached("wave-general-fd3c4ac4-1300")
            return 1.000 + increase * (rt.to_f/hours)
        end

        if item["mikuType"] == "BufferIn" then
            increase = 1.5
            hours    = 1.0
            rt = BankDerivedData::recoveredAverageHoursPerDayCached("0a8ca68f-d931-4110-825c-8fd290ad7853")
            return 1.5 + increase * (rt.to_f/hours)
        end

        if item["mikuType"] == "NxTask" and item["tlname-11"] then
            increase = 1.5
            hours    = 1.0
            listname = item["tlname-11"]
            rt = BankDerivedData::recoveredAverageHoursPerDayCached("tlname-11:#{listname}")
            return 1.500 + increase * (rt.to_f/hours)
        end

        if item["mikuType"] == "NxTask" and item["tlname-11"].nil? then
            puts "We are not supposed to be listing those, are we ? (they are automatically transmuted to NxToday)"
            raise "[2414c0e5]"
        end

        raise "[error: 4DC6AEBD] I do not know how to decide the listing position for item: #{item}"
    end

    # ListingPosition::delist(item)
    def self.delist(item)
        Items::setAttribute(item["uuid"], "nx42", nil)
    end
end
