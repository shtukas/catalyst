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

    # Operations::globalMaintenance()
    def self.globalMaintenance()
        puts "> Operations::globalMaintenance()"
        puts "> Nx2133::maintenance()"
        Nx2133::maintenance()
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
        unixtime = DoNotShowUntil::getUnixtimeOrNull(item["uuid"])
        if unixtime then
            puts "do not show until: #{Time.at(unixtime).to_s} "
        end
        LucilleCore::pressEnterToContinue()
    end

    # Operations::interactivelySelectTargetForDonationOrNull()
    def self.interactivelySelectTargetForDonationOrNull()
        targets = [
            NxBalls::activeItems(),
            NxTasks::importantItems(),
            NxCores::coresInRatioOrder()
        ].flatten
        LucilleCore::selectEntityFromListOfEntitiesOrNull("donation target", targets, lambda{|item| PolyFunctions::toString(item) })
    end

    # Operations::interactivelySetDonation(item)
    def self.interactivelySetDonation(item)
        target = Operations::interactivelySelectTargetForDonationOrNull()
        return if target.nil?
        Items::setAttribute(item["uuid"], "donation-1205", target["uuid"])
    end

    # Operations::dispatchPickUp()
    def self.dispatchPickUp()
        directory = "#{Config::userHomeDirectory()}/Desktop/Dispatch/Buffer-In"
        if File.exist?(directory) then
            LucilleCore::locationsAtFolder(directory).each{|location|
                puts location.yellow
                nx1949 = PolyFunctions::makeNewNearTopNx1949InInfinityOrNull()
                next if nx1949.nil?
                description = File.basename(location)
                item = NxTasks::locationToTask(description, location, nx1949)
                #puts JSON.pretty_generate(item)
                LucilleCore::removeFileSystemLocation(location)
            }
        end

        directory = "#{Config::userHomeDirectory()}/Desktop/Dispatch/Today"
        if File.exist?(directory) then
            LucilleCore::locationsAtFolder(directory).each{|location|
                puts location.yellow
                description = File.basename(location)
                item = NxDateds::locationToItem(description, location)
                #puts JSON.pretty_generate(item)
                LucilleCore::removeFileSystemLocation(location)
                #puts PolyFunctions::toString(item)
            }
        end

        directory = "#{Config::userHomeDirectory()}/Desktop/Dispatch/Tomorrow"
        if File.exist?(directory) then
            LucilleCore::locationsAtFolder(directory).each{|location|
                puts location.yellow
                description = File.basename(location)
                item = NxDateds::locationToItem(description, location)
                Items::setAttribute(item["uuid"], "date", CommonUtils::tomorrow())
                #puts JSON.pretty_generate(item)
                LucilleCore::removeFileSystemLocation(location)
                #puts PolyFunctions::toString(item)
            }
        end
    end

    # Operations::topNotifications()
    def self.topNotifications()
        notifications = []
        JSON.parse(IO.read("#{Config::userHomeDirectory()}/Galaxy/DataHub/Backups-Utils/Orbital-Backup-Data/under-counted-target-directory-names.json")).each{|directory_name|
            notifications << "under counted back up target directory name: #{directory_name}"
        }
        notifications
    end

    # Operations::interactivelySelectParentOrNull()
    def self.interactivelySelectParentOrNull()
        targets = [
            NxTasks::importantItems(),
            NxCores::coresInRatioOrder()
        ].flatten
        LucilleCore::selectEntityFromListOfEntitiesOrNull("parent", targets, lambda{|item| PolyFunctions::toString(item) })
    end

    # Operations::makeNx1949OrNull()
    def self.makeNx1949OrNull()
        parent = Operations::interactivelySelectParentOrNull()
        return nil if parent.nil?
        position = PolyFunctions::interactivelySelectGlobalPositionInParent(parent)
        nx1949 = {
            "position" => position,
            "parentuuid" => parent["uuid"]
        }
        nx1949
    end

    # Operations::diveItem(parent)
    def self.diveItem(parent)

        if parent["uuid"] == NxCores::infinityuuid() then
            puts "You cannot dive in Infinity"
            LucilleCore::pressEnterToContinue()
            return
        end

        loop {
            store = ItemStore.new()

            puts ""
            store.register(parent, false)
            puts Listing::toString2(store, parent)
            puts ""

            PolyFunctions::childrenInOrder(parent)
                .each{|element|
                    store.register(element, Listing::canBeDefault(element))
                    puts Listing::toString2(store, element)
                }

            puts ""

            puts "todo (here, with position selection) | pile | important * | position * | sort"

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
                Operations::interactivelyGetLines()
                    .reverse
                    .each{|line|
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

            if input.start_with?("important") then
                listord = input[8, input.size].strip.to_i
                i = store.get(listord.to_i)
                next if i.nil?
                Items::setAttribute(i["uuid"], "nx2290-important", true)
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

    # Operations::probeHead()
    def self.probeHead()
        NxCores::cores()
            .each{|core|
                #puts "probing core #{core["description"]}"
                PolyFunctions::childrenInOrder(core)
                    .first(200)
                    .each{|item|
                        #puts "probing item #{item["description"]}"
                        next if item["uxpayload-b4e4"].nil?
                        if item["uxpayload-b4e4"]["type"] == "Dx8Unit" then
                            unitId = item["uxpayload-b4e4"]["id"]
                            location = Dx8Units::acquireUnitFolderPathOrNull(unitId)
                            puts "unit location: #{location}"
                            payload2 = UxPayload::locationToPayload(item["uuid"], location)
                            Items::setAttribute(item["uuid"], "uxpayload-b4e4", payload2)
                            LucilleCore::removeFileSystemLocation(location)
                        end
                    }
            }
    end
end
