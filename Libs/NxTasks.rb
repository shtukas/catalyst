

class NxTasks

    # --------------------------------------------------
    # Makers

    # NxTasks::coreFreePositions()
    def self.coreFreePositions()
        DarkEnergy::mikuType("NxTask")
            .select{|task| task["sequenceuuid"].nil? }
            .map{|task| task["position"] || 0 }
    end

    # NxTasks::coordinates(item or null)
    def self.coordinates(item)
        core = 
            if item then
                if item["coreuuid"] then
                    DarkEnergy::itemOrNull(item["coreuuid"])
                else
                    NxCores::interactivelySelectOneOrNull()
                end
            else
                 NxCores::interactivelySelectOneOrNull()
            end

        if core then
            position = NxCores::firstPositionInCore(core)
        else
            position = CommonUtils::computeThatPosition(NxTasks::coreFreePositions().sort.first(100))
        end

        [core ? core["uuid"] : nil, position]
    end

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        # We need to create the blade before we call CoreData::interactivelyMakeNewReferenceStringOrNull
        # because the blade need to exist for aion points data blobs to have a place to go.

        uuid = SecureRandom.uuid
        DarkEnergy::init("NxPure", uuid)

        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull()

        coreuuid, position = NxTasks::coordinates(nil)

        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "field11", coredataref)
        DarkEnergy::patch(uuid, "coreuuid", coreuuid)
        DarkEnergy::patch(uuid, "position", position)
        DarkEnergy::patch(uuid, "mikuType", "NxTask")

        item = DarkEnergy::itemOrNull(uuid)
        if LucilleCore::askQuestionAnswerAsBoolean("set engine ? ") then
            item = TxEngines::setItemEngine(item)
        end
        item
    end

    # NxTasks::viennaUrl(url)
    def self.viennaUrl(url)
        description = "(vienna) #{url}"
        uuid = SecureRandom.uuid

        DarkEnergy::init("NxPure", uuid)

        nhash = DarkMatter::putBlob(url)
        coredataref = "url:#{nhash}"

        position = CommonUtils::computeThatPosition(NxTasks::coreFreePositions())
        engine = TxEngines::makeEngine(1, 30)

        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "field11", coredataref)
        DarkEnergy::patch(uuid, "position", position)
        DarkEnergy::patch(uuid, "engine", engine)
        DarkEnergy::patch(uuid, "mikuType", "NxTask")
        DarkEnergy::itemOrNull(uuid)
    end

    # NxTasks::lineToOrbitalTask(line, sequenceuuid, position)
    def self.lineToOrbitalTask(line, sequenceuuid, position)
        uuid = SecureRandom.uuid
        description = line
        DarkEnergy::init("NxPure", uuid)
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "sequenceuuid", sequenceuuid)
        DarkEnergy::patch(uuid, "position", position)
        DarkEnergy::patch(uuid, "mikuType", "NxTask")
        DarkEnergy::itemOrNull(uuid)
    end

    # --------------------------------------------------
    # Data

    # NxTasks::toString(item)
    def self.toString(item)
        "👨🏻‍💻 (#{"%5.2f" % (item["position"] || 0)}) #{item["description"]}"
    end

    # NxTasks::listingItems()
    def self.listingItems()
        DarkEnergy::mikuType("NxTask").first(1000)
    end

    # --------------------------------------------------
    # Operations

    # NxTasks::access(item)
    def self.access(item)
        CoreData::access(item["uuid"], item["field11"])
    end

    # NxTasks::program(task)
    def self.program(task)
        PolyActions::doubleDot(task)
    end

    # NxTasks::maintenance()
    def self.maintenance()
        DarkEnergy::mikuType("NxTask").each{|task|
            next if task["coreuuid"].nil?
            core = DarkEnergy::itemOrNull(task["coreuuid"])
            if core.nil? then
                DarkEnergy::patch(task["uuid"], "coreuuid", nil)
            end
        }
    end
end
