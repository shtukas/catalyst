
class NxDeadlines

    # NxDeadlines::makeDeadlineCore()
    def self.makeDeadlineCore()
        duration = LucilleCore::askQuestionAnswerAsString("duration in days: ").to_f
        requirementInHours = LucilleCore::askQuestionAnswerAsString("requirement in hours: ").to_f
        {
            "uuid"               => SecureRandom.uuid,
            "start"              => Time.new.to_f,
            "end"                => Time.new.to_f + duration*86400,
            "requirementInHours" => requirementInHours
        }
    end

    # NxDeadlines::interactivelyIssueNewForItem(item)
    def self.interactivelyIssueNewForItem(item)
        uuid = SecureRandom.uuid
        deadlineCore = NxDeadlines::makeDeadlineCore()
        DarkEnergy::init("NxDeadline", uuid)
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "targetuuid", item["uuid"])
        DarkEnergy::patch(uuid, "deadlineCore", deadlineCore)

        DarkEnergy::patch(item["uuid"], "deadline", uuid) # we need to mark the item with the deadline

        DarkEnergy::itemOrNull(uuid)
    end

    # NxDeadlines::coreIsLate(core)
    def self.coreIsLate(core)
        timeDone = Bank::getValue(core["uuid"])
        timeNeeded = 86400*core["requirementInHours"]*(Time.new.to_f - core["start"]).to_f/(core["end"] - core["start"])
        timeNeeded > timeDone
    end

    # NxDeadlines::deadlineIsLate(item)
    def self.deadlineIsLate(item)
        NxDeadlines::coreIsLate(item["deadlineCore"])
    end

    # NxDeadlines::itemToString(item)
    def self.itemToString(item)
        timeDoneInHours = Bank::getValue(item["uuid"]).to_f/3600
        timeDoneRatio = timeDoneInHours.to_f/item["requirementInHours"]
        timespanSinceStartInSeconds = CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(CommonUtils::getLocalTimeZone()) - item["start"]
        timeSinceStartRatio = timespanSinceStartInSeconds.to_f/(item["end"] - item["start"])
        isLate = timeDoneRatio < timeSinceStartRatio
        "⏱️  (done: #{"%5.2f" % (timeDoneRatio*100)}% of #{"%5.2f" % item["requirementInHours"]} hours, ideal: #{"%5.2f" % (timeSinceStartRatio*100)}%, #{isLate ? "late 😓" : "😎"})"
    end

    # NxDeadlines::toString(item)
    def self.toString(item)
        target = DarkEnergy::itemOrNull(item["targetuuid"])
        if target then
            "#{NxDeadlines::itemToString(item["deadlineCore"])} #{target["description"]}"
        else
            "⏱️  target not found 🤔"
        end
    end

    # NxDeadlines::access(item)
    def self.access(item)
        target = DarkEnergy::itemOrNull(item["targetuuid"])
        PolyActions::access(target)
    end

    # NxDeadlines::done(item)
    def self.done(item)
        NxBalls::stop(item)
        if LucilleCore::askQuestionAnswerAsBoolean("Confirm destruction of '#{NxDeadlines::toString(item).green}': ", true) then
            target = DarkEnergy::itemOrNull(item["targetuuid"])
            if target then
                PolyActions::done(target)
            end
            DarkEnergy::destroy(item["uuid"])
        end
    end

    # NxDeadlines::listingItems()
    def self.listingItems()
        DarkEnergy::mikuType("NxDeadline")
            .select{|item| NxDeadlines::deadlineIsLate(item) }
    end

    # NxDeadlines::program1(item)
    def self.program1(item)
        loop {
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["start", "done"])
            return if option.nil?
            if option == "start" then
                PolyActions::start(item)
            end
            if option == "done" then
                PolyActions::done(item)
            end
        }
    end

    # NxDeadlines::program0()
    def self.program0()
        loop {
            items = DarkEnergy::mikuType("NxDeadline")
            if items.empty? then
                puts "no deadline found"
                LucilleCore::pressEnterToContinue()
                return
            end
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("deadline", items, lambda{|item| NxDeadlines::toString(item) })
            return if item.nil?
            NxDeadlines::program1(item)
        }
    end

    # NxDeadlines::attachDeadlineAttempt(item)
    def self.attachDeadlineAttempt(item)
        NxDeadlines::interactivelyIssueNewForItem(item)
    end

    # NxDeadlines::askAndThenAttachDeadlineToItemAttempt(item)
    def self.askAndThenAttachDeadlineToItemAttempt(item)
        if LucilleCore::askQuestionAnswerAsBoolean("> add deadline ? ", false) then
            NxDeadlines::attachDeadlineAttempt(item)
        end
    end

    # NxDeadlines::suffix(item)
    def self.suffix(item)
        return "" if item["deadline"].nil?
        deadline = DarkEnergy::itemOrNull(item["deadline"])
        return "" if deadline.nil?
        " (⏱️  #{NxDeadlines::itemToString(deadline["deadlineCore"])})"
    end
end