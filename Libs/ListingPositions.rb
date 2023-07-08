
# encoding: UTF-8

class ListingPositions

    # ListingPositions::getOrNull(item)
    def self.getOrNull(item)
        CatalystSharedCache::getOrNull("6229611a-b67b-4b0f-9303-d5e10f97428a:#{item["uuid"]}") # Float
    end

    # ListingPositions::automaticPositioning(item)
    def self.automaticPositioning(item)
        position = CatalystSharedCache::getOrNull("6229611a-b67b-4b0f-9303-d5e10f97428a:#{item["uuid"]}") # Float
        return if !position.nil?
        if item["mikuType"] == "Wave" and !item["interruption"] then
            position = ListingPositions::nextPosition()
            ListingPositions::set(item, position)
        end
        if item["mikuType"] == "Wave" and item["interruption"] then
            position = ListingPositions::positionMinus1()
            ListingPositions::set(item, position)
        end
        if item["mikuType"] == "PhysicalTarget" then
            position = ListingPositions::positionMinus1()
            ListingPositions::set(item, position)
        end
        if item["mikuType"] == "NxFeeder" then
            position = ListingPositions::nextPosition()
            ListingPositions::set(item, position)
        end
        if item["mikuType"] == "NxTask" then
            position = ListingPositions::nextPosition()
            ListingPositions::set(item, position)
        end
    end

    # ListingPositions::getOrNullForListing(item)
    def self.getOrNullForListing(item)
        CatalystSharedCache::getOrNull("6229611a-b67b-4b0f-9303-d5e10f97428a:#{item["uuid"]}") # Float
    end

    # ListingPositions::set(item, position)
    def self.set(item, position)
        CatalystSharedCache::set("6229611a-b67b-4b0f-9303-d5e10f97428a:#{item["uuid"]}", position)
        range = JSON.parse(XCache::getOrDefaultValue("deeecc9c-2c6f-4880-be79-d0708a3caf72", "[1,1]"))
        range = [[range[0], position].min, [range[1], position].max]
        XCache::set("deeecc9c-2c6f-4880-be79-d0708a3caf72", JSON.generate(range))
    end

    # ListingPositions::positionMinus1()
    def self.positionMinus1()
        range = JSON.parse(XCache::getOrDefaultValue("deeecc9c-2c6f-4880-be79-d0708a3caf72", "[1,1]"))
        range[0] - 1
    end

    # ListingPositions::nextPosition()
    def self.nextPosition()
        range = JSON.parse(XCache::getOrDefaultValue("deeecc9c-2c6f-4880-be79-d0708a3caf72", "[1,1]"))
        range[1] + 1
    end

    # ListingPositions::interactivelySetPositionAttempt(item)
    def self.interactivelySetPositionAttempt(item)
        position = "" 
        loop {
            position = LucilleCore::askQuestionAnswerAsString("position (float) (top, next): ")
            break if position != ""
        }
        px = nil
        if position == "top" then
            px = ListingPositions::positionMinus1()
        end
        if position == "next" then
            px = ListingPositions::nextPosition()
        end
        if px.nil? then
            px = position.to_f
        end
        ListingPositions::set(item, px)
    end

    # ListingPositions::extractRangeFromListingItems(items)
    def self.extractRangeFromListingItems(items)
        positions = items
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

    # ListingPositions::revoke(item)
    def self.revoke(item)
        CatalystSharedCache::destroy("6229611a-b67b-4b0f-9303-d5e10f97428a:#{item["uuid"]}")
    end
end
