
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
        "(time) [#{item["time"]}] #{item["description"]}"
    end

    # NxTimes::listingItems(canBeDefault)
    def self.listingItems(canBeDefault)
        DarkEnergy::mikuType("NxTime")
            .sort_by{|item| item["time"] }
            .map{|item|
                item["canBeDefault"] = canBeDefault
                item
            }
    end

    # NxTimes::hasPendingTime()
    def self.hasPendingTime()
        currentTime = Time.new.strftime("%H:%M")
        DarkEnergy::mikuType("NxTime").any?{|item| item["time"] >= currentTime }
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
end