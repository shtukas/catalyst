

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
        Cubes2::itemInit(uuid, "NxTask")

        coredataref, todotextfile = NxTasks::contentMaker(uuid)

        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::setAttribute(uuid, "field11", coredataref)
        Cubes2::setAttribute(uuid, "todotextfile-1312", todotextfile)

        Cubes2::itemOrNull(uuid)
    end

    # NxTasks::urlToTask(url)
    def self.urlToTask(url)
        description = "(vienna) #{url}"
        uuid = SecureRandom.uuid

        Cubes2::itemInit(uuid, "NxTask")

        nhash = Cubes1::putBlob(uuid, url)
        coredataref = "url:#{nhash}"

        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::setAttribute(uuid, "field11", coredataref)

        Cubes2::itemOrNull(uuid)
    end

    # NxTasks::bufferInLocationToTask(location)
    def self.bufferInLocationToTask(location)
        description = "(buffer-in) #{File.basename(location)}"
        uuid = SecureRandom.uuid

        Cubes2::itemInit(uuid, "NxTask")

        coredataref = CoreDataRefStrings::locationToAionPointCoreDataReference(uuid, location)

        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::setAttribute(uuid, "field11", coredataref)

        Cubes2::itemOrNull(uuid)
    end

    # NxTasks::descriptionToTask1(uuid, description)
    def self.descriptionToTask1(uuid, description)
        Cubes2::itemInit(uuid, "NxTask")
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "description", description)

        Cubes2::itemOrNull(uuid)
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
        Cubes2::mikuType("NxTask")
            .select{|item| item["engine-0020"] }
    end

    # NxTasks::getParentOrNull(item)
    def self.getParentOrNull(item)
        return nil if item["parentuuid-0032"].nil?
        Cubes2::itemOrNull(item["parentuuid-0032"])
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
                    Cubes2::setAttribute(item["uuid"], "todotextfile-1312", nil)
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
        Cubes2::mikuType("NxTask").each{|item|
            CoreDataRefStrings::fsck(item)
        }
    end
end
