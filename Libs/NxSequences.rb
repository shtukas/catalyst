
class NxSequences

    # NxSequences::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        DarkEnergy::init("NxSequence", uuid)
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::itemOrNull(uuid)
    end

    # NxSequences::toString(item)
    def self.toString(item)
        "⛵️ #{item["description"]}#{CoreData::itemToSuffixString(item)}#{NxCores::suffix(item)}"
    end

    # NxSequences::sequencesOrderedForListing()
    def self.sequencesOrderedForListing()
        DarkEnergy::mikuType("NxSequence")
            .sort_by{|item| Bank::recoveredAverageHoursPerDay(item["uuid"]) }
    end

    # NxSequences::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        sequences = DarkEnergy::mikuType("NxSequence").sort_by{|item| item["description"] }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("sequences", sequences, lambda{|sequence| NxSequences::toString(sequence) })
    end

    # NxSequences::interactivelyDecidePositionInSequence(sequence)
    def self.interactivelyDecidePositionInSequence(sequence)
        position = LucilleCore::askQuestionAnswerAsString("> position: ").to_f
        position
    end

    # NxSequences::setSequenceAttempt(item)
    def self.setSequenceAttempt(item)
        if item["mikuType"] != "NxTask" and item["mikuType"] != "NxLine"  then
            puts "At the moment we only put NxTasks and NxLines into sequences"
            LucilleCore::pressEnterToContinue()
            return
        end
        sequence = NxSequences::interactivelySelectOneOrNull()
        if sequence.nil? then
            if LucilleCore::askQuestionAnswerAsBoolean("You did not select a sequence, would you like to make a new one ? ") then
                NxSequences::interactivelyIssueNewOrNull()
                NxSequences::setSequenceAttempt(item)
            end
            return
        end
        position = NxSequences::interactivelyDecidePositionInSequence(sequence)
        DarkEnergy::patch(item["uuid"], "sequence", {
            "uuid" => sequence["uuid"],
            "position" => position
        })
    end

    # NxSequences::childrenOrderedForListing(sequence)
    def self.childrenOrderedForListing(sequence)
        (DarkEnergy::mikuType("NxTask") + DarkEnergy::mikuType("NxLine"))
            .select{|item| item["sequence"] }
            .select{|item| item["sequence"]["uuid"] == sequence["uuid"] }
            .sort_by{|item| item["sequence"]["position"] }
     end

    # NxSequences::program(sequence)
    def self.program(sequence)
        loop {

            sequence = DarkEnergy::itemOrNull(sequence["uuid"])
            return if sequence.nil? # could have been deleted in the previous run

            system("clear")

            store = ItemStore.new()
            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            puts ""
            spacecontrol.putsline "@sequence:"
            store.register(sequence, false)
            spacecontrol.putsline Listing::itemToListingLine(store, sequence)

            items = NxSequences::childrenOrderedForListing(sequence)

            Listing::printing(spacecontrol, store, items)

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxSequences::done(sequence)
    def self.done(sequence)
        if NxSequences::childrenOrderedForListing(sequence).empty? then
            if LucilleCore::askQuestionAnswerAsBoolean("> destroy '#{NxSequences::toString(sequence).green}' ") then
                DarkEnergy::destroy(sequence["uuid"])
            end
        else
            puts "You cannot done a non empty sequence"
            LucilleCore::pressEnterToContinue()
        end
    end

    # NxSequences::destroy(sequence)
    def self.destroy(sequence)
        NxSequences::done(sequence)
    end

    # NxSequences::pile(item)
    def self.pile(item)

        if item["mikuType"] != "NxTask" and item["mikuType"] != "NxSequence" then
            puts "You can only pile NxTasks or NxSequences"
            LucilleCore::pressEnterToContinue()
            return
        end

        sequence = nil

        if item["mikuType"] == "NxSequence" then
            sequence = item
        end

        if sequence.nil? and item["sequence"].nil? then
            puts "You are trying to pile an item that is not in a sequence"
            if LucilleCore::askQuestionAnswerAsBoolean("Would you like to create a sequence ? ") then
                sequence = NxSequences::interactivelyIssueNewOrNull()
                return if sequence.nil?
                item["sequence"] = {
                    "uuid" => sequence["uuid"],
                    "position" => 1
                }
                DarkEnergy::commit(item)
            else
                return
            end
        end

        if sequence.nil? and DarkEnergy::itemOrNull(item["sequence"]["uuid"]).nil? then
            puts "You are trying to pile an item that is not in a sequence"
            if LucilleCore::askQuestionAnswerAsBoolean("Would you like to create a sequence ? ") then
                sequence = NxSequences::interactivelyIssueNewOrNull()
                return if sequence.nil?
                item["sequence"] = {
                    "uuid" => sequence["uuid"],
                    "position" => 1
                }
                DarkEnergy::commit(item)
            else
                return
            end
        end

        if sequence.nil? then
            sequence = DarkEnergy::itemOrNull(item["sequence"]["uuid"])
        end

        children = NxSequences::childrenOrderedForListing(sequence)
        if !children.empty? then
            if item["uuid"] != children.first["uuid"] then
                puts "You cna only pile the first item of a sequence"
                LucilleCore::pressEnterToContinue()
                return
            end
        end

        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["one", "multiple"])
        return if option.nil?

        if option == "one" then
            children = NxSequences::childrenOrderedForListing(sequence)
            if children.empty? then
                position = 1
            else
                position = children.map{|child| child["sequence"]["position"] }.min - 1
            end

            i = NxTasks::interactivelyIssueNewOrNull()
            i["sequence"] = {
                "uuid" => sequence["uuid"],
                "position" => position
            }
            DarkEnergy::commit(i)
        end

        if option == "multiple" then
            text = CommonUtils::editTextSynchronously(text).strip
            return if text == ""
            text.lines.to_a.reverse.each{|line|
                children = NxSequences::childrenOrderedForListing(sequence)
                if children.empty? then
                    position = 1
                else
                    position = children.map{|child| child["sequence"]["position"] }.min - 1
                end
                i = NxLines::issue(line)
                i["sequence"] = {
                    "uuid" => sequence["uuid"],
                    "position" => position
                }
                DarkEnergy::commit(i)
            }
        end
    end

    # NxSequences::sequenceSuffix(item)
    def self.sequenceSuffix(item)
        return "" if item["sequence"].nil?
        sequence = DarkEnergy::itemOrNull(item["sequence"]["uuid"])
        return "" if sequence.nil?
        " (⛵️ #{sequence["description"].green})#{NxCores::suffix(sequence)}"
    end

    # NxSequences::program2()
    def self.program2()
        loop {
            sequences = DarkEnergy::mikuType("NxSequence")
            sequence = LucilleCore::selectEntityFromListOfEntitiesOrNull("sequence", sequences, lambda{|sequence| NxSequences::toString(sequence) })
            break if sequence.nil?
            NxSequences::program(sequence)
        }
    end
end
