
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

    # ListingPosition::bases()
    def self.bases()
        {
            "buffer-in" => {
                "name"     => "Buffer In",
                "account"  => BufferIn::uuid(),
                "rtTarget" => 1
            },
            "cliques" => {
                "name"     => "Nx38s",
                "account"  => "cliques-general-abe8-29c00fe4f10c",
                "rtTarget" => 5 # we select 3 each morning that are expected to do 1.5 + 1 + 1
            },
            "waves" => {
                "name"     => "Waves",
                "account"  => "waves-general-fd3c4ac4-1300",
                "rtTarget" => 2
            }
        }
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
        # Today         : 0.800
        # NxBackups     : 0.900
        # NxOndate      : 1.100
        # Today         : 1.200

        # Wave          : 1.500 -> 2.500+

        # engined tasks or listing
        #               : 2.000+

        # BufferIn      : 3.000 -> 4.000+
        # NxListing     : 3.000 -> 4.000+

        bases = ListingPosition::bases()

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
            ratio = BankDerivedData::recoveredAverageHoursPerDayShortLivedCache(bases["waves"]["account"]).to_f/bases["waves"]["rtTarget"]
            return 1.500 + ratio + item["random"]/1000
        end

        if item["mikuType"] == "BufferIn" then
            ratio = BankDerivedData::recoveredAverageHoursPerDayShortLivedCache(bases["buffer-in"]["account"]).to_f/bases["buffer-in"]["rtTarget"]
            return nil if ratio >= 1
            return 3 + ratio + item["random"]/1000
        end

        if item["engine-24"] then
            return NxEngines::position(item, item["engine-24"])
        end

        if item["mikuType"] == "NxListing" then
            ratio = BankDerivedData::recoveredAverageHoursPerDayShortLivedCache(bases["cliques"]["account"]).to_f/bases["cliques"]["rtTarget"]
            return nil if ratio >= 1
            epsilon = NxListings::ratio(item)
            return nil if epsilon.nil?
            return 3 + ratio + epsilon.to_f/1000
        end

        raise "[error: 4DC6AEBD] I do not know how to decide the listing position for item: #{item}"
    end

    # ListingPosition::delist(item)
    def self.delist(item)
        Blades::setAttribute(item["uuid"], "nx42", nil)
    end
end
