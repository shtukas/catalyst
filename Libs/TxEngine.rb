
class TxEngine

    # TxEngine::ratio(engine)
    def self.ratio(engine)
        if engine["mikuType"] == "TxE-TimeCommitment" then
            return Bank::recoveredAverageHoursPerDay(engine["uuid"]).to_f/engine["rt"]
        end
        if engine["mikuType"] == "TxE-OnDate" then
            return 0
        end
        if engine["mikuType"] == "TxE-Trajectory" then
            daysSinceStart = (Time.new.to_i - engine["start"]).to_f/86400
            return daysSinceStart.to_f/engine["horizonInDays"]
        end
    end

    # TxEngine::interactivelyMakeOrNull()
    def self.interactivelyMakeOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("engine type", ["time commitment", "date", "trajectory"])
        return nil if type.nil?
        if type == "time commitment" then
            rt = LucilleCore::askQuestionAnswerAsString("hours per week (will be converted into a rt): ").to_f/7
            return {
                "mikuType" => "TxE-TimeCommitment",
                "uuid"     => SecureRandom.hex,
                "rt"       => rt
            }
        end
        if type == "date" then
            return {
                "mikuType" => "TxE-OnDate",
                "date"     => CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode()[0, 10]
            }
        end
        if type == "trajectory" then
            horizon = LucilleCore::askQuestionAnswerAsString("horizonInDays: ").to_f
            return {
                "mikuType"      => "TxE-Trajectory",
                "start"         => Time.new.to_f,
                "horizonInDays" => horizon
            }
        end
    end

    # TxEngine::prefix(item)
    def self.prefix(item)
        return "" if item["engine-0852"].nil?
        engine = item["engine-0852"]
        if engine["mikuType"] == "TxE-TimeCommitment" then
            return "(time comm: #{"%5.2f" % (100*TxEngine::ratio(engine))} % of #{"%4.2f" % engine["rt"]} hours) ".green
        end
        if engine["mikuType"] == "TxE-OnDate" then
            return "(ondate: #{engine["date"]}) ".green
        end
        if engine["mikuType"] == "TxE-Trajectory" then
            return "(trajectory: #{"%5.2f" % (100*TxEngine::ratio(engine))} %) ".green
        end
    end
end
