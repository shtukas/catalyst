

class Catalyst

    # Catalyst::editItem(item)
    def self.editItem(item)
        item = JSON.parse(CommonUtils::editTextSynchronously(JSON.pretty_generate(item)))
        item.to_a.each{|key, value|
            Cubes2::setAttribute(item["uuid"], key, value)
        }
    end

    # Catalyst::program2(elements)
    def self.program2(elements)
        loop {

            elements = elements.map{|item| Cubes2::itemOrNull(item["uuid"]) }.compact
            return if elements.empty?

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

    # Catalyst::program3(elementsLambda)
    def self.program3(elementsLambda)
        loop {

            elements = elementsLambda.call()
            return if elements.empty?

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

            Cubes1::maintenance()

            DoNotShowUntil1::maintenance()

            NxBackups::maintenance()

            if Cubes2::mikuType("NxTodo").size < 100 then
                raise "(error: 390817c3-d1f9)"
                Cubes2::mikuType("NxIce").take(1000).each{|item|

                }
            end

            Cubes2::items().each{|item|
                next if item["parentuuid-0032"].nil?
                parent = Cubes2::itemOrNull(item["parentuuid-0032"])
                if parent.nil? then
                    Cubes2::setAttribute(item["uuid"], "parentuuid-0032", nil)
                    next
                end
            }

            Cubes2::items().each{|item|
                next if item["donation-1601"].nil?
                target = Cubes2::itemOrNull(item["donation-1601"])
                if target.nil? then
                    Cubes2::setAttribute(item["uuid"], "donation-1601", nil)
                    next
                end
            }
        end
    end

    # Catalyst::donationSuffix(item)
    def self.donationSuffix(item)
        return "" if item["donation-1601"].nil?
        uuid = item["donation-1601"]
        item = Cubes2::itemOrNull(uuid)
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
        Cubes2::items()
            .select{|item| item["parentuuid-0032"] == parent["uuid"] }
            .sort_by{|item| item["global-positioning"] || 0 }
    end

    # Catalyst::isOrphan(item)
    def self.isOrphan(item)
        item["parentuuid-0032"].nil? or Cubes2::itemOrNull(item["parentuuid-0032"]).nil?
    end

    # Catalyst::interactivelySetDonation(item)
    def self.interactivelySetDonation(item)
        puts "Set donation for item: '#{PolyFunctions::toString(item)}'"
        core = TxCores::interactivelySelectOneOrNull()
        return if core.nil?
        Cubes2::setAttribute(item["uuid"], "donation-1601", core["uuid"])
    end

    # Catalyst::interactivelySetParent(item)
    def self.interactivelySetParent(item)
        TxCores::interactivelySelectOneOrNull()
    end

    # Catalyst::ratioOrNull(item)
    def self.ratioOrNull(item)
        return nil if item["hours"].nil?
        if item["mikuType"] == "NxTodo" then
            return NxTodos::ratio(item)
        end
        if item["mikuType"] == "NxThread" then
            return NxThreads::ratio(item)
        end
        if item["mikuType"] == "TxCore" then
            return TxCores::ratio(item)
        end
        nil
    end

    # Catalyst::deepRatioMinOrNull(item)
    def self.deepRatioMinOrNull(item)
        r1 = Catalyst::ratioOrNull(item)
        r2 = Catalyst::children(item).map{|c| Catalyst::deepRatioMinOrNull(c) }.compact.reduce(nil){|acc, value| [acc, value].compact.min }
        return nil if (r1.nil? and r2.nil?)
        [r1, r2].compact.min
    end
end
