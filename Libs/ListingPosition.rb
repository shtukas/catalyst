
class ListingPosition

    # ---------------------------------------------------------------
    # Functions & Data

    # ListingPosition::realLineTo01Increasing(x)
    def self.realLineTo01Increasing(x)
        (2 + Math.atan(x)).to_f/10
    end

    # ListingPosition::firstListingPosition()
    def self.firstListingPosition()
        positions = Items::objects()
            .select{|item| item["nx41"] }
            .map{|item| item["nx41"]["position"] }
        ([0.500] + positions).min
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

        # (sorted)       : (smaller positives)

        # priorities     : 0.000 -> 0.500
        # interruptions  : 0.000 -> 0.500

        # today          : 1.147 # exact number for search and replace
        # ondates        : 1.151 # exact number for search and replace
        # NxHappening    : 1.198 # exact number for search and replace

        # Wave           : 2.000 -> 3.000 over 2.0 hours
        # NxTask         : 2.000 -> 3.000 over 5.0 hours
        # NxInfinity     : 2.000 -> 3.000 over 1.0 hours

        if item["uuid"] == "2eed73e7-8424-4b4c-af01-14ccac76b300" then
            # wave morning
            Items::setAttribute(item["uuid"], "nx41", {
                "type"     => "override",
                "position" => 0.95 * ListingPosition::firstListingPosition()
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
            return 1.147 # exact number for search and replace + item["random"].to_f/1000
        end
        if item["mikuType"] == "NxHappening" then
            return 1.198 # 
        end
        if item["mikuType"] == "NxOndate" then
            if item["random"].nil? then
                item["random"] = rand
                Items::setAttribute(item["uuid"], "random", item["random"])
            end
            return 1.151 + item["random"].to_f/1000
        end
        if item["mikuType"] == "NxTask" then
            if item["random"].nil? then
                item["random"] = rand
                Items::setAttribute(item["uuid"], "random", item["random"])
            end
            base = BankDerivedData::recoveredAverageHoursPerDayCached("task-general-5f03ccc7-2b00").to_f/5.0
            return 2 + base + item["random"].to_f/1000
        end
        if item["mikuType"] == "Wave" then
            if item["random"].nil? then
                item["random"] = rand
                Items::setAttribute(item["uuid"], "random", item["random"])
            end
            if item["interruption"] then
                return 0.500 + item["random"].to_f/1000
            end
            base = BankDerivedData::recoveredAverageHoursPerDayCached("wave-general-fd3c4ac4-1300").to_f/2.0
            return 2 + base + item["random"].to_f/1000
        end
        if item["mikuType"] == "NxInfinity" then
            if item["random"].nil? then
                item["random"] = rand
                Items::setAttribute(item["uuid"], "random", item["random"])
            end
            base = BankDerivedData::recoveredAverageHoursPerDayCached("infinity-general-b8618ad8-a5ec").to_f/1.5
            return 2 + base + item["random"].to_f/1000
        end
        raise "[error: 4DC6AEBD] I do not know how to decide the listing position for item: #{item}"
    end

    # ListingPosition::delistNonOverridenItem(item)
    def self.delistNonOverridenItem(item)
        return if item["nx41"].nil?
        return if item["nx41"]["type"] == "override"
        Items::setAttribute(item["uuid"], "nx41", nil)
    end
end
