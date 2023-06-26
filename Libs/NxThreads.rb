
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

    # ----------------------------------------------
    # Building

    # NxThreads::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        tt = NxThreads::interactivelySelectThreadType()
        DarkEnergy::init("NxThread", uuid)
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "type", tt)
        DarkEnergy::itemOrNull(uuid)
    end

    # NxThreads::toString(item)
    def self.toString(item)
        "🪔 #{item["description"]}"
    end

    # NxThreads::listingItems()
    def self.listingItems()
        DarkEnergy::mikuType("NxThread")
    end

    # NxThreads::program1(thread)
    def self.program1(thread)
        loop {

            system("clear")

            store = ItemStore.new()
            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            if thread["engineuuids"] then
                spacecontrol.putsline ""
                thread["engineuuids"].each{|engineuuid|
                    engine = DarkEnergy::itemOrNull(engineuuid)
                    puts "- #{NxEngines::toString(engine)}"
                }
            end

            spacecontrol.putsline ""
            spacecontrol.putsline "thread:"
            store.register(thread, false)
            spacecontrol.putsline Listing::itemToListingLine(store, thread)

            spacecontrol.putsline ""
            items = NxEngines::children(thread)

            if items.size > 0 then
                items = Pure::pureFromItem(items.first) + items.drop(1)
            end

            Listing::printing(spacecontrol, store, items)

            spacecontrol.putsline ""
            spacecontrol.putsline "task | engines"

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

            if input == "engines" then
                eToE = lambda {|engineuuid|
                    engine = DarkEnergy::itemOrNull(engineuuid)
                    return "(engine not found for engineuuid: #{engineuuid})" if engine.nil?
                    PolyFunctions::toString(engine)
                }

                selected = (thread["engineuuids"] || [])
                notSelected = DarkEnergy::mikuType("NxEngine").map{|e| e["uuid"] } - selected
                engineuuids, _ = LucilleCore::selectZeroOrMore("engines", selected, notSelected, lambda{|engineuuid| eToE.call(engineuuid) })
                thread["engineuuids"] = engineuuids
                DarkEnergy::commit(thread)
                next
            end

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end
end

