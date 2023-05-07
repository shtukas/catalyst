# encoding: UTF-8

class NxTasks

    # NxTasks::items()
    def self.items()
        BladeAdaptation::mikuTypeItems("NxTask")
    end

    # NxTasks::getItemOfNull(uuid)
    def self.getItemOfNull(uuid)
        BladeAdaptation::getItemOrNull(uuid)
    end

    # NxTasks::destroy(uuid)
    def self.destroy(uuid)
        Blades::destroy(uuid)
    end

    # --------------------------------------------------
    # Makers

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        uuid = SecureRandom.uuid

        Blades::init("NxPure", uuid)

        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        board    = NxBoards::interactivelySelectOneOrNull()
        position = NxTasksPositions::decidePositionAtOptionalBoard(board)
        engine   = TxEngines::interactivelyMakeEngineOrDefault()

        boarduuid = board ? board["uuid"] : nil

        Blades::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Blades::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Blades::setAttribute2(uuid, "description", description)
        Blades::setAttribute2(uuid, "field11", coredataref)
        Blades::setAttribute2(uuid, "boarduuid", boarduuid)
        Blades::setAttribute2(uuid, "position", position)
        Blades::setAttribute2(uuid, "engine", engine)

        Blades::setAttribute2(uuid, "mikuType", "NxTask")

        BladeAdaptation::getItemOrNull(uuid)
    end

    # NxTasks::netflix(title)
    def self.netflix(title)
        description = "Watch '#{title}' on Netflix"
        uuid = SecureRandom.uuid

        Blades::init("NxPure", uuid)

        nhash = Blades::putDatablob2(uuid, url)
        coredataref = "url:#{nhash}"
        position = NxTasksPositions::automaticPositioningAtNoBoard(50)

        Blades::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Blades::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Blades::setAttribute2(uuid, "description", description)
        Blades::setAttribute2(uuid, "field11", coredataref)
        Blades::setAttribute2(uuid, "boarduuid", nil)
        Blades::setAttribute2(uuid, "position", position)
        Blades::setAttribute2(uuid, "engine", TxEngines::defaultEngine(nil))

        Blades::setAttribute2(uuid, "mikuType", "NxTask")

        BladeAdaptation::getItemOrNull(uuid)
    end

    # NxTasks::viennaUrl(url)
    def self.viennaUrl(url)
        description = "(vienna) #{url}"
        uuid = SecureRandom.uuid

        Blades::init("NxPure", uuid)

        nhash = Blades::putDatablob2(uuid, url)
        coredataref = "url:#{nhash}"
        position = NxTasksPositions::automaticPositioningAtNoBoard(50)

        Blades::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Blades::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Blades::setAttribute2(uuid, "description", description)
        Blades::setAttribute2(uuid, "field11", coredataref)
        Blades::setAttribute2(uuid, "boarduuid", nil)
        Blades::setAttribute2(uuid, "position", position)
        Blades::setAttribute2(uuid, "engine", TxEngines::defaultEngine(nil))

        Blades::setAttribute2(uuid, "mikuType", "NxTask")

        BladeAdaptation::getItemOrNull(uuid)
    end

    # NxTasks::bufferInImport(location)
    def self.bufferInImport(location)
        description = File.basename(location)
        uuid = SecureRandom.uuid

        Blades::init("NxPure", uuid)

        nhash = AionCore::commitLocationReturnHash(BladeElizabeth.new(uuid), location)
        coredataref = "aion-point:#{nhash}"
        position = NxTasksPositions::automaticPositioningAtNoBoard(50)

        Blades::init("NxTask", uuid)
        Blades::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Blades::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Blades::setAttribute2(uuid, "description", description)
        Blades::setAttribute2(uuid, "field11", coredataref)
        Blades::setAttribute2(uuid, "boarduuid", nil)
        Blades::setAttribute2(uuid, "position", position)
        Blades::setAttribute2(uuid, "engine", TxEngines::defaultEngine(nil))

        Blades::setAttribute2(uuid, "mikuType", "NxTask")

        BladeAdaptation::getItemOrNull(uuid)
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

    # --------------------------------------------------
    # Operations

    # NxTasks::access(item)
    def self.access(item)
        CoreData::access(item["uuid"], item["field11"])
    end

    # NxTasks::recoordinates(item)
    def self.recoordinates(item)
        board    = NxBoards::interactivelySelectOneOrNull()
        position = NxTasksPositions::decidePositionAtOptionalBoard(board)
        engine   = TxEngines::interactivelyMakeEngineOrDefault()
        item["boarduuid"] = board ? board["uuid"] : nil
        item["position"]  = position
        item["engine"]    = engine
        item
    end
end
