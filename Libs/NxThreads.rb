
class NxThreads

    # ----------------------------------------------
    # Building

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

    # ----------------------------------------------
    # Data

    # NxThreads::toString(thread)
    def self.toString(thread)
        "⛵️ #{thread["description"]} #{TxCores::coreSuffix(thread)}"
    end

    # ----------------------------------------------
    # Ops

    # NxThreads::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        threads = DarkEnergy::mikuType("NxThread").sort_by{|item| item["description"] }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("thread", threads, lambda{|thread| NxThreads::toString(thread) })
    end

    # NxThreads::program1(thread)
    def self.program1(thread)
        loop {

            thread = DarkEnergy::itemOrNull(thread["uuid"])
            return if thread.nil?

            system("clear")

            store = ItemStore.new()
            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            spacecontrol.putsline ""
            store.register(thread, false)
            spacecontrol.putsline Listing::itemToListingLine(store, thread)

            spacecontrol.putsline ""
            items = Tx8s::childrenInOrder(thread)

            Listing::printing(spacecontrol, store, items)

            spacecontrol.putsline ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                NxTasks::interactivelyIssueNewAtParentOrNull(thread)
                next
            end

            if input == "engine" then
                if thread["engine"] then
                    puts "You cannot reset an engine, modify the hour during maintenance"
                    LucilleCore::pressEnterToContinue()
                    next
                else
                    engine = TxCores::interactivelyMakeCoreOrNull()
                    DarkEnergy::patch(thread["uuid"], "engine", engine)
                end
                next
            end

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxThreads::program2()
    def self.program2()
        loop {
            threads = DarkEnergy::mikuType("NxThread").sort_by{|item| item["description"] }
            thread = LucilleCore::selectEntityFromListOfEntitiesOrNull("thread", threads, lambda{|thread| NxThreads::toString(thread) })
            return if thread.nil?
            NxThreads::program1(thread)
        }
    end
end

