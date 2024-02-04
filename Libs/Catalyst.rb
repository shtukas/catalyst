

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
                    store.register(item, MainUserInterface::canBeDefault(item))
                    puts MainUserInterface::toString2(store, item)
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
        end
    end

    # Catalyst::donationSuffix(item)
    def self.donationSuffix(item)
        return "" if item["donation-1752"].nil?
        " (#{item["donation-1752"].map{|uuid| Cubes2::itemOrNull(uuid)}.compact.map{|target| target["description"]}.join(", ")})".green
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

    # Catalyst::addDonation(item, target)
    def self.addDonation(item, target)
        donation = ((item["donation-1752"] || []) + [target["uuid"]]).uniq
        Cubes2::setAttribute(item["uuid"], "donation-1752", donation)
    end

    # Catalyst::interactivelySetDonations(item)
    def self.interactivelySetDonations(item)
        target = Catalyst::interactivelySelectNodeOrNull()
        if target then
            Catalyst::addDonation(item, target)
        end
    end

    # Catalyst::interactivelySelectNodeOrNull(cursor = nil)
    def self.interactivelySelectNodeOrNull(cursor = nil)
        if cursor.nil? then
            timecore = TxTimeCores::interactivelySelectOneOrNull()
            return nil if timecore.nil?
            if LucilleCore::askQuestionAnswerAsBoolean("return '#{PolyFunctions::toString(timecore)}' ? (alternatively dive) ") then
                return timecore
            else
                return Catalyst::interactivelySelectNodeOrNull(timecore)
            end
        end
        if cursor["mikuType"] == "TxTimeCore" then
            target = LucilleCore::selectEntityFromListOfEntitiesOrNull("todo", TxTimeCores::children(cursor), lambda{|item| PolyFunctions::toString(item) })
            return nil if target.nil?
            children = NxTodos::children(target)
            if children.empty? then
                return target
            end
            if LucilleCore::askQuestionAnswerAsBoolean("return '#{PolyFunctions::toString(target)}' ? (alternatively dive) ") then
                return target
            else
                return Catalyst::interactivelySelectNodeOrNull(target)
            end
        end
        if cursor["mikuType"] == "NxTodo" then
            children = NxTodos::children(cursor)
            target = LucilleCore::selectEntityFromListOfEntitiesOrNull("todo", children, lambda{|item| PolyFunctions::toString(item) })
            return nil if target.nil?
            children = NxTodos::children(target)
            if children.empty? then
                return target
            end
            if LucilleCore::askQuestionAnswerAsBoolean("return '#{PolyFunctions::toString(target)}' ? (alternatively dive) ") then
                return target
            else
                return Catalyst::interactivelySelectNodeOrNull(target)
            end
        end
        raise "(error: d7256dcc-6d95-42b4-9fd2-3f1e5c2b674b) cursor: #{cursor}"
    end

    # Catalyst::selectSubsetOfItemsAndMove(items)
    def self.selectSubsetOfItemsAndMove(items)
        selected, _ = LucilleCore::selectZeroOrMore("selection", [], items, lambda{|item| PolyFunctions::toString(item) })
        return if selected.size == 0
        node = Catalyst::interactivelySelectNodeOrNull()
        return if node.nil?
        selected.each{|item|
            Cubes2::setAttribute(item["uuid"], "parentuuid-0032", node["uuid"])
        }
    end
end
