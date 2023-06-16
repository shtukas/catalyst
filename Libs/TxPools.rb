
class TxPools

    # TxPools::interactivelyMakeOrNull()
    def self.interactivelyMakeOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "TxPool",
            "unixtime"    => Time.new.to_f,
            "datetime"    => Time.new.utc.iso8601,
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
        "👩‍💻 (pool) #{item["description"]}#{CoreData::itemToSuffixString(item)}"
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
            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            puts ""
            spacecontrol.putsline "@pool:"
            store.register(pool, false)
            puts Listing::itemToListingLine(store, pool)

            puts ""
            TxPools::children(item)
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

    # TxPools::program0()
    def self.program0()
        loop {
            pools = DarkEnergy::mikuType("TxPool")
            if pools.empty? then
                puts "no pool found"
                LucilleCore::pressEnterToContinue()
                return
            end
            pool = LucilleCore::selectEntityFromListOfEntitiesOrNull("pool", pools, lambda{|pool| TxPools::toString(pool) })
            return if pool.nil?
            TxPools::program(pool)
        }
    end

    # TxPools::getItemPoolOrNull(item)
    def self.getItemPoolOrNull(item)
        return nil if item["nspool1131"].nil?
        DarkEnergy::itemOrNull(item["nspool1131"])
    end

    # TxPools::suffix(item)
    def self.suffix(item)
        pool = TxPools::getItemPoolOrNull(item)
        return "" if pool.nil?
        " (pool: #{pool["description"]})".green
    end

    # TxPools::children(pool)
    def self.children(pool)
        DarkEnergy::all().select{|item| item["nspool1131"] == pool["uuid"] }
    end
end