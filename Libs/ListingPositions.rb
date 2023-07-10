
# encoding: UTF-8

# A Np01 is either null, or [1, float] or [2]
#     - null means no position found for today
#     - { zone: "1", position: }
#     - { zone: "2", position: }

class ListingPositions

    # ListingPositions::getNp01OrNull(item)
    def self.getNp01OrNull(item)
        CatalystSharedCache::getOrNull("09880513-4617-4a00-9495-333df8e6a57c:#{item["uuid"]}")
    end

    # ListingPositions::setNp01(item, np01)
    def self.setNp01(item, np01)
        raise "error 1426" if np01["zone"].nil?
        raise "error 1427" if np01["position"].nil?
        CatalystSharedCache::set("09880513-4617-4a00-9495-333df8e6a57c:#{item["uuid"]}",  np01)
    end

    # ListingPositions::positionMinus1()
    def self.positionMinus1()
        range = JSON.parse(XCache::getOrDefaultValue("range-86a4-fde7a736ef93", "[1, 1]"))
        range[0] - 1
    end

    # ListingPositions::nextPosition()
    def self.nextPosition()
        range = JSON.parse(XCache::getOrDefaultValue("range-86a4-fde7a736ef93", "[1, 1]"))
        range[1] + 1
    end

    # ListingPositions::interactivelyMakeNp01OrNull()
    def self.interactivelyMakeNp01OrNull()
        position = nil
        loop {
            position = LucilleCore::askQuestionAnswerAsString("position (top, next, zone 1 <float>): ")
            break if position != ""
        }
        np01 = nil
        if position == "top" then
            np01 = {
                "zone"     => "1",
                "position" => ListingPositions::positionMinus1()
            }
        end
        if position == "next" then
            np01 = {
                "zone"     => "2",
                "position" => ListingPositions::nextPosition()
            }
        end
        if np01.nil? then
            np01 = {
                "zone"     => "1",
                "position" => position.to_f
            }
        end
        return if np01.nil?
    end

    # ListingPositions::interactivelySetNp01Attempt(item)
    def self.interactivelySetNp01Attempt(item)
        np01 = ListingPositions::interactivelyMakeNp01OrNull()
        return if np01.nil?
        ListingPositions::setNp01(item, np01)
    end

    # ListingPositions::extractAndStoreRangeFromListingItems(items)
    def self.extractAndStoreRangeFromListingItems(items)
        positions = items
                        .map{|item| ListingPositions::getNp01OrNull(item) }
                        .compact
                        .map{|np01| np01["position"] }
        range = 
            if positions.empty? then
                [1, 1]
            else
                [positions.min, positions.max]
            end
        XCache::set("range-86a4-fde7a736ef93", JSON.generate(range))
    end

    # ListingPositions::revoke(item)
    def self.revoke(item)
        CatalystSharedCache::destroy("09880513-4617-4a00-9495-333df8e6a57c:#{item["uuid"]}")
    end
end
