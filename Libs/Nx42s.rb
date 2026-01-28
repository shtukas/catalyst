
class Nx42s

    # Nx42s::listingItems()
    def self.listingItems()
        Blades::items().select{|item| item["nx42"] }
    end
end
