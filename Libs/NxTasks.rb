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

        Blades::init("NxTask", uuid)

        item = {}
        item["uuid"] = uuid
        item["mikuType"] = "NxTask"
        item["unixtime"] = Time.new.to_i
        item["datetime"] = Time.new.utc.iso8601
        item["description"] = description
        item["field11"] = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)

        board    = NxBoards::interactivelySelectOneOrNull()
        position = NxTasksPositions::decidePositionAtOptionalBoard(board)
        engine   = TxEngines::interactivelyMakeEngineOrDefault()

        item["boarduuid"] = board ? board["uuid"] : nil
        item["position"]  = position
        item["engine"]    = engine

        BladeAdaptation::commitItem(item)
        item
    end

    # NxTasks::netflix(title)
    def self.netflix(title)
        uuid  = SecureRandom.uuid
        Blades::init("NxTask", uuid)
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
        BladeAdaptation::commitItem(item)
        item
    end

    # NxTasks::viennaUrl(url)
    def self.viennaUrl(url)
        description = "(vienna) #{url}"
        uuid  = SecureRandom.uuid
        Blades::init("NxTask", uuid)
        nhash = Blades::putDatablob2(uuid, url)
        coredataref = "url:#{nhash}"
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
        BladeAdaptation::commitItem(item)
        item
    end

    # NxTasks::bufferInImport(location)
    def self.bufferInImport(location)
        description = File.basename(location)
        uuid = SecureRandom.uuid
        Blades::init("NxTask", uuid)
        nhash = AionCore::commitLocationReturnHash(BladeElizabeth.new(uuid), location)
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
        BladeAdaptation::commitItem(item)
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
