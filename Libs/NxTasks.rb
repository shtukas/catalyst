
class NxTasks

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        Items::itemInit(uuid, "NxTask")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", UxPayload::makeNewOrNull())
        Items::itemOrNull(uuid)
    end

    # NxTasks::descriptionToTask1(description)
    def self.descriptionToTask1(description)
        uuid = SecureRandom.hex
        Items::itemInit(uuid, "NxTask")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxTasks::icon(item)
    def self.icon(item)
        "🔹"
    end

    # NxTasks::ratio(item)
    def self.ratio(item)
        [Bank1::recoveredAverageHoursPerDay(item["uuid"]), 0].max.to_f/(item["hours-1905"].to_f/7)
    end

    # NxTasks::ratioString(item)
    def self.ratioString(item)
        return "" if item["hours-1905"].nil?
        "(#{"%6.2f" % (100 * NxTasks::ratio(item))} %; #{"%5.2f" % item["hours-1905"]} h/w)".yellow
    end

    # NxTasks::toString(item, context)
    def self.toString(item, context = nil)
        if context == "main-listing-1315" and item["hours-1905"] then
            return "🔺 #{NxTasks::ratioString(item)} #{item["description"]}"
        end
        if context == "main-listing-1315" and !item["hours-1905"] then
            return "#{NxTasks::icon(item)} (#{"%7.3f" % (item["global-positioning"] || 0)}) #{item["description"]}"
        end
        "#{NxTasks::icon(item)} #{item["description"]}"
    end

    # NxTasks::managed()
    def self.managed()
        Items::mikuType("NxTask")
            .select{|item| item["hours-1905"] }
            .sort_by{|item| NxTasks::ratio(item) }
            .select{|item| NxTasks::ratio(item) < 1 }
    end

    # NxTasks::tail(cardinal)
    def self.tail(cardinal)
        Items::mikuType("NxTask")
            .sort_by{|item| item["global-positioning"] || 0 }
            .first(cardinal)
    end
end
