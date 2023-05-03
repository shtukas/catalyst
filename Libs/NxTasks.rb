# encoding: UTF-8

class NxTasks

    # NxTasks::items()
    def self.items()
        N3Objects::getMikuType("NxTask")
    end

    # NxTasks::commit(item)
    def self.commit(item)
        N3Objects::commit(item)
    end

    # NxTasks::getItemOfNull(uuid)
    def self.getItemOfNull(uuid)
        N3Objects::getOrNull(uuid)
    end

    # NxTasks::destroy(uuid)
    def self.destroy(uuid)
        N3Objects::destroy(uuid)
    end

    # --------------------------------------------------
    # Makers

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        uuid = SecureRandom.uuid

        item = {}
        item["uuid"] = uuid
        item["mikuType"] = "NxTask"
        item["unixtime"] = Time.new.to_i
        item["datetime"] = Time.new.utc.iso8601
        item["description"] = description
        item["field11"] = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)

        board    = NxBoards::interactivelySelectOneBoardOrNull()
        position = NxTasksPositions::decidePositionAtOptionalBoard(board)
        engine   = TxEngines::interactivelyMakeEngineOrDefault()

        item["boarduuid"] = board ? board["uuid"] : nil
        item["position"]  = position
        item["engine"]    = engine

        NxTasks::commit(item)
        item
    end

    # NxTasks::netflix(title)
    def self.netflix(title)
        uuid  = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTask",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => "Watch '#{title}' on Netflix",
            "field11"     => nil,
            "boarduuid"   => nil,
            "position"    => NxTasksPositions::automaticPositioningAtNoBoard(50),
            "engine"      => TxEngines::defaultEngine(nil),
        }
        NxTasks::commit(item)
        item
    end

    # NxTasks::viennaUrl(url)
    def self.viennaUrl(url)
        uuid  = SecureRandom.uuid
        description = "(vienna) #{url}"
        coredataref = "url:#{N1Data::putBlob(url)}"
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTask",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "boarduuid"   => nil,
            "position"    => NxTasksPositions::automaticPositioningAtNoBoard(50),
            "engine"      => TxEngines::defaultEngine(nil),
        }
        N3Objects::commit(item)
        item
    end

    # NxTasks::bufferInImport(location)
    def self.bufferInImport(location)
        description = File.basename(location)
        uuid = SecureRandom.uuid
        nhash = AionCore::commitLocationReturnHash(N1DataElizabeth.new(), location)
        coredataref = "aion-point:#{nhash}"
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTask",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "boarduuid"   => nil,
            "position"    => NxTasksPositions::automaticPositioningAtNoBoard(50),
            "engine"      => TxEngines::defaultEngine(nil),
        }
        N3Objects::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxTasks::toString(item)
    def self.toString(item)
        "(task) (#{item["position"].round(2)}) #{item["description"]} #{TxEngines::toString(item["engine"])}"
    end

    # NxTasks::toStringNoEngine(item)
    def self.toStringNoEngine(item)
        "(task) (#{item["position"].round(2)}) #{item["description"]}"
    end

    # NxTasks::completionRatio(item)
    def self.completionRatio(item)
        TxEngines::completionRatio(item["engine"]) 
    end

    # NxTasks::performance()
    def self.performance()
        (-6..0)
            .map{|i| Bank::getValueAtDate("34c37c3e-d9b8-41c7-a122-ddd1cb85ddbc", CommonUtils::nDaysInTheFuture(i))}
            .inject(0, :+)
            .to_f/3600
    end

    # NxTasks::boardlessItems()
    def self.boardlessItems()
        NxTasks::items()
            .select{|item| item["boarduuid"].nil? }
    end

    # NxTasks::boardItems(board)
    def self.boardItems(board)
        NxTasks::items()
            .select{|item| item["boarduuid"] == board["uuid"] }
            .sort_by{|item| item["position"] }
    end

    # --------------------------------------------------
    # Data: NxMonitor1

    # NxTasks::monitor1()
    def self.monitor1()
        getEngine = lambda {
            engine = XCache::getOrNull("7f0e6638-e60b-49fe-b707-14a3a2d12ea8")
            if engine.nil? then
                engine = {
                    "uuid"          => "b35be246-2237-4bf4-ae0d-0c6794350f8e",
                    "type"          => "weekly-time",
                    "hours"         => 10,
                    "lastResetTime" => 0,
                    "capsule"       => "1cbf5a45-bc37-47af-a165-290e3f45d675"
                }
                XCache::set("7f0e6638-e60b-49fe-b707-14a3a2d12ea8", JSON.generate(engine))
                engine
            else
                JSON.parse(engine)
            end
        }

        engine = getEngine.call()
        engine2 = TxEngines::engineMaintenance("NxTasks (boardless)", engine)
        if engine2 then
            engine = engine2
            XCache::set("7f0e6638-e60b-49fe-b707-14a3a2d12ea8", JSON.generate(engine))
        end

        [
            {
                "uuid" => "bea0e9c7-f609-47e7-beea-70e433e0c82e",
                "mikuType" => "NxMonitor1",
                "description" => "NxTasks (boardless)",
                "lambda" => lambda {
                    NxTasks::program1()
                },
                "engine" => engine
            }
        ]
    end

    # NxTasks::monitor1ToString(item)
    def self.monitor1ToString(item)
        "NxTasks (boardless) #{TxEngines::toString(item["engine"])}"
    end

    # --------------------------------------------------
    # Operations

    # NxTasks::access(item)
    def self.access(item)
        CoreData::access(item["field11"])
    end

    # NxTasks::program1()
    def self.program1()
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

            Listing::listingCommandInterpreter(input, store, nil)
        }
    end

    # NxTasks::recoordinates(item)
    def self.recoordinates(item)
        board    = NxBoards::interactivelySelectOneBoardOrNull()
        position = NxTasksPositions::decidePositionAtOptionalBoard(board)
        engine   = TxEngines::interactivelyMakeEngineOrDefault()
        item["boarduuid"] = board ? board["uuid"] : nil
        item["position"]  = position
        item["engine"]    = engine
        item
    end
end
