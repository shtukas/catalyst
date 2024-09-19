
class Catalyst

    # Catalyst::editItem(item)
    def self.editItem(item)
        item = JSON.parse(CommonUtils::editTextSynchronously(JSON.pretty_generate(item)))
        item.to_a.each{|key, value|
            Items::setAttribute(item["uuid"], key, value)
        }
    end

    # Catalyst::program2(elements, context)
    def self.program2(elements, context = nil)
        loop {
            elements = elements.map{|item| Items::itemOrNull(item["uuid"]) }.compact

            system("clear")

            store = ItemStore.new()

            puts ""

            elements
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts Listing::toString2(store, item, context)
                }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            puts ""
            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # Catalyst::parentOrNull(item)
    def self.parentOrNull(item)
        return nil if item["parentuuid-0032"].nil?
        Items::itemOrNull(item["parentuuid-0032"])
    end

    # Catalyst::periodicPrimaryInstanceMaintenance()
    def self.periodicPrimaryInstanceMaintenance()
        if Config::isPrimaryInstance() then

            puts "> Catalyst::periodicPrimaryInstanceMaintenance()"

            NxBackups::maintenance()

            Items::items().each{|item|
                next if item["parentuuid-0032"].nil?
                parent = Items::itemOrNull(item["parentuuid-0032"])
                next if parent
                Items::setAttribute(item["uuid"], "parentuuid-0032", nil)
            }

            Items::items().each{|item|
                next if item["donation-1601"].nil?
                target = Items::itemOrNull(item["donation-1601"])
                next if target
                Items::setAttribute(item["uuid"], "donation-1601", nil)
            }
        end
    end

    # Catalyst::donationSuffix(item)
    def self.donationSuffix(item)
        return "" if item["donation-1601"].nil?
        uuid = item["donation-1601"]
        item = Items::itemOrNull(uuid)
        return "" if item.nil?
        " (#{item["description"]})".green
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

    # Catalyst::children(parent)
    def self.children(parent)
        Items::items()
            .select{|item| item["parentuuid-0032"] == parent["uuid"] }
    end

    # Catalyst::childrenInGlobalPositioningOrder(parent)
    def self.childrenInGlobalPositioningOrder(parent)
        Catalyst::children(parent)
            .sort_by{|item| item["global-positioning"] || 0 }
    end

    # Catalyst::isOrphan(item)
    def self.isOrphan(item)
        item["parentuuid-0032"].nil? or Items::itemOrNull(item["parentuuid-0032"]).nil?
    end

    # Catalyst::interactivelySetDonation(item)
    def self.interactivelySetDonation(item)
        puts "Set donation for item: '#{PolyFunctions::toString(item)}'"
        target = NxThreads::interactivelySelectOneOrNull()
        return if target.nil?
        Items::setAttribute(item["uuid"], "donation-1601", target["uuid"])
    end

    # Catalyst::topPositionInParent(parent)
    def self.topPositionInParent(parent)
        elements = Catalyst::children(parent)
        ([0] + elements.map{|item| item["global-positioning"] || 0 }).min
    end

    # Catalyst::interactivelyGetLinesParentToChildren()
    def self.interactivelyGetLinesParentToChildren()
        text = CommonUtils::editTextSynchronously("").strip
        return [] if text == ""
        text
            .lines
            .map{|line| line.strip }
            .select{|line| line != "" }
            .reverse
    end

    # Catalyst::interactivelyPile(target)
    def self.interactivelyPile(target)

        if target["mikuType"] == "NxTask" then
            parent = Catalyst::parentOrNull(item)
            if parent["mikuType"] == "NxThread" then
                Catalyst::interactivelyPile(parent)
            end
            return
        end

        if target["mikuType"] == "NxThread" then
            thread = target
            Catalyst::interactivelyGetLinesParentToChildren()
                .reverse
                .each_with_index{|description, i|
                    item = NxTasks::descriptionToTask1(description)
                    Items::setAttribute(item["uuid"], "parentuuid-0032", thread["uuid"])
                    Items::setAttribute(item["uuid"], "global-positioning", Catalyst::topPositionInParent(thread) - 1)
                }
            return
        end

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

    # Catalyst::interactivelyPush(item)
    def self.interactivelyPush(item)
        puts "push '#{PolyFunctions::toString(item).green}'"
        unixtime = CommonUtils::interactivelyMakeUnixtimeUsingDateCodeOrNull()
        return if unixtime.nil?
        NxBalls::stop(item)
        puts "pushing until '#{Time.at(unixtime).to_s.green}'"
        DoNotShowUntil1::setUnixtime(item["uuid"], unixtime)
    end

    # Catalyst::pushByNHour(item, timeSpanInHours)
    def self.pushByNHour(item, timeSpanInHours)
        unixtime = Time.new.to_f + timeSpanInHours*3600
        NxBalls::stop(item)
        puts "pushing until '#{Time.at(unixtime).to_s.green}'"
        DoNotShowUntil1::setUnixtime(item["uuid"], unixtime)
    end
end
