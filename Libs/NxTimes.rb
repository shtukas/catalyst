
class NxTimes

    # NxTimes::issue(time, description)
    def self.issue(time, description)
        uuid = SecureRandom.uuid
        DarkEnergy::init("NxTime", uuid)
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "time", time)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::itemOrNull(uuid)
    end

    # NxTimes::toString(item)
    def self.toString(item)
        "(time) [#{item["time"]}] #{item["description"]}#{CoreData::itemToSuffixString(item)}"
    end

    # NxTimes::listingItems()
    def self.listingItems()
        DarkEnergy::mikuType("NxTime")
            .sort_by{|item| item["time"] }
    end

    # NxTimes::isPending(item)
    def self.isPending(item)
        item["time"] <= Time.new.strftime("%H:%M")
    end

    # NxTimes::itemsWithPendingTime()
    def self.itemsWithPendingTime()
        DarkEnergy::mikuType("NxTime").any?{|item| NxTimes::isPending(item) }
    end

    # NxTimes::reschedule()
    def self.reschedule()
        puts "@reschedule:"
        DarkEnergy::mikuType("NxTime")
            .sort_by{|item| item["time"] }
            .each{|item|
                puts "    - #{NxTimes::toString(item)}"
            }
        puts "@reschedule:"
        DarkEnergy::mikuType("NxTime")
            .sort_by{|item| item["time"] }
            .each{|item|
                time = LucilleCore::askQuestionAnswerAsString("time for '#{NxTimes::toString(item).green}' (or remove) : ")
                if time == "remove" then
                    DarkEnergy::destroy(item["uuid"])
                    next
                end
                DarkEnergy::patch(item["uuid"], "time", time)
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