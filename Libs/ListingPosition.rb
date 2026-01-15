
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
        # Today         : 0.800
        # NxBackups     : 0.900
        # Wave          : 1.000 (disappearing after 2 hours)
        # NxOndate      : 1.100
        # Today         : 1.200
        # BufferIn      : 1.500 (disappearing after 1 hour)
        # Cliques       : 1.600

        bases = {
            "buffer-in" => {
                "account" => BufferIn::uuid(),
                "rt-target" => 1
            },
            "cliques" => {
                "account" => "cliques-general-abe8-29c00fe4f10c",
                "rt-target" => 4
            },
            "waves" => {
                "account" => "waves-general-fd3c4ac4-1300",
                "rt-target" => 2
            }
        }

        if item["random"].nil? and (item["mikuType"] != "NxClique") then
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
            base = BankDerivedData::recoveredAverageHoursPerDayShortLivedCache(bases["waves"]["account"]).to_f/bases["waves"]["rt-target"]
            return base + item["random"]/1000
        end

        if item["mikuType"] == "BufferIn" then
            base = BankDerivedData::recoveredAverageHoursPerDayShortLivedCache(bases["buffer-in"]["account"]).to_f/bases["buffer-in"]["rt-target"]
            return base + item["random"]/1000
        end

        if item["mikuType"] == "NxClique" then
            base = BankDerivedData::recoveredAverageHoursPerDayShortLivedCache(bases["waves"]["account"]).to_f/bases["waves"]["rt-target"]
            epsilon = BankDerivedData::recoveredAverageHoursPerDayShortLivedCache(item["uuid"])
            return base + epsilon
        end

        raise "[error: 4DC6AEBD] I do not know how to decide the listing position for item: #{item}"
    end

    # ListingPosition::delist(item)
    def self.delist(item)
        Blades::setAttribute(item["uuid"], "nx42", nil)
    end
end
