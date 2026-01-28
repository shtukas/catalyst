
class Active67

    # Active67::listingItems()
    def self.listingItems()
        Blades::items().select{|item| item["active-67"] }
    end
end
