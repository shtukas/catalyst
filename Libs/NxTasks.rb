

class NxTasks

    # --------------------------------------------------
    # Makers

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

    # NxTasks::toString(item)
    def self.toString(item)
        "🔹#{TxStacks::positionsuffix(item)} #{item["description"]}#{CoreData::itemToSuffixString(item)}#{NxEngines::suffix(item)}#{NxDeadlines::suffix(item)}"
    end

    # --------------------------------------------------
    # Operations

    # NxTasks::access(task)
    def self.access(task)
        CoreData::access(task["uuid"], task["field11"])
    end
end
