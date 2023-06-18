
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
        "⛵️ #{item["description"]}#{CoreData::itemToSuffixString(item)}"
    end

    # NxSequences::orderedForListing()
    def self.orderedForListing()
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
        if item["mikuType"] != "NxTask" then
            puts "At the moment we only put NxTasks into sequences"
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

    # NxSequences::children_ordered(sequence)
    def self.children_ordered(sequence)
        DarkEnergy::mikuType("NxTask")
            .select{|item| item["sequence"] }
            .select{|item| item["sequence"]["uuid"] == sequence["uuid"] }
            .sort_by{|item| item["sequence"]["position"] }
     end

    # NxSequences::program(sequence)
    def self.program(sequence)
        loop {

            system("clear")

            store = ItemStore.new()
            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            puts ""
            spacecontrol.putsline "@sequence:"
            store.register(sequence, false)
            spacecontrol.putsline Listing::itemToListingLine(store, sequence)

            items = NxSequences::children_ordered(sequence)

            Listing::printing(spacecontrol, store, items)

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end
end