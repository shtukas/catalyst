
class NxListings

    # NxListings::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        whours = LucilleCore::askQuestionAnswerAsString("hours per week: ").to_f
        uuid = SecureRandom.uuid
        Blades::init(uuid)
        Blades::setAttribute(uuid, "unixtime", Time.new.to_i)
        Blades::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Blades::setAttribute(uuid, "description", description)
        Blades::setAttribute(uuid, "whours-45", whours)
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

    # NxListings::toString(item)
    def self.toString(item)
        "🌌 #{item["description"].ljust(NxListings::dimension())} (#{NxListings::itemsInOrder(item).size.to_s.rjust(6)} items)#{NxEngine::suffix(item)}"
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
            .sort_by{|item| ListingMembership::itemPositionInListingOrZero(item, listinguuid) }
    end

    # NxListings::itemsInOrder(listing)
    def self.itemsInOrder(listing)
        Blades::mikuType("NxTask")
            .select{|item| NxListings::itemBelongsToListing(item, listing["uuid"]) }
            .sort_by{|item| ListingMembership::itemPositionInListingOrZero(item, listing["uuid"]) }
    end

    # NxListings::itemsInOrderWithPosition(listing)
    def self.itemsInOrderWithPosition(listing)
        Blades::mikuType("NxTask")
            .select{|item| NxListings::itemBelongsToListing(item, listing["uuid"]) }
            .map{|item| {
                "item"     => item,
                "position" => ListingMembership::itemPositionInListingOrZero(item, listing["uuid"])
            }}
            .sort_by{|packet| packet["position"] }
    end

    # NxListings::firstPositionInListing(listing)
    def self.firstPositionInListing(listing)
        ([1] + NxListings::itemsInOrder(listing).map{|item| ListingMembership::itemMembershipClaimInlistingOrNull(item, listing["uuid"])["position"] }).min
    end

    # NxListings::lastPositionInListing(listing)
    def self.lastPositionInListing(listing)
        ([1] + NxListings::itemsInOrder(listing).map{|item| ListingMembership::itemMembershipClaimInlistingOrNull(item, listing["uuid"])["position"] }).max
    end

    # NxListings::interactivelyDeterminePositionInListing(listing)
    def self.interactivelyDeterminePositionInListing(listing)
        packets = NxListings::itemsInOrderWithPosition(listing)
        return 0 if packets.empty?
        puts "element:"
        packets.each{|packet|
            item = packet["item"]
            position = packet["position"]
            puts "#{"%8.3f" % position} #{PolyFunctions::toString(item)}"
        }
        answer = LucilleCore::askQuestionAnswerAsString("position (empty for next): ")
        if answer == "" then
            return NxListings::lastPositionInListing(listing) + 1
        end
        answer.to_f
    end

    # NxListings::architectNx38()
    def self.architectNx38()
        listing = NxListings::interactivelySelectListingOrNull()
        if listing then
            position = NxListings::interactivelyDeterminePositionInListing(listing)
            return {
                "uuid" => listing["uuid"],
                "position" => position
            }
        end
        listing = NxListings::interactivelyIssueNewOrNull()
        if listing then
            position = NxListings::interactivelyDeterminePositionInListing(listing)
            return {
                "uuid" => listing["uuid"],
                "position" => position
            }
        end
        NxListings::architectNx38()
    end

    # NxListings::ratio(item)
    def self.ratio(item)
        NxEngine::ratio(item)
    end

    # --------------------------------------
    # Operations

    # NxListings::diveListing(listing)
    def self.diveListing(listing)
        loop {
            listing = Blades::itemOrNull(listing["uuid"])
            store = ItemStore.new()
            puts ""
            puts "#{NxListings::toString(listing)}".yellow
            NxListings::itemsInOrder(listing)
                .each{|item|
                    store.register(item, FrontPage::canBeDefault(item))
                    puts FrontPage::toString2(store, item)
                }
            puts "new | sort | engine"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "new" then
                position = NxListings::interactivelyDeterminePositionInListing(listing["uuid"])
                nx38 = {
                    "uuid"     => listing["uuid"],
                    "name"     => NxListings::listinguuidToName(listing["uuid"]),
                    "position" => position
                }
                NxTasks::interactivelyIssueNewOrNull(nx38)
                next
            end

            if input == "sort" then
                selected = CommonUtils::selectZeroOrMore(items, lambda{|i| PolyFunctions::toString(i) })
                name1 = NxListings::listinguuidToName(listing["uuid"])
                selected.reverse.each{|item|
                    position = NxListings::firstPositionInListing(listing) - 1
                    ListingMembership::setMembership(item, {
                        "uuid"     => listing["uuid"],
                        "name"     => name1,
                        "position" => position
                    })
                }
                next
            end

            if input == "engine" then
                NxEngine::set_value(listing)
                next
            end
            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxListings::dive()
    def self.dive()
        loop {
            listings = Blades::mikuType("NxListing").sort_by{|item| NxListings::ratio(item) }
            store = ItemStore.new()
            puts ""
            listings.each{|listing|
                store.register(listing, false)
                puts "#{FrontPage::toString2(store, listing)}"
            }
            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""
            CommandsAndInterpreters::interpreter(input, store)
        }
    end
end
