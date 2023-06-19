
class NxThreads

    # NxThreads::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        DarkEnergy::init("NxThread", uuid)
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::itemOrNull(uuid)
    end

    # NxThreads::toString(item)
    def self.toString(item)
        "⛵️ #{item["description"]}#{CoreData::itemToSuffixString(item)}#{NxCores::suffix(item)}"
    end

    # NxThreads::threadsOrderedForListing()
    def self.threadsOrderedForListing()
        DarkEnergy::mikuType("NxThread")
            .sort_by{|item| Bank::recoveredAverageHoursPerDay(item["uuid"]) }
    end

    # NxThreads::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        threads = DarkEnergy::mikuType("NxThread").sort_by{|item| item["description"] }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("threads", threads, lambda{|thread| NxThreads::toString(thread) })
    end

    # NxThreads::interactivelySelectOneThreadAtCoreOrNull(core)
    def self.interactivelySelectOneThreadAtCoreOrNull(core)
        threads = DarkEnergy::mikuType("NxThread")
                    .select{|item| item["core"] == core["uuid"] }
                    .sort_by{|item| item["description"] }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("threads", threads, lambda{|thread| NxThreads::toString(thread) })
    end

    # NxThreads::interactivelyDecidePositionInSequence(thread)
    def self.interactivelyDecidePositionInSequence(thread)
        position = LucilleCore::askQuestionAnswerAsString("> position: ").to_f
        position
    end

    # NxThreads::setSequenceAttempt(item)
    def self.setSequenceAttempt(item)
        if item["mikuType"] != "NxTask" and item["mikuType"] != "NxLine"  then
            puts "At the moment we only put NxTasks and NxLines into threads"
            LucilleCore::pressEnterToContinue()
            return
        end
        thread = NxThreads::interactivelySelectOneOrNull()
        if thread.nil? then
            if LucilleCore::askQuestionAnswerAsBoolean("You did not select a thread, would you like to make a new one ? ") then
                NxThreads::interactivelyIssueNewOrNull()
                NxThreads::setSequenceAttempt(item)
            end
            return
        end
        position = NxThreads::interactivelyDecidePositionInSequence(thread)
        DarkEnergy::patch(item["uuid"], "thread", {
            "uuid" => thread["uuid"],
            "position" => position
        })
    end

    # NxThreads::childrenOrderedForListing(thread)
    def self.childrenOrderedForListing(thread)
        (DarkEnergy::mikuType("NxTask") + DarkEnergy::mikuType("NxLine"))
            .select{|item| item["thread"] }
            .select{|item| item["thread"]["uuid"] == thread["uuid"] }
            .sort_by{|item| item["thread"]["position"] }
     end

    # NxThreads::program(thread)
    def self.program(thread)
        loop {

            thread = DarkEnergy::itemOrNull(thread["uuid"])
            return if thread.nil? # could have been deleted in the previous run

            system("clear")

            store = ItemStore.new()
            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            puts ""
            spacecontrol.putsline "thread:"
            store.register(thread, false)
            spacecontrol.putsline Listing::itemToListingLine(store, thread)

            items = NxThreads::childrenOrderedForListing(thread)

            Listing::printing(spacecontrol, store, items)

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                task = NxTasks::interactivelyIssueNewOrNull()
                next if task.nil?
                position = NxThreads::interactivelyDecidePositionInSequence(thread)
                DarkEnergy::patch(task["uuid"], "thread", {
                    "uuid" => thread["uuid"],
                    "position" => position
                })
                next
            end

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxThreads::done(thread)
    def self.done(thread)
        if NxThreads::childrenOrderedForListing(thread).empty? then
            if LucilleCore::askQuestionAnswerAsBoolean("> destroy '#{NxThreads::toString(thread).green}' ") then
                DarkEnergy::destroy(thread["uuid"])
            end
        else
            puts "You cannot done a non empty thread"
            LucilleCore::pressEnterToContinue()
        end
    end

    # NxThreads::destroy(thread)
    def self.destroy(thread)
        NxThreads::done(thread)
    end

    # NxThreads::pile(item)
    def self.pile(item)

        if item["mikuType"] != "NxTask" and item["mikuType"] != "NxThread" then
            puts "You can only pile NxTasks or NxThreads"
            LucilleCore::pressEnterToContinue()
            return
        end

        thread = nil

        if item["mikuType"] == "NxThread" then
            thread = item
        end

        if thread.nil? and item["thread"].nil? then
            puts "You are trying to pile an item that is not in a thread"
            if LucilleCore::askQuestionAnswerAsBoolean("Would you like to create a thread ? ") then
                thread = NxThreads::interactivelyIssueNewOrNull()
                return if thread.nil?
                item["thread"] = {
                    "uuid" => thread["uuid"],
                    "position" => 1
                }
                DarkEnergy::commit(item)
            else
                return
            end
        end

        if thread.nil? and DarkEnergy::itemOrNull(item["thread"]["uuid"]).nil? then
            puts "You are trying to pile an item that is not in a thread"
            if LucilleCore::askQuestionAnswerAsBoolean("Would you like to create a thread ? ") then
                thread = NxThreads::interactivelyIssueNewOrNull()
                return if thread.nil?
                item["thread"] = {
                    "uuid" => thread["uuid"],
                    "position" => 1
                }
                DarkEnergy::commit(item)
            else
                return
            end
        end

        if thread.nil? then
            thread = DarkEnergy::itemOrNull(item["thread"]["uuid"])
        end

        children = NxThreads::childrenOrderedForListing(thread)
        if !children.empty? then
            if item["uuid"] != children.first["uuid"] then
                puts "You cna only pile the first item of a thread"
                LucilleCore::pressEnterToContinue()
                return
            end
        end

        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["one", "multiple"])
        return if option.nil?

        if option == "one" then
            children = NxThreads::childrenOrderedForListing(thread)
            if children.empty? then
                position = 1
            else
                position = children.map{|child| child["thread"]["position"] }.min - 1
            end

            i = NxTasks::interactivelyIssueNewOrNull()
            i["thread"] = {
                "uuid" => thread["uuid"],
                "position" => position
            }
            DarkEnergy::commit(i)
        end

        if option == "multiple" then
            text = CommonUtils::editTextSynchronously(text).strip
            return if text == ""
            text.lines.to_a.reverse.each{|line|
                children = NxThreads::childrenOrderedForListing(thread)
                if children.empty? then
                    position = 1
                else
                    position = children.map{|child| child["thread"]["position"] }.min - 1
                end
                i = NxLines::issue(line)
                i["thread"] = {
                    "uuid" => thread["uuid"],
                    "position" => position
                }
                DarkEnergy::commit(i)
            }
        end
    end

    # NxThreads::threadSuffix(item)
    def self.threadSuffix(item)
        return "" if item["thread"].nil?
        thread = DarkEnergy::itemOrNull(item["thread"]["uuid"])
        return "" if thread.nil?
        " (⛵️ #{thread["description"].green})#{NxCores::suffix(thread)}"
    end

    # NxThreads::program2()
    def self.program2()
        loop {
            threads = DarkEnergy::mikuType("NxThread")
            thread = LucilleCore::selectEntityFromListOfEntitiesOrNull("thread", threads, lambda{|thread| NxThreads::toString(thread) })
            break if thread.nil?
            NxThreads::program(thread)
        }
    end
end
