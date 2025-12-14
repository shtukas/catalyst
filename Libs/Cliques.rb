
class Cliques

    # --------------------------------------
    # Data

    # Cliques::cliquesSuffix(item)
    def self.cliquesSuffix(item)
        return "" if item["cliques-128"].nil?
        return "" if item["cliques-128"].empty?
        " (c: #{item["cliques-128"].map{|clique| clique["name"] }.join(', ').yellow})"
    end

    # Cliques::cliqueNames()
    def self.cliqueNames()
        Items::objects()
            .map{|item| item["cliques-128"] }
            .compact
            .flatten
            .map{|clique| clique["name"] }
            .uniq
    end

    # Cliques::getItemsInOrder(cliquename)
    def self.getItemsInOrder(cliquename)
        items = []
        Items::objects().each{|item|
            next if item["cliques-128"].nil?
            next if !item["cliques-128"].map{|clique| clique["name"]}.include?(cliquename)
            items << item
        }
        # We are also going to sort them
        items.sort_by{|item| 
            item["cliques-128"]
                .select{|clique| clique["name"] == cliquename }
                .first["position"]
        }
    end

    # Cliques::cliqueFirstPosition(cliquename)
    def self.cliqueFirstPosition(cliquename)
        items = Cliques::getItemsInOrder(cliquename)
        return 1 if items.empty?
        items
            .first["cliques-128"]
            .select{|clique| clique["name"] == cliquename }
            .first["position"]
    end

    # Cliques::cliqueLastPosition(cliquename)
    def self.cliqueLastPosition(cliquename)
        items = Cliques::getItemsInOrder(cliquename)
        return 1 if items.empty?
        items
            .last["cliques-128"]
            .select{|clique| clique["name"] == cliquename }
            .first["position"]
    end

    # --------------------------------------
    # Ops

    # Cliques::interactivelySelectCliqueNameOrNull()
    def self.interactivelySelectCliqueNameOrNull()
        names = Cliques::cliqueNames()
        return  if names.empty?
        LucilleCore::selectEntityFromListOfEntitiesOrNull("name", names)
    end

    # Cliques::interactivelySelectCliqueNameOrNull_Extended()
    def self.interactivelySelectCliqueNameOrNull_Extended()
        names = Cliques::cliqueNames() + ["(new)"]
        return  if names.empty?
        LucilleCore::selectEntityFromListOfEntitiesOrNull("name", names)
    end


    # Cliques::architectNameOrNull()
    def self.architectNameOrNull()
        name1 = Cliques::interactivelySelectCliqueNameOrNull_Extended()
        return nil if name1.nil?
        if name1 == "(new)" then
            name1 = LucilleCore::askQuestionAnswerAsString("name (empty to abort): ")
            return nil if name1 == ""
            return name1
        end
        name1
    end

    # Cliques::itemProgram(item)
    def self.itemProgram(item)
        loop {
            item = Items::itemOrNull(item["uuid"])
            puts "cliques: #{PolyFunctions::toString(item).green}#{Cliques::cliquesSuffix(item)}"
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["new (clique)"])
            return if option.nil?
            if option == "new (clique)" then
                name1 = Cliques::architectNameOrNull()
                cliques = item["cliques-128"]
                if cliques.nil? then
                    cliques = []
                end
                cliques << {
                    "name" => name1,
                    "position" => Cliques::cliqueLastPosition(name1)
                }
                Items::setAttribute(item["uuid"], "cliques-128", cliques)
            end
        }
    end

    # Cliques::cliqueDive(cliquename)
    def self.cliqueDive(cliquename)
        loop {
            elements = Cliques::getItemsInOrder(cliquename)
            store = ItemStore.new()
            puts ""
            elements
                .each{|item|
                    store.register(item, FrontPage::canBeDefault(item))
                    puts FrontPage::toString2(store, item)
                }
            puts ""
            puts "new (task) | sort"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""
            if input == "new" then
                item = NxTasks::interactivelyIssueNewOrNull()
                next if item.nil?
                Items::setAttribute(item["uuid"], "cliques-128", [{
                    "name"     => cliquename,
                    "position" => Cliques::cliqueLastPosition(cliquename) + 1
                }])
                next
            end
            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("elements", [], elements, lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|item|
                    cliques = item["cliques-128"].map{|clique|
                        if clique["name"] == cliquename then
                            clique["position"] = Cliques::cliqueFirstPosition(cliquename) - 1
                        end
                        clique
                    }
                    Items::setAttribute(item["uuid"], "cliques-128", cliques)
                }
                next
            end
            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # Cliques::generalDive()
    def self.generalDive()
        cliquename = LucilleCore::selectEntityFromListOfEntitiesOrNull("clique", Cliques::cliqueNames())
        return if cliquename.nil?
        Cliques::cliqueDive(cliquename)
    end
end
