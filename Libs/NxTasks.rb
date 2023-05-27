

class NxTasks

    # --------------------------------------------------
    # Makers

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        # We need to create the blade before we call CoreData::interactivelyMakeNewReferenceStringOrNull
        # because the blade need to exist for aion points data blobs to have a place to go.

        # We also cannot give to the blade a NxTask type because position resolution
        # will find an item without a position in the collection, which is going 
        # to break sorting. There for we create a NxPure and we will recast as 
        # NxTask later.

        uuid = SecureRandom.uuid
        Solingen::init("NxPure", uuid)

        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        thread, position = NxThreads::interactivelyDecideCoordinates("NxTask")

        Solingen::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Solingen::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Solingen::setAttribute2(uuid, "description", description)
        Solingen::setAttribute2(uuid, "field11", coredataref)
        Solingen::setAttribute2(uuid, "parentuuid", thread["uuid"])
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

        thread, position = NxThreads::coordinatesForVienna()

        Solingen::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Solingen::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Solingen::setAttribute2(uuid, "description", description)
        Solingen::setAttribute2(uuid, "field11", coredataref)
        Solingen::setAttribute2(uuid, "parentuuid", thread["uuid"])
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

        thread, position = NxThreads::coordinatesForNxTasksBufferIn()

        Solingen::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Solingen::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Solingen::setAttribute2(uuid, "description", description)
        Solingen::setAttribute2(uuid, "field11", coredataref)
        Solingen::setAttribute2(uuid, "parentuuid", thread["uuid"])
        Solingen::setAttribute2(uuid, "position", position)
        Solingen::setAttribute2(uuid, "mikuType", "NxTask")
        Solingen::getItemOrNull(uuid)
    end

    # NxTasks::interactivelyIssueNewTaskAtThreadOrNull(thread)
    def self.interactivelyIssueNewTaskAtThreadOrNull(thread)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        # We need to create the blade before we call CoreData::interactivelyMakeNewReferenceStringOrNull
        # because the blade need to exist for aion points data blobs to have a place to go.

        # We also cannot give to the blade a NxTask type because position resolution
        # will find an item without a position in the collection, which is going 
        # to break sorting. There for we create a NxPure and we will recast as 
        # NxTask later.

        uuid = SecureRandom.uuid
        Solingen::init("NxPure", uuid)

        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        position = LucilleCore::askQuestionAnswerAsString("position: ").to_f

        Solingen::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Solingen::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Solingen::setAttribute2(uuid, "description", description)
        Solingen::setAttribute2(uuid, "field11", coredataref)
        Solingen::setAttribute2(uuid, "parentuuid", thread["uuid"])
        Solingen::setAttribute2(uuid, "position", position)
        Solingen::setAttribute2(uuid, "mikuType", "NxTask")

        Solingen::getItemOrNull(uuid)
    end

    # --------------------------------------------------
    # Data

    # NxTasks::toString(item)
    def self.toString(item)
        "(task) (#{"%5.2f" % item["position"]}) #{item["description"]}"
    end

    # NxTasks::runningTasks()
    def self.runningTasks()

    end

    # --------------------------------------------------
    # Operations

    # NxTasks::access(item)
    def self.access(item)
        CoreData::access(item["uuid"], item["field11"])
    end
end
