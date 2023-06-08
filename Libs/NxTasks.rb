

class NxTasks

    # --------------------------------------------------
    # Makers

    # NxTasks::cliquelessPositions()
    def self.cliquelessPositions()
        Solingen::mikuTypeItems("NxTask")
            .select{|task| task["cliqueuuid"].nil? }
            .map{|task| task["position"] }
    end

    # NxTasks::coordinates()
    def self.coordinates()
        cliqueuuid = nil
        position = nil

        clique = TxCliques::interactivelySelectCliqueOrNull()
        if clique then
            cliqueuuid = clique["uuid"]
            position = TxCliques::interactivelySelectPositionInClique(clique)
        else
            position = CommonUtils::computeThatPosition(NxTasks::cliquelessPositions())
        end

        [cliqueuuid, position]
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

        cliqueuuid, position = NxTasks::coordinates()

        Solingen::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Solingen::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Solingen::setAttribute2(uuid, "description", description)
        Solingen::setAttribute2(uuid, "field11", coredataref)
        Solingen::setAttribute2(uuid, "position", position)
        Solingen::setAttribute2(uuid, "cliqueuuid", cliqueuuid)
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

        position = CommonUtils::computeThatPosition(NxTasks::cliquelessPositions())

        Solingen::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Solingen::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Solingen::setAttribute2(uuid, "description", description)
        Solingen::setAttribute2(uuid, "field11", coredataref)
        Solingen::setAttribute2(uuid, "position", position)
        Solingen::setAttribute2(uuid, "mikuType", "NxTask")
        Solingen::getItemOrNull(uuid)
    end

    # NxTasks::lineToCliqueTask(line, cliqueuuid, position)
    def self.lineToCliqueTask(line, cliqueuuid, position)
        uuid = SecureRandom.uuid
        description = line
        Solingen::init("NxPure", uuid)
        Solingen::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Solingen::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Solingen::setAttribute2(uuid, "description", description)
        Solingen::setAttribute2(uuid, "cliqueuuid", cliqueuuid)
        Solingen::setAttribute2(uuid, "position", position)
        Solingen::setAttribute2(uuid, "mikuType", "NxTask")
        Solingen::getItemOrNull(uuid)
    end

    # --------------------------------------------------
    # Data

    # NxTasks::toString(item)
    def self.toString(item)
        if item["cliqueuuid"] then
            clique = Solingen::getItemOrNull(item["cliqueuuid"])
            if clique.nil? then
                Solingen::setAttribute2(item["uuid"], "cliqueuuid", nil)
                return NxTasks::toString(item)
            end
            "🫧 (#{"%5.2f" % item["position"]}) #{item["description"]} (#{clique["description"]})"
        else
            "👨🏻‍💻 #{item["description"]}"
        end
    end

    # --------------------------------------------------
    # Operations

    # NxTasks::access(item)
    def self.access(item)
        CoreData::access(item["uuid"], item["field11"])
    end
end
