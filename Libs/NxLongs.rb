
class NxLongs

    # NxLongs::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        active = LucilleCore::askQuestionAnswerAsBoolean("is active ? : ")
        Solingen::init("NxLong", uuid)
        Solingen::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Solingen::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Solingen::setAttribute2(uuid, "description", description)
        Solingen::setAttribute2(uuid, "field11", coredataref)
        Solingen::setAttribute2(uuid, "active", active)
        Solingen::getItemOrNull(uuid)
    end

    # NxLongs::toString(item)
    def self.toString(item)
        "(long) #{item["description"]}#{CoreData::referenceStringToSuffixString(item["field11"])} #{item["active"] ? "(active)" : "(sleeping)"}"
    end

    # NxLongs::program1()
    def self.program1()
        loop {

            system("clear")

            puts ""

            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            store = ItemStore.new()

            puts "active projects:"
            Solingen::mikuTypeItems("NxLong")
                .select{|item| item["active"] }
                .sort_by{|item| Bank::recoveredAverageHoursPerDay(item["uuid"]) }
                .each{|item|
                    store.register(item, Listing::canBeDefault(item)) 
                    status = spacecontrol.putsline(Listing::itemToListingLine(store: store, item: item))
                    break if !status
                }

            puts ""

            puts "sleeping projects:"
            Solingen::mikuTypeItems("NxLong")
                .select{|item| !item["active"] }
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

    # NxLongs::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        items = Solingen::mikuTypeItems("NxLong").select{|item| !item["active"] }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("board", items, lambda{|item| NxLongs::toString(item) })
    end

    # NxLongs::dataMaintenance()
    def self.dataMaintenance()
        # We scan the tasks and any boardless task with more than 2 hours in the bank is automatically turned into a long running project
        NxTasksBoardless::items()
            .sort_by{|item| item["position"] }
            .first(100)
            .each{|item|
                next if Bank::getValue(item["uuid"]) < 3600*2
                puts "transmuting task: #{item["description"]} into a long running project"
                active = LucilleCore::askQuestionAnswerAsBoolean("active ? : ")
                Solingen::setAttribute2(item["uuid"], "mikuType", "NxLong")
                Solingen::setAttribute2(item["uuid"], "active", active)
            }

        if Solingen::mikuTypeItems("NxLong").size > 0 and Solingen::mikuTypeItems("NxLong").none?{|item| item["active"] } then
            puts "We do not currently have active long running projects"
            puts "Please select one or more:"
            loop {
                item = NxLongs::interactivelySelectOneOrNull()
                break if item.nil?
                Solingen::setAttribute2(item["uuid"], "active", true)
                break if !LucilleCore::askQuestionAnswerAsBoolean("more ? ")
            }
        end
    end
end