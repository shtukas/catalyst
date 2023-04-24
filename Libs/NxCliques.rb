
class NxCliques

    # -----------------------------------------
    # IO
    # -----------------------------------------

    # NxCliques::items()
    def self.items()
        N3Objects::getMikuType("NxClique")
    end

    # NxCliques::commit(item)
    def self.commit(item)
        N3Objects::commit(item)
    end

    # NxCliques::destroy(uuid)
    def self.destroy(uuid)
        N3Objects::destroy(uuid)
    end

    # NxCliques::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        board = NxBoards::interactivelySelectOneBoard()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxClique",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "boarduuid"   => board["uuid"],
            "engine"      => TxEngines::interactivelyMakeEngineOrDefault()
        }
        puts JSON.pretty_generate(item)
        NxCliques::commit(item)
        item
    end

    # -----------------------------------------
    # Data
    # -----------------------------------------

    # NxCliques::toString(item)
    def self.toString(item)
        "(clique) #{item["description"]}#{CoreData::referenceStringToSuffixString(item["field11"])} #{TxEngines::toString(item["engine"])} (#{NxCliques::cliqueToItems(item).count} items)"
    end

    # NxCliques::boardToCliques(board)
    def self.boardToCliques(board)
        NxCliques::items().select{|clique| clique["boarduuid"] == board["uuid"] }
    end

    # NxCliques::cliqueToItems(clique)
    def self.cliqueToItems(clique)
        NxTasks::items().select{|task| task["cliqueuuid"] == clique["uuid"] }
    end

    # -----------------------------------------
    # Ops
    # -----------------------------------------

    # NxCliques::access(item)
    def self.access(item)
        loop {
            puts NxCliques::toString(item).green
            if item["field11"] and NxCliques::cliqueToItems(item).size > 0 then
                action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["access CoreData payload", "access drops"])
                return if action.nil?
                if action == "access CoreData payload" then
                    CoreData::access(item["field11"])
                end
                if action == "access drops" then
                    NxCliques::program1(item)
                end
                return
            end
            if item["field11"].nil? and NxCliques::cliqueToItems(item).size > 0 then
                NxCliques::program1(item)
                return
            end
            if item["field11"] and NxCliques::cliqueToItems(item).size == 0 then
                CoreData::access(item["field11"])
                return
            end
            if item["field11"].nil? and NxCliques::cliqueToItems(item).size == 0 then
                LucilleCore::pressEnterToContinue()
                return
            end
        }
    end

    # NxCliques::program1(clique)
    def self.program1(clique)
        # We are running a listing program with the clique's drops
        NxCliques::cliqueToItems(clique)
        loop {

            system("clear")

            puts ""

            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            store = ItemStore.new()

            store.register(clique, false)
            line = "(#{store.prefixString()}) #{NxCliques::toString(clique)}#{NxBalls::nxballSuffixStatusIfRelevant(clique)}"
            if NxBalls::itemIsActive(clique) then
                line = line.green
            end
            spacecontrol.putsline line

            spacecontrol.putsline ""

            NxCliques::cliqueToItems(clique)
                .each{|item|
                    store.register(item, Listing::canBeDefault(item)) 
                    status = spacecontrol.putsline(Listing::itemToListingLine(store, item))
                    break if !status
                }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == ""
            if input == "drop" then
                TxDrops::interactivelyIssueNewOrNull(clique["uuid"])
                next
            end

            Listing::listingCommandInterpreter(input, store, nil)
        }
    end

    # NxCliques::program2()
    def self.program2()
        loop {
            clique = NxBoards::interactivelySelectOneCliqueOrNull()
            return if clique.nil?
            NxCliques::program1(clique)
        }
    end

    # NxCliques::dataManagement()
    def self.dataManagement()
        NxCliques::items()
            .select{|clique| (Time.new.to_i - clique["unixtime"]) > 3600 }
            .select{|clique| NxCliques::cliqueToItems(clique).size == 0 }
            .each{|clique|
                puts "destroying empty clique: #{clique["description"]}"
                NxCliques::destroy(clique["uuid"])
            }
    end
end

class CliquesAndItems

    # CliquesAndItems::attachToItem(item, clique or nil)
    def self.attachToItem(item, clique)
        return if clique.nil?
        item["cliqueuuid"] = clique["uuid"]
        N3Objects::commit(item)
    end

    # CliquesAndItems::askAndMaybeAttach(item)
    def self.askAndMaybeAttach(item)
        return item if item["cliqueuuid"]
        return item if item["mikuType"] == "NxClique"
        return item if item["mikuType"] == "NxBoard"
        clique = NxBoards::interactivelySelectOneCliqueOrNull()
        return item if clique.nil?
        item["cliqueuuid"] = clique["uuid"]
        N3Objects::commit(item)
        item
    end
end