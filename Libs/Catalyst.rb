

class Catalyst

    # Catalyst::editItem(item)
    def self.editItem(item)
        item = JSON.parse(CommonUtils::editTextSynchronously(JSON.pretty_generate(item)))
        item.to_a.each{|key, value|
            Cubes1::setAttribute(item["uuid"], key, value)
        }
    end

    # Catalyst::program2(elements)
    def self.program2(elements)
        loop {
            datatrace = Catalyst::datatrace()

            elements = elements.map{|item| Cubes1::itemOrNull(datatrace, item["uuid"]) }.compact

            system("clear")

            store = ItemStore.new()

            puts ""

            elements
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts Listing::toString2(datastrace, store, item)
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

            datatrace = Catalyst::datatrace()

            elements
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts Listing::toString2(datatrace, store, item)
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

            Cubes1::items(Catalyst::datatrace()).each{|item|
                next if item["parentuuid-0032"].nil?
                parent = Cubes1::itemOrNull(Catalyst::datatrace(), item["parentuuid-0032"])
                if parent.nil? then
                    Cubes1::setAttribute(item["uuid"], "parentuuid-0032", nil)
                    next
                end
            }

            Cubes1::items(Catalyst::datatrace()).each{|item|
                next if item["donation-1601"].nil?
                target = Cubes1::itemOrNull(Catalyst::datatrace(), item["donation-1601"])
                if target.nil? then
                    Cubes1::setAttribute(item["uuid"], "donation-1601", nil)
                    next
                end
            }
        end
    end

    # Catalyst::donationSuffix(datatrace, item)
    def self.donationSuffix(datatrace, item)
        return "" if item["donation-1601"].nil?
        uuid = item["donation-1601"]
        item = Cubes1::itemOrNull(datatrace, uuid)
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

    # Catalyst::children(datatrace, parent)
    def self.children(datatrace, parent)
        if parent["uuid"] == "b83d12b6-9607-482f-8e89-239c1db49160" then
            return NxTodos::orphans(datatrace)
        end
        if parent["uuid"] == "6dd9910e-49d8-4a6f-86fb-e9b3ba0c5900" then
            return Waves::muiItemsNotInterruption(datatrace)
        end

        Cubes1::items(datatrace)
            .select{|item| item["parentuuid-0032"] == parent["uuid"] }
    end

    # Catalyst::childrenInGlobalPositioningOrder(datatrace, parent)
    def self.childrenInGlobalPositioningOrder(datatrace, parent)
        Catalyst::children(datatrace, parent)
            .sort_by{|item| item["global-positioning"] || 0 }
    end

    # Catalyst::isOrphan(datatrace, item)
    def self.isOrphan(datatrace, item)
        item["parentuuid-0032"].nil? or Cubes1::itemOrNull(datatrace, item["parentuuid-0032"]).nil?
    end

    # Catalyst::interactivelySetDonation(item)
    def self.interactivelySetDonation(item)
        puts "Set donation for item: '#{PolyFunctions::toString(item)}'"
        datatrace = Catalyst::datatrace()
        thread = NxThreads::interactivelySelectOneOrNull(datatrace)
        return if thread.nil?
        Cubes1::setAttribute(item["uuid"], "donation-1601", thread["uuid"])
    end

    # Catalyst::topPositionInParent(datatrace, parent)
    def self.topPositionInParent(datatrace, parent)
        elements = Catalyst::children(datatrace, parent)
        ([0] + elements.map{|item| item["global-positioning"] || 0 }).min
    end

    # Catalyst::insertionPositions(datatrace, parent, position, count)
    def self.insertionPositions(datatrace, parent, position, count)
        children = Catalyst::children(datatrace, parent)
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

    # Catalyst::interactivelyInsertAtPosition(parent, position)
    def self.interactivelyInsertAtPosition(parent, position)
        text = CommonUtils::editTextSynchronously("").strip
        return if text == ""
        descriptions = text.lines.map{|line| line.strip }.select{|line| line != "" }
        positions = Catalyst::insertionPositions(parent, position, descriptions.size)
        descriptions.zip(positions).each{|description, position|
            task = NxTodos::descriptionToTask1(parent, SecureRandom.hex, description)
            puts JSON.pretty_generate(task)
            Cubes1::setAttribute(task["uuid"], "global-positioning", position)
        }
    end

    # Catalyst::interactivelyPile(datatrace, thread)
    def self.interactivelyPile(datatrace, thread)
        position = Catalyst::topPositionInParent(datatrace, thread) - 1
        Catalyst::interactivelyInsertAtPosition(thread, position)
    end

    # Catalyst::interactivelySelectPositionInParent(datatrace, parent)
    def self.interactivelySelectPositionInParent(datatrace, parent)
        elements = Catalyst::childrenInGlobalPositioningOrder(datatrace, parent)
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

    # Catalyst::datatrace()
    def self.datatrace()
        "#{Cubes1::datatrace()}"
    end
end
