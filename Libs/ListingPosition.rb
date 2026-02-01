
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
        # NxCounter     : 0.320
        # (morning)     : 0.350 -> 0.450
        # Float         : 0.500
        # Wave          : 0.600 -> 4.000
        # Today         : 0.800
        # NxBackups     : 0.900
        # NxOndate      : 1.100
        # Today         : 1.200
        # engined       : 2.000 -> 3.000
        # BufferIn      : 3.000 -> 4.000
        # active-67     : 3.400
        # NxListing     : 3.500

        if item["random"].nil? then
            item["random"] = rand
            Blades::setAttribute(item["uuid"], "random", item["random"])
        end

        if item["mikuType"] == "Wave" and item["interruption"] then
            return 0.300 + item["random"]/1000
        end

        if item["mikuType"] == "NxCounter" then
            return 0.320 + item["random"]/1000
        end

        if item["mikuType"] == "NxBackup" then
            return 0.900 + item["random"]/1000
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
            base = 0.600
            top = 4.000
            return base + item["random"] * (top - base)
        end

        if item["mikuType"] == "BufferIn" then
            rt = BankDerivedData::recoveredAverageHoursPerDay(BufferIn::uuid()).to_f
            return nil if rt >= 1
            return 3 + rt
        end

        if item["engine-24"] then
            return NxEngines::positionOrNull(item, item["engine-24"])
        end

        if item["mikuType"] == "NxListing" then
            return 3.500 + item["random"]/1000
        end

        if item["active-67"] then
            return 3.400 + item["random"]/1000
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
