
class NxThreads

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

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end
end

