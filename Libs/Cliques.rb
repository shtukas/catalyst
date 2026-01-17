
# encoding: UTF-8

class Cliques

    # ---------------------------------------
    # Data

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
        ([1] + Cliques::cliqueToItemsInOrder(cliqueuuid).map{|item| Cliques::itemToNx38OrNull(item, cliqueuuid)["position"] }).min
    end

    # Cliques::lastPositionInClique(cliqueuuid)
    def self.lastPositionInClique(cliqueuuid)
        ([1] + Cliques::cliqueToItemsInOrder(cliqueuuid).map{|item| Cliques::itemToNx38OrNull(item, cliqueuuid)["position"] }).max
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

    # Cliques::interactivelyDeterminePositionInClique(cliqueuuid)
    def self.interactivelyDeterminePositionInClique(cliqueuuid)
        elements = Cliques::cliqueToItemsInOrder(cliqueuuid)
        return 0 if elements.empty?
        puts "elements:"
        elements.each{|item|
            puts PolyFunctions::toString(item)
        }
        answer = LucilleCore::askQuestionAnswerAsString("position (empty for next): ")
        if answer == "" then
            return Cliques::lastPositionInClique(cliqueuuid) + 1
        end
        answer.to_f
    end

    # Cliques::toString(cliqueuuid)
    def self.toString(cliqueuuid)
        name1 = Cliques::cliqueuuidToName(cliqueuuid)
        "⛵️ #{name1} (#{Cliques::rtTargetForClique(cliqueuuid)} hours) (#{Cliques::cliqueSizeCached(cliqueuuid)} items)"
    end

    # Cliques::toStringWithDimension(cliqueuuid)
    def self.toStringWithDimension(cliqueuuid)
        name1 = Cliques::cliqueuuidToName(cliqueuuid)
        "⛵️ #{name1.ljust(Cliques::dimension())} #{"%4.2f" % Cliques::rtTargetForClique(cliqueuuid)} hours #{Cliques::cliqueSizeCached(cliqueuuid).to_s.rjust(6)} items"
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

    # Cliques::interactivelyMakeNewNx37()
    def self.interactivelyMakeNewNx37()
        name1 = LucilleCore::askQuestionAnswerAsString("name: ")
        {
            "uuid" => SecureRandom.hex,
            "name" => name1
        }
    end

    # Cliques::selectNx37OrNull()
    def self.selectNx37OrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("clique", Cliques::nx37s(), lambda {|nx37| nx37["name"] })
    end

    # Cliques::architectNx38()
    def self.architectNx38()
        nx37 = Cliques::selectNx37OrNull()
        if nx37 then
            position = Cliques::interactivelyDeterminePositionInClique(nx37["uuid"])
            nx38 = nx37.clone()
            nx38["position"] = position
            return nx38
        end
        nx37 = Cliques::interactivelyMakeNewNx37()
        nx38 = nx37.clone()
        nx38["position"] = 0
        nx38
    end

    # Cliques::cliqueSizeCached(cliqueuuid)
    def self.cliqueSizeCached(cliqueuuid)
        Cliques::cliqueToItemsInOrder(cliqueuuid).size
    end

    # Cliques::rtTargetForClique(cliqueuuid)
    def self.rtTargetForClique(cliqueuuid)
        filepath = "#{Config::pathToCatalystDataRepository()}/cliques-targets/#{cliqueuuid}.txt"
        if !File.exist?(filepath) then
            return 1
        end
        IO.read(filepath).to_f
    end

    # Cliques::clique_epsilon(cliqueuuid)
    def self.clique_epsilon(cliqueuuid)
        target = Cliques::rtTargetForClique(cliqueuuid)
        BankDerivedData::recoveredAverageHoursPerDayShortLivedCache(cliqueuuid).to_f/target
    end

    # Cliques::dimension()
    def self.dimension()
        15
    end

    # ---------------------------------------
    # Ops

    # Cliques::setMembership(item, nx38)
    def self.setMembership(item, nx38)
        nx38s = Cliques::itemToNx38s(item)
        nx38s = nx38s.select{|x| x["uuid"] != nx38["uuid"] }
        nx38s = nx38s + [nx38]
        Blades::setAttribute(item["uuid"], "clique8", nx38s)
    end

    # Cliques::diveClique(cliqueuuid)
    def self.diveClique(cliqueuuid)
        loop {
            items = Cliques::cliqueToItemsInOrder(cliqueuuid)
            store = ItemStore.new()
            puts ""
            puts "#{Cliques::cliqueuuidToName(cliqueuuid)}".yellow
            items
                .each{|item|
                    store.register(item, FrontPage::canBeDefault(item))
                    puts FrontPage::toString2(store, item)
                }
            puts "new | sort | hours"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "new" then
                position = Cliques::interactivelyDeterminePositionInClique(cliqueuuid)
                nx38 = {
                    "uuid"     => cliqueuuid,
                    "name"     => Cliques::cliqueuuidToName(cliqueuuid),
                    "position" => position
                }
                NxTasks::interactivelyIssueNewOrNull(nx38)
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

            if input == "hours" then
                hours = LucilleCore::askQuestionAnswerAsString("hours : ")
                filepath = "#{Config::pathToCatalystDataRepository()}/cliques-targets/#{cliqueuuid}.txt"
                File.open(filepath, "w"){|f| f.write(hours) }
                next
            end

            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # Cliques::dive()
    def self.dive()
        loop {
            nxcliques = Cliques::nxCliques().sort_by{|clique| Cliques::clique_epsilon(clique["uuid"]) }
            store = ItemStore.new()
            puts ""
            nxcliques
                .each{|nxclique|
                    store.register(nxclique, false)
                    puts "(#{store.prefixString()}) #{Cliques::toStringWithDimension(nxclique["uuid"])}"
                }
            total = nxcliques.map{|nxclique| Cliques::rtTargetForClique(nxclique["uuid"]) }.sum
            puts "                 total: #{"%4.2f" % total} hours"
            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""
            CommandsAndInterpreters::interpreter(input, store)
        }
    end

end
