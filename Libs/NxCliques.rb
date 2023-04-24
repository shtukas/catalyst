
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
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        board = NxCapitalShips::interactivelySelectOneOrNull()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxClique",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "boarduuid"   => board ? board["uuid"] : nil,
            "engine"      => TxEngines::interactivelyMakeEngineOrNull()
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
        "(clique) #{item["description"]}#{CoreData::referenceStringToSuffixString(item["field11"])} #{TxEngines::toString(item["engine"])} (#{NxCliques::cliqueMembers(item).count} items)"
    end

    # NxCliques::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        items = NxCliques::items()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("project", items, lambda{|item| NxCliques::toString(item) })
    end

    # NxCliques::interactivelySelectOne()
    def self.interactivelySelectOne()
        project = NxCliques::interactivelySelectOneOrNull()
        return project if project
        NxCliques::interactivelySelectOne()
    end

    # NxCliques::listingItems()
    def self.listingItems()
        NxCliques::items().sort_by{|item| item["unixtime"] }
    end

    # NxCliques::cliqueMembers(clique)
    def self.cliqueMembers(clique)
        NxTasks::items().select{|item|
            item["cliqueuuid"] == clique["uuid"]
        }
    end

    # -----------------------------------------
    # Ops
    # -----------------------------------------

    # NxCliques::access(item)
    def self.access(item)
        loop {
            puts NxCliques::toString(item).green
            if item["field11"] and NxCliques::cliqueMembers(item).size > 0 then
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
            if item["field11"].nil? and NxCliques::cliqueMembers(item).size > 0 then
                NxCliques::program1(item)
                return
            end
            if item["field11"] and NxCliques::cliqueMembers(item).size == 0 then
                CoreData::access(item["field11"])
                return
            end
            if item["field11"].nil? and NxCliques::cliqueMembers(item).size == 0 then
                LucilleCore::pressEnterToContinue()
                return
            end
        }
    end

    # NxCliques::program1(project)
    def self.program1(project)
        # We are running a listing program with the project's drops
        NxCliques::cliqueMembers(project)
        loop {

            system("clear")

            puts ""

            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            store = ItemStore.new()

            store.register(project, false)
            line = "(#{store.prefixString()}) #{NxCliques::toString(project)}#{NxBalls::nxballSuffixStatusIfRelevant(project)}"
            if NxBalls::itemIsActive(project) then
                line = line.green
            end
            spacecontrol.putsline line

            spacecontrol.putsline ""

            NxCliques::cliqueMembers(project)
                .each{|item|
                    store.register(item, Listing::canBeDefault(item)) 
                    spacecontrol.putsline(Listing::itemToListingLine(store, item))
                }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == ""
            if input == "drop" then
                TxDrops::interactivelyIssueNewOrNull(project["uuid"])
                next
            end

            Listing::listingCommandInterpreter(input, store, nil)
        }
    end

    # NxCliques::program2()
    def self.program2()
        loop {
            project = NxCliques::interactivelySelectOneOrNull()
            return if project.nil?
            NxCliques::program1(project)
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
        return item if item["mikuType"] == "NxCapitalShip"
        clique = NxCliques::interactivelySelectOneOrNull()
        return item if clique.nil?
        item["cliqueuuid"] = clique["uuid"]
        N3Objects::commit(item)
        item
    end
end