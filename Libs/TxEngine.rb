
class TxEngine

    # TxEngine::ratio(engine)
    def self.ratio(engine)
        if engine["type"] == "recovery-time" then
            return Bank::recoveredAverageHoursPerDay(engine["uuid"]).to_f/engine["rt"]
        end
        if engine["type"] == "recovery-time(2)" then
            return Bank::recoveredAverageHoursPerDay(engine["uuid"]).to_f/(engine["week-time"].to_f/7)
        end
        if engine["type"] == "active-burner-forefront" then
            return 0
        end
        raise "(error: 361099e7-4368-4932-94e5-ee878994536f): #{engine}"
    end

    # TxEngine::interactivelyMakeOrNull()
    def self.interactivelyMakeOrNull()
        options = ["recovery-time(2) [weekly hours]", "active-burner-forefront"]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("engine type", options)
        return nil if option.nil?
        if option == "recovery-time(2) [weekly hours]" then
            hours = LucilleCore::askQuestionAnswerAsString("hours per week: ").to_f
            return {
                "uuid"      => SecureRandom.hex,
                "mikuType"  => "TxEngine",
                "type"      => "recovery-time(2)",
                "week-time" => hours
            }
        end
        if option == "active-burner-forefront" then
            return {
                "uuid"      => SecureRandom.hex,
                "mikuType"  => "TxEngine",
                "type"      => "active-burner-forefront"
            }
        end
    end

    # TxEngine::interactivelyIssueNew()
    def self.interactivelyIssueNew()
        engine = TxEngine::interactivelyMakeOrNull()
        return engine if engine
        TxEngine::interactivelyMakeOrNull()
    end

    # TxEngine::prefix(item)
    def self.prefix(item)
        return "" if item["engine-2251"].nil?
        engine = item["engine-2251"]
        if engine["type"] == "recovery-time" then
            return "(engine: #{"%6.2f" % (100*TxEngine::ratio(engine))} % of #{"%4.2f" % engine["rt"]}) ".green
        end
        if engine["type"] == "recovery-time(2)" then
            return "(engine: #{"%6.2f" % (100*TxEngine::ratio(engine))} % of #{"%4.2f" % engine["week-time"]} h/w) ".green
        end
        if engine["type"] == "active-burner-forefront" then
            return ""
        end
        raise "(error: 5440d0bb-ce79-49b7-b125-cbe1d6ccc372): #{engine}"
    end
end