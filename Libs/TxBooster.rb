
class TxBoosters

    # -----------------------------------------------
    # Build

    # TxBoosters::interactivelyMakeNewOrNull()
    def self.interactivelyMakeNewOrNull()
        hours = LucilleCore::askQuestionAnswerAsString("hours for today: ")
        return nil if hours == ""
        hours = hours.to_f
        return nil if hours == 0
        {
            "uuid"          => SecureRandom.uuid,
            "mikuType"      => "TxBooster",
            "date"          => CommonUtils::today(),
            "hours"         => hours
        }
    end

    # -----------------------------------------------
    # Data

    # TxBoosters::completionRatio(booster)
    def self.completionRatio(booster)
        Bank::getValueAtDate(booster["uuid"], CommonUtils::today()).to_f/(3600*booster["hours"])
    end

    # TxBoosters::hasActiveBooster(item)
    def self.hasActiveBooster(item)
        return false if item["booster-1521"].nil?
        [CommonUtils::today(), CommonUtils::nDaysInTheFuture(-1)].include?(item["booster-1521"]["date"])
    end

    # TxBoosters::suffix(item)
    def self.suffix(item)
        return "" if item["booster-1521"].nil?
        return "" if ![CommonUtils::today(), CommonUtils::nDaysInTheFuture(-1)].include?(item["booster-1521"]["date"])
        booster = item["booster-1521"]
        " 🚀 (#{"%6.2f" % (100*TxBoosters::completionRatio(booster))} % of #{"%4.2f" % booster["hours"]} hours)".green
    end
end
