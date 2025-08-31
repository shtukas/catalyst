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

    # NxThreads::ratio(thread)
    def self.ratio(thread)
        hours = thread["hours"].to_f
        [BankData::recoveredAverageHoursPerDay(thread["uuid"]), 0].max.to_f/(hours/7)
    end

    # NxThreads::shouldShow(thread)
    def self.shouldShow(thread)
        return false if !DoNotShowUntil::isVisible(thread["uuid"])
        BankData::recoveredAverageHoursPerDay(thread["uuid"]) < (thread["hours"].to_f/7)
    end

    # NxThreads::ratioString(thread)
    def self.ratioString(thread)
        "(#{"%6.2f" % (100 * NxThreads::ratio(thread))} %; #{"%5.2f" % thread["hours"]} h/w)".yellow
    end

    # NxThreads::infinityuuid()
    def self.infinityuuid()
        "427bbceb-923e-4feb-8232-05883553bb28"
    end

    # NxThreads::threads()
    def self.threads()
        Items::mikuType("NxThread")
    end

    # NxThreads::threadsInRatioOrder()
    def self.threadsInRatioOrder()
        NxThreads::threads()
            .sort_by{|thread| NxThreads::ratio(thread) }
    end

    # NxThreads::listingItems()
    def self.listingItems()
        NxThreads::threads()
            .select{|thread| NxThreads::ratio(thread) < 1 }
            .select{|thread| DoNotShowUntil::isVisible(thread["uuid"]) }
            .map{|thread|
                Parenting::childrenInOrderHead(thread["uuid"], 3, lambda{|item| DoNotShowUntil::isVisible(item["uuid"]) }) + [thread]
            }
            .flatten
    end

    # NxThreads::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        l = lambda{|thread| "#{NxThreads::ratioString(thread)} #{thread["description"]}#{DoNotShowUntil::suffix1(thread["uuid"]).yellow}" }
        threads = NxThreads::threadsInRatioOrder()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("thread", threads, l)
    end
end
