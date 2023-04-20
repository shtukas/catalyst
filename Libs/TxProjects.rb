
class TxProjects

    # -----------------------------------------
    # IO
    # -----------------------------------------

    # TxProjects::items()
    def self.items()
        N3Objects::getMikuType("TxProject")
    end

    # TxProjects::commit(item)
    def self.commit(item)
        N3Objects::commit(item)
    end

    # TxProjects::destroy(uuid)
    def self.destroy(uuid)
        N3Objects::destroy(uuid)
    end

    # TxProjects::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        board = NxBoards::interactivelySelectOneOrNull()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "TxProject",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "boarduuid"   => board ? board["uuid"] : nil
        }
        puts JSON.pretty_generate(item)
        TxProjects::commit(item)
        item
    end

    # -----------------------------------------
    # Data
    # -----------------------------------------

    # TxProjects::toString(item)
    def self.toString(item)
        "#{"(project)".red} #{item["description"]}#{CoreData::referenceStringToSuffixString(item["field11"])}"
    end

    # TxProjects::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        items = TxProjects::items()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("project", items, lambda{|item| TxProjects::toString(item) })
    end

    # TxProjects::interactivelySelectOne()
    def self.interactivelySelectOne()
        project = TxProjects::interactivelySelectOneOrNull()
        return project if project
        TxProjects::interactivelySelectOne()
    end

    # TxProjects::listingItems()
    def self.listingItems()
        TxProjects::items().sort_by{|item| item["unixtime"] }
    end

    # -----------------------------------------
    # Ops
    # -----------------------------------------

    # TxProjects::access(project)
    def self.access(project)
        puts TxProjects::toString(project).green
        if project["field11"] and TxDrops::projectDrops(project).size > 0 then
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["access CoreData payload", "access drops"])
            return if action.nil?
            if action == "access CoreData payload" then
                CoreData::access(item["field11"])
            end
            if action == "access drops" then
                TxProjects::program1(project)
            end
            return
        end
        if project["field11"].nil? and TxDrops::projectDrops(project).size > 0 then
            TxProjects::program1(project)
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
    end

    # TxProjects::program1(project)
    def self.program1(project)
        # We are running a listing program with the project's drops
        TxDrops::projectDrops(project)
        loop {

            system("clear")

            puts ""

            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            store = ItemStore.new()

            store.register(project, false)
            line = "(#{store.prefixString()}) #{TxProjects::toString(project)}#{NxBalls::nxballSuffixStatusIfRelevant(project)}"
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

            Listing::listingCommandInterpreter(input, store, nil)
        }
    end

    # TxProjects::program2()
    def self.program2()
        loop {
            project = TxProjects::interactivelySelectOneOrNull()
            return if project.nil?
            TxProjects::program1(project)
        }
    end
end