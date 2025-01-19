
class ListingPositioning

    # ListingPositioning::itemsInOrder()
    def self.itemsInOrder()
        Items::items()
            .each{|item|
                next if item["listing-positioning-2141"]
                next if item["mikuType"] == "NxTask"
                next if item["mikuType"] == "NxCore"
                next if item["mikuType"] == "NxStrat"
                Items::setAttribute(item["uuid"], "listing-positioning-2141", ListingPositioning::next_unixtime(item))
            }

        Items::items()
            .reject{|item| ["NxCore", "NxTask", "NxStrat"].include?(item["mikuType"]) }
            .select{|item| item["listing-positioning-2141"] }
            .sort_by{|item| item["listing-positioning-2141"] }
    end

    # ListingPositioning::next_unixtime(item)
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
        raise "(error: c21b8535) do not know how to reposition #{JSON.pretty_generate(item)}"
    end

    # ListingPositioning::reposition(item)
    def self.reposition(item)
        unixtime = ListingPositioning::next_unixtime(item)
        puts "repositioning '#{PolyFunctions::toString(item)}' at #{Time.at(unixtime).to_s.green}"
        Items::setAttribute(item["uuid"], "listing-positioning-2141", unixtime)
    end
end

