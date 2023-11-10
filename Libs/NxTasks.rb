

class NxTasks

    # --------------------------------------------------
    # Makers

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        uuid = SecureRandom.uuid
        Updates::itemInit(uuid, "NxTask")

        coredataref = CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(uuid)

        Updates::itemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Updates::itemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Updates::itemAttributeUpdate(uuid, "description", description)
        Updates::itemAttributeUpdate(uuid, "field11", coredataref)

        Broadcasts::publishItem(uuid)
        Catalyst::itemOrNull(uuid)
    end

    # NxTasks::urlToTask(url)
    def self.urlToTask(url)
        description = "(vienna) #{url}"
        uuid = SecureRandom.uuid

        Updates::itemInit(uuid, "NxTask")

        nhash = Datablobs::putBlob(url)
        coredataref = "url:#{nhash}"

        Updates::itemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Updates::itemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Updates::itemAttributeUpdate(uuid, "description", description)
        Updates::itemAttributeUpdate(uuid, "field11", coredataref)

        Broadcasts::publishItem(uuid)
        Catalyst::itemOrNull(uuid)
    end

    # NxTasks::bufferInLocationToTask(location)
    def self.bufferInLocationToTask(location)
        description = "(buffer-in) #{File.basename(location)}"
        uuid = SecureRandom.uuid

        Updates::itemInit(uuid, "NxTask")

        coredataref = CoreDataRefStrings::locationToAionPointCoreDataReference(uuid, location)

        Updates::itemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Updates::itemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Updates::itemAttributeUpdate(uuid, "description", description)
        Updates::itemAttributeUpdate(uuid, "field11", coredataref)

        Broadcasts::publishItem(uuid)
        Catalyst::itemOrNull(uuid)
    end

    # NxTasks::descriptionToTask1(uuid, description)
    def self.descriptionToTask1(uuid, description)
        Updates::itemInit(uuid, "NxTask")
        Updates::itemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Updates::itemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Updates::itemAttributeUpdate(uuid, "description", description)

        Broadcasts::publishItem(uuid)
        Catalyst::itemOrNull(uuid)
    end

    # --------------------------------------------------
    # Data

    # NxTasks::toString(item)
    def self.toString(item)
        "#{item["active"] ? "🔺" : "🔹"} #{TxEngines::prefix2(item)}#{item["description"]}#{CoreDataRefStrings::itemToSuffixString(item)}"
    end

    # NxTasks::orphans()
    def self.orphans()
        Catalyst::mikuType("NxTask")
            .select{|item| item["parent-1328"].nil? }
            .select{|item| item["engine-0916"].nil? }
            .sort_by{|item| item["unixtime"] }
            .reverse
    end

    # --------------------------------------------------
    # Operations

    # NxTasks::access(task)
    def self.access(task)
        CoreDataRefStrings::accessAndMaybeEdit(task["uuid"], task["field11"])
    end

    # NxTasks::maintenance()
    def self.maintenance()

        # Feed Infinity using NxIce
        if Catalyst::mikuType("NxTask").size < 100 then
            Catalyst::mikuType("NxIce").take(10).each{|item|

            }
        end
    end

    # NxTasks::fsck()
    def self.fsck()
        Catalyst::mikuType("NxTask").each{|item|
            CoreDataRefStrings::fsck(item)
        }
    end
end
