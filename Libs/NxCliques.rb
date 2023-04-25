
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
        activestr = (BankCore::getValue(item["uuid"]) > 0) ? "[*]" : "[ ]"
        "(clique) #{activestr} #{item["description"]}#{CoreData::referenceStringToSuffixString(item["field11"])} #{TxEngines::toString(item["engine"])} (#{NxCliques::cliqueToItems(item).count} items)"
    end

    # NxCliques::cliqueToItems(clique)
    def self.cliqueToItems(clique)
        NxTasks::items().select{|task| task["cliqueuuid"] == clique["uuid"] }
    end

    # NxCliques::isEssentiallyRunning(clique)
    def self.isEssentiallyRunning(clique)
        NxBalls::itemIsRunning(clique) or NxCliques::cliqueToItems(clique).any?{|item| NxBalls::itemIsRunning(item) }
    end

    # NxCliques::listingItems(clique)
    def self.listingItems(clique)
        CommonUtils::putFirst(NxCliques::cliqueToItems(clique), lambda{|item| NxBalls::itemIsRunning(item) })
    end

    # NxCliques::runningItems(clique)
    def self.runningItems(clique)
        NxCliques::cliqueToItems(clique).select{|item| NxBalls::itemIsRunning(item) }
    end

    # -----------------------------------------
    # Ops
    # -----------------------------------------

    # NxCliques::access(clique)
    def self.access(clique)
        Listing::genericListingProgram(clique, NxCliques::cliqueToItems(clique))
    end

    # NxCliques::program2()
    def self.program2()
        loop {
            clique = NxBoards::interactivelySelectOneCliqueOrNull(board)
            return if clique.nil?
            NxCliques::access(clique)
        }
    end

    # NxCliques::dataManagement()
    def self.dataManagement()
        NxCliques::items()
            .select{|clique| (Time.new.to_i - clique["unixtime"]) > 86400 }
            .select{|clique| NxCliques::cliqueToItems(clique).size == 0 }
            .each{|clique|
                puts "> destroying empty clique: #{clique["description"]}"
                LucilleCore::pressEnterToContinue()
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
        return item if item["mikuType"] != "NxTask"
        board = NxBoards::interactivelySelectOneBoardOrNull()
        return item if board.nil?
        clique = NxBoards::interactivelySelectOneCliqueOrNull(board)
        return item if clique.nil?
        item["cliqueuuid"] = clique["uuid"]
        N3Objects::commit(item)
        item
    end
end