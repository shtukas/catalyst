
class NxNodes

    # NxNodes::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        DarkEnergy::init("NxNode", uuid)
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::itemOrNull(uuid)
    end

    # NxNodes::positionSuffix(item)
    def self.positionSuffix(item)
        return "" if item["parent"].nil?
        " (#{"%5.2f" % item["parent"]["position"]})"
    end

    # NxNodes::toString(item)
    def self.toString(item)
        "⛵️#{NxNodes::positionSuffix(item)} #{item["description"]}#{CoreData::itemToSuffixString(item)}#{Tx8s::parentSuffix(item)}"
    end

    # NxNodes::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        threads = DarkEnergy::mikuType("NxNode").sort_by{|item| item["description"] }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("threads", threads, lambda{|thread| NxNodes::toString(thread) })
    end

    # NxNodes::orphanNodes()
    def self.orphanNodes()
        DarkEnergy::mikuType("NxNode")
            .select{|thread| thread["parent"].nil? }
    end

    # NxNodes::interactivelyDecidePositionInNode(thread)
    def self.interactivelyDecidePositionInNode(thread)
        NxNodes::childrenOrderedForListing(thread)
            .each{|item|
                puts " - #{PolyFunctions::toString(item)}"
            }
        position = LucilleCore::askQuestionAnswerAsString("> position (empty for next): ")
        if position == "" then
            positions = Tx8s::childrenPositions(thread)
            return 1 if positions.empty?
            return positions.max + 1
        else
            return position.to_f
        end
    end

    # NxNodes::setThreadAttempt(item)
    def self.setThreadAttempt(item)
        if item["mikuType"] != "NxTask" and item["mikuType"] != "NxLine"  then
            puts "At the moment we only put NxTasks and NxLines into threads"
            LucilleCore::pressEnterToContinue()
            return
        end
        thread = NxNodes::interactivelySelectOneOrNull()
        if thread.nil? then
            if LucilleCore::askQuestionAnswerAsBoolean("You did not select a thread, would you like to make a new one ? ") then
                NxNodes::interactivelyIssueNewOrNull()
                NxNodes::setThreadAttempt(item)
            end
            return
        end
        position = NxNodes::interactivelyDecidePositionInNode(thread)
        DarkEnergy::patch(item["uuid"], "parent", Tx8s::make(thread["uuid"], position))
    end

    # NxNodes::childrenOrderedForListing(thread)
    def self.childrenOrderedForListing(thread)
        (DarkEnergy::mikuType("NxTask") + DarkEnergy::mikuType("NxLine"))
            .select{|item| item["parent"] }
            .select{|item| item["parent"]["uuid"] == thread["uuid"] }
            .sort_by{|item| item["parent"]["position"] }
     end

    # NxNodes::program(node)
    def self.program(node)
        loop {

            node = DarkEnergy::itemOrNull(node["uuid"])
            return if node.nil? # could have been deleted in the previous run

            system("clear")

            store = ItemStore.new()
            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            puts ""
            spacecontrol.putsline "node:"
            store.register(node, false)
            spacecontrol.putsline Listing::itemToListingLine(store, node)

            items = NxNodes::childrenOrderedForListing(node)

            Listing::printing(spacecontrol, store, items)

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "node" then
                n1 = NxNodes::interactivelyIssueNewOrNull()
                next if n1.nil?
                tx8 = Tx8s::interactivelyMakeNewTx8BelowThisElementOrNull(node)
                next if tx8.nil?
                n1["parent"] = tx8
                DarkEnergy::commit(n1)
                next
            end

            if input == "task" then
                task = NxTasks::interactivelyIssueNewOrNull()
                next if task.nil?
                tx8 = Tx8s::interactivelyMakeNewTx8BelowThisElementOrNull(node)
                next if tx8.nil?
                task["parent"] = tx8
                DarkEnergy::commit(task)
                next
            end

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxNodes::done(node)
    def self.done(node)
        if NxNodes::childrenOrderedForListing(node).empty? then
            if LucilleCore::askQuestionAnswerAsBoolean("> destroy '#{NxNodes::toString(node).green}' ") then
                DarkEnergy::destroy(node["uuid"])
            end
        else
            puts "You cannot done a non empty node"
            LucilleCore::pressEnterToContinue()
        end
    end

    # NxNodes::destroy(node)
    def self.destroy(node)
        NxNodes::done(node)
    end

    # NxNodes::pile(node)
    def self.pile(node)

        if node["mikuType"] != "NxNode" then
            puts "You can only pile NxNodes"
            LucilleCore::pressEnterToContinue()
            return
        end

        children = NxNodes::childrenOrderedForListing(node)
        if !children.empty? then
            if item["uuid"] != children.first["uuid"] then
                puts "You cna only pile the first item of a node"
                LucilleCore::pressEnterToContinue()
                return
            end
        end

        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["one", "multiple"])
        return if option.nil?

        if option == "one" then
            children = NxNodes::childrenOrderedForListing(node)
            if children.empty? then
                position = 1
            else
                position = children.map{|child| child["parent"]["position"] }.min - 1
            end

            i = NxTasks::interactivelyIssueNewOrNull()
            i["parent"] = Tx8s::make(node["uuid"], position)
            DarkEnergy::commit(i)
        end

        if option == "multiple" then
            text = CommonUtils::editTextSynchronously(text).strip
            return if text == ""
            text.lines.to_a.reverse.each{|line|
                children = NxNodes::childrenOrderedForListing(node)
                if children.empty? then
                    position = 1
                else
                    position = children.map{|child| child["parent"]["position"] }.min - 1
                end
                i = NxLines::issue(line)
                i["parent"] = Tx8s::make(node["uuid"], position)
                DarkEnergy::commit(i)
            }
        end
    end
end
