
class TxEngine

    # TxEngine::ratio(engine)
    def self.ratio(engine)
        Bank::recoveredAverageHoursPerDay(engine["uuid"]).to_f/(engine["rt"] || 1)
    end

    # TxEngine::interactivelyMakeOrNull()
    def self.interactivelyMakeOrNull()
        hoursPerWeek = LucilleCore::askQuestionAnswerAsString("hours per week (will be converted into a rt)").to_f
        {
            "uuid" => SecureRandom.hex,
            "rt"   => hoursPerWeek.to_f/7
        }
    end

    # TxEngine::prefix(item)
    def self.prefix(item)
        return "         " if item["drive-nx1"].nil?
        "#{"%6.2f" % (100*TxEngine::ratio(item["drive-nx1"]))} % "
    end
end
