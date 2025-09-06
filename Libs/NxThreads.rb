class NxThreads

    # NxThreads::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        hoursPerDay = LucilleCore::askQuestionAnswerAsString("hours per day: ").to_f
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "hoursPerDay", hoursPerDay)
        Items::setAttribute(uuid, "priorityLevel47", PriorityLevels::interactivelySelectOne())
        Items::setAttribute(uuid, "mikuType", "NxThread")
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxThreads::toString(item)
    def self.toString(item)
        "🔺 #{item["description"]} #{NxThreads::ratioString(item)}"
    end

    # NxThreads::ratio(thread)
    def self.ratio(thread)
        hoursPerDay = thread["hoursPerDay"]
        [BankData::recoveredAverageHoursPerDay(thread["uuid"]), 0].max.to_f/hoursPerDay
    end

    # NxThreads::shouldShow(thread)
    def self.shouldShow(thread)
        return false if !DoNotShowUntil::isVisible(thread["uuid"])
        hoursPerDay = thread["hoursPerDay"]
        BankData::recoveredAverageHoursPerDay(thread["uuid"]) < hoursPerDay
    end

    # NxThreads::ratioString(thread)
    def self.ratioString(thread)
        hoursPerDay = thread["hoursPerDay"]
        "(#{"%6.2f" % (100 * NxThreads::ratio(thread))} %; #{"%5.2f" % hoursPerDay} h/d)".yellow
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
                tasks = (lambda{|thread|
                    if NxThreads::ratio(thread) < 1 then
                        Parenting::childrenInOrderHead(thread["uuid"], 3, lambda{|item| DoNotShowUntil::isVisible(item["uuid"]) })
                    else
                        []
                    end
                }).call(thread)
                tasks + [thread]
            }
            .flatten
    end

    # NxThreads::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        l = lambda{|thread| "#{NxThreads::ratioString(thread)} #{thread["description"]}#{DoNotShowUntil::suffix1(thread["uuid"]).yellow}" }
        threads = NxThreads::threadsInRatioOrder()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("thread", threads, l)
    end

    # NxThreads::architectOrNull()
    def self.architectOrNull()
        thread = NxThreads::interactivelySelectOneOrNull()
        return thread if thread
        puts "You have not selected a thread, let's make a new one"
        NxThreads::interactivelyIssueNewOrNull()
    end

    # -----------------------------------------
    # Operations

    # NxThreads::setHours()
    def self.setHours()
        loop {
            thread = NxThreads::interactivelySelectOneOrNull()
            return if thread.nil?
            puts PolyFunctions::toString(thread)
            hours = LucilleCore::askQuestionAnswerAsString("hours per day: ").to_f
            Items::setAttribute(thread["uuid"], "hoursPerDay", hours)
        }
    end

    # NxThreads::maintenance()
    def self.maintenance()
        Items::mikuType("NxThread").each{|item|
            if !Parenting::hasChildren(item["uuid"]) and item["uxpayload-b4e4"].nil? then
                if LucilleCore::askQuestionAnswerAsBoolean("Thread '#{PolyFunctions::toString(item)}' is now empty. Going to delete it ", true) then
                    Items::deleteItem(item["uuid"])
                end
            end
        }
    end
end
