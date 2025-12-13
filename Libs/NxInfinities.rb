
class NxInfinities

    # NxInfinities::icon()
    def self.icon()
        "🫆"
    end

    # NxInfinities::toString(item)
    def self.toString(item)
        "#{NxInfinities::icon()} #{item["description"]}"
    end

    # NxInfinities::listingItems()
    def self.listingItems()
        Items::mikuType("NxInfinity")
            .sort_by{|item| item["px36"] }
            .first(5)
    end
end
