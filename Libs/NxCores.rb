class NxCores

    # NxCores::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        hours = LucilleCore::askQuestionAnswerAsString("hours per week: ").to_f
        Items::init(uuid)
        Items::setAttribute(uuid, "mikuType", "NxCore")
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "hours", hours)
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxCores::toString(item)
    def self.toString(item)
        "⏱️  #{item["description"]} #{NxCores::ratioString(item)}"
    end

    # NxCores::ratio(core)
    def self.ratio(core)
        hours = core["hours"].to_f
        [Bank1::recoveredAverageHoursPerDay(core["uuid"]), 0].max.to_f/(hours/7)
    end

    # NxCores::shouldShow(core)
    def self.shouldShow(core)
        return false if !DoNotShowUntil::isVisible(core["uuid"])
        Bank1::recoveredAverageHoursPerDay(core["uuid"]) < (core["hours"].to_f/7)
    end

    # NxCores::ratioString(core)
    def self.ratioString(core)
        "(#{"%6.2f" % (100 * NxCores::ratio(core))} %; #{"%5.2f" % core["hours"]} h/w)".yellow
    end

    # NxCores::infinityuuid()
    def self.infinityuuid()
        "427bbceb-923e-4feb-8232-05883553bb28"
    end

    # NxCores::cores()
    def self.cores()
        Items::mikuType("NxCore")
    end

    # NxCores::totalHoursPerWeek()
    def self.totalHoursPerWeek()
        NxCores::cores().map{|item| item["hours"] }.inject(0, :+)
    end

    # NxCores::coresInRatioOrder()
    def self.coresInRatioOrder()
        NxCores::cores()
            .sort_by{|core| NxCores::ratio(core) }
    end

    # NxCores::listingItems()
    def self.listingItems()
        NxCores::cores()
            .select{|core| PolyFunctions::childrenForParent(core).empty? }
            .sort_by{|core| NxCores::ratio(core) }
            .select{|core| NxCores::ratio(core) < 1 }
    end

    # NxCores::interactivelySelectOrNull()
    def self.interactivelySelectOrNull()
        l = lambda{|core| "#{NxCores::ratioString(core)} #{core["description"]}#{DoNotShowUntil::suffix1(core["uuid"]).yellow}" }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("core", NxCores::coresInRatioOrder(), l)
    end

    # NxCores::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        l = lambda{|core| "#{NxCores::ratioString(core)} #{core["description"]}#{DoNotShowUntil::suffix1(core["uuid"]).yellow}" }
        cores = NxCores::coresInRatioOrder()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("core", cores, l)
    end

    # NxCores::selectCoreByUUIDOrNull(coreuuid)
    def self.selectCoreByUUIDOrNull(coreuuid)
        NxCores::cores().select{|core| core["uuid"] == coreuuid }.first
    end
end
