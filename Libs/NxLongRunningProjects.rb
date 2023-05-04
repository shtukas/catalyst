
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
            "active"    => LucilleCore::askQuestionAnswerAsBoolean("is active ? : ")
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

            puts "active projects:"
            NxLongRunningProjects::items().select{|item| item["active"] }
                .sort_by{|item| TxEngines::completionRatio(item["engine"]) }
                .each{|item|
                    store.register(item, Listing::canBeDefault(item)) 
                    status = spacecontrol.putsline(Listing::itemToListingLine(store: store, item: item))
                    break if !status
                }

            puts ""

            puts "sleeping projects:"
            NxLongRunningProjects::items().select{|item| !item["active"] }
                .sort_by{|item| item["unixtime"] }
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

    # NxLongRunningProjects::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        items = NxLongRunningProjects::items().select{|item| !item["active"] }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("board", items, lambda{|item| NxLongRunningProjects::toString(item) })
    end

    # NxLongRunningProjects::dataMaintenance()
    def self.dataMaintenance()
        # We scan the tasks and any boardless task with more than 2 hours in the bank is automatically turned into a long running project
        NxTasks::boardlessItems()
            .sort_by{|item| item["position"] }
            .first(100)
            .each{|item|
                next if Bank::getValue(item["uuid"]) < 3600*2
                puts "transmuting task: #{item["description"]} into a long running project"
                active = LucilleCore::askQuestionAnswerAsBoolean("active ? : ")
                item["mikuType"] = "NxLongRunningProject"
                item["active"] = active
                N3Objects::commit(item)
            }

        if NxLongRunningProjects::items().size > 0 and NxLongRunningProjects::items().none?{|item| item["active"] } then
            puts "We do not currently have active long running projects"
            puts "Please select one or more:"
            loop {
                item = NxLongRunningProjects::interactivelySelectOneOrNull()
                break if item.nil?
                item["active"] = true
                N3Objects::commit(item)
                break if !LucilleCore::askQuestionAnswerAsBoolean("more ? ")
            }
        end
    end
end