
class ListingPosition

    # ---------------------------------------------------------------
    # Functions & Data

    # ListingPosition::realLineTo01Increasing(x)
    def self.realLineTo01Increasing(x)
        (2 + Math.atan(x)).to_f/10
    end

    # ListingPosition::firstGlobalListingPosition()
    def self.firstGlobalListingPosition()
        positions = Blades::items()
            .select{|item| item["nx42"] }
            .map{|item| item["nx42"] }
        ([-1] + positions).min
    end

    # ListingPosition::firstPrioritiesListingPosition()
    def self.firstPrioritiesListingPosition()
        positions = Blades::items()
            .select{|item| item["nx42"] }
            .select{|item| 0 <= item["nx42"] and item["nx42"] < 1.000 }
            .map{|item| item["nx42"] }
        ([0.900] + positions).min
    end

    # ListingPosition::newPrioritiesListingPosition()
    def self.newPrioritiesListingPosition()
        0.9 * ListingPosition::firstPrioritiesListingPosition()
    end

    # ListingPosition::firstTodaySpecialListingPosition()
    def self.firstTodaySpecialListingPosition()
        positions = Blades::items()
            .select{|item| item["nx42"] }
            .select{|item| 2.000 <= item["nx42"] and item["nx42"] < 3.000 }
            .map{|item| item["nx42"] }
        ([2.900] + positions).min
    end

    # ListingPosition::newTodaySpecialListingPosition()
    def self.newTodaySpecialListingPosition()
        0.1 * 2.000 + 0.9 * ListingPosition::firstTodaySpecialListingPosition()
    end

    # ListingPosition::listingBucketAndPositionOrNull(item) # float
    def self.listingBucketAndPositionOrNull(item)

        # directive: Nx42s are not delisted, unless `done`

        # listing buckets:
        # global sort           -infty -> 0.000 (nx42: sorted)
        # priorities             0.000 -> 1.000 (nx42)
        # interruptions          1.000 -> 2.000
        # today special (sorted) 2.000 -> 3.000 (nx42: sorted)
        # today                  3.000 -> 4.000
        # today or next days     4.000 -> 5.000

        rotation = lambda{|x| 0.5 + 0.5 * Math.sin(x + Time.new.to_f/86400) }

        if item["nx42"] then
            # those are the result of either
            # 1. a global sort, when we decide to do things 
            # 2. priorities
            # 3. today specials
            if item["nx42"] < 0 then
                return ["global sort", item["nx42"]]
            end
            if item["nx42"] >= 0 and item["nx42"] < 1 then
                return ["priorities", item["nx42"]]
            end
            return ["today special", item["nx42"]] # this will also be catch all for backward compatibility
        end

        if item["random"].nil? then
            item["random"] = rand
            Blades::setAttribute(item["uuid"], "random", item["random"])
        end

        if item["mikuType"] == "Wave" and item["interruption"] then
            return ["priorities", 0.000 + rotation.call(item["random"])]
        end

        if item["mikuType"] == "NxCounter" then
            return ["today", 3.000 + rotation.call(item["random"])]
        end

        if item["mikuType"] == "NxBackup" then
            return ["today", 3.000 + rotation.call(item["random"])]
        end

        if item["mikuType"] == "Float" then
            return ["today", 3.000 + rotation.call(item["random"])]
        end

        if item["mikuType"] == "NxOndate" then
            return ["today", 3.000 + rotation.call(item["random"])]
        end

        if item["mikuType"] == "NxToday" then
            return ["today", 3.000 + rotation.call(item["random"])]
        end

        if item["mikuType"] == "BufferIn" then
            return ["today", 3.000 + rotation.call(item["random"])]
        end

        if item["mikuType"] == "Wave" then
            if item["listing-marker-57"].nil? then
                item["listing-marker-57"] = Time.new.to_i
                Blades::setAttribute(item["uuid"], "listing-marker-57", item["listing-marker-57"])
            end
            dt = (Time.new.to_i - item["listing-marker-57"]).to_i/86400
            if dt < 3 then
                return ["today or next days", 4.000 + rotation.call(item["random"])]
            else
                return ["today", 3.000 + rotation.call(item["random"])]
            end
        end

        if item["engine-24"] then
            position = NxEngines::positionOrNull(item, item["engine-24"], 3.000, 4.000)
            return nil if position.nil?
            return ["today", position]
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
