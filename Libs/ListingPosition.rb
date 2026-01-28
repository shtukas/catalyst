
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

        # (sorted)      : (negatives)
        # priorities    : (negatives)
        # Interruptions : 0.300
        # Float         : 0.500
        # Wave          : 0.600
        # Today         : 0.800
        # NxBackups     : 0.900
        # NxOndate      : 1.100
        # Today         : 1.200
        # engined       : 2.000+
        # BufferIn      : 3.000 -> 4.000+
        # active-67     : 3.100
        # NxListing     : 3.500

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

        if item["mikuType"] == "Float" then
            return 0.500 + item["random"]/1000
        end

        if item["mikuType"] == "NxOndate" then
            return 1.100 + item["random"]/1000
        end

        if item["mikuType"] == "NxToday" then
            return 1.200 + item["random"]/1000
        end

        if item["mikuType"] == "Wave" then
            return 0.600 + item["random"]/1000
        end

        if item["mikuType"] == "BufferIn" then
            ratio = BankDerivedData::recoveredAverageHoursPerDay(BufferIn::uuid()).to_f/1
            return nil if ratio >= 1
            return 3 + ratio + item["random"]/1000
        end

        if item["engine-24"] then
            return NxEngines::positionOrNull(item, item["engine-24"])
        end

        if item["mikuType"] == "NxListing" then
            return 3.500 + item["random"]/1000
        end

        if item["active-67"] then
            return 3.100 + item["random"]/1000
        end

        raise "[error: 4DC6AEBD] I do not know how to decide the listing position for item: #{item}"
    end

    # ---------------------------------------------------------------
    # Ops

    # ListingPosition::delist(item)
    def self.delist(item)
        Blades::setAttribute(item["uuid"], "nx42", nil)
    end
end
