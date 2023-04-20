
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
        board = NxBoards::interactivelySelectOneOrNull()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "TxProject",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
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

    # -----------------------------------------
    # Ops
    # -----------------------------------------

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