
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
        " (#{"%6.2f" % (100 * NxTasks::ratio(item))} %; #{"%5.2f" % item["hours-1905"]} h/w)".yellow
    end

    # NxTasks::toString(item, context)
    def self.toString(item, context = nil)
        if context == "main-listing-1315" then
            return "#{NxTasks::icon(item)} #{item["description"]}#{NxTasks::ratioString(item)}"
        end
        "(#{"%7.3f" % (item["global-positioning"] || 0)}) #{NxTasks::icon(item)} #{item["description"]}#{NxTasks::ratioString(item)}"
    end

    # NxTasks::orphans()
    def self.orphans()
        data = XCache::getOrNull("0.04768800735473633")
        if data then
            data = JSON.parse(data)
            if (Time.new.to_i - data["unixtime"]) < 3600 then
                return data["items"]
                        .map{|item| Items::itemOrNull(item["uuid"]) }
                        .compact
                        .select{|item| item["parentuuid-0032"].nil? }
            end
        end

        items = Items::mikuType("NxTask")
                    .select{|item| Catalyst::isOrphan(item) }

        XCache::set("0.04768800735473633", JSON.generate({
            "unixtime" => Time.new.to_i,
            "items" => items
        }))

        items
    end
end
