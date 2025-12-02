
class ListingPosition

    # ---------------------------------------------------------------
    # Functions & Data

    # ListingPosition::realLineTo01Increasing(x)
    def self.realLineTo01Increasing(x)
        (2 + Math.atan(x)).to_f/10
    end

    # ListingPosition::firstNegativeListingPosition()
    def self.firstNegativeListingPosition()
        positions = Items::objects()
            .select{|item| item["nx41"] }
            .map{|item| item["nx41"]["position"] }
        ([-1] + positions).min
    end

    # ListingPosition::decideRatioListingOrNull(behaviour, nx41)
    def self.decideRatioListingOrNull(behaviour, nx41)
        raise "(error d8e9d7a7) I do not know how to compute ratio for behaviour: #{behaviour}"
    end

    # ListingPosition::decideItemListingPositionOrNull(item)
    def self.decideItemListingPositionOrNull(item)
        if item["nx41"] and item["nx41"]["type"] == "override" then
            return item["nx41"]["position"]
        end
        if item["nx41"] and item["nx41"]["type"] == "natural" and (Time.new.to_i - item["nx41"]["unixtime"]) < 3600*2 then
            return item["nx41"]["position"]
        end
        # interruptions : 0.100
        # priorities    : 0.500
        # ondates       : 1.150
        # waits         : 1.190
        # waves         : 1.350          (over 1.5 hours), then [1.8 ,  1.9]
        # projects      : 1.400 -> 1.500 (over 3.0 hours), then  1.8 -> 1.9  (over 3 hours)
        # items         : 1.500 -> 1.600 (over 2.0 hours), then  1.8 -> 1.9  (over 3 hours)
        if item["mikuType"] == "NxPriority" then
            return item["position-09"]
        end
        if item["mikuType"] == "NxWait" then
            return 1.190
        end
        if item["mikuType"] == "NxOndate" then
            return 1.150
        end
        if item["mikuType"] == "NxTask" then
            position = NxTasks::listingPosition(item)
            Items::setAttribute(item["uuid"], "nx41", {
                "type"     => "natural",
                "unixtime" => Time.new.to_i,
                "position" => position
            })
            return position
        end
        if item["mikuType"] == "Wave" then
            position = Waves::listingPosition(item)
            Items::setAttribute(item["uuid"], "nx41", {
                "type"     => "natural",
                "unixtime" => Time.new.to_i,
                "position" => position
            })
            return position
        end
        raise "[error: 4DC6AEBD] I do not know how to decide the listing position for item: #{item}"
    end

    # ListingPosition::delistItemAndSimilar(item)
    def self.delistItemAndSimilar(item)
        Items::setAttribute(item["uuid"], "nx41", nil)
        if item["mikuType"] == "NxTask" then
            NxTasks::listingItems().each{|item|
                next if item["nx41"].nil?
                next if item["nx41"]["type"] == "override"
                Items::setAttribute(item["uuid"], "nx41", nil)
            }
        end
        if item["mikuType"] == "Wave" then
            Waves::wavesListingItems().each{|item|
                next if item["nx41"].nil?
                next if item["nx41"]["type"] == "override"
                Items::setAttribute(item["uuid"], "nx41", nil)
            }
        end
    end
end
