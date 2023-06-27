
class NxThreads

    # ----------------------------------------------
    # Building

    # NxThreads::threadTypes()
    def self.threadTypes()
        [
            {
                "type"        => "ns1",
                "description" => "ideally should end as soon as possible"
            },
            {
                "type"        => "ns2",
                "description" => "open, in progress, external dependencies"
            },
            {
                "type"        => "ns3",
                "description" => "background inactive"
            }
        ]
    end

    # NxThreads::interactivelySelectThreadType()
    def self.interactivelySelectThreadType()
        loop {
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("thread thread:", NxThreads::threadTypes(), lambda{|tt| tt["description"] })
            next if item.nil?
            return item["type"]
        }
    end

    # NxThreads::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        uuid = SecureRandom.uuid
        tt = NxThreads::interactivelySelectThreadType()

        eToE = lambda {|threaduuid|
            engine = DarkEnergy::itemOrNull(threaduuid)
            return "(engine not found for threaduuid: #{threaduuid})" if engine.nil?
            PolyFunctions::toString(engine)
        }

        selected = []
        notSelected = DarkEnergy::mikuType("NxThread").map{|e| e["uuid"] } - selected
        parents, _ = LucilleCore::selectZeroOrMore(
            "threads",
            [],
            DarkEnergy::mikuType("NxThread").map{|e| e["uuid"] },
            lambda{ |threaduuid| eToE.call(threaduuid) }
        )

        if LucilleCore::askQuestionAnswerAsBoolean("> own engine: ") then
            engine = TxEngines::interactivelyMakeEngineOrNull()
        else
            engine = nil
        end

        DarkEnergy::init("NxThread", uuid)
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "type", tt)
        DarkEnergy::patch(uuid, "parents", parents)
        DarkEnergy::patch(uuid, "engine", engine)
        DarkEnergy::itemOrNull(uuid)
    end

    # ----------------------------------------------
    # Data

    # NxThreads::toString(thread)
    def self.toString(thread)
        "🪔 #{thread["description"]}"
    end

    # NxThreads::toStringWithDetails(thread)
    def self.toStringWithDetails(thread)
        padding = XCache::getOrDefaultValue("e8f9022e-3a5d-4e3b-87e0-809a3308b8ad", "0").to_i
        engineSuffix = thread["engine"] ? " #{TxEngines::toString(thread["engine"])}" : ""
        "🪔 #{thread["description"].ljust(padding)}#{engineSuffix}"
    end

    # NxThreads::toStringForListing(thread)
    def self.toStringForListing(thread)
        padding = XCache::getOrDefaultValue("e8f9022e-3a5d-4e3b-87e0-809a3308b8ad", "0").to_i
        engineSuffix = thread["engine"] ? " ⏱️ #{"%5.2f" % (TxEngines::dayCompletionRatio(thread["engine"])*100)} %" : ""
        "🪔 #{thread["description"].ljust(padding)}#{engineSuffix}"
    end

    # ----------------------------------------------
    # Ops

    # NxThreads::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("thread", DarkEnergy::mikuType("NxThread"), lambda{|thread| NxThreads::toString(thread) })
    end

    # NxThreads::architectThreadOrNull()
    def self.architectThreadOrNull()
        thread = NxThreads::interactivelySelectOneOrNull()
        return thread if thread
        puts "No thread selected. Making a new one."
        NxThreads::interactivelyIssueNewOrNull()
    end

    # NxThreads::maintenance()
    def self.maintenance()
        DarkEnergy::mikuType("NxThread").each{|thread|
            next if thread["engine"].nil?
            engine = TxEngines::engine_maintenance(thread, thread["engine"])
            next if engine.nil?
            DarkEnergy::patch(thread["uuid"], "engine", engine)
        }
    end

    # NxThreads::maintenance2()
    def self.maintenance2()
        padding = ([0] + DarkEnergy::mikuType("NxThread").map{|thread| thread["description"].size}).max
        XCache::set("e8f9022e-3a5d-4e3b-87e0-809a3308b8ad", padding)
    end

    # NxThreads::program1(thread)
    def self.program1(thread)
        loop {

            thread = DarkEnergy::itemOrNull(thread["uuid"])
            return if thread.nil?

            system("clear")

            store = ItemStore.new()
            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            if thread["parents"] then
                spacecontrol.putsline ""
                spacecontrol.putsline "parents:"
                thread["parents"].each{|threaduuid|
                    thread = DarkEnergy::itemOrNull(threaduuid)
                    next if thread.nil?
                    puts "- #{NxThreads::toString(thread)}"
                }
            end

            if thread["engine"] then
                spacecontrol.putsline ""
                spacecontrol.putsline "engine:"
                spacecontrol.putsline "- #{TxEngines::toString(thread["engine"])}"
            end

            spacecontrol.putsline ""
            spacecontrol.putsline "thread:"
            store.register(thread, false)
            spacecontrol.putsline Listing::itemToListingLine(store, thread)

            spacecontrol.putsline ""
            items = Tx8s::childrenInOrder(thread)

            if items.size > 0 then
                items = Pure::pureFromItem(items.first) + items.drop(1)
            end

            Listing::printing(spacecontrol, store, items)

            spacecontrol.putsline ""
            spacecontrol.putsline "task | parents | engine"

            spacecontrol.putsline ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                task = NxTasks::interactivelyIssueNewOrNull()
                next if task.nil?
                position = Tx8s::interactivelyDecidePositionUnderThisParent(thread)
                task["parent"] = Tx8s::make(thread["uuid"], position)
                DarkEnergy::commit(task)
                next
            end

            if input == "parents" then
                eToE = lambda {|threaduuid|
                    engine = DarkEnergy::itemOrNull(threaduuid)
                    return "(engine not found for threaduuid: #{threaduuid})" if engine.nil?
                    PolyFunctions::toString(engine)
                }

                selected = (thread["parents"] || [])
                notSelected = DarkEnergy::mikuType("NxThread").map{|e| e["uuid"] } - (selected + [thread["uuid"]])
                parents, _ = LucilleCore::selectZeroOrMore("engines", selected, notSelected, lambda{|engineuuid| eToE.call(engineuuid) })
                thread["parents"] = parents
                DarkEnergy::commit(thread)
                next
            end

            if input == "engine" then
                if thread["engine"] then
                    puts "You cannot reset an engine, modify the hour during maintenance"
                    LucilleCore::pressEnterToContinue()
                    next
                else
                    engine = TxEngines::interactivelyMakeEngineOrNull()
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
            thread = LucilleCore::selectEntityFromListOfEntitiesOrNull("thread", DarkEnergy::mikuType("NxThread"), lambda{|thread| NxThreads::toStringWithDetails(thread) })
            return if thread.nil?
            NxThreads::program1(thread)
        }
    end

    # NxThreads::interactivelyMakeTx8ForThreadParentingOrNull()
    def self.interactivelyMakeTx8ForThreadParentingOrNull()
        thread = NxThreads::interactivelySelectOneOrNull()
        return nil if thread.nil?
        position = Tx8s::interactivelyDecidePositionUnderThisParent(thread)
        Tx8s::make(thread["uuid"], position)
    end

    # NxThreads::interactivelySetIntoThreadAttempt(item)
    def self.interactivelySetIntoThreadAttempt(item)
        tx8 = NxThreads::interactivelyMakeTx8ForThreadParentingOrNull()
        DarkEnergy::patch(item["uuid"], "parent", tx8)
    end
end

