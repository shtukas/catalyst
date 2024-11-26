
class Catalyst

    # Catalyst::editItem(item)
    def self.editItem(item)
        item = JSON.parse(CommonUtils::editTextSynchronously(JSON.pretty_generate(item)))
        item.to_a.each{|key, value|
            Items::setAttribute(item["uuid"], key, value)
        }
    end

    # Catalyst::program2(elements)
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

    # Catalyst::periodicPrimaryInstanceMaintenance()
    def self.periodicPrimaryInstanceMaintenance()
        if Config::isPrimaryInstance() then

            puts "> Catalyst::periodicPrimaryInstanceMaintenance()"

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

            NxTimeCapsules::maintenance()
        end
    end

    # Catalyst::selectTodoTextFileLocationOrNull(todotextfile)
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

    # Catalyst::donationSuffix(item)
    def self.donationSuffix(item)
        return "" if item["donation-1205"].nil?
        target = Items::itemOrNull(item["donation-1205"])
        return "" if target.nil?
        " #{"(#{target["description"]})".yellow}"
    end

    # Catalyst::interactivelyGetLines()
    def self.interactivelyGetLines()
        text = CommonUtils::editTextSynchronously("").strip
        return [] if text == ""
        text
            .lines
            .map{|line| line.strip }
            .select{|line| line != "" }
    end

    # Catalyst::interactivelyPush(item)
    def self.interactivelyPush(item)
        puts "push '#{PolyFunctions::toString(item).green}'"
        unixtime = CommonUtils::interactivelyMakeUnixtimeUsingDateCodeOrNull()
        return if unixtime.nil?
        puts "pushing until '#{Time.at(unixtime).to_s.green}'"
        Catalyst::postposeItemToUnixtime(item, unixtime)
    end

    # Catalyst::children(item)
    def self.children(item)
        if item["uuid"] == "427bbceb-923e-4feb-8232-05883553bb28" then # Infinity Core
            return NxTasks::listingItems()
        end
        if item["mikuType"] == "NxTimeCapsule" and item["targetuuid"] then
            return [Items::itemOrNull(item["targetuuid"])].compact
        end
        if item["mikuType"] == "NxStrat" then
            return [NxStrats::topOrNull(item["uuid"])].compact
        end
        Items::items()
            .select{|i| i["parentuuid-0014"] == item["uuid"] }
    end

    # Catalyst::parentOrNull(item)
    def self.parentOrNull(item)
        if item["parentuuid-0014"] then
            return Items::itemOrNull(item["parentuuid-0014"])
        end
        if item["mikuType"] == "NxStrat" then
            return [Items::itemOrNull(item["bottomuuid"])].compact
        end
        if (parent = NxTimeCapsules::getFirstCapsuleForTargetOrNull(item["uuid"])) then
            return parent
        end
        if item["mikuType"] == "NxTask" then
            # we have an NxTask withhout a parent
            # The parent is the Infinity Core
            return Items::itemOrNull("427bbceb-923e-4feb-8232-05883553bb28")
        end
        nil
    end

    # Catalyst::childrenInGlobalPositioningOrder(parent)
    def self.childrenInGlobalPositioningOrder(parent)
        Catalyst::children(parent)
            .sort_by{|item| item["global-positioning"] || 0 }
    end

    # Catalyst::firstPositionInParent(parent)
    def self.firstPositionInParent(parent)
        elements = Catalyst::children(parent)
        ([0] + elements.map{|item| item["global-positioning"] || 0 }).min
    end

    # Catalyst::lastPositionInParent(parent)
    def self.lastPositionInParent(parent)
        elements = Catalyst::children(parent)
        ([0] + elements.map{|item| item["global-positioning"] || 0 }).max
    end

    # Catalyst::interactivelySelectPositionInParent(parent)
    def self.interactivelySelectPositionInParent(parent)
        elements = Catalyst::childrenInGlobalPositioningOrder(parent)
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

    # Catalyst::interactivelySelectParentInHierarchyOrNull(context: Item or Null)
    def self.interactivelySelectParentInHierarchyOrNull(context)
        # The hierarchy has the cores and then whatever is a children, all the way down

        if context.nil? then
            core = NxCores::interactivelySelectOrNull()
            if core.nil? then
                return nil
            end
            return Catalyst::interactivelySelectParentInHierarchyOrNull(core)
        end

        # We automatically return the context if it doesn't have any children 
        # and otherwise choose between returning the context or diving into one of the children

        if Catalyst::children(context).empty? then
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
            child = LucilleCore::selectEntityFromListOfEntitiesOrNull("child", Catalyst::children(context), lambda{|item| PolyFunctions::toString(item) })
            if child.nil? then
                return Catalyst::interactivelySelectParentInHierarchyOrNull(context)
            end
            return Catalyst::interactivelySelectParentInHierarchyOrNull(child)
        end
    end

    # Catalyst::postposeItemToUnixtime(item, unixtime)
    def self.postposeItemToUnixtime(item, unixtime)
        # We stop, set DoNotShowUntil1, and recompute the flight data
        NxBalls::stop(item)
        DoNotShowUntil1::setUnixtime(item["uuid"], unixtime)
        if (flightdata = item["flight-data-27"]) then
            flightdata = NxFlightData::updateEstimatedStart(flightdata, unixtime)
            Items::setAttribute(item["uuid"], "flight-data-27", flightdata)
        end
    end
end
