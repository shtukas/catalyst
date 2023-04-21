
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
        board = NxBoards::interactivelySelectOneOrNull()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxClique",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "boarduuid"   => board ? board["uuid"] : nil
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
        "#{"(project)".red} #{item["description"]}#{CoreData::referenceStringToSuffixString(item["field11"])}"
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

    # -----------------------------------------
    # Ops
    # -----------------------------------------

    # NxCliques::access(project)
    def self.access(project)
        loop {
            puts NxCliques::toString(project).green
            if project["field11"] and TxDrops::projectDrops(project).size > 0 then
                action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["access CoreData payload", "access drops"])
                return if action.nil?
                if action == "access CoreData payload" then
                    CoreData::access(item["field11"])
                end
                if action == "access drops" then
                    NxCliques::program1(project)
                end
                return
            end
            if project["field11"].nil? and TxDrops::projectDrops(project).size > 0 then
                NxCliques::program1(project)
                return
            end
            if project["field11"] and TxDrops::projectDrops(project).size == 0 then
                CoreData::access(item["field11"])
                return
            end
            if project["field11"].nil? and TxDrops::projectDrops(project).size == 0 then
                LucilleCore::pressEnterToContinue()
                return
            end
        }
    end

    # NxCliques::program1(project)
    def self.program1(project)
        # We are running a listing program with the project's drops
        TxDrops::projectDrops(project)
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

            TxDrops::projectDrops(project)
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