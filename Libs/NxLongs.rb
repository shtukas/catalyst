
class NxLongs

    # NxLongs::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        Solingen::init("NxLong", uuid)
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        Solingen::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Solingen::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Solingen::setAttribute2(uuid, "description", description)
        Solingen::setAttribute2(uuid, "field11", coredataref)
        Solingen::getItemOrNull(uuid)
    end

    # NxLongs::toString(item)
    def self.toString(item)
        "(long) #{item["description"]}#{CoreData::referenceStringToSuffixString(item["field11"])}"
    end

    # NxLongs::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        items = Solingen::mikuTypeItems("NxLong")
        LucilleCore::selectEntityFromListOfEntitiesOrNull("board", items, lambda{|item| NxLongs::toString(item) })
    end

    # NxLongs::program1()
    def self.program1()
        loop {

            system("clear")

            puts ""

            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            store = ItemStore.new()

            Solingen::mikuTypeItems("NxLong")
                .sort_by{|item| Bank::recoveredAverageHoursPerDay(item["uuid"]) }
                .each{|item|
                    store.register(item, Listing::canBeDefault(item)) 
                    status = spacecontrol.putsline(Listing::itemToListingLine(store: store, item: item))
                    break if !status
                }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == ""

            ListingCommandsAndInterpreters::interpreter(input, store, nil)
        }
    end

    # NxLongs::program2()
    def self.program2()
        loop {
            monitor = Solingen::mikuTypeItems("NxMonitorLongs").first
            puts NxLongs::monitorToString(monitor)
            actions = ["program(NxLongs)", "start", "add time"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            break if action.nil?
            if action == "start" then
                PolyActions::start(monitor)
            end
            if action == "add time" then
                timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
                PolyActions::addTimeToItem(monitor, timeInHours*3600)
            end
            if action == "program(NxLongs)" then
                NxLongs::program1()
            end
        }
    end

    # NxLongs::dataMaintenance()
    def self.dataMaintenance()
        # We scan the tasks and any boardless task with more than 2 hours in the bank is automatically turned into a long running project
        NxTasks::boardlessItems()
            .sort_by{|item| item["position"] }
            .first(100)
            .each{|item|
                next if Bank::getValue(item["uuid"]) < 3600*2
                puts "transmuting task: #{item["description"]} into a long running project NxLong"
                Solingen::setAttribute2(item["uuid"], "mikuType", "NxLong")
            }
    end

    # -------------------------------------
    # Monitor

    # NxLongs::monitorToString(item)
    def self.monitorToString(item)
        "(#{"moni".green}) NxLongs #{TxEngines::toString(item["engine"])}"
    end

    # NxLongs::monitorDataMaintenance()
    def self.monitorDataMaintenance()
        monitor = Solingen::mikuTypeItems("NxMonitorLongs").first
        engine2 = TxEngines::engineCarrierMaintenance(monitor)
        if engine2 then
            Solingen::setAttribute2(monitor["uuid"], "engine", engine2)
        end
    end
end