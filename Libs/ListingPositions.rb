
# encoding: UTF-8

class ListingPositions

    # ListingPositions::getOrNull(item)
    def self.getOrNull(item)
        CatalystSharedCache::getOrNull("6229611a-b67b-4b0f-9303-d5e10f97428a:#{item["uuid"]}") # Float
    end

    # ListingPositions::set(item, position)
    def self.set(item, position)
        CatalystSharedCache::set("6229611a-b67b-4b0f-9303-d5e10f97428a:#{item["uuid"]}", position)
    end

    # ListingPositions::nextPosition()
    def self.nextPosition()
        range = JSON.parse(XCache::getOrDefaultValue("deeecc9c-2c6f-4880-be79-d0708a3caf72", "[1,1]"))
        range[1] + 1
    end

    # ListingPositions::interactivelySetOrdinalAttempt(item)
    def self.interactivelySetOrdinalAttempt(item)
        position = LucilleCore::askQuestionAnswerAsString("position (empty for next): ")
        position =
            if position == "" then
                ListingPositions::nextPosition()
            else
                position.to_f
            end
        ListingPositions::set(item, position)
    end

    # ListingPositions::extractRangeFromListingItems(items)
    def self.extractRangeFromListingItems(items)
        positions = items
                        .select{|item| item["mikuType"] != "TxCore" }
                        .map{|item| ListingPositions::getOrNull(item) }
                        .compact
        range = 
            if positions.empty? then
                [1, 1]
            else
                [positions.min, positions.max]
            end
        XCache::set("deeecc9c-2c6f-4880-be79-d0708a3caf72", JSON.generate(range))
    end

    # ListingPositions::completionRatioToPosition(ratio)
    def self.completionRatioToPosition(ratio)
        range = JSON.parse(XCache::getOrDefaultValue("deeecc9c-2c6f-4880-be79-d0708a3caf72", "[1,1]"))
        ratio * range[1]
    end

    # ListingPositions::randomPositionInRange()
    def self.randomPositionInRange()
        range = JSON.parse(XCache::getOrDefaultValue("deeecc9c-2c6f-4880-be79-d0708a3caf72", "[1,1]"))
        range[0] + rand * (range[1]-range[0])
    end

    # ListingPositions::revoke(item)
    def self.revoke(item)
        CatalystSharedCache::destroy("6229611a-b67b-4b0f-9303-d5e10f97428a:#{item["uuid"]}")
    end
end
