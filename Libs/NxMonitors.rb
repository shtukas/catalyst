
class NxMonitors

    # NxMonitors::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        Cubes2::itemInit(uuid, "NxMonitor")
        coredataref = CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(uuid)
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::setAttribute(uuid, "field11", coredataref)
        Cubes2::itemOrNull(uuid)
    end

    # NxMonitors::issueNew(uuid, description)
    def self.issueNew(uuid, description)
        Cubes2::itemInit(uuid, "NxMonitor")
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxMonitors::access(item)
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

    # NxMonitors::toString(item)
    def self.toString(item)
        "☀️  #{item["description"]}#{CoreDataRefStrings::itemToSuffixString(item).red}"
    end

    # NxMonitors::listingItems()
    def self.listingItems()
        Cubes2::mikuType("NxMonitor")
    end
end
