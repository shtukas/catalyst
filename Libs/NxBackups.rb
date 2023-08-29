
class NxBackups

    # NxBackups::toString(item)
    def self.toString(item)
        "💾 #{item["description"]}"
    end

    # NxBackups::listingItems()
    def self.listingItems()
        Cubes::mikuType("NxBackup")
            .select{|item| Time.new.to_i >= (item["lastDoneUnixtime"] + item["periodInDays"]*86400) }
    end

    # NxBackups::performDone(item)
    def self.performDone(item)
        Cubes::setAttribute2(item["uuid"], "lastDoneUnixtime", Time.new.to_i)
    end

    # NxBackups::program(item)
    def self.program(item)
        loop {
            puts PolyFunctions::toString(item).green
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["perform done"])
            return if action.nil?
            if action == "perform done" then
                NxBackups::performDone(item)
            end
        }
    end
end
