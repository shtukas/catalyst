
class NxListings

    # NxListings::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        hours = LucilleCore::askQuestionAnswerAsString("daily hours: ").to_f
        priority = LucilleCore::askQuestionAnswerAsBoolean("is priority ? (must complete first) : ")
        uuid = SecureRandom.uuid
        Blades::init(uuid)
        Blades::setAttribute(uuid, "unixtime", Time.new.to_i)
        Blades::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Blades::setAttribute(uuid, "description", description)
        Blades::setAttribute(uuid, "hours-24", hours)
        Blades::setAttribute(uuid, "priority-19", priority)
        Blades::setAttribute(uuid, "mikuType", "NxListing")
        item = Blades::itemOrNull(uuid)
        item
    end

    # NxListings::icon(item)
    def self.icon(item)
        "🌌"
    end

    # NxListings::dimension()
    def self.dimension()
        15
    end

    # NxListings::toString(listing)
    def self.toString(listing)
        ratios = " ratio: #{NxListings::ratio(listing)}".yellow
        "🌌 #{listing["description"].ljust(NxListings::dimension())} #{"%4.2f" % listing["hours-24"]} hours, #{NxListings::itemsInOrder(listing).size.to_s.rjust(6)} items, is priority: #{listing["priority-19"].to_s.ljust(5)}#{ratios}"
    end

    # NxListings::listingItems()
    def self.listingItems()
        priorities, non_priorities = Blades::mikuType("NxListing").partition{|item| item["priority-19"] }
        if priorities.size > 0 and priorities.any?{|item| NxListings::ratio(item) < 1 } then
            return priorities.select{|item| NxListings::ratio(item) < 1 }
        end
        non_priorities
    end

    # NxListings::listinguuidToName(listinguuid)
    def self.listinguuidToName(listinguuid)
        listing = Blades::itemOrNull(listinguuid)
        if listing then
            return listing["description"]
        end
        raise "(error: 49f22a07) could not determine name for clique: #{listinguuid}"
    end

    # NxListings::interactivelySelectListingOrNull()
    def self.interactivelySelectListingOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("nxlisting", Blades::mikuType("NxListing"), lambda {|listing| PolyFunctions::toString(listing) })
    end

    # NxListings::itemBelongsToListing(item, listinguuid)
    def self.itemBelongsToListing(item, listinguuid)
        return false if item["clique8"].nil?
        item["clique8"].any?{|nx38| nx38["uuid"] == listinguuid }
    end

    # NxListings::listinguuidToItemsInOrder(listinguuid)
    def self.listinguuidToItemsInOrder(listinguuid)
        Blades::mikuType("NxTask")
            .select{|item| NxListings::itemBelongsToListing(item, listinguuid) }
            .sort_by{|item| Nx38s::itemToNx38OrNull(item, listinguuid)["position"] }
    end

    # NxListings::itemsInOrder(listing)
    def self.itemsInOrder(listing)
        Blades::mikuType("NxTask")
            .select{|item| NxListings::itemBelongsToListing(item, listing["uuid"]) }
            .sort_by{|item| Nx38s::itemToNx38OrNull(item, listing["uuid"])["position"] }
    end

    # NxListings::firstPositionInListing(listing)
    def self.firstPositionInListing(listing)
        ([1] + NxListings::itemsInOrder(listing).map{|item| Nx38s::itemToNx38OrNull(item, listing["uuid"])["position"] }).min
    end

    # NxListings::lastPositionInListing(listing)
    def self.lastPositionInListing(listing)
        ([1] + NxListings::itemsInOrder(listing).map{|item| Nx38s::itemToNx38OrNull(item, listing["uuid"])["position"] }).max
    end

    # NxListings::interactivelyDeterminePositionInListing(listing)
    def self.interactivelyDeterminePositionInListing(listing)
        elements = NxListings::itemsInOrder(listing)
        return 0 if elements.empty?
        puts "elements:"
        elements.each{|item|
            puts PolyFunctions::toString(item)
        }
        answer = LucilleCore::askQuestionAnswerAsString("position (empty for next): ")
        if answer == "" then
            return NxListings::lastPositionInListing(listing) + 1
        end
        answer.to_f
    end

    # Nx38s::architectNx38()
    def self.architectNx38()
        listing = NxListings::interactivelySelectListingOrNull()
        if listing then
            position = NxListings::interactivelyDeterminePositionInListing(listing)
            return {
                "uuid" => listing["uuid"],
                "position" => position
            }
        end
        {
            "uuid" => listing["uuid"],
            "position" => 0
        }
    end

    # NxListings::ratio(listing)
    def self.ratio(listing)
        hours = listing["hours-24"]
        BankDerivedData::recoveredAverageHoursPerDayShortLivedCache(listing["uuid"]).to_f/hours
    end

    # --------------------------------------
    # Operations

    # NxListings::diveListing(listing)
    def self.diveListing(listing)
        loop {
            store = ItemStore.new()
            puts ""
            puts "#{NxListings::toString(listing)}".yellow
            NxListings::itemsInOrder(listing)
                .each{|item|
                    store.register(item, FrontPage::canBeDefault(item))
                    puts FrontPage::toString2(store, item)
                }
            puts "new | sort | set hours | set priority"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "new" then
                position = NxListings::interactivelyDeterminePositionInListing(listinguuid)
                nx38 = {
                    "uuid"     => listinguuid,
                    "name"     => NxListings::listinguuidToName(listinguuid),
                    "position" => position
                }
                NxTasks::interactivelyIssueNewOrNull(nx38)
                next
            end

            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("items", [], items, lambda{|i| PolyFunctions::toString(i) })
                name1 = NxListings::listinguuidToName(listinguuid)
                selected.reverse.each{|item|
                    position = NxListings::firstPositionInListing(listing) - 1
                    Nx38s::setMembership(item, {
                        "uuid"     => listinguuid,
                        "name"     => name1,
                        "position" => position
                    })
                }
                next
            end

            if input == "set hours" then
                hours = LucilleCore::askQuestionAnswerAsString("daily hours: ").to_f
                Blades::setAttribute(listing["uuid"], "hours-24", hours)
                next
            end

            if input == "set priority" then
                priority = LucilleCore::askQuestionAnswerAsBoolean("is priority ? (must complete first) : ")
                Blades::setAttribute(listing["uuid"], "priority-19", priority)
                next
            end

            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxListings::dive()
    def self.dive()
        loop {
            listings = Blades::mikuType("NxListing").sort_by{|clique| NxListings::ratio(clique) }
            store = ItemStore.new()
            puts ""
            listings.each{|listing|
                store.register(listing, false)
                puts "(#{store.prefixString()}) #{NxListings::toString(listing)}"
            }
            total = listings.map{|listing| listing["hours"] }.sum
            puts "                 total: #{"%4.2f" % total} hours"
            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""
            CommandsAndInterpreters::interpreter(input, store)
        }
    end

end
