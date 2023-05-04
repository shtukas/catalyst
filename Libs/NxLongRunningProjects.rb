
class NxLongRunningProjects

    # NxLongRunningProjects::items()
    def self.items()
        N3Objects::getMikuType("NxLongRunningProject")
    end

    # NxLongRunningProjects::commit(item)
    def self.commit(item)
        N3Objects::commit(item)
    end

    # NxLongRunningProjects::destroy(uuid)
    def self.destroy(uuid)
        N3Objects::destroy(uuid)
    end

    # NxLongRunningProjects::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxLongRunningProject",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "isActive"    => LucilleCore::askQuestionAnswerAsBoolean("is active ? : ")
        }
        puts JSON.pretty_generate(item)
        NxLongRunningProjects::commit(item)
        item
    end

    # NxLongRunningProjects::toString(item)
    def self.toString(item)
        "(⛵️) #{item["active"] ? "(active)" : "(sleeping)"} #{item["description"]}#{CoreData::referenceStringToSuffixString(item["field11"])}"
    end

    # NxLongRunningProjects::program1()
    def self.program1()
        loop {

            system("clear")

            puts ""

            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            store = ItemStore.new()

            NxLongRunningProjects::items()
                .sort_by{|item| TxEngines::completionRatio(item["engine"]) }
                .take(CommonUtils::screenHeight()-5)
                .each{|item|
                    store.register(item, Listing::canBeDefault(item)) 
                    status = spacecontrol.putsline(Listing::itemToListingLine(store: store, item: item))
                    break if !status
                }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == ""

            Listing::listingCommandInterpreter(input, store, nil)
        }
    end
end