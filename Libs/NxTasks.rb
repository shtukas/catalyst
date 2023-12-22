

class NxTasks

    # --------------------------------------------------
    # Makers

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        uuid = SecureRandom.uuid
        Cubes::itemInit(uuid, "NxTask")

        coredataref = CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(uuid)

        Cubes::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes::setAttribute(uuid, "description", description)
        Cubes::setAttribute(uuid, "field11", coredataref)

        CacheWS::emit("mikutype-has-been-modified:NxTask")

        Cubes::itemOrNull(uuid)
    end

    # NxTasks::urlToTask(url)
    def self.urlToTask(url)
        description = "(vienna) #{url}"
        uuid = SecureRandom.uuid

        Cubes::itemInit(uuid, "NxTask")

        nhash = Cubes::putBlob(uuid, url)
        coredataref = "url:#{nhash}"

        Cubes::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes::setAttribute(uuid, "description", description)
        Cubes::setAttribute(uuid, "field11", coredataref)

        CacheWS::emit("mikutype-has-been-modified:NxTask")

        Cubes::itemOrNull(uuid)
    end

    # NxTasks::bufferInLocationToTask(location)
    def self.bufferInLocationToTask(location)
        description = "(buffer-in) #{File.basename(location)}"
        uuid = SecureRandom.uuid

        Cubes::itemInit(uuid, "NxTask")

        coredataref = CoreDataRefStrings::locationToAionPointCoreDataReference(uuid, location)

        Cubes::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes::setAttribute(uuid, "description", description)
        Cubes::setAttribute(uuid, "field11", coredataref)

        CacheWS::emit("mikutype-has-been-modified:NxTask")

        Cubes::itemOrNull(uuid)
    end

    # NxTasks::descriptionToTask1(uuid, description)
    def self.descriptionToTask1(uuid, description)
        Cubes::itemInit(uuid, "NxTask")
        Cubes::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes::setAttribute(uuid, "description", description)

        CacheWS::emit("mikutype-has-been-modified:NxTask")

        Cubes::itemOrNull(uuid)
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
        Cubes::mikuType("NxTask")
            .select{|item| item["engine-0020"] }
    end

    # NxTasks::getParentOrNull(item)
    def self.getParentOrNull(item)
        return nil if item["parentuuid-0032"].nil?
        Cubes::itemOrNull(item["parentuuid-0032"])
    end

    # NxTasks::isOrphan(item)
    def self.isOrphan(item)
        NxTasks::getParentOrNull(item).nil?
    end

    # --------------------------------------------------
    # Operations

    # NxTasks::access(task)
    def self.access(task)
        CoreDataRefStrings::accessAndMaybeEdit(task["uuid"], task["field11"])
    end

    # NxTasks::fsck()
    def self.fsck()
        Cubes::mikuType("NxTask").each{|item|
            CoreDataRefStrings::fsck(item)
        }
    end
end
