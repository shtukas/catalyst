
class TxPools

    # TxPools::interactivelyMakeOrNull()
    def self.interactivelyMakeOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "TxPool",
            "description" => description
        }
    end

    # TxPools::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        pool = TxPools::interactivelyMakeOrNull()
        DarkEnergy::commit(pool)
        pool
    end

    # TxPools::toString(item)
    def self.toString(item)
        "👩‍💻 (pool)#{Parenting::positionSuffix(item)} #{item["description"]}#{CoreData::itemToSuffixString(item)}"
    end

    # TxPools::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        pools = DarkEnergy::mikuType("NxPool")
        LucilleCore::selectEntityFromListOfEntitiesOrNull("pool", pools, lambda{|item| item["description"] })
    end

    # TxPools::program(pool)
    def self.program(pool)
        loop {

            system("clear")

            store = ItemStore.new()

            puts ""
            spacecontrol.putsline "@pool:"
            store.register(pool, false)
            puts Listing::itemToListingLine(store, pool)

            puts ""
            Parenting::children(pool)
                .sort_by{|item| Bank::recoveredAverageHoursPerDay(item["uuid"]) }
                .each{|item|
                    store.register(item, false)
                    puts Listing::itemToListingLine(store, item)
                }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end
end