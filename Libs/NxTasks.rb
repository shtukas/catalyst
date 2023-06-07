

class NxTasks

    # --------------------------------------------------
    # Makers

    # NxTasks::coordinates()
    def self.coordinates()
        engineuuid = TxEngines::interactivelySelectOneUUIDOrNull()
        engine =
            if engineuuid then
                engine = Solingen::getItemOrNull(engineuuid)
            else
                nil
            end

        clique = 
            if engine then
                TxCliques::architectCliqueInEngine(engine)
            else
                TxCliques::cliquesWithoutEngine()
            end

        position = TxCliques::interactivelySelectPositionInClique(clique)
        [engineuuid, clique, position]
    end

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        # We need to create the blade before we call CoreData::interactivelyMakeNewReferenceStringOrNull
        # because the blade need to exist for aion points data blobs to have a place to go.

        uuid = SecureRandom.uuid
        Solingen::init("NxPure", uuid)

        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)

        engineuuid, clique, position = NxTasks::coordinates()

        Solingen::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Solingen::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Solingen::setAttribute2(uuid, "description", description)
        Solingen::setAttribute2(uuid, "field11", coredataref)
        Solingen::setAttribute2(uuid, "engineuuid", engineuuid)
        Solingen::setAttribute2(uuid, "cliqueuuid", clique["uuid"])
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
        clique = TxCliques::cliqueForNewItemAtNoEngine()
        position = TxCliques::cliqueToNewLastPosition(clique)

        Solingen::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Solingen::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Solingen::setAttribute2(uuid, "description", description)
        Solingen::setAttribute2(uuid, "field11", coredataref)
        Solingen::setAttribute2(uuid, "cliqueuuid", clique["uuid"])
        Solingen::setAttribute2(uuid, "position", position)
        Solingen::setAttribute2(uuid, "mikuType", "NxTask")
        Solingen::getItemOrNull(uuid)
    end

    # NxTasks::lineToCliqueTask(line, engineuuid, cliqueuuid, position)
    def self.lineToCliqueTask(line, engineuuid, cliqueuuid, position)
        uuid = SecureRandom.uuid
        description = line
        Solingen::init("NxPure", uuid)
        Solingen::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Solingen::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Solingen::setAttribute2(uuid, "description", description)
        Solingen::setAttribute2(uuid, "engineuuid", engineuuid)
        Solingen::setAttribute2(uuid, "cliqueuuid", cliqueuuid)
        Solingen::setAttribute2(uuid, "position", position)
        Solingen::setAttribute2(uuid, "mikuType", "NxTask")
        Solingen::getItemOrNull(uuid)
    end

    # --------------------------------------------------
    # Data

    # NxTasks::toString(item)
    def self.toString(item)
        " 👩🏻‍💻  (#{"%5.2f" % item["position"]}) #{item["description"]}"
    end

    # --------------------------------------------------
    # Operations

    # NxTasks::access(item)
    def self.access(item)
        CoreData::access(item["uuid"], item["field11"])
    end

    # NxTasks::setCliqueAndPositionAtEngine(engine, task)
    def self.setCliqueAndPositionAtEngine(engine, task)
        clique = TxCliques::architectCliqueInEngine(engine)
        position = TxCliques::interactivelySelectPositionInClique(clique)
        Solingen::setAttribute2(task["uuid"], "cliqueuuid", clique["uuid"])
        Solingen::setAttribute2(task["uuid"], "position", position)
    end
end
