class NxThreads

    # NxThreads::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        hours = LucilleCore::askQuestionAnswerAsString("hours per week: ").to_f
        Items::init(uuid)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "hours", hours)
        Items::setAttribute(uuid, "mikuType", "NxThread")
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxThreads::toString(item)
    def self.toString(item)
        "⏱️  #{item["description"]} #{NxThreads::ratioString(item)}"
    end

    # NxThreads::ratio(core)
    def self.ratio(core)
        hours = core["hours"].to_f
        [BankData::recoveredAverageHoursPerDay(core["uuid"]), 0].max.to_f/(hours/7)
    end

    # NxThreads::shouldShow(core)
    def self.shouldShow(core)
        return false if !DoNotShowUntil::isVisible(core["uuid"])
        BankData::recoveredAverageHoursPerDay(core["uuid"]) < (core["hours"].to_f/7)
    end

    # NxThreads::ratioString(core)
    def self.ratioString(core)
        "(#{"%6.2f" % (100 * NxThreads::ratio(core))} %; #{"%5.2f" % core["hours"]} h/w)".yellow
    end

    # NxThreads::infinityuuid()
    def self.infinityuuid()
        "427bbceb-923e-4feb-8232-05883553bb28"
    end

    # NxThreads::cores()
    def self.cores()
        Items::mikuType("NxThread")
    end

    # NxThreads::coresInRatioOrder()
    def self.coresInRatioOrder()
        NxThreads::cores()
            .sort_by{|core| NxThreads::ratio(core) }
    end

    # NxThreads::listingItems()
    def self.listingItems()
        NxThreads::cores()
            .select{|core| NxThreads::ratio(core) < 1 }
            .select{|core| DoNotShowUntil::isVisible(core["uuid"]) }
            .map{|core|
                Parenting::childrenInOrderHead(core["uuid"], 3, lambda{|item| DoNotShowUntil::isVisible(item["uuid"]) }) + [core]
            }
            .flatten
    end

    # NxThreads::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        l = lambda{|core| "#{NxThreads::ratioString(core)} #{core["description"]}#{DoNotShowUntil::suffix1(core["uuid"]).yellow}" }
        cores = NxThreads::coresInRatioOrder()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("core", cores, l)
    end
end
