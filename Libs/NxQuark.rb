

class NxQuarks

    # --------------------------------------------------
    # Makers

    # NxQuarks::interactivelyIssueNewOrNull(taskuuid)
    def self.interactivelyIssueNewOrNull(taskuuid)

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        uuid = SecureRandom.uuid
        Events::publishItemInit("NxQuark", uuid)

        coredataref = CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(uuid)

        Events::publishItemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Events::publishItemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Events::publishItemAttributeUpdate(uuid, "description", description)
        Events::publishItemAttributeUpdate(uuid, "field11", coredataref)
        Events::publishItemAttributeUpdate(uuid, "global-position", NxQuarks::newGlobalLastPosition())
        Events::publishItemAttributeUpdate(uuid, "taskuuid", taskuuid)

        Catalyst::itemOrNull(uuid)
    end

    # NxQuarks::descriptionToTask1(taskuuid, description)
    def self.descriptionToTask1(taskuuid, description)
        uuid = SecureRandom.uuid
        Events::publishItemInit("NxQuark", uuid)
        Events::publishItemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Events::publishItemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Events::publishItemAttributeUpdate(uuid, "description", description)
        Events::publishItemAttributeUpdate(uuid, "global-position", NxTasks::newGlobalLastPosition())
        Events::publishItemAttributeUpdate(uuid, "taskuuid", taskuuid)
        Catalyst::itemOrNull(uuid)
    end

    # --------------------------------------------------
    # Data

    # NxQuarks::toString(item)
    def self.toString(item)
        "▪️  #{item["description"]}"
    end

    # NxQuarks::quarksForTaskInOrder(taskuuid)
    def self.quarksForTaskInOrder(taskuuid)
        Catalyst::mikuType("NxQuark")
            .select{|item| item["taskuuid"] == taskuuid }
            .sort_by{|item| item["global-position"] }
    end

    # NxQuarks::newFirstPosition(taskuuid)
    def self.newFirstPosition(taskuuid)
        t = Catalyst::mikuType("NxQuark")
                .select{|item| item["taskuuid"] == taskuuid }
                .map{|item| item["global-position"] }
                .reduce(0){|number, x| [number, x].min}
        t - 1
    end

    # NxQuarks::newLastPosition(taskuuid)
    def self.newLastPosition(taskuuid)
        t = Catalyst::mikuType("NxQuark")
                .select{|item| item["taskuuid"] == taskuuid }
                .map{|item| item["global-position"] }
                .reduce(0){|number, x| [number, x].max }
        t + 1
    end

    # --------------------------------------------------
    # Operations

    # NxQuarks::access(item)
    def self.access(item)
        CoreDataRefStrings::accessAndMaybeEdit(item["uuid"], item["field11"])
    end
end
