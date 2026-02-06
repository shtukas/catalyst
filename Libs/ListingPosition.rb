
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

    # ListingPosition::listingPositionOrNull(item) # float
    def self.listingPositionOrNull(item)

        # directive: Nx42s are not delisted, unless `done`

        # listing buckets:
        # global-sort           -infty -> 0.000 (nx42: sorted)
        # interruptions          1.000 -> 2.000
        # active and al          2.000 -> 3.000
        # listings               3.000 -> 4.000
        # next-days              4.000 -> 5.000

        rotation = lambda{|x| 0.5 + 0.5 * Math.sin(x + Time.new.to_f/86400) }

        if item["nx42"] then
            return item["nx42"]
        end

        if item["random"].nil? then
            item["random"] = rand
            Blades::setAttribute(item["uuid"], "random", item["random"])
        end

        if item["mikuType"] == "Wave" and item["interruption"] then
            return 1.000 + rotation.call(item["random"])
        end

        if item["mikuType"] == "NxCounter" then
            return 2.000 + item["random"]/1000
        end

        if item["mikuType"] == "NxBackup" then
            return 2.000 + rotation.call(item["random"])
        end

        if item["mikuType"] == "NxActive" then
            return 2.000 + rotation.call(item["random"])
        end

        if item["mikuType"] == "NxOndate" then
            return 2.000 + rotation.call(item["random"])
        end

        if item["mikuType"] == "BufferIn" then
            return 2.998 + item["random"]/1000
        end

        if item["mikuType"] == "Wave" then
            if item["listing-marker-57"].nil? then
                item["listing-marker-57"] = Time.new.to_i
                Blades::setAttribute(item["uuid"], "listing-marker-57", item["listing-marker-57"])
            end
            dt = (Time.new.to_i - item["listing-marker-57"]).to_i/86400
            if dt < 1 then
                return 4.000 + rotation.call(item["random"])
            end
            return 2.000 + rotation.call(item["random"])
        end

        if item["mikuType"] == "NxListing" then
            return 3.000 + rotation.call(item["random"])
        end

        if item["engine-24"] then
            return NxEngines::positionOrNull(item, item["engine-24"], 2.000, 4.000)
        end

        raise "[error: 4DC6AEBD] I do not know how to decide the listing position for item: #{item}"
    end

    # ---------------------------------------------------------------
    # Ops

    # ListingPosition::nullifyNx42(item)
    def self.nullifyNx42(item)
        Blades::setAttribute(item["uuid"], "nx42", nil)
    end
end
