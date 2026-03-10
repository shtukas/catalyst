
class Nx43s

    # Nx43s::listingItems()
    def self.listingItems()
        Blades::items().select{|item| item["nx43"] and item["nx43"]["date"] == CommonUtils::today() }
    end
end
