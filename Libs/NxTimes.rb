
class NxTimes

    # NxTimes::issue(time, description)
    def self.issue(time, description)
        uuid = SecureRandom.uuid
        Cubes::init("NxTime", uuid)
        Cubes::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Cubes::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Cubes::setAttribute2(uuid, "time", time)
        Cubes::setAttribute2(uuid, "description", description)
        Cubes::itemOrNull(uuid)
    end

    # NxTimes::toString(item)
    def self.toString(item)
        "(time) [#{item["time"]}] #{item["description"]}#{CoreDataRefStrings::itemToSuffixString(item)}"
    end

    # NxTimes::listingItems()
    def self.listingItems()
        Cubes::mikuType("NxTime")
            .sort_by{|item| item["time"] }
    end

    # NxTimes::isPending(item)
    def self.isPending(item)
        item["time"] <= Time.new.strftime("%H:%M")
    end

    # NxTimes::itemsWithPendingTime()
    def self.itemsWithPendingTime()
        Cubes::mikuType("NxTime").any?{|item| NxTimes::isPending(item) }
    end

    # NxTimes::reschedule()
    def self.reschedule()
        puts "@reschedule:"
        Cubes::mikuType("NxTime")
            .sort_by{|item| item["time"] }
            .each{|item|
                puts "    - #{NxTimes::toString(item)}"
            }
        puts "@reschedule:"
        Cubes::mikuType("NxTime")
            .sort_by{|item| item["time"] }
            .each{|item|
                time = LucilleCore::askQuestionAnswerAsString("time for '#{NxTimes::toString(item).green}' (or remove) : ")
                if time == "remove" then
                    Cubes::destroy(item["uuid"])
                    next
                end
                Cubes::setAttribute2(item["uuid"], "time", time)
            }
    end

    # NxTimes::interactivelyIssueTimeOrNull()
    def self.interactivelyIssueTimeOrNull()
        entry = LucilleCore::askQuestionAnswerAsString("entry (HH:MM <text>) (empty to terminate): ")
        return nil if entry == ""
        time = entry[0, 5]
        description = entry[5, entry.size].strip
        return nil if description == ""
        NxTimes::issue(time, description)
    end
end