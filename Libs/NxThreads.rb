
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

    # NxThreads::positionSuffix(item)
    def self.positionSuffix(item)
        return "" if item["parent"].nil?
        " (#{"%5.2f" % item["parent"]["position"]})"
    end

    # NxThreads::toString(item)
    def self.toString(item)
        "⛵️#{NxThreads::positionSuffix(item)} #{item["description"]}#{CoreData::itemToSuffixString(item)}#{Tx8s::parentSuffix(item)}"
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
                    .select{|item| item["parent"] }
                    .select{|item| item["parent"]["uuid"] == core["uuid"] }
                    .sort_by{|item| item["description"] }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("threads", threads, lambda{|thread| NxThreads::toString(thread) })
    end

    # NxThreads::interactivelyDecidePositionInSequence(thread)
    def self.interactivelyDecidePositionInSequence(thread)
        NxThreads::childrenOrderedForListing(thread)
            .each{|item|
                puts " - #{PolyFunctions::toString(item)}"
            }
        position = LucilleCore::askQuestionAnswerAsString("> position (empty for next): ")
        if position == "" then
            positions = NxThreads::childrenPositions(thread)
            return 1 if positions.empty?
            return positions.max + 1
        else
            return position.to_f
        end
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
        DarkEnergy::patch(item["uuid"], "parent", Tx8s::make(thread["uuid"], position))
    end

    # NxThreads::childrenPositions(thread)
    def self.childrenPositions(thread)
        (DarkEnergy::mikuType("NxTask") + DarkEnergy::mikuType("NxLine"))
            .select{|item| item["parent"] }
            .select{|item| item["parent"]["uuid"] == thread["uuid"] }
            .map{|item| item["parent"]["position"] }
     end

    # NxThreads::childrenOrderedForListing(thread)
    def self.childrenOrderedForListing(thread)
        (DarkEnergy::mikuType("NxTask") + DarkEnergy::mikuType("NxLine"))
            .select{|item| item["parent"] }
            .select{|item| item["parent"]["uuid"] == thread["uuid"] }
            .sort_by{|item| item["parent"]["position"] }
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
                DarkEnergy::patch(task["uuid"], "parent", Tx8s::make(thread["uuid"], position))
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

    # NxThreads::pile(thread)
    def self.pile(thread)

        if thread["mikuType"] != "NxThread" then
            puts "You can only pile NxThreads"
            LucilleCore::pressEnterToContinue()
            return
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
                position = children.map{|child| child["parent"]["position"] }.min - 1
            end

            i = NxTasks::interactivelyIssueNewOrNull()
            i["parent"] = Tx8s::make(thread["uuid"], position)
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
                    position = children.map{|child| child["parent"]["position"] }.min - 1
                end
                i = NxLines::issue(line)
                i["parent"] = Tx8s::make(thread["uuid"], position)
                DarkEnergy::commit(i)
            }
        end
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
