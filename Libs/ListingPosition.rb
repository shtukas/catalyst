
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
            .select{|item| item["nx41"] }
            .map{|item| item["nx41"]["position"] }
        ([-1] + positions).min
    end

    # ListingPosition::firstPositiveListingPosition()
    def self.firstPositiveListingPosition()
        positions = Items::objects()
            .select{|item| item["nx41"] }
            .map{|item| item["nx41"]["position"] }
        ([0.500] + positions).min
    end

    # ListingPosition::decideItemListingPositionOrNull(item)
    def self.decideItemListingPositionOrNull(item)
        if item["nx41"] and item["nx41"]["type"] == "override" then
            return item["nx41"]["position"]
        end
        if item["nx41"] and item["nx41"]["type"] == "natural" and (Time.new.to_i - item["nx41"]["unixtime"]) < 3600*2 then
            return item["nx41"]["position"]
        end

        # (sorted)            : (negatives)
        # priorities          : (negatives)
        # Interruptions       : 0.300
        # Today               : 1.000
        # Wave                : 1.000 -> 2.500 over 2.5 hours
        # NxInProgress        : 1.300
        # BufferIn            : 1.500 -> 3.000 over 1.0 hours
        # NxTask (cored)      : 1.500 -> 3.000 over 2.5 hours
        # NxTask (free)       : 2.000 -> 3.000 over 2.0 hours

        if item["mikuType"] == "Wave" and item["interruption"] then
            return 0.300 + ListingPosition::realLineTo01Increasing((item["lastDoneUnixtime"]-1766445888).to_f/86400).to_f/1000
        end

        if item["mikuType"] == "NxInProgress" then
            return 1.300
        end

        if item["mikuType"] == "NxToday" then
            return 1.000 + ListingPosition::realLineTo01Increasing((item["unixtime"]-1766445888).to_f/86400).to_f/1000
        end

        if item["mikuType"] == "Wave" then
            increase = 1.5
            hours    = 2.5
            rt = BankDerivedData::recoveredAverageHoursPerDayCached("wave-general-fd3c4ac4-1300")
            return 1.000 + increase * (rt.to_f/hours) + ListingPosition::realLineTo01Increasing((item["lastDoneUnixtime"]-1766445888).to_f/86400).to_f/1000
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

        if item["mikuType"] == "NxTask" then
            increase = 1.5
            hours    = 2.0
            rt = BankDerivedData::recoveredAverageHoursPerDayCached("task-general-free-2b01")
            return 2 + increase * (rt.to_f/hours) + ListingPosition::realLineTo01Increasing((item["unixtime"]-1766445888).to_f/86400).to_f/1000
        end

        raise "[error: 4DC6AEBD] I do not know how to decide the listing position for item: #{item}"
    end

    # ListingPosition::delist(item)
    def self.delist(item)
        Items::setAttribute(item["uuid"], "nx41", nil)
    end
end
