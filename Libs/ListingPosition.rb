
class ListingPosition

    # ---------------------------------------------------------------
    # Functions & Data

    # ListingPosition::realLineTo01Increasing(x)
    def self.realLineTo01Increasing(x)
        (2 + Math.atan(x)).to_f/10
    end

    # ListingPosition::firstPriorityListingPosition()
    def self.firstPriorityListingPosition()
        positions = Items::objects()
            .select{|item| item["nx41"] }
            .map{|item| item["nx41"]["position"] }
        ([-1] + positions).min
    end

    # ListingPosition::lastPriorityListingPosition()
    def self.lastPriorityListingPosition()
        positions = Items::objects()
            .select{|item| item["nx41"] }
            .select{|item| item["nx41"]["position"] < 0 }
            .map{|item| item["nx41"]["position"] }
        ([-1] + positions).max
    end

    # ListingPosition::firstTodayListingPosition()
    def self.firstTodayListingPosition()
        positions = Items::objects()
            .select{|item| item["nx41"] }
            .select{|item| 0 < item["nx41"]["position"] and item["nx41"]["position"] < 1 }
            .map{|item| item["nx41"]["position"] }
        ([0.5] + positions).min
    end

    # ListingPosition::lastTodayListingPosition()
    def self.lastTodayListingPosition()
        positions = Items::objects()
            .select{|item| item["nx41"] }
            .select{|item| 0 < item["nx41"]["position"] and item["nx41"]["position"] < 1 }
            .map{|item| item["nx41"]["position"] }
        ([0.5] + positions).max
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
        # (sorted)       : (negative)
        # interruptions  : 0.100
        # day priorities : 0.500
        # today          : 1.140
        # ondates        : 1.150
        # NxHappening    : 1.190
        # Wave           : 1.350
        # NxTask         : 1.400
        # NxInfinity     : 1.600

        if item["uuid"] == "2eed73e7-8424-4b4c-af01-14ccac76b300" then
            # wave morning
            Items::setAttribute(item["uuid"], "nx41", {
                "type"     => "override",
                "position" => ListingPosition::firstPriorityListingPosition()/2,
            })
        end

        if item["mikuType"] == "NxLine" then
            # should have been handled above as they are born with a never expire Nx41
            raise "(064142) how did this happen ? item: #{item}"
        end
        if item["mikuType"] == "NxToday" then
            if item["random"].nil? then
                item["random"] = rand
                Items::setAttribute(item["uuid"], "random", item["random"])
            end
            return 1.140 + item["random"].to_f/1000
        end
        if item["mikuType"] == "NxHappening" then
            return 1.190
        end
        if item["mikuType"] == "NxInfinity" then
            return 2.000
        end
        if item["mikuType"] == "NxOndate" then
            if item["random"].nil? then
                item["random"] = rand
                Items::setAttribute(item["uuid"], "random", item["random"])
            end
            return 1.150 + item["random"].to_f/1000
        end
        if item["mikuType"] == "NxTask" then
            if item["random"].nil? then
                item["random"] = rand
                Items::setAttribute(item["uuid"], "random", item["random"])
            end
            return 1.4 + item["random"].to_f/1000
        end
        if item["mikuType"] == "Wave" then
            if item["random"].nil? then
                item["random"] = rand
                Items::setAttribute(item["uuid"], "random", item["random"])
            end
            return 1.350 + item["random"].to_f/1000
        end
        if item["mikuType"] == "NxInfinity" then
            if item["random"].nil? then
                item["random"] = rand
                Items::setAttribute(item["uuid"], "random", item["random"])
            end
            return 1.600 + item["random"].to_f/1000
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
            Waves::listingItems().each{|item|
                next if item["nx41"].nil?
                next if item["nx41"]["type"] == "override"
                Items::setAttribute(item["uuid"], "nx41", nil)
            }
        end
    end
end
