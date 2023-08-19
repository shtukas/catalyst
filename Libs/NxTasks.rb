

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
        Cubes::init(nil, "NxTask", uuid)

        coredataref = CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(uuid)

        Cubes::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Cubes::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Cubes::setAttribute2(uuid, "description", description)
        Cubes::setAttribute2(uuid, "field11", coredataref)

        Cubes::itemOrNull(uuid)
    end

    # NxTasks::interactivelyIssueNewAtParentOrNull(parent)
    def self.interactivelyIssueNewAtParentOrNull(parent)

        position = Tx8s::interactivelyDecidePositionUnderThisParentOrNull(parent)
        return nil if position.nil?
        tx8 = Tx8s::make(parent["uuid"], position)

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        # We need to create the blade before we call CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull
        # because the blade need to exist for aion points data blobs to have a place to go.

        uuid = SecureRandom.uuid
        Cubes::init(nil, "NxTask", uuid)

        coredataref = CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(uuid)

        Cubes::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Cubes::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Cubes::setAttribute2(uuid, "description", description)
        Cubes::setAttribute2(uuid, "field11", coredataref)
        Cubes::setAttribute2(uuid, "parent", tx8)

        Cubes::itemOrNull(uuid)
    end

    # NxTasks::urlToTask(url)
    def self.urlToTask(url)
        description = "(vienna) #{url}"
        uuid = SecureRandom.uuid

        Cubes::init(nil, "NxTask", uuid)

        nhash = Cubes::putDatablob2(uuid, url)
        coredataref = "url:#{nhash}"

        Cubes::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Cubes::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Cubes::setAttribute2(uuid, "description", description)
        Cubes::setAttribute2(uuid, "field11", coredataref)
        Cubes::itemOrNull(uuid)
    end

    # NxTasks::locationToTask(location)
    def self.locationToTask(location)
        description = "(buffer-in) #{File.basename(location)}"
        uuid = SecureRandom.uuid

        Cubes::init(nil, "NxTask", uuid)

        coredataref = CoreDataRefStrings::locationToAionPointCoreDataReference(uuid, location)

        Cubes::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Cubes::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Cubes::setAttribute2(uuid, "description", description)
        Cubes::setAttribute2(uuid, "field11", coredataref)
        Cubes::itemOrNull(uuid)
    end

    # NxTasks::descriptionToTask(description)
    def self.descriptionToTask(description)
        uuid = SecureRandom.uuid
        Cubes::init(nil, "NxTask", uuid)
        Cubes::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Cubes::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Cubes::setAttribute2(uuid, "description", description)
        Cubes::itemOrNull(uuid)
    end

    # NxTasks::descriptionToTask_vX(uuid, description)
    def self.descriptionToTask_vX(uuid, description)
        Cubes::init(nil, "NxTask", uuid)
        Cubes::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Cubes::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Cubes::setAttribute2(uuid, "description", description)
        Cubes::itemOrNull(uuid)
    end

    # --------------------------------------------------
    # Data

    # NxTasks::toString(item)
    def self.toString(item)
        "🔹#{Tx8s::positionInParentSuffix(item)} #{item["description"]}#{CoreDataRefStrings::itemToSuffixString(item)}"
    end

    # NxTasks::orphanItems()
    def self.orphanItems()
        Cubes::mikuType("NxTask")
            .select{|item| item["parent"].nil? }
    end

    # --------------------------------------------------
    # Operations

    # NxTasks::pile(task)
    def self.pile(task)
        text = CommonUtils::editTextSynchronously("").strip
        return if text == ""
        text.lines.to_a.map{|line| line.strip }.select{|line| line != ""}.reverse.each {|line|
            t1 = NxTasks::descriptionToTask(line)
            next if t1.nil?
            puts JSON.pretty_generate(t1)
            t1["parent"] = Tx8s::make(task["uuid"], Tx8s::newFirstPositionAtThisParent(task))
            puts JSON.pretty_generate(t1)
            Cubes::setAttribute2(t1["uuid"], "parent", t1["parent"])
        }
    end

    # NxTasks::access(task)
    def self.access(task)
        CoreDataRefStrings::access(task["uuid"], task["field11"])
    end

    # NxTasks::maintenance()
    def self.maintenance()
        # Ensuring consistency of task parenting targets
        Cubes::mikuType("NxTask").each{|task|
            next if task["parent"].nil?
            if Cubes::itemOrNull(task["parent"]["uuid"]).nil? then
                Cubes::setAttribute2(uuid, "parent", nil)
            end
        }

        # Pick up NxFronts-BufferIn
        LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/DataHub/NxFronts-BufferIn").each{|location|
            NxTasks::locationToTask(location)
            LucilleCore::removeFileSystemLocation(location)
        }

        # Feed Infinity using NxIce
        if Cubes::mikuType("NxTask").size < 100 then
            Cubes::mikuType("NxIce").take(10).each{|item|
                item["mikuType"] == "NxTask"
                Cubes::setAttribute2(item["uuid"], "mikuType", "NxTask")
                core = Cubes::itemOrNull("7cf30bc6-d791-4c0c-b03f-16c728396f22") # Infinity Core
                tx8 = Tx8s::make(parent["uuid"], Tx8s::nextPositionAtThisParent(core))
                Cubes::setAttribute2(item["uuid"], "parent", tx8)
            }
        end
    end

    # NxTasks::fsck()
    def self.fsck()
        Cubes::mikuType("NxTask").each{|item|
            CoreDataRefStrings::fsck(item)
        }
    end
end
