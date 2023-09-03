

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
        thread = Cubes::itemOrNull(item["lineage-nx128"])
        s1 = thread ? " (#{thread["description"]})".green : ""
        "🔺 (#{"%5.2f" % item["coordinate-nx129"]}) #{item["description"]}#{s1}"
    end

    # --------------------------------------------------
    # Operations

    # NxTasks::pile(task)
    def self.pile(task)
        text = CommonUtils::editTextSynchronously("").strip
        return if text == ""
        text.lines.to_a.map{|line| line.strip }.select{|line| line != ""}.reverse.each {|line|

            thread = Cubes::itemOrNull(task["lineage-nx128"])
            position = NxThreads::newFirstPosition(thread)

            t1 = NxTasks::descriptionToTask(line)
            next if t1.nil?
            puts JSON.pretty_generate(t1)

            Cubes::setAttribute2(t1["uuid"], "lineage-nx128", thread["uuid"])
            Cubes::setAttribute2(t1["uuid"], "coordinate-nx129", position)
        }
    end

    # NxTasks::access(task)
    def self.access(task)
        CoreDataRefStrings::access(task["uuid"], task["field11"])
    end

    # NxTasks::maintenance()
    def self.maintenance()

        # Ensuring consistency of lineages

        Cubes::mikuType("NxTask").each{|task|
            next if task["lineage-nx128"]
            thread = Cubes::itemOrNull("bc3901ad-18ad-4354-b90b-63f7a611e64e")  # Infinity Thread
            if thread.nil? then
                raise "error: C41FBB5C-518C-45A5-B45A-126C23282A05"
            end
            position = NxThreads::newFirstPosition(thread)
            Cubes::setAttribute2(uuid, "lineage-nx128", thread["uuid"])
            Cubes::setAttribute2(uuid, "coordinate-nx129", position)
        }

        Cubes::mikuType("NxTask").each{|task|
            if task["lineage-nx128"] then
                thread = Cubes::itemOrNull(task["lineage-nx128"])
                if thread.nil? then
                    thread = Cubes::itemOrNull("bc3901ad-18ad-4354-b90b-63f7a611e64e")  # Infinity Thread
                    if thread.nil? then
                        raise "error: 51F2586F-E2BB-4F3D-954D-F859714F2267"
                    end
                    position = NxThreads::newFirstPosition(thread)
                    Cubes::setAttribute2(uuid, "lineage-nx128", thread["uuid"])
                    Cubes::setAttribute2(uuid, "coordinate-nx129", position)
                end
            end
        }

        # Ensuring consistency of tasks lineages
        Cubes::mikuType("NxTask").each{|task|
            next if task["lineage-nx128"].nil?
            next if Cubes::itemOrNull(task["lineage-nx128"])
            Cubes::setAttribute2(uuid, "lineage-nx128", nil)
        }

        # Pick up NxFronts-BufferIn
        LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/DataHub/NxFronts-BufferIn").each{|location|
            NxTasks::locationToTask(location)
            LucilleCore::removeFileSystemLocation(location)
        }

        # Feed Infinity using NxIce
        if Cubes::mikuType("NxTask").size < 100 then
            Cubes::mikuType("NxIce").take(10).each{|item|
                thread = Cubes::itemOrNull("8d67eae1-787e-4763-81bf-3ffb6e28c0eb") # Infinity Thread
                position = NxThreads::newNextPosition(thread)
                Cubes::setAttribute2(item["uuid"], "mikuType", "NxTask")
                Cubes::setAttribute2(item["uuid"], "lineage-nx128", thread["uuid"])
                Cubes::setAttribute2(item["uuid"], "coordinate-nx129", position)
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
