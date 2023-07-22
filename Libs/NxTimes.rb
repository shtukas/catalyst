
class NxTimes

    # NxTimes::issue(time, description)
    def self.issue(time, description)
        uuid = SecureRandom.uuid
        BladesGI::init("NxTime", uuid)
        BladesGI::setAttribute2(uuid, "unixtime", Time.new.to_i)
        BladesGI::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        BladesGI::setAttribute2(uuid, "time", time)
        BladesGI::setAttribute2(uuid, "description", description)
        BladesGI::itemOrNull(uuid)
    end

    # NxTimes::toString(item)
    def self.toString(item)
        "(time) [#{item["time"]}] #{item["description"]}#{CoreDataRefStrings::itemToSuffixString(item)}"
    end

    # NxTimes::listingItems()
    def self.listingItems()
        BladesItemised::mikuType("NxTime")
            .sort_by{|item| item["time"] }
    end

    # NxTimes::isPending(item)
    def self.isPending(item)
        item["time"] <= Time.new.strftime("%H:%M")
    end

    # NxTimes::itemsWithPendingTime()
    def self.itemsWithPendingTime()
        BladesItemised::mikuType("NxTime").any?{|item| NxTimes::isPending(item) }
    end

    # NxTimes::reschedule()
    def self.reschedule()
        puts "@reschedule:"
        BladesItemised::mikuType("NxTime")
            .sort_by{|item| item["time"] }
            .each{|item|
                puts "    - #{NxTimes::toString(item)}"
            }
        puts "@reschedule:"
        BladesItemised::mikuType("NxTime")
            .sort_by{|item| item["time"] }
            .each{|item|
                time = LucilleCore::askQuestionAnswerAsString("time for '#{NxTimes::toString(item).green}' (or remove) : ")
                if time == "remove" then
                    BladesItemised::destroy(item["uuid"])
                    next
                end
                BladesGI::setAttribute2(item["uuid"], "time", time)
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