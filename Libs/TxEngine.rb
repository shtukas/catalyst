
class TxEngine

    # TxEngine::ratio(engine)
    def self.ratio(engine)
        Bank::recoveredAverageHoursPerDay(engine["uuid"]).to_f/(engine["rt"] || 1)
    end

    # TxEngine::interactivelyMakeOrNull()
    def self.interactivelyMakeOrNull()
        rt = LucilleCore::askQuestionAnswerAsString("hours per week (will be converted into a rt): ").to_f/7
        {
            "uuid" => SecureRandom.hex,
            "rt"   => rt
        }
    end

    # TxEngine::prefix(item)
    def self.prefix(item)
        return "         " if item["drive-nx1"].nil?
        "(#{"%6.2f" % (100*TxEngine::ratio(item["drive-nx1"]))} %) "
    end
end
