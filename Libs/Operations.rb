
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

            Items::items().each{|item|
                next if item["donation-1205"].nil?
                target = Items::itemOrNull(item["uuid"])
                next if target
                Items::setAttribute(item["uuid"], "donation-1205", nil)
            }

            if NxTasks::activeItems().map{|item| item['nx1608']["hours"] }.inject(0, :+) < 20 then
                task = Items::mikuType("NxTask")
                        .select{|item| item["nx1941"] }
                        .select{|item| item["nx1941"]["core"]["uuid"] == NxCores::infinityuuid() }
                        .select{|item| item["nx1608"].nil? }
                        .sort_by{|item| item["nx1941"]["position"] }
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

    # Operations::setDonation(item)
    def self.setDonation(item)
        core = NxCores::interactivelySelectOrNull()
        return if core.nil?
        Items::setAttribute(item["uuid"], "donation-1205", core["uuid"])
    end

    # Operations::pickUpBufferIn()
    def self.pickUpBufferIn()
        buffer_in_location = "#{Config::userHomeDirectory()}/Desktop/Buffer-In"
        if File.exist?(buffer_in_location) then
            LucilleCore::locationsAtFolder(buffer_in_location).each{|location|
                puts location.yellow
                nx1941 = NxCores::makeNewTopNx1941InInfinityOrNull()
                next if nx1941.nil?
                description = File.basename(location)
                task = NxTasks::locationToTask(description, location, nx1941)
                puts JSON.pretty_generate(task)
                LucilleCore::removeFileSystemLocation(location)
            }
        end
    end
end
