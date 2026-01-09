
class ListingPosition

    # ---------------------------------------------------------------
    # Functions & Data

    # ListingPosition::realLineTo01Increasing(x)
    def self.realLineTo01Increasing(x)
        (2 + Math.atan(x)).to_f/10
    end

    # ListingPosition::firstNegativeListingPosition()
    def self.firstNegativeListingPosition()
        positions = Blades::items()
            .select{|item| item["nx42"] }
            .map{|item| item["nx42"] }
        ([-1] + positions).min
    end

    # ListingPosition::firstPositiveListingPosition()
    def self.firstPositiveListingPosition()
        positions = Blades::items()
            .select{|item| item["nx42"] }
            .map{|item| item["nx42"] }
        ([0.500] + positions).min
    end

    # ListingPosition::decideItemListingPositionOrNull(item)
    def self.decideItemListingPositionOrNull(item)
        if item["nx42"] then
            return item["nx42"]
        end

        if item["uuid"] == "6d4e97fa-d1ed-4db8-aa68-be403c659f9e" then
            return 0.200
        end

        # (sorted)      : (negatives)
        # priorities    : (negatives)
        # morning       : 0.200
        # Interruptions : 0.300
        # NxOndate & Today (morning selection)
        #               : 0.800
        # NxBackups     : 0.900
        # Wave          : 1.000 (disappearing after 2 hours)
        # NxOndate      : 1.100
        # Today         : 1.200
        # NxTask with tc-15
        #               : 1.300 disappearing after daily requirement)
        # BufferIn      : 1.500 (disappearing after 1 hour)
        # Environment   : 1.600 (disappearing after daily requirement)
        # NxTask        : 2.000

        if item["random"].nil? then
            item["random"] = rand
            Blades::setAttribute(item["uuid"], "random", item["random"])
        end

        if item["mikuType"] == "Wave" and item["interruption"] then
            return 0.300 + item["random"]/1000
        end

        if item["mikuType"] == "NxBackup" then
            return 0.900
        end

        if item["mikuType"] == "NxOndate" then
            return 1.100 + item["random"]/1000
        end

        if item["mikuType"] == "NxToday" then
            return 1.200 + item["random"]/1000
        end

        if item["mikuType"] == "Wave" then
            increase = 1.5
            hours    = 2.5
            rt = BankDerivedData::recoveredAverageHoursPerDayShortLivedCache("wave-general-fd3c4ac4-1300")
            return nil if rt > 2.0
            return 1.000 + increase * (rt.to_f/hours) + item["random"]/1000
        end

        if item["mikuType"] == "BufferIn" then
            increase = 1.5
            hours    = 1.0
            rt = BankDerivedData::recoveredAverageHoursPerDayShortLivedCache("0a8ca68f-d931-4110-825c-8fd290ad7853")
            return nil if rt > 1.0
            return 1.5 + item["random"]/1000
        end

        if item["mikuType"] == "Environment" then
            return nil if (Bank::getValueAtDate(item["uuid"], CommonUtils::today()) > (item["tc-16"].to_f/7)*3600)
            return 1.600 + item["random"]/1000
        end

        if item["mikuType"] == "NxTask" then
            if item["tc-15"] then
                return nil if (Bank::getValueAtDate(item["uuid"], CommonUtils::today()) > item["tc-15"]*3600)
                return 1.300 + item["random"]/1000
            end
            return 2.000
        end

        raise "[error: 4DC6AEBD] I do not know how to decide the listing position for item: #{item}"
    end

    # ListingPosition::delist(item)
    def self.delist(item)
        Blades::setAttribute(item["uuid"], "nx42", nil)
    end
end
