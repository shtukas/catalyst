
# encoding: UTF-8

class Cliques

    # Cliques::itemToNx38s(item)
    def self.itemToNx38s(item)
        return [] if item["clique8"].nil?
        item["clique8"]
    end

    # Cliques::itemToNx38OrNull(item, cliqueuuid)
    def self.itemToNx38OrNull(item, cliqueuuid)
        Cliques::itemToNx38s(item).select{|nx38| nx38["uuid"] == cliqueuuid }.first
    end

    # Cliques::itemBelongsToClique(item, cliqueuuid)
    def self.itemBelongsToClique(item, cliqueuuid)
        return false if item["clique8"].nil?
        item["clique8"].any?{|nx38| nx38["uuid"] == cliqueuuid }
    end

    # Cliques::cliqueToItemsInOrder(cliqueuuid)
    def self.cliqueToItemsInOrder(cliqueuuid)
        Blades::mikuType("NxTask")
            .select{|item| Cliques::itemBelongsToClique(item, cliqueuuid) }
            .sort_by{|item| Cliques::itemToNx38OrNull(item, cliqueuuid)["position"] }
    end

    # Cliques::firstPositionInClique(cliqueuuid)
    def self.firstPositionInClique(cliqueuuid)
        ([1] + Cliques::cliqueToItemsInOrder(cliqueuuid).map{|item| Cliques::itemToNx38OrNull(cliqueuuid)["position"] }).min
    end

    # Cliques::nx37s()
    def self.nx37s()
        nx37s = {}
        Blades::mikuType("NxTask").each{|item|
            Cliques::itemToNx38s(item).each{|nx37|
                nx37s[nx37["uuid"]] = nx37
            }
        }
        nx37s.values.map{|x|
            x.clone().delete("position")
            x
        }
    end

    # Cliques::cliqueuuidToName(cliqueuuid)
    def self.cliqueuuidToName(cliqueuuid)
        Cliques::nx37s().each{|nx37|
            if nx37["uuid"] == cliqueuuid then
                return nx37["name"]
            end
        }
        raise "(error: 49f22a07) could not determine name for clique: #{cliqueuuid}"
    end

    # Cliques::setMembership(item, nx38)
    def self.setMembership(item, nx38)
        nx38s = Cliques::itemToNx38s(item)
        nx38s = nx38s.select{|x| x["uuid"] != nx38["uuid"] }
        nx38s = nx38s + [nx38]
        Blades::setAttribute(item["uuid"], "clique8", nx38s)
    end

    # Cliques::interactivelyDeterminePositionInClique(cliqueuuid)
    def self.interactivelyDeterminePositionInClique(cliqueuuid)
        elements = Cliques::cliqueToItemsInOrder(cliqueuuid)
        return 0 if elements.empty?
        puts "elements:"
        elements.each{|item|
            puts PolyFunctions::toString(item)
        }
        LucilleCore::askQuestionAnswerAsString("position (empty for next): ").to_f
    end

    # Cliques::toString(cliqueuuid)
    def self.toString(cliqueuuid)
        name1 = Cliques::cliqueuuidToName(cliqueuuid)
        "⛵️ #{name1}"
    end

    # Cliques::diveClique(cliqueuuid)
    def self.diveClique(cliqueuuid)
        loop {
            items = Cliques::cliqueToItemsInOrder(cliqueuuid)
            store = ItemStore.new()
            puts ""
            items
                .each{|item|
                    store.register(item, FrontPage::canBeDefault(item))
                    puts FrontPage::toString2(store, item)
                }
            puts "new | sort"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "new" then
                item = NxTasks::interactivelyIssueNewOrNull()
                position = Cliques::interactivelyDeterminePositionInClique(cliqueuuid)
                Cliques::setMembership(item, {
                    "uuid"     => cliqueuuid,
                    "name"     => Cliques::cliqueuuidToName(cliqueuuid),
                    "position" => position
                })
                next
            end

            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("items", [], items, lambda{|i| PolyFunctions::toString(i) })
                name1 = Cliques::cliqueuuidToName(cliqueuuid)
                selected.reverse.each{|item|
                    position = Cliques::firstPositionInClique(cliqueuuid) - 1
                    Cliques::setMembership(item, {
                        "uuid"     => cliqueuuid,
                        "name"     => name1,
                        "position" => position
                    })
                }
                next
            end

            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # Cliques::nxCliques()
    def self.nxCliques()
        Cliques::nx37s().map{|nx37|
            {
                "uuid"        => nx37["uuid"],
                "mikuType"    => "NxClique",
                "description" => nx37["name"]
            }
        }
    end

    # Cliques::itemsForListing()
    def self.itemsForListing()
        Cliques::nxCliques()
    end
end
