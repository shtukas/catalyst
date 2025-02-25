
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

    # Operations::interactivelySelectGlobalPositionInParent(parent)
    def self.interactivelySelectGlobalPositionInParent(parent)
        elements = PolyFunctions::naturalChildren(parent).sort_by{|item| item["nx1940"]["position"] }
        elements.first(20).each{|item|
            puts "#{PolyFunctions::toString(item)}"
        }
        position = LucilleCore::askQuestionAnswerAsString("position (first, next (default), <position>): ")
        if position == "" then # default does next
            position = "next"
        end
        if position == "first" then
            return ([0] + elements.map{|item| item["nx1940"]["position"] }).min - 1
        end
        if position == "next" then
            return ([0] + elements.map{|item| item["nx1940"]["position"] }).max + 1
        end
        position = position.to_f
        position
    end

    # Operations::expose(item)
    def self.expose(item)
        puts JSON.pretty_generate(item)
        puts "recovered average hours per day: #{Bank1::recoveredAverageHoursPerDay(item["uuid"])}"
        LucilleCore::pressEnterToContinue()
    end

    # Operations::setDonation(item)
    def self.setDonation(item)
        target = PolyFunctions::interactivelySelectDonationTargetOrNull()
        return if target.nil?
        return if item["uuid"] == target["uuid"]
        Items::setAttribute(item["uuid"], "donation-1205", target["uuid"])
    end
end
