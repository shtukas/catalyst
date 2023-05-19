# encoding: UTF-8

class NxTasks

    # NxTasks::getItemOfNull(uuid)
    def self.getItemOfNull(uuid)
        Solingen::getItemOrNull(uuid)
    end

    # --------------------------------------------------
    # Makers

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        uuid = SecureRandom.uuid

        # We need to create the blade before we call CoreData::interactivelyMakeNewReferenceStringOrNull
        # because the blade need to exist for aion points data blobs to have a place to go.

        # We cannot give to the blade a NxTask type because NxTasksPositions::decidePositionAtOptionalBoard
        # will find an item without a position in the collection, which is going to break sorting
        # There for we create a NxPure and we will recast as NxTask later

        Solingen::init("NxPure", uuid)

        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        board    = NxBoards::interactivelySelectOneOrNull()
        position = NxTasksPositions::decidePositionAtOptionalBoard(board)

        boarduuid = board ? board["uuid"] : nil

        Solingen::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Solingen::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Solingen::setAttribute2(uuid, "description", description)
        Solingen::setAttribute2(uuid, "field11", coredataref)
        Solingen::setAttribute2(uuid, "boarduuid", boarduuid)
        Solingen::setAttribute2(uuid, "position", position)

        Solingen::setAttribute2(uuid, "mikuType", "NxTask")

        Solingen::getItemOrNull(uuid)
    end

    # NxTasks::netflix(title)
    def self.netflix(title)
        description = "Watch '#{title}' on Netflix"
        uuid = SecureRandom.uuid

        Solingen::init("NxPure", uuid)

        nhash = Solingen::putDatablob2(uuid, url)
        coredataref = "url:#{nhash}"
        position = NxTasksPositions::slice_positioning2_boardless(50, 100)

        Solingen::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Solingen::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Solingen::setAttribute2(uuid, "description", description)
        Solingen::setAttribute2(uuid, "field11", coredataref)
        Solingen::setAttribute2(uuid, "boarduuid", nil)
        Solingen::setAttribute2(uuid, "position", position)

        Solingen::setAttribute2(uuid, "mikuType", "NxTask")

        Solingen::getItemOrNull(uuid)
    end

    # NxTasks::viennaUrl(url)
    def self.viennaUrl(url)
        description = "(vienna) #{url}"
        uuid = SecureRandom.uuid

        Solingen::init("NxPure", uuid)

        nhash = Solingen::putDatablob2(uuid, url)
        coredataref = "url:#{nhash}"
        position = NxTasksPositions::slice_positioning2_boardless(50, 100)

        Solingen::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Solingen::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Solingen::setAttribute2(uuid, "description", description)
        Solingen::setAttribute2(uuid, "field11", coredataref)
        Solingen::setAttribute2(uuid, "boarduuid", nil)
        Solingen::setAttribute2(uuid, "position", position)

        Solingen::setAttribute2(uuid, "mikuType", "NxTask")

        Solingen::getItemOrNull(uuid)
    end

    # NxTasks::bufferInImport(location)
    def self.bufferInImport(location)
        description = File.basename(location)
        uuid = SecureRandom.uuid

        Solingen::init("NxPure", uuid)

        nhash = AionCore::commitLocationReturnHash(BladeElizabeth.new(uuid), location)
        coredataref = "aion-point:#{nhash}"
        position = NxTasksPositions::slice_positioning2_boardless(50, 100)

        Solingen::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Solingen::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Solingen::setAttribute2(uuid, "description", description)
        Solingen::setAttribute2(uuid, "field11", coredataref)
        Solingen::setAttribute2(uuid, "boarduuid", nil)
        Solingen::setAttribute2(uuid, "position", position)

        Solingen::setAttribute2(uuid, "mikuType", "NxTask")

        Solingen::getItemOrNull(uuid)
    end

    # --------------------------------------------------
    # Data

    # NxTasks::toString(item)
    def self.toString(item)
        "(task) #{item["description"]} (#{item["position"].round(2)})"
    end

    # NxTasks::toStringNoEngine(item)
    def self.toStringNoEngine(item)
        "(task) (#{item["position"].round(2)}) #{item["description"]}"
    end

    # --------------------------------------------------
    # Operations

    # NxTasks::access(item)
    def self.access(item)
        CoreData::access(item["uuid"], item["field11"])
    end

    # --------------------------------------------------
    # Boardless Items

    # NxTasks::boardlessItems()
    def self.boardlessItems()
        Solingen::mikuTypeItems("NxTask")
            .select{|item| item["boarduuid"].nil? }
    end

    # NxTasks::itemIsBoardless(item)
    def self.itemIsBoardless(item)
        return false if item["mikuType"] != "NxTask"
        return false if item["boarduuid"]
        true
    end

    # NxTasks::boardlessItemsProgram1()
    def self.boardlessItemsProgram1()
        loop {
            system("clear")
            puts ""
            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)
            store = ItemStore.new()
            NxTasks::boardlessItems()
                .sort_by{|item| item["position"] }
                .take(CommonUtils::screenHeight()-5)
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

    # NxTasks::boardlessItemsProgram2()
    def self.boardlessItemsProgram2()
        loop {
            monitor = Solingen::getItem("bea0e9c7-f609-47e7-beea-70e433e0c82e")
            puts NxTasks::monitorToString(monitor)
            actions = ["program(NxTask boardless)", "start", "add time"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            break if action.nil?
            if action == "start" then
                PolyActions::start(monitor)
            end
            if action == "add time" then
                timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
                PolyActions::addTimeToItem(monitor, timeInHours*3600)
            end
            if action == "program(NxTask boardless)" then
                NxTasks::boardlessItemsProgram1()
            end
        }
    end

    # NxTasks::boardlessMonitorToString(item)
    def self.boardlessMonitorToString(item)
        "(#{"moni".green}) boardless tasks #{TxEngines::toString(item["engine"])}"
    end

    # NxTasks::boardlessMonitorDataMaintenance()
    def self.boardlessMonitorDataMaintenance()
        monitor = Solingen::getItemOrNull("bea0e9c7-f609-47e7-beea-70e433e0c82e")
        engine2 = TxEngines::engineCarrierMaintenance(monitor)
        if engine2 then
            Solingen::setAttribute2(monitor["uuid"], "engine", engine2)
        end
    end

    # --------------------------------------------------
    # Boarded Items

    # NxTasks::boardedItems(board)
    def self.boardedItems(board)
        Solingen::mikuTypeItems("NxTask")
            .select{|item| item["boarduuid"] == board["uuid"] }
            .sort_by{|item| item["position"] }
    end
end
