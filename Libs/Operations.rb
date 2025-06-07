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

            store = ItemStore.new()

            puts ""

            elements
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts Listing::toString2(store, item)
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
        puts "> Operations::periodicPrimaryInstanceMaintenance()"
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
        LucilleCore::pressEnterToContinue()
    end

    # Operations::interactivelySetDonation(item)
    def self.interactivelySetDonation(item)
        core = Operations::interactivelySelectParentForDonationOrNull()
        return if core.nil?
        Items::setAttribute(item["uuid"], "donation-1205", core["uuid"])
    end

    # Operations::pickUpBufferIn()
    def self.pickUpBufferIn()
        buffer_in_location = "#{Config::userHomeDirectory()}/Desktop/Buffer-In"
        if File.exist?(buffer_in_location) then
            LucilleCore::locationsAtFolder(buffer_in_location).each{|location|
                puts location.yellow
                nx1949 = NxCores::makeNewNearTopNx1949InInfinityOrNull()
                next if nx1949.nil?
                description = File.basename(location)
                task = NxTasks::locationToTask(description, location, nx1949)
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

    # Operations::interactivelySelectParentForDonationOrNull()
    def self.interactivelySelectParentForDonationOrNull()
        parents = [
            NxTasks::activeItems(),
            NxCores::coresInRatioOrder()
        ].flatten
        LucilleCore::selectEntityFromListOfEntitiesOrNull("core", parents, lambda{|item| PolyFunctions::toString(item) })
    end

    # Operations::makeNx1949OrNull()
    def self.makeNx1949OrNull()
        parent = Operations::interactivelySelectParentForDonationOrNull()
        return nil if parent.nil?
        position = PolyFunctions::interactivelySelectGlobalPositionInParent(parent)
        nx1949 = {
            "position" => position,
            "parentuuid" => parent["uuid"]
        }
        ValueCache::destroy("#{HardProblem::get_general_prefix()}:children-for-parent:e76c2bdb-b869-429f-9889:#{parent["uuid"]}")
        nx1949
    end

    # Operations::diveItem(parent)
    def self.diveItem(parent)

        loop {

            ValueCache::destroy("#{HardProblem::get_general_prefix()}:children-for-parent:e76c2bdb-b869-429f-9889:#{parent["uuid"]}")

            store = ItemStore.new()

            puts ""
            store.register(parent, false)
            puts Listing::toString2(store, parent)
            puts ""

            PolyFunctions::childrenForParent(parent)
                .each{|element|
                    store.register(element, Listing::canBeDefault(element))
                    puts Listing::toString2(store, element)
                }

            puts ""

            puts "todo (here, with position selection) | pile | activate * | position * | sort"

            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "todo" then
                position = PolyFunctions::interactivelySelectGlobalPositionInParent(parent)
                nx1949 = {
                    "position" => position,
                    "parentuuid" => parent["uuid"]
                }
                todo = NxTasks::interactivelyIssueNewOrNull(nx1949)
                puts JSON.pretty_generate(todo)
                next
            end

            if input == "pile" then
                text = CommonUtils::editTextSynchronously("")
                lines = text.strip.lines.map{|line| line.strip }
                lines = lines.reverse
                lines.each{|line|
                    position = PolyFunctions::firstPositionInParent(parent) - 1
                    nx1949 = {
                        "position" => position,
                        "parentuuid" => parent["uuid"]
                    }
                    todo = NxTasks::descriptionToTask(line, nx1949)
                    puts JSON.pretty_generate(todo)
                }
                next
            end

            if input.start_with?("activate") then
                listord = input[8, input.size].strip.to_i
                i = store.get(listord.to_i)
                next if i.nil?
                nx1609 = NxTasks::interactivelyMakeNx1609OrNull()
                return if nx1609.nil?
                Items::setAttribute(i["uuid"], "nx1609", nx1609)
                next
            end

            if input.start_with?("position") then
                listord = input[8, input.size].strip.to_i
                i = store.get(listord.to_i)
                next if i.nil?
                position = PolyFunctions::interactivelySelectGlobalPositionInParent(parent)
                nx1949 = {
                    "position" => position,
                    "parentuuid" => parent["uuid"]
                }
                Items::setAttribute(i["uuid"], "nx1949", nx1949)
                next
            end

            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("elements", [], PolyFunctions::childrenInOrder(core).sort_by{|item| item["nx1949"]["position"] }, lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|i|
                    position = PolyFunctions::firstPositionInParent(core) - 1
                    nx1949 = {
                        "position" => position,
                        "parentuuid" => core["uuid"]
                    }
                    Items::setAttribute(i["uuid"], "nx1949", nx1949)
                }
                next
            end

            CommandsAndInterpreters::interpreter(input, store)
        }
    end
end
