

class NxTasks

    # --------------------------------------------------
    # Makers

    # NxTasks::orbitalFreePositions()
    def self.orbitalFreePositions()
        DarkEnergy::mikuType("NxTask")
            .select{|task| task["sequenceuuid"].nil? }
            .map{|task| task["position"] }
    end

    # NxTasks::coordinates()
    def self.coordinates()
        sequenceuuid = nil
        position = nil

        clique = NxSequences::interactivelySelectOneOrNull()
        if clique then
            sequenceuuid = clique["uuid"]
            position = NxSequences::interactivelySelectTaskPositionInOrbital(clique)
        else
            position = CommonUtils::computeThatPosition(NxTasks::orbitalFreePositions().sort.first(100))
        end

        [sequenceuuid, position]
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

        sequenceuuid, position = NxTasks::coordinates()

        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "field11", coredataref)
        DarkEnergy::patch(uuid, "position", position)
        DarkEnergy::patch(uuid, "sequenceuuid", sequenceuuid)
        DarkEnergy::patch(uuid, "mikuType", "NxTask")

        DarkEnergy::itemOrNull(uuid)
    end

    # NxTasks::viennaUrl(url)
    def self.viennaUrl(url)
        description = "(vienna) #{url}"
        uuid = SecureRandom.uuid

        DarkEnergy::init("NxPure", uuid)

        nhash = DarkMatter::putBlob(url)
        coredataref = "url:#{nhash}"

        position = CommonUtils::computeThatPosition(NxTasks::orbitalFreePositions())

        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "field11", coredataref)
        DarkEnergy::patch(uuid, "position", position)
        DarkEnergy::patch(uuid, "mikuType", "NxTask")

        engine = TxEngines::makeEngine(SecureRandom.hex, uuid, Time.new.to_i, 1, 30)
        DarkEnergy::commit(engine)
        DarkEnergy::patch(item["uuid"], "engineuuid", engine["uuid"])

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
        "👨🏻‍💻 (#{"%5.2f" % item["position"]}) #{item["description"]}"
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

    # NxTasks::setDriverAttempt(item) # boolean
    def self.setDriverAttempt(item)
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["core", "sequence", "engine"])
        return false if option.nil?
        if option == "core" then
            core = NxCores::interactivelySelectOneOrNull()
            return false if core.nil?
            DarkEnergy::patch(item["uuid"], "coreuuid", core["uuid"])
            return true
        end
        if option == "sequence" then
            sequence = NxSequences::interactivelySelectOneOrNull()
            return false if sequence.nil?
            DarkEnergy::patch(item["uuid"], "sequenceuuid", sequence["uuid"])
            return true
        end
        if option == "engine" then
            return TxEngines::interactivelyEngineSpawnAttempt(item)
        end
    end

    # NxTasks::program(task)
    def self.program(task)
        PolyActions::doubleDot(task)
    end
end
