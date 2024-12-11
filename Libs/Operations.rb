
class Operations

    # Operations::editItem(item)
    def self.editItem(item)
        item = JSON.parse(CommonUtils::editTextSynchronously(JSON.pretty_generate(item)))
        item.to_a.each{|key, value|
            Items::setAttribute(item["uuid"], key, value)
        }
    end

    # Operations::program2(elements)
    def self.program2(elements)
        loop {
            elements = elements.map{|item| Items::itemOrNull(item["uuid"]) }.compact

            system("clear")

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
        if Config::isPrimaryInstance() then

            puts "> Operations::periodicPrimaryInstanceMaintenance()"

            NxBackups::maintenance()

            Items::items().each{|item|
                next if item["donation-1205"].nil?
                target = Items::itemOrNull(item["uuid"])
                next if target
                Items::setAttribute(item["uuid"], "donation-1205", nil)
            }

            Items::items().each{|item|
                next if item["parentuuid-0014"].nil?
                target = Items::itemOrNull(item["uuid"])
                next if target
                Items::setAttribute(item["uuid"], "parentuuid-0014", nil)
            }

            NxStrats::garbageCollection()

            NxCores::maintenance()

            NxCapsuledTasks::maintenance()
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

    # Operations::donationSuffix(item)
    def self.donationSuffix(item)
        return "" if item["donation-1205"].nil?
        target = Items::itemOrNull(item["donation-1205"])
        return "" if target.nil?
        " #{"(#{target["description"]})".yellow}"
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

        if item["mikuType"] == "NxTimeCapsule" then
            options = ["next available flight slot (default)", "manual"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            if option == "next available flight slot (default)" or option.nil? then
                NxFlightData::resheduleItemAtTheEnd(item)
                return
            end
        end

        unixtime = CommonUtils::interactivelyMakeUnixtimeUsingDateCodeOrNull()
        return if unixtime.nil?
        puts "pushing until '#{Time.at(unixtime).to_s.green}'"
        Operations::postposeItemToUnixtime(item, unixtime)
    end

    # Operations::childrenInGlobalPositioningOrder(parent)
    def self.childrenInGlobalPositioningOrder(parent)
        PolyFunctions::children(parent)
            .sort_by{|item| item["global-positioning"] || 0 }
    end

    # Operations::firstPositionInParent(parent)
    def self.firstPositionInParent(parent)
        elements = PolyFunctions::children(parent)
        ([0] + elements.map{|item| item["global-positioning"] || 0 }).min
    end

    # Operations::lastPositionInParent(parent)
    def self.lastPositionInParent(parent)
        elements = PolyFunctions::children(parent)
        ([0] + elements.map{|item| item["global-positioning"] || 0 }).max
    end

    # Operations::interactivelySelectPositionInParent(parent)
    def self.interactivelySelectPositionInParent(parent)
        elements = Operations::childrenInGlobalPositioningOrder(parent)
        elements.first(20).each{|item|
            puts "#{PolyFunctions::toString(item)}"
        }
        position = LucilleCore::askQuestionAnswerAsString("position (first, next (default), <position>): ")
        if position == "" then # default does next
            position = "next"
        end
        if position == "first" then
            return ([0] + elements.map{|item| item["global-positioning"] || 0 }).min - 1
        end
        if position == "next" then
            return ([0] + elements.map{|item| item["global-positioning"] || 0 }).max + 1
        end
        position = position.to_f
        position
    end

    # Operations::interactivelySelectParentInHierarchyOrNull(context: Item or Null)
    def self.interactivelySelectParentInHierarchyOrNull(context)
        # The hierarchy has the cores and then whatever is a children, all the way down

        if context.nil? then
            core = NxCores::interactivelySelectOrNull()
            if core.nil? then
                return nil
            end
            return Operations::interactivelySelectParentInHierarchyOrNull(core)
        end

        # We automatically return the context if it doesn't have any children 
        # and otherwise choose between returning the context or diving into one of the children

        if PolyFunctions::children(context).empty? then
            return context
        end
        # We have a NxCore that has children
        o1 = "select: '#{PolyFunctions::toString(context)}' (default)"
        o2 = "select one from children"
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", [o1, o2])
        if option.nil? or option == o1 then
            return context
        end
        if option == o2 then
            child = LucilleCore::selectEntityFromListOfEntitiesOrNull("child", PolyFunctions::children(context), lambda{|item| PolyFunctions::toString(item) })
            if child.nil? then
                return Operations::interactivelySelectParentInHierarchyOrNull(context)
            end
            return Operations::interactivelySelectParentInHierarchyOrNull(child)
        end
    end

    # Operations::postposeItemToUnixtime(item, unixtime)
    def self.postposeItemToUnixtime(item, unixtime)
        # We stop, set DoNotShowUntil1, and recompute the flight data
        NxBalls::stop(item)
        DoNotShowUntil1::setUnixtime(item["uuid"], unixtime)
        if item["flight-data-27"] then
            flightdata = NxFlightData::updateEstimatedStart(item["flight-data-27"], unixtime)
            Items::setAttribute(item["uuid"], "flight-data-27", flightdata)
        end
    end

    # Operations::expose(item)
    def self.expose(item)
        puts JSON.pretty_generate(item)
        unixtime = DoNotShowUntil1::getUnixtimeOrNull(item["uuid"])
        puts "Do not show until: #{unixtime}"
        puts "Do not show until: #{Time.at(unixtime).utc.iso8601}"
        if item["mikuType"] == "NxTimeCapsule" then
            puts "live value: #{NxTimeCapsules::liveValue(item)}"
        end
        LucilleCore::pressEnterToContinue()
    end
end
