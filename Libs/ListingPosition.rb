
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

    # ListingPosition::decideItemListingPositionOrNull(item)
    def self.decideItemListingPositionOrNull(item)
        if item["nx41"] and item["nx41"]["type"] == "override" then
            return item["nx41"]["position"]
        end
        if item["nx41"] and item["nx41"]["type"] == "natural" and (Time.new.to_i - item["nx41"]["unixtime"]) < 3600*2 then
            return item["nx41"]["position"]
        end

        # (sorted)     : (negatives)
        # priorities   : (negatives)

        # Interruptions: 0.300

        # NxTask, focus
        #    priority                  : 0.400
        #    happening                 : 0.450
        #    today                     : 0.500
        #    task:todo-within-days     : 0.550
        #    task:todo-within-a-week   : 0.600
        #    task:todo-within-weeks    : 0.650
        #    task:todo-within-a-month  : 0.700
        #    project:run-with-deadline : 0.750
        #    project:short-run         : 0.800
        #    project:long-run          : 0.900

        # Wave        : 1.000 -> 2.500 over 2.5 hours
        # BufferIn    : 2.000 -> 3.000 over 1.0 hours
        # NxTask      : 2.000 -> 3.000 over 2.5 hours

        if item["mikuType"] == "Wave" and item["interruption"] then
            if item["random"].nil? then
                item["random"] = rand
                Items::setAttribute(item["uuid"], "random", item["random"])
            end
            return 0.300 + item["random"].to_f/10000
        end

        if item["mikuType"] == "NxOndate" then
            if item["random"].nil? then
                item["random"] = rand
                Items::setAttribute(item["uuid"], "random", item["random"])
            end
            return 1.151 + item["random"].to_f/10000
        end

        if item["mikuType"] == "NxTask" and item["focus-24"] then
            if item["random"].nil? then
                item["random"] = rand
                Items::setAttribute(item["uuid"], "random", item["random"])
            end
            focus = item["focus-24"]
            base = nil
            if focus["type"] == "priority" then
                base = 0.400
            end
            if focus["type"] == "priority" then
                base = 0.450
            end
            if focus["type"] == "today" then
                base = 0.500
            end
            if focus["type"] == "task:todo-within-days" then
                base = 0.550
            end
            if focus["type"] == "task:todo-within-a-week" then
                base = 0.600
            end
            if focus["type"] == "task:todo-within-weeks" then
                base = 0.650
            end
            if focus["type"] == "task:todo-within-a-month" then
                base = 0.700
            end
            if focus["type"] == "project:run-with-deadline" then
                base = 0.750
            end
            if focus["type"] == "project:short-run" then
                base = 0.800
            end
            if focus["type"] == "project:long-run" then
                base = 0.900
            end
            if base.nil? then
                raise "I do not know how to listing position NxTask with focus '#{focus}'"
                exit
            end
            return base + item["random"].to_f/10000
        end

        if item["mikuType"] == "Wave" then
            if item["random"].nil? then
                item["random"] = rand
                Items::setAttribute(item["uuid"], "random", item["random"])
            end
            shift = BankDerivedData::recoveredAverageHoursPerDayCached("wave-general-fd3c4ac4-1300").to_f/2.500
            return 1.000 + shift * 1.5 + item["random"].to_f/10000
        end

        if item["mikuType"] == "BufferIn" then
            return 2 + BankDerivedData::recoveredAverageHoursPerDayCached("0a8ca68f-d931-4110-825c-8fd290ad7853")
        end

        if item["mikuType"] == "NxTask" then
            if item["random"].nil? then
                item["random"] = rand
                Items::setAttribute(item["uuid"], "random", item["random"])
            end
            shift = BankDerivedData::recoveredAverageHoursPerDayCached("task-general-5f03ccc7-2b00").to_f/2.500
            return 2 + shift + item["random"].to_f/10000
        end

        raise "[error: 4DC6AEBD] I do not know how to decide the listing position for item: #{item}"
    end

    # ListingPosition::delist(item)
    def self.delist(item)
        Items::setAttribute(item["uuid"], "nx41", nil)
    end
end
