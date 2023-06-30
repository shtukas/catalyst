
# encoding: UTF-8

class Ordinals

    # Ordinals::getOrNull(item)
    def self.getOrNull(item)
        CatalystSharedCache::getOrNull("6229611a-b67b-4b0f-9303-d5e10f97428a:#{item["uuid"]}") # Float
    end

    # Ordinals::set(item, position)
    def self.set(item, position)
        CatalystSharedCache::set("6229611a-b67b-4b0f-9303-d5e10f97428a:#{item["uuid"]}", position)
    end

    # Ordinals::interactivelySetOrdinalAttempt(item)
    def self.interactivelySetOrdinalAttempt(item)
        position = LucilleCore::askQuestionAnswerAsString("position (empty for next): ")
        position =
            if position == "" then
                range = JSON.parse(XCache::getOrDefaultValue("deeecc9c-2c6f-4880-be79-d0708a3caf72", "[1,1]"))
                range[1] + 1
            else
                position.to_f
            end
        Ordinals::set(item, position)
    end

    # Ordinals::extractRangeFromListingItems(items)
    def self.extractRangeFromListingItems(items)
        positions = items
                        .select{|item| item["mikuType"] != "TxCore" }
                        .map{|item| Ordinals::getOrNull(item) }
                        .compact
        range = 
            if positions.empty? then
                [1, 1]
            else
                [positions.min, positions.max]
            end
        XCache::set("deeecc9c-2c6f-4880-be79-d0708a3caf72", JSON.generate(range))
    end

    # Ordinals::completionRatioToPosition(ratio)
    def self.completionRatioToPosition(ratio)
        range = JSON.parse(XCache::getOrDefaultValue("deeecc9c-2c6f-4880-be79-d0708a3caf72", "[1,1]"))
        ratio*range[1]
    end
end
