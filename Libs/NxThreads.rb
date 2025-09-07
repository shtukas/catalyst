class NxThreads

    # NxThreads::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "priorityLevel47", PriorityLevels::interactivelySelectOne())
        Items::setAttribute(uuid, "mikuType", "NxThread")
        Items::itemOrNull(uuid)
    end

    # NxThreads::issue(description, priorityLevel)
    def self.issue(description, priorityLevel)
        uuid = SecureRandom.uuid
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "priorityLevel47", priorityLevel)
        Items::setAttribute(uuid, "mikuType", "NxThread")
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxThreads::toString(item)
    def self.toString(item)
        "🔺 #{item["description"]}"
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
            .sort_by{|thread| ListingService::itemToComputedPosition(thread) }
    end

    # NxThreads::listingItems()
    def self.listingItems()
        NxThreads::threads()
            .select{|thread| ListingService::itemToComputedPosition(thread) < 1 }
            .select{|thread| DoNotShowUntil::isVisible(thread["uuid"]) }
            .map{|thread|
                tasks = (lambda{|thread|
                    if ListingService::itemToComputedPosition(thread) < 1 then
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
        l = lambda{|thread| "#{thread["description"]}#{DoNotShowUntil::suffix1(thread["uuid"]).yellow}" }
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
