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
            "position"    => NxTasksPositions::computeThatPositionAtNoBoard(),
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
            "position"    => NxTasksPositions::computeThatPositionAtNoBoard(),
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
            "position"    => NxTasksPositions::computeThatPositionAtNoBoard(),
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

    # NxTasks::completionRatio(item)
    def self.completionRatio(item)
        TxEngines::completionRatio(item["engine"]) 
    end

    # NxTasks::performance()
    def self.performance()
        (-6..0)
            .map{|i| BankCore::getValueAtDate("34c37c3e-d9b8-41c7-a122-ddd1cb85ddbc", CommonUtils::nDaysInTheFuture(i))}
            .inject(0, :+)
            .to_f/3600
    end

    # NxTasks::boardlessItems()
    def self.boardlessItems()
        NxTasks::items()
            .select{|item| item["boarduuid"].nil? }
    end

    # --------------------------------------------------
    # Data (Position)

    # NxTasks::firstPosition()
    def self.firstPosition()
        items = NxTasks::items()
        return 1 if items.empty?
        items.map{|item| item["position"]}.min
    end

    # NxTasks::lastPosition()
    def self.lastPosition()
        items = NxTasks::items()
        return 1 if items.empty?
        items.map{|item| item["position"]}.max
    end

    # --------------------------------------------------
    # Operations

    # NxTasks::access(item)
    def self.access(item)
        CoreData::access(item["field11"])
    end
end
