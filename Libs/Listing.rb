
class Listing

    # Listing::itemToRange(item) # [cursor, size]
    def self.itemToRange(item)
        if item["mikuType"] == "Wave" and item["interruption"] then
            return [2, 2]
        end
        if item["mikuType"] == "NxOndate" then
            return [4, 4]
        end
        [8, 6]
    end

    # Listing::ordinals()
    def self.ordinals()
        MainUserInterface::items()
            .select{|item| item["listing-ordinal-134"] }
            .sort_by{|item| item["listing-ordinal-134"] }
            .map{|i| i["listing-ordinal-134"] }
    end

    # Listing::decideOrdinal(ordinals, range)
    def self.decideOrdinal(ordinals, range)
        ordinals = ordinals.drop(range[0]).take(range[1])
        if ordinals.empty? then
            return 1
        end
        if ordinals.size < range[1] then
            return ordinals.last + 1
        end
        ordinals.first + rand*(ordinals.last - ordinals.first)
    end

    # Listing::itemToOrdinal(item)
    def self.itemToOrdinal(item)
        Listing::decideOrdinal(Listing::ordinals(), Listing::itemToRange(item))
    end

    # Listing::prepareItems()
    def self.prepareItems()
        MainUserInterface::items().map{|item|
            if item["listing-ordinal-134"].nil? then
                ordinal = Listing::itemToOrdinal(item)
                Cubes2::setAttribute(item["uuid"], "listing-ordinal-134", ordinal)
            end
        }
    end

    # Listing::getListedItemsInOrder()
    def self.getListedItemsInOrder()
        Listing::prepareItems()
        MainUserInterface::items()
            .select{|item| item["listing-ordinal-134"] }
            .sort_by{|item| item["listing-ordinal-134"] }
    end
end
