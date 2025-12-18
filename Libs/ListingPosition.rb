
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

    # ListingPosition::firstPositiveListingPosition()
    def self.firstPositiveListingPosition()
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

        # (sorted)        : (negatives)
        # priorities      : (negatives)

        # Interruptions   : 0.300

        # Wave               : 1.000 -> 2.500 over 2.5 hours
        # NxTask & NxProject
        #    priority        : 0.500
        #    happening       : 0.600
        #    today           : 1.500
        #    short-run-with-deadline
        #                    : 1.700
        #    short-run       : 2.000 -> 3.000 over 1.0 hours
        #    long-run        : 2.500 -> 3.500 over 1.0 hours

        # BufferIn           : 2.000 -> 3.000 over 1.0 hours
        # NxTask             : 2.000 -> 3.000 over 2.5 hours
        # NxProject          : 3.000 -> 4.000 over 2.5 hours

        if item["uuid"] == "2eed73e7-8424-4b4c-af01-14ccac76b300" then
            # wave morning
            Items::setAttribute(item["uuid"], "nx41", {
                "type"     => "override",
                "position" => 0.95 * ListingPosition::firstPositiveListingPosition()
            })
        end
        if item["mikuType"] == "NxOndate" then
            if item["random"].nil? then
                item["random"] = rand
                Items::setAttribute(item["uuid"], "random", item["random"])
            end
            return 1.151 + item["random"].to_f/1000
        end
        if item["mikuType"] == "BufferIn" then
            return 2 + BankDerivedData::recoveredAverageHoursPerDayCached("0a8ca68f-d931-4110-825c-8fd290ad7853")
        end
        if item["mikuType"] == "Wave" then
            if item["random"].nil? then
                item["random"] = rand
                Items::setAttribute(item["uuid"], "random", item["random"])
            end
            if item["interruption"] then
                return 0.300 + item["random"].to_f/1000
            end
            shift = BankDerivedData::recoveredAverageHoursPerDayCached("wave-general-fd3c4ac4-1300").to_f/2.500
            return 1.000 + shift*1.5 + item["random"].to_f/1000
        end
        if item["focus-23"] then
            if item["focus-23"] == "priority" then
                return 0.500 + item["random"].to_f/1000
            end
            if item["focus-23"] == "happening" then
                return 0.600 + item["random"].to_f/1000
            end
            if item["focus-23"] == "today" then
                return 1.500 + item["random"].to_f/1000
            end
            if item["focus-23"] == "short-run-with-deadline" then
                return 1.700 + item["random"].to_f/1000
            end
            if item["focus-23"] == "short-run" then
                shift = BankDerivedData::recoveredAverageHoursPerDayCached("short-run-general-f2b27a1f").to_f
                return 2 + shift + item["random"].to_f/1000
            end
            if item["focus-23"] == "long-run" then
                shift = BankDerivedData::recoveredAverageHoursPerDayCached("long-run-general-a4b09369").to_f
                return 2.500 + shift + item["random"].to_f/1000
            end
        end
        if item["mikuType"] == "NxTask" then
            if item["random"].nil? then
                item["random"] = rand
                Items::setAttribute(item["uuid"], "random", item["random"])
            end
            shift = BankDerivedData::recoveredAverageHoursPerDayCached("task-general-5f03ccc7-2b00").to_f/2.500
            return 2 + shift + item["random"].to_f/1000
        end
        if item["mikuType"] == "NxProject" then
            if item["random"].nil? then
                item["random"] = rand
                Items::setAttribute(item["uuid"], "random", item["random"])
            end
            shift = BankDerivedData::recoveredAverageHoursPerDayCached("nxproject-general-45bca48d").to_f/2.500
            return 2 + shift + item["random"].to_f/1000
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
