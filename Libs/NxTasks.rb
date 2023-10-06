

class NxTasks

    # --------------------------------------------------
    # Makers

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        # We need to create the blade before we call CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull
        # because the blade need to exist for aion points data blobs to have a place to go.

        uuid = SecureRandom.uuid
        Events::publishItemInit("NxTask", uuid)

        coredataref = CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(uuid)

        Events::publishItemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Events::publishItemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Events::publishItemAttributeUpdate(uuid, "description", description)
        Events::publishItemAttributeUpdate(uuid, "field11", coredataref)
        Events::publishItemAttributeUpdate(uuid, "global-position", Catalyst::newGlobalLastPosition())

        Catalyst::itemOrNull(uuid)
    end

    # NxTasks::urlToTask(url)
    def self.urlToTask(url)
        description = "(vienna) #{url}"
        uuid = SecureRandom.uuid

        Events::publishItemInit("NxTask", uuid)

        nhash = Datablobs::putBlob(url)
        coredataref = "url:#{nhash}"

        Events::publishItemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Events::publishItemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Events::publishItemAttributeUpdate(uuid, "description", description)
        Events::publishItemAttributeUpdate(uuid, "field11", coredataref)
        Catalyst::itemOrNull(uuid)
    end

    # NxTasks::bufferInLocationToTask(location)
    def self.bufferInLocationToTask(location)
        description = "(buffer-in) #{File.basename(location)}"
        uuid = SecureRandom.uuid

        Events::publishItemInit("NxTask", uuid)

        coredataref = CoreDataRefStrings::locationToAionPointCoreDataReference(uuid, location)

        Events::publishItemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Events::publishItemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Events::publishItemAttributeUpdate(uuid, "description", description)
        Events::publishItemAttributeUpdate(uuid, "field11", coredataref)
        Events::publishItemAttributeUpdate(uuid, "global-position", Catalyst::newGlobalLastPosition())
        Catalyst::itemOrNull(uuid)
    end

    # NxTasks::descriptionToTask1(uuid, description)
    def self.descriptionToTask1(uuid, description)
        Events::publishItemInit("NxTask", uuid)
        Events::publishItemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Events::publishItemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Events::publishItemAttributeUpdate(uuid, "description", description)
        Events::publishItemAttributeUpdate(uuid, "global-position", Catalyst::newGlobalLastPosition())
        Catalyst::itemOrNull(uuid)
    end

    # --------------------------------------------------
    # Data

    # NxTasks::suffixIcons(item)
    def self.suffixIcons(item)
        icons = []
        if Catalyst::elementsInOrder(item).size > 0 then
            icons << "📃"
        end
        if item["star-0936"] then
            icons << "⭐️"
        end
        return "" if icons.empty?
        " #{icons.join("")}"
    end 

    # NxTasks::toString(item)
    def self.toString(item)
        icon = "🔹"
        if item["engine-2251"] and item["engine-2251"]["type"] == "active-burner-forefront" then
            icon = "🔺"
        end
        "#{icon} #{TxEngine::prefix(item)}#{item["description"]}#{CoreDataRefStrings::itemToSuffixString(item)}#{TxCores::suffix(item)}#{NxTasks::suffixIcons(item)}"
    end

    # NxTasks::orphans()
    def self.orphans()
        Catalyst::mikuType("NxTask")
            .select{|item| item["coreX-2300"].nil? }
            .select{|item| item["engine-2251"].nil? }
            .select{|item| item["parent-1328"].nil? }
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

        Catalyst::mikuType("NxTask").each{|item|
            if item["coreX-2300"] and Catalyst::itemOrNull(item["coreX-2300"]).nil? then
                Events::publishItemAttributeUpdate(item["uuid"], "coreX-2300", nil)
            end
        }

        Catalyst::mikuType("NxTask").each{|item|
            if item["parent-1328"] and Catalyst::itemOrNull(item["parent-1328"]).nil? then
                Events::publishItemAttributeUpdate(item["uuid"], "parent-1328", nil)
            end
        }

        # Pick up NxFronts-BufferIn
        LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/DataHub/NxFronts-BufferIn").each{|location|
            next if File.basename(location)[0, 1] == "."
            NxTasks::bufferInLocationToTask(location)
            LucilleCore::removeFileSystemLocation(location)
        }

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
