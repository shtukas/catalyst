
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
        if behaviour["btype"] == "backup" then
            return 0.300
        end
        if behaviour["btype"] == "anniversary" then
            return 0.150
        end
        raise "(error d8e9d7a7) I do not know how to compute ratio for behaviour: #{behaviour}"
    end

    # ListingPosition::decideItemListingPositionOrNull(item)
    def self.decideItemListingPositionOrNull(item)
        if item["nx41"] and item["nx41"]["position"] < 0 then
            return item["nx41"]["position"]
        end
        if item["mikuType"] == "NxPriority" then
            return item["position-09"]
        end
        # interruptions : 0.1
        # projects      : 0.2 -> 1.0 over 5 hours
        # items         : 0.2 -> 1.0 over 2 hours
        # waves         : 0.2 -> 1.0
        # waits         : 0.500
        if item["nx41"] and (Time.new.to_i - item["nx41"]["unixtime"]) < 3600 then
            return item["nx41"]["position"]
        end
        if item["mikuType"] == "NxWait" then
            return 0.5
        end
        if item["mikuType"] == "NxProject" then
            position = NxProjects::computeListingPosition(item)
            Items::setAttribute(item["uuid"], "nx41", {
                "unixtime" => Time.new.to_f,
                "position" => position
            })
            return position
        end
        if item["mikuType"] == "NxTask" then
            position = NxTasks::listingPosition(item)
            Items::setAttribute(item["uuid"], "nx41", {
                "unixtime" => Time.new.to_f,
                "position" => position
            })
            return position
        end
        if item["mikuType"] == "NxPolymorph" then
            ratio = ListingPosition::decideRatioListingOrNull(item["bx42"], item["nx41"])
            if ratio.nil? then
                Items::setAttribute(item["uuid"], "nx41", nil)
                return nil
            end
            position = ratio
            Items::setAttribute(item["uuid"], "nx41", {
                "unixtime" => Time.new.to_f,
                "position" => position
            })
            return position
        end
        if item["mikuType"] == "Wave" then
            if item["random"].nil? then
                item["random"] = rand
                Items::setAttribute(item["uuid"], "random", item["random"])
            end
            if item["interruption"] then
                return 0.100 + 0.001 * item["random"]
            end
            return 0.600 + 0.4 * Math.sin(Time.new.to_f/86400 + item["random"])
        end
        raise "[error: 4DC6AEBD] I do not know how to decide the listing position for item: #{item}"
    end

    # ListingPosition::delistItemAndSimilar(item)
    def self.delistItemAndSimilar(item)
        Items::setAttribute(item["uuid"], "nx41", nil)
        if item["mikuType"] == "NxProject" then
            Items::mikuType("NxProject").each{|item|
                Items::setAttribute(item["uuid"], "nx41", nil)
            }
        end
        if item["mikuType"] == "NxTask" then
            NxTasks::listingItems().each{|item|
                Items::setAttribute(item["uuid"], "nx41", nil)
            }
        end
    end
end
