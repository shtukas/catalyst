
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

            Operations::ensure_gps()
        end
    end

    # Operations::ensure_gps()
    def self.ensure_gps()
        Items::items().each{|item|
            next if item["mikuType"] == "NxTask"
            next if item["mikuType"] == "NxCore"
            next if item["mikuType"] == "NxLongTask"
            next if item["listing-positioning-2141"]
            ListingPositioning::reposition(item)
        }
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
        unixtime = CommonUtils::interactivelyMakeUnixtimeUsingDateCodeOrNull()
        return if unixtime.nil?
        puts "pushing until '#{Time.at(unixtime).to_s.green}'"
        Items::setAttribute(item["uuid"], "listing-positioning-2141", unixtime)
    end

    # Operations::interactivelySelectGlobalPositionInParent(parent)
    def self.interactivelySelectGlobalPositionInParent(parent)
        elements = PolyFunctions::naturalChildren(parent).sort_by{|item| item["global-positioning-4233"] || 0 }
        elements.first(20).each{|item|
            puts "#{PolyFunctions::toString(item)}"
        }
        position = LucilleCore::askQuestionAnswerAsString("position (first, next (default), <position>): ")
        if position == "" then # default does next
            position = "next"
        end
        if position == "first" then
            return ([0] + elements.map{|item| item["global-positioning-4233"] || 0 }).min - 1
        end
        if position == "next" then
            return ([0] + elements.map{|item| item["global-positioning-4233"] || 0 }).max + 1
        end
        position = position.to_f
        position
    end

    # Operations::postposeItemToUnixtime(item, unixtime)
    def self.postposeItemToUnixtime(item, unixtime)
        NxBalls::stop(item)
        Items::setAttribute(item["uuid"], "listing-positioning-2141", unixtime)
    end

    # Operations::expose(item)
    def self.expose(item)
        puts JSON.pretty_generate(item)
        puts "recovered average hours per day: #{Bank1::recoveredAverageHoursPerDay(item["uuid"])}"
        LucilleCore::pressEnterToContinue()
    end

    # Operations::transformation1(item)
    def self.transformation1(item)
        if  ["NxDated", "NxTask"].include?(item["mikuType"]) then
            if LucilleCore::askQuestionAnswerAsBoolean("You are stopping a #{item["mikuType"]}, would you like to make it a NxLongTask ? ") then
                Items::setAttribute(item["uuid"], "mikuType", "NxLongTask")
                Items::setAttribute(item["uuid"], "listing-positioning-2141", nil)
                return
            end
        end
    end
end
