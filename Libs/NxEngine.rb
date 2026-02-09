# encoding: UTF-8

class NxEngine

    # NxEngine::set_value(item)
    def self.set_value(item)
        whours = LucilleCore::askQuestionAnswerAsString("hours per week: ").to_f
        Blades::setAttribute(item["uuid"], "whours-45", whours)
        Blades::itemOrNull(item["uuid"])
    end

    # NxEngine::set_value_proposal(item)
    def self.set_value_proposal(item)
        if LucilleCore::askQuestionAnswerAsBoolean("set engine value for #{PolyFunctions::toString(item).green} ? ") then
            whours = LucilleCore::askQuestionAnswerAsString("hours per week: ").to_f
            Blades::setAttribute(item["uuid"], "whours-45", whours)
            return Blades::itemOrNull(item["uuid"])
        end
        item
    end

    # NxEngine::ratio(item)
    def self.ratio(item)
        return 0 if item["whours-45"].nil?
        return 0 if item["whours-45"] == 0
        BankDerivedData::recoveredAverageHoursPerDay(item["uuid"])/item["whours-45"]
    end

    # NxEngine::listingItems()
    def self.listingItems()
    Blades::items()
        .select{|item| item["whours-45"] }
        .select{|item| NxEngine::ratio(item) < 1 }
    end

    # NxEngine::suffix(item)
    def self.suffix(item)
        return "" if item["whours-45"].nil?
        " (#{(100 * NxEngine::ratio(item)).round(2)} % of daily #{(item["whours-45"].to_f/7).round(2)})".green
    end
end
