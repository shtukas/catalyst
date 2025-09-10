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
        "🔺 #{item["description"]} (#{item["priorityLevel47"].yellow})"
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
            .sort_by{|thread| ListingService::computePositionForItem(thread) }
    end

    # NxThreads::listingItems()
    def self.listingItems()
        NxThreads::threads()
            .select{|thread| ListingService::computePositionForItem(thread) < 1 }
            .select{|thread| DoNotShowUntil::isVisible(thread["uuid"]) }
            .map{|thread|
                tasks = (lambda{|thread|
                    if ListingService::computePositionForItem(thread) < 1 then
                        Parenting::childrenInOrderHead(thread["uuid"], 3, lambda{|item| DoNotShowUntil::isVisible(item["uuid"]) })
                    else
                        []
                    end
                }).call(thread)
                tasks + [thread]
            }
            .flatten
    end

    # NxThreads::isStructuralThread(item)
    def self.isStructuralThread(item)
        # {"uuid" => "04f2e85f-7157-435f-bf37-d91c8ae36976", "mikuType" => "NxThread", "unixtime" => 1757362983, "description" => "(low)", "priorityLevel47" => "low"}
        # {"uuid" => "4392a2a7-04b6-4e35-be41-cf57c43b088e", "mikuType" => "NxThread", "unixtime" => 1757362983, "description" => "(regular)", "priorityLevel47" => "regular"}
        # {"uuid" => "fccf059f-2ba0-41de-963e-34834ded1b74", "mikuType" => "NxThread", "unixtime" => 1757362983, "description" => "(high)", "priorityLevel47" => "high"}
        [
            "04f2e85f-7157-435f-bf37-d91c8ae36976",
            "4392a2a7-04b6-4e35-be41-cf57c43b088e",
            "fccf059f-2ba0-41de-963e-34834ded1b74"
        ].include?(item["uuid"])
    end

    # NxThreads::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        l = lambda{|thread| "#{thread["description"]}#{DoNotShowUntil::suffix1(thread["uuid"]).yellow}" }
        threads = NxThreads::threadsInRatioOrder()
                    .reject{|thread| !NxThreads::isStructuralThread(thread) }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("thread", threads, l)
    end

    # NxThreads::architectOrNull()
    def self.architectOrNull()
        thread = NxThreads::interactivelySelectOneOrNull()
        return thread if thread
        puts "You have not selected a thread, let's make a new one"
        NxThreads::interactivelyIssueNewOrNull()
    end

    # NxThreads::ensureThreadParenting(item)
    def self.ensureThreadParenting(item)
        return item if Parenting::parentOrNull(item["uuid"])
        data = Operations::architectParentAndPositionOrNull()
        if data then
            parent = data["parent"]
            position = data["position"]
            Parenting::insertEntry(parent["uuid"], item["uuid"], position)
            return
        end
        level = PriorityLevels::interactivelySelectOne()
        thread = PriorityLevels::levelToThread(level)
        Parenting::insertEntry(thread["uuid"], item["uuid"], rand)
        Items::itemOrNull(item["uuid"])
    end

    # -----------------------------------------
    # Operations

    # NxThreads::maintenance()
    def self.maintenance()
        Items::mikuType("NxThread").each{|item|
            next if ["(low)", "(regular)", "(high)"].include?(item["description"])
            if !Parenting::hasChildren(item["uuid"]) and item["uxpayload-b4e4"].nil? and (Time.new.to_i - item["unixtime"]) > 86400*5 then
                if LucilleCore::askQuestionAnswerAsBoolean("Thread '#{PolyFunctions::toString(item)}' is now empty. Going to delete it ") then
                    Items::deleteItem(item["uuid"])
                else
                    Parenting::insertEntry(item["uuid"], "unixtime", Time.new.to_i)
                end
            end
        }
    end
end
