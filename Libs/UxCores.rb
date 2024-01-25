class UxCores

    # UxCores::interactivelyMakeNewOrNull()
    def self.interactivelyMakeNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        hours = LucilleCore::askQuestionAnswerAsString("weekly hours (empty for abort): ")
        return nil if hours == ""
        hours = hours.to_f
        return nil if hours == 0

        uuid = SecureRandom.uuid
        Cubes2::itemInit(uuid, "UxCore")
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::setAttribute(uuid, "type", "weekly-hours")
        Cubes2::setAttribute(uuid, "hours", hours)

        Cubes2::itemOrNull(uuid)
    end

    # UxCores::toString(item)
    def self.toString(item)
        "⛵️ #{item["description"]}"
    end

    # UxCores::numbersline()
    def self.numbersline()
        [
            "⛵️ ",
            Cubes2::mikuType("UxCore")
                .map{|core| TxCores::dayCompletionRatio(core) }
                .map{|ratio| "#{(100 * ratio).round(2)}" }
                .join(" "),
        ].join()
    end

end