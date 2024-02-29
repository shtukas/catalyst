
class TxCores

    # TxCores::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        hours = LucilleCore::askQuestionAnswerAsString("hours: ").to_f
        return if hours == 0
        Cubes2::itemInit(uuid, "TxCore")
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::setAttribute(uuid, "hours", hours)
        Cubes2::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # TxCores::ratio(item)
    def self.ratio(item)
        Bank2::recoveredAverageHoursPerDay(item["uuid"]).to_f/item["hours"]
    end

    # TxCores::toString(item)
    def self.toString(item)
        "⏱️  (#{"%7.2f" % TxCores::ratio(item)}) #{item["description"]}"
    end

    # TxCores::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("thread", Cubes2::mikuType("TxCore"), lambda{|item| PolyFunctions::toString(item) })
    end
end
