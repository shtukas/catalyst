

class NxTasks

    # --------------------------------------------------
    # Makers

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        uuid = SecureRandom.uuid
        DataCenter::itemInit(uuid, "NxTask")

        coredataref = CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(uuid)

        DataCenter::setAttribute(uuid, "unixtime", Time.new.to_i)
        DataCenter::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        DataCenter::setAttribute(uuid, "description", description)
        DataCenter::setAttribute(uuid, "field11", coredataref)

        DataCenter::itemOrNull(uuid)
    end

    # NxTasks::urlToTask(url)
    def self.urlToTask(url)
        description = "(vienna) #{url}"
        uuid = SecureRandom.uuid

        DataCenter::itemInit(uuid, "NxTask")

        nhash = Cubes::putBlob(uuid, url)
        coredataref = "url:#{nhash}"

        DataCenter::setAttribute(uuid, "unixtime", Time.new.to_i)
        DataCenter::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        DataCenter::setAttribute(uuid, "description", description)
        DataCenter::setAttribute(uuid, "field11", coredataref)

        DataCenter::itemOrNull(uuid)
    end

    # NxTasks::bufferInLocationToTask(location)
    def self.bufferInLocationToTask(location)
        description = "(buffer-in) #{File.basename(location)}"
        uuid = SecureRandom.uuid

        DataCenter::itemInit(uuid, "NxTask")

        coredataref = CoreDataRefStrings::locationToAionPointCoreDataReference(uuid, location)

        DataCenter::setAttribute(uuid, "unixtime", Time.new.to_i)
        DataCenter::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        DataCenter::setAttribute(uuid, "description", description)
        DataCenter::setAttribute(uuid, "field11", coredataref)

        DataCenter::itemOrNull(uuid)
    end

    # NxTasks::descriptionToTask1(uuid, description)
    def self.descriptionToTask1(uuid, description)
        DataCenter::itemInit(uuid, "NxTask")
        DataCenter::setAttribute(uuid, "unixtime", Time.new.to_i)
        DataCenter::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        DataCenter::setAttribute(uuid, "description", description)

        DataCenter::itemOrNull(uuid)
    end

    # --------------------------------------------------
    # Data

    # NxTasks::toString(item)
    def self.toString(item)
        icon = (lambda {|item|
            if NxTasks::isOrphan(item) then
                return "◽️"
            end
            "🔹"
        }).call(item)
        "#{icon} #{item["description"]}#{CoreDataRefStrings::itemToSuffixString(item)}"
    end

    # NxTasks::engined()
    def self.engined()
        DataCenter::mikuType("NxTask")
            .select{|item| TxCores::extractActiveCoreOrNull(item) }
    end

    # NxTasks::isOrphan(item)
    def self.isOrphan(item)
        item["stackuuid"].nil? or DataCenter::itemOrNull(item["stackuuid"]).nil?
    end

    # --------------------------------------------------
    # Operations

    # NxTasks::access(task)
    def self.access(task)
        CoreDataRefStrings::accessAndMaybeEdit(task["uuid"], task["field11"])
    end

    # NxTasks::fsck()
    def self.fsck()
        DataCenter::mikuType("NxTask").each{|item|
            CoreDataRefStrings::fsck(item)
        }
    end
end
