

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
        "🔹#{TxEngines::string1(item)} #{item["description"]}#{CoreDataRefStrings::itemToSuffixString(item)}"
    end

    # NxTasks::unattached()
    def self.unattached()
        DataCenter::mikuType("NxTask")
            .select{|item| item["coreX-2137"].nil? }
            .select{|item| item["engine-0916"].nil? }
    end

    # NxTasks::unattachedForListing()
    def self.unattachedForListing()
        $DataCenterListingItems
            .values
            .select{|item| item["mikuType"] == "NxTask" }
            .select{|item| item["coreX-2137"].nil? }
            .select{|item| item["engine-0916"].nil? }
    end

    # --------------------------------------------------
    # Operations

    # NxTasks::access(task)
    def self.access(task)
        CoreDataRefStrings::accessAndMaybeEdit(task["uuid"], task["field11"])
    end

    # NxTasks::maintenance()
    def self.maintenance()

        DataCenter::mikuType("NxTask")
            .each{|item|
                next if item["coreX-2137"].nil?
                core = DataCenter::itemOrNull(item["coreX-2137"])
                if core.nil? or (core["mikuType"] != "TxCore") then
                    DataCenter::setAttribute(item["uuid"], "coreX-2137", nil)
                end
            }

        # Feed Infinity using NxIce
        if DataCenter::mikuType("NxTask").size < 100 then
            DataCenter::mikuType("NxIce").take(10).each{|item|

            }
        end
    end

    # NxTasks::fsck()
    def self.fsck()
        DataCenter::mikuType("NxTask").each{|item|
            CoreDataRefStrings::fsck(item)
        }
    end

    # NxTasks::setTaskMode(item)
    def self.setTaskMode(item)
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["core", "engine", "ondate"])
        return if option.nil?
        if option == "core" then
            core = TxCores::interactivelySelectOneOrNull()
            if core then
                DataCenter::setAttribute(item["uuid"], "coreX-2137", core["uuid"])
            end
        end
        if option == "engine" then
            engine = TxEngines::interactivelyMakeNewOrNull()
            if engine then
                DataCenter::setAttribute(item["uuid"], "engine-0916", engine)
            end
        end
        if option == "ondate" then
            datetime = CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode()
            DataCenter::setAttribute(item["uuid"], "datetime", datetime)
            DataCenter::setAttribute(item["uuid"], "mikuType", "NxOndate")
        end
    end
end
