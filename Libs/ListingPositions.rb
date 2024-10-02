
class ListingPositions

    # ListingPositions::applyOrder(items)
    def self.applyOrder(items)
        is1, is2 = items.partition{|item| item["list-pos-1610"] and item["list-pos-1610"]["date"] == CommonUtils::today() }
        is1 = is1.sort_by {|item| item["list-pos-1610"]["position"] }
        is1 + is2
    end

    # ListingPositions::getFirstPosition()
    def self.getFirstPosition()
        items = Listing::items().select {|item| item["list-pos-1610"] and item["list-pos-1610"]["date"] == CommonUtils::today() }
        return 1 if items.empty?
        items.map{|item| item["list-pos-1610"]["position"] }.min
    end

    # ListingPositions::toString(item)
    def self.toString(item)
        return "       " if ( item["list-pos-1610"].nil? or item["list-pos-1610"]["date"] != CommonUtils::today() )
        "%7.3f" % item["list-pos-1610"]["position"]
    end

    # ListingPositions::itemsInOrder()
    def self.itemsInOrder()
        ListingPositions::applyOrder(Listing::items())
    end
end
