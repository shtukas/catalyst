
class Operations

    # Operations::editItem(item)
    def self.editItem(item)
        item = JSON.parse(CommonUtils::editTextSynchronously(JSON.pretty_generate(item)))
        item.to_a.each{|key, value|
            Items::setAttribute(item["uuid"], key, value)
        }
    end

    # Operations::program3(lx)
    def self.program3(lx)
        loop {
            elements = lx.call()

            system("clear")

            store = ItemStore.new()

            puts ""

            elements
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts Listing::toString3(store, item)
                }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            puts ""
            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # Operations::periodicPrimaryInstanceMaintenance()
    def self.periodicPrimaryInstanceMaintenance()
        if Config::isPrimaryInstance() then

            puts "> Operations::periodicPrimaryInstanceMaintenance()"

            if NxTasks::activeItems().map{|item| item['nx1608']["hours"] }.inject(0, :+) < 20 then
                task = Items::mikuType("NxTask")
                        .select{|item| item["nx1948"] }
                        .select{|item| item["nx1948"]["coreuuid"] == NxCores::infinityuuid() }
                        .select{|item| item["nx1608"].nil? }
                        .sort_by{|item| item["nx1948"]["position"] }
                        .first
                if task then
                    puts "promiting to active item: #{JSON.pretty_generate(task)}"
                    Items::setAttribute(task["uuid"], "nx1608", {
                        "hours" => 7
                    })
                end
            end
        end
    end

    # Operations::selectTodoTextFileLocationOrNull(todotextfile)
    def self.selectTodoTextFileLocationOrNull(todotextfile)
        location = XCache::getOrNull("fcf91da7-0600-41aa-817a-7af95cd2570b:#{todotextfile}")
        if location and File.exist?(location) then
            return location
        end

        roots = [Config::pathToGalaxy()]
        Galaxy::locationEnumerator(roots).each{|location|
            if File.basename(location).include?(todotextfile) then
                XCache::set("fcf91da7-0600-41aa-817a-7af95cd2570b:#{todotextfile}", location)
                return location
            end
        }
        nil
    end

    # Operations::interactivelyGetLines()
    def self.interactivelyGetLines()
        text = CommonUtils::editTextSynchronously("").strip
        return [] if text == ""
        text
            .lines
            .map{|line| line.strip }
            .select{|line| line != "" }
    end

    # Operations::interactivelyPush(item)
    def self.interactivelyPush(item)
        PolyActions::stop(item)
        puts "push '#{PolyFunctions::toString(item).green}'"
        unixtime = CommonUtils::interactivelyMakeUnixtimeUsingDateCodeOrNull()
        return if unixtime.nil?
        puts "pushing until '#{Time.at(unixtime).to_s.green}'"
        DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
    end

    # Operations::expose(item)
    def self.expose(item)
        puts JSON.pretty_generate(item)
        puts "recovered average hours per day: #{Bank1::recoveredAverageHoursPerDay(item["uuid"])}"
        LucilleCore::pressEnterToContinue()
    end

    # Operations::interactivelySetDonation(item)
    def self.interactivelySetDonation(item)
        core = NxCores::interactivelySelectOrNullForDonation()
        return if core.nil?
        Items::setAttribute(item["uuid"], "donation-1205", core["uuid"])
    end

    # Operations::pickUpBufferIn()
    def self.pickUpBufferIn()
        buffer_in_location = "#{Config::userHomeDirectory()}/Desktop/Buffer-In"
        if File.exist?(buffer_in_location) then
            LucilleCore::locationsAtFolder(buffer_in_location).each{|location|
                puts location.yellow
                nx1948 = NxCores::makeNewTopNx1948InInfinityOrNull()
                next if nx1948.nil?
                description = File.basename(location)
                task = NxTasks::locationToTask(description, location, nx1948)
                puts JSON.pretty_generate(task)
                LucilleCore::removeFileSystemLocation(location)
            }
        end
    end

    # Operations::top_notifications()
    def self.top_notifications()
        notifications = []
        if Config::isPrimaryInstance() then
            JSON.parse(IO.read("#{Config::userHomeDirectory()}/Galaxy/DataHub/Backups-Utils/Orbital-Backup-Data/under-counted-target-directory-names.json")).each{|directory_name|
                notifications << "under counted back up target directory name: #{directory_name}"
            }
        end
        notifications
    end
end
