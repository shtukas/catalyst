
class NxTodos

    # NxTodos::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        Cubes1::itemInit(uuid, "NxTodo")
        Cubes1::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes1::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes1::setAttribute(uuid, "description", description)
        Cubes1::itemOrNull(uuid)
    end

    # NxTodos::descriptionToTask1(parent, uuid, description)
    def self.descriptionToTask1(parent, uuid, description)
        Cubes1::itemInit(uuid, "NxTodo")
        Cubes1::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes1::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes1::setAttribute(uuid, "description", description)
        Cubes1::setAttribute(uuid, "parentuuid-0032", parent["uuid"])
        Cubes1::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxTodos::icon(item)
    def self.icon(item)
        "🔹"
    end

    # NxTodos::ratio(item)
    def self.ratio(item)
        [Bank1::recoveredAverageHoursPerDay(item["uuid"]), 0].max.to_f/(item["hours"].to_f/7)
    end

    # NxTodos::ratioString(item)
    def self.ratioString(item)
        return "" if item["hours"].nil?
        " (#{"%6.2f" % (100 * NxTodos::ratio(item))} %; #{"%5.2f" % item["hours"]} h/w)".yellow
    end

    # NxTodos::toString(item)
    def self.toString(item)
        "(#{"%7.3f" % (item["global-positioning"] || 0)}) #{NxTodos::icon(item)} #{item["description"]}#{NxTodos::ratioString(item)}"
    end

    # NxTodos::orphans()
    def self.orphans()
        Cubes1::mikuType("NxTodo")
            .select{|item| Catalyst::isOrphan(item) }
    end
end
