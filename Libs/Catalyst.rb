

class Catalyst

    # Catalyst::editItem(item)
    def self.editItem(item)
        item = JSON.parse(CommonUtils::editTextSynchronously(JSON.pretty_generate(item)))
        item.to_a.each{|key, value|
            Cubes2::setAttribute(item["uuid"], key, value)
        }
    end

    # Catalyst::program2(elements, context = nil)
    def self.program2(elements, context = nil)
        loop {

            elements = elements.map{|item| Cubes2::itemOrNull(item["uuid"]) }.compact
            return if elements.empty?

            system("clear")

            store = ItemStore.new()

            puts ""

            elements
                .each{|item|
                    store.register(item, MainUserInterface::canBeDefault(item))
                    puts MainUserInterface::toString2(store, item, context)
                }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            puts ""
            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # Catalyst::program3(elementsLambda, context = nil)
    def self.program3(elementsLambda, context = nil)
        loop {

            elements = elementsLambda.call()
            return if elements.empty?

            system("clear")

            store = ItemStore.new()

            puts ""

            elements
                .each{|item|
                    store.register(item, MainUserInterface::canBeDefault(item))
                    puts MainUserInterface::toString2(store, item, context)
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
            NxTodos::maintenance()
            if Cubes2::mikuType("NxTodo").size < 100 then
                Cubes2::mikuType("NxIce").take(10).each{|item|

                }
            end

            Cubes2::items().each{|item|
                next if item["donation-1601"].nil?
                target = Cubes2::itemOrNull(item["donation-1601"])
                if item.nil? then
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

    # Catalyst::interactivelySetDonation(item)
    def self.interactivelySetDonation(item)
        target = NxThreads::interactivelySelectOneOrNull()
        return if target.nil?
        Cubes2::setAttribute(item["uuid"], "donation-1601", target["uuid"])
    end

    # Catalyst::insertionPositions(parent, position, count)
    def self.insertionPositions(parent, position, count)
        children = NxThreads::children(parent)
        if children.empty? then
            return (1..count).to_a
        end
        childrens1 = children.select{|item| (item["global-positioning"] || 0) < position }
        childrens2 = children.select{|item| (item["global-positioning"] || 0) > position }
        if childrens1.empty? and childrens2.empty? then
            # this should not happen
            raise "(error: cb689a8d-5fb9-4b8d-80b7-1f30ecb4edca; parent: #{parent}, position: #{position}, count: #{count})"
        end
        if childrens1.size > 0 and childrens2.size == 0 then
            x = position.ceil
            return (x..x+count-1).to_a
        end
        if childrens1.size == 0 and childrens2.size > 0 then
            x = position.floor - count
            return (x..x+count-1).to_a
        end
        if childrens1.size > 0 and childrens2.size > 0 then
            x1 = childrens1.map{|item| item["global-positioning"] || 0 }.max
            x2 = childrens2.map{|item| item["global-positioning"] || 0 }.min
            spread = 0.8*(x2 - x1)
            shift  = 0.1*(x2 - x1)
            return (0..count-1).to_a.map{|x| x1 + shift + spread*x.to_f/(count) }
        end
    end
end
