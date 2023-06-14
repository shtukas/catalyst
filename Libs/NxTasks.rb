

class NxTasks

    # --------------------------------------------------
    # Makers

    # NxTasks::coreFreePositions()
    def self.coreFreePositions()
        DarkEnergy::mikuType("NxTask")
            .select{|task| task["sequenceuuid"].nil? }
            .map{|task| task["position"] || 0 }
    end

    # NxTasks::interactivelyMakeOrNull()
    def self.interactivelyMakeOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        uuid = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull()

        {
            "uuid"        => uuid,
            "mikuType"    => "NxTask",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref

        }
    end

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        # We need to create the blade before we call CoreData::interactivelyMakeNewReferenceStringOrNull
        # because the blade need to exist for aion points data blobs to have a place to go.

        uuid = SecureRandom.uuid
        DarkEnergy::init("NxTask", uuid)

        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull()

        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "field11", coredataref)

        DarkEnergy::itemOrNull(uuid)
    end

    # NxTasks::viennaUrl(url)
    def self.viennaUrl(url)
        description = "(vienna) #{url}"
        uuid = SecureRandom.uuid

        DarkEnergy::init("NxTask", uuid)

        nhash = DarkMatter::putBlob(url)
        coredataref = "url:#{nhash}"

        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "field11", coredataref)
        DarkEnergy::itemOrNull(uuid)
    end

    # --------------------------------------------------
    # Data

    # NxTasks::getItemPositionOrNull(item)
    def self.getItemPositionOrNull(item)
        parent = Parenting::getParentOrNull(item)
        return nil if parent.nil?
        Parenting::getPositionOrNull(parent, item)
    end

    # NxTasks::toString(item, positionDisplayStyle)
    def self.toString(item, positionDisplayStyle = "stack")
        "🔹#{Parenting::positionSuffix(item, positionDisplayStyle)} #{item["description"]}#{CoreData::itemToSuffixString(item)}"
    end

    # --------------------------------------------------
    # Operations

    # NxTasks::access(task)
    def self.access(task)
        CoreData::access(task["uuid"], task["field11"])
    end
end
