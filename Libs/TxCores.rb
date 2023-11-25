
class TxCores

    # -----------------------------------------------
    # Build

    # TxCores::interactivelyMakeNewOrNull()
    def self.interactivelyMakeNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["daily-hours", "weekly-hours"])
        return nil if type.nil?
        if type == "daily-hours" then
            hours = LucilleCore::askQuestionAnswerAsString("daily hours (empty for abort): ")
            return nil if hours == ""
            hours = hours.to_f
            return nil if hours == 0
            return {
                "uuid"          => SecureRandom.uuid,
                "mikuType"      => "TxCore",
                "description"   => description,
                "type"          => "daily-hours",
                "hours"         => hours,
            }
        end
        if type == "weekly-hours" then
            hours = LucilleCore::askQuestionAnswerAsString("weekly hours (empty for abort): ")
            return nil if hours == ""
            hours = hours.to_f
            return nil if hours == 0
            return {
                "uuid"          => SecureRandom.uuid,
                "mikuType"      => "TxCore",
                "description"   => description,
                "type"          => "weekly-hours",
                "hours"         => hours
            }
        end
        raise "(error: 9ece0a71-f6bc-4b2d-ae27-3d4b5a0fac17)"
    end

    # -----------------------------------------------
    # Data

    # TxCores::dayCompletionRatio(engine)
    def self.dayCompletionRatio(engine)
        if engine["type"] == "weekly-hours" then
            doneSinceLastSaturdayInSeconds = CommonUtils::datesSinceLastSaturday().reduce(0){|time, date| time + Bank::getValueAtDate(engine["uuid"], date) }
            doneSinceLastSaturdayInHours = doneSinceLastSaturdayInSeconds.to_f/3600
            return 1 if doneSinceLastSaturdayInHours >= engine["hours"]

            dailyHours = engine["hours"].to_f/7
            todayhours = Bank::getValueAtDate(engine["uuid"], CommonUtils::today()).to_f/3600
            return todayhours.to_f/dailyHours
        end
        if engine["type"] == "daily-hours" then
            dailyHours = engine["hours"]
            todayhours = Bank::getValueAtDate(engine["uuid"], CommonUtils::today()).to_f/3600
            return todayhours.to_f/dailyHours
        end
        raise "(error: 1cd26e69-4d2b-4cf7-9497-9bc715ea8f44): engine: #{engine}"
    end

    # TxCores::dayCompletionRatio2(item)
    def self.dayCompletionRatio2(item)
        return 0 if item["engine-multicore-2257"].nil?
        item["engine-multicore-2257"].reduce(1){|m, core|
            [m, TxCores::dayCompletionRatio(core)].min
        }
    end

    # TxCores::string1(item)
    def self.string1(item)
        "(#{"%6.2f" % (100*TxCores::dayCompletionRatio2(item))} %)".green
    end
end
