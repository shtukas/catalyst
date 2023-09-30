
class TxEngine

    # TxEngine::ratio(engine)
    def self.ratio(engine)
        Bank::recoveredAverageHoursPerDay(engine["uuid"]).to_f/(engine["rt"] || 1)
    end

    # TxEngine::interactivelyMakeOrNull()
    def self.interactivelyMakeOrNull()
        rt = LucilleCore::askQuestionAnswerAsString("hours per week (will be converted into a rt): ").to_f/7
        {
            "uuid"     => SecureRandom.hex,
            "mikuType" => "TxEngine",
            "type"     => "recovery-time",
            "rt"       => rt
        }
    end

    # TxEngine::prefix(item)
    def self.prefix(item)
        return "" if item["engine-2251"].nil?
        "(engine: #{"%5.2f" % (100*TxEngine::ratio(item["engine-2251"]))} % of #{"%4.2f" % item["engine-2251"]["rt"]} hours) ".green
    end
end