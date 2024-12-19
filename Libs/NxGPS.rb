
class NxGPS

    # NxGPS::itemsInOrder()
    def self.itemsInOrder()
        Items::items()
            .select{|item| item["gps-2119"] }
            .sort_by{|item| item["gps-2119"] }
    end

    # NxGPS::next_unixtime(item)
    def self.next_unixtime(item)
        if item["mikuType"] == "NxAnniversary" then
            return Anniversaries::next_unixtime(item)
        end
        if item["mikuType"] == "Wave" then
            return Waves::next_unixtime(item)
        end
        if item["mikuType"] == "NxFloat" then
            return NxFloats::next_unixtime()
        end
        if item["mikuType"] == "NxBackup" then
            return NxBackups::next_unixtime(item)
        end

        if item["mikuType"] == "NxDated" then
            return NxDateds::next_unixtime(item)
        end

        if item["mikuType"] == "NxCore" then
            return NxCores::next_unixtime(item)
        end
        raise "(error: c21b8535) do not know how to reposition #{JSON.pretty_generate(item)}"
    end

    # NxGPS::reposition(item)
    def self.reposition(item)
        unixtime = NxGPS::next_unixtime(item)
        puts "repositioning '#{PolyFunctions::toString(item)}' at #{Time.at(unixtime).to_s}"
        Items::setAttribute(item["uuid"], "gps-2119", unixtime)
    end
end

