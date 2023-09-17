
class TxEngine

    # TxEngine::dayRatioOrNull(engine)
    def self.dayRatioOrNull(engine)
        return nil if engine["dailyHours"].nil?
        Bank::getValueAtDate(engine["uuid"], CommonUtils::today()).to_f/engine["dailyHours"]
    end
 
    # TxEngine::weekRatioOrNull(engine)
    def self.weekRatioOrNull(engine)
        return nil if engine["weeklyHours"].nil?
        (0..6).map{|ind| Bank::getValueAtDate(engine["uuid"], CommonUtils::nDaysInTheFuture(-ind)).to_f/3600 }.inject(0, :+).to_f/engine["weeklyHours"]
    end
 
    # TxEngine::ratio(engine)
    def self.ratio(engine)
        [TxEngine::dayRatioOrNull(engine), TxEngine::weekRatioOrNull(engine)].compact.max
    end

    # TxEngine::interactivelyMakeOrNull()
    def self.interactivelyMakeOrNull()
        dailyHours = LucilleCore::askQuestionAnswerAsString("daily hours: ")
        dailyHours = dailyHours.size > 0 ? dailyHours.to_f : nil
        weeklyHours = LucilleCore::askQuestionAnswerAsString("weekly hours: ")
        weeklyHours = weeklyHours.size > 0 ? weeklyHours.to_f : nil
        return nil if dailyHours.nil? and weeklyHours.nil?
        {
            "uuid"        => SecureRandom.hex,
            "dailyHours"  => dailyHours,
            "weeklyHours" => weeklyHours
        }
    end

    # TxEngine::prefix(item)
    def self.prefix(item)
        return "" if item["drive-nx1"].nil?
        engine = item["drive-nx1"]
        dhs = engine["dailyHours"] ? "#{"%5.2f" % TxEngine::dayRatioOrNull(engine)} of #{"%5.2f" % engine["dailyHours"]} hours" : ""
        whs = engine["weeklyHours"] ? "#{"%5.2f" % TxEngine::weekRatioOrNull(engine)} of #{"%5.2f" % engine["weeklyHours"]} hours" : ""
        "(#{dhs} ; #{whs}) ".yellow
    end
end
