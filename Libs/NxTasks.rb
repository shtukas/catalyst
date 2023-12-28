

class NxTasks

    # --------------------------------------------------
    # Makers

    # NxTasks::contentMaker(uuid) # [coredataref or null, todotextfile or null]
    def self.contentMaker(uuid)
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["coredata", "todotextfile"])
        return [nil, nil] if option.nil?
        if option == "coredata" then
            return [CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(uuid), nil]
        end
        if option == "todotextfile" then
            fragment = LucilleCore::askQuestionAnswerAsString("name or fragment: ")
            return [nil, nil] if fragment == ""
            return [nil, fragment]
        end
    end

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        uuid = SecureRandom.uuid
        Cubes::itemInit(uuid, "NxTask")

        coredataref, todotextfile = NxTasks::contentMaker(uuid)

        Cubes::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes::setAttribute(uuid, "description", description)
        Cubes::setAttribute(uuid, "field11", coredataref)
        Cubes::setAttribute(uuid, "todotextfile-1312", todotextfile)

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

        Cubes::itemOrNull(uuid)
    end

    # NxTasks::descriptionToTask1(uuid, description)
    def self.descriptionToTask1(uuid, description)
        Cubes::itemInit(uuid, "NxTask")
        Cubes::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes::setAttribute(uuid, "description", description)

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

    # NxTasks::access(item)
    def self.access(item)
        if item["todotextfile-1312"] then
            # this takes priority
            todotextfile = item["todotextfile-1312"]
            location = Catalyst::selectTodoTextFileLocationOrNull(todotextfile)
            if location.nil? then
                puts "Could not resolve this todotextfile: #{todotextfile}"
                if LucilleCore::askQuestionAnswerAsBoolean("remove reference from item ?") then
                    Cubes::setAttribute(item["uuid"], "todotextfile-1312", nil)
                end
                return
            end
            puts "found: #{location}"
            system("open '#{location}'")
            return
        end
        CoreDataRefStrings::accessAndMaybeEdit(item["uuid"], item["field11"])
    end

    # NxTasks::fsck()
    def self.fsck()
        Cubes::mikuType("NxTask").each{|item|
            CoreDataRefStrings::fsck(item)
        }
    end
end
