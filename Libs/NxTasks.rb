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

        Solingen::init("NxPure", uuid)

        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        board    = NxBoards::interactivelySelectOneOrNull()
        position = NxTasksPositions::decidePositionAtOptionalBoard(board)
        engine   = TxEngines::interactivelyMakeEngineOrDefault()

        boarduuid = board ? board["uuid"] : nil

        Solingen::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Solingen::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Solingen::setAttribute2(uuid, "description", description)
        Solingen::setAttribute2(uuid, "field11", coredataref)
        Solingen::setAttribute2(uuid, "boarduuid", boarduuid)
        Solingen::setAttribute2(uuid, "position", position)
        Solingen::setAttribute2(uuid, "engine", engine)

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
        Solingen::setAttribute2(uuid, "engine", TxEngines::defaultEngine(nil))

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
        Solingen::setAttribute2(uuid, "engine", TxEngines::defaultEngine(nil))

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

        Solingen::init("NxTask", uuid)
        Solingen::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Solingen::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Solingen::setAttribute2(uuid, "description", description)
        Solingen::setAttribute2(uuid, "field11", coredataref)
        Solingen::setAttribute2(uuid, "boarduuid", nil)
        Solingen::setAttribute2(uuid, "position", position)
        Solingen::setAttribute2(uuid, "engine", TxEngines::defaultEngine(nil))

        Solingen::setAttribute2(uuid, "mikuType", "NxTask")

        Solingen::getItemOrNull(uuid)
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
end
