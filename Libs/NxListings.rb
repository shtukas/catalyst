
class NxListings

    # NxListings::issueWithInit(uuid, description, engine)
    def self.issueWithInit(uuid, description, engine)
        Cubes2::itemInit(uuid, "NxListing")
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "engine-0020", engine)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::itemOrNull(uuid)
    end

    # NxListings::interactivelyIssueNewOrNull2(uuid)
    def self.interactivelyIssueNewOrNull2(uuid)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        core = TxCores::interactivelyMakeNewOrNull()
        return if core.nil?
        NxListings::issueWithInit(uuid, description, core)
    end

    # NxListings::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        NxListings::interactivelyIssueNewOrNull2(uuid)
    end

    # ------------------
    # Data

    # NxListings::bufferInCardinal()
    def self.bufferInCardinal()
        LucilleCore::locationsAtFolder("#{Config::pathToGalaxy()}/DataHub/Buffer-In")
            .select{|location| !File.basename(location).start_with?(".") }
            .size
    end

    # NxListings::icon(item)
    def self.icon(item)
        if item["special-circumstances-bottom-task-1939"] then
            return "🔥"
        end
        NxListings::isRootListing(item) ? "🔺" : "🔸"
    end

    # NxListings::toString(item, context = nil)
    def self.toString(item, context = nil)
        icon = NxListings::icon(item)
        if item["uuid"] == "06ebad3e-2ecf-4acd-9eea-00cdaa6acdc3" then # orphaned tasks (automatic)
            if NxListings::bufferInCardinal() > 0 then
                return "#{icon}#{TxCores::suffix1(item["engine-0020"], context)} orphaned tasks (automatic); special circumstances: DataHub/Buffer-In"
            end
        end
        "#{icon}#{TxCores::suffix1(item["engine-0020"], context)} #{item["description"]}"
    end

    # NxListings::metric(item, indx)
    def self.metric(item, indx)
        core = item["engine-0020"]
        if core["type"] == "blocking-until-done" then
            return 0.75 + 0.01 * 1.to_f/(indx+1)
        end
        0.30 + 0.20 * 1.to_f/(indx+1)
    end

    # NxListings::isRootListing(item)
    def self.isRootListing(item)
        item["parentuuid-0032"].nil? or Cubes2::itemOrNull(item["parentuuid-0032"]).nil? 
    end

    # NxListings::muiItems()
    def self.muiItems()
        Cubes2::mikuType("NxListing")
            .select{|block| NxListings::dayCompletionRatio(block) < 1 }
            .sort_by{|block| NxListings::dayCompletionRatio(block) }
    end

    # NxListings::children(listing)
    def self.children(listing)
        Cubes2::items()
            .select{|item| item["parentuuid-0032"] == listing["uuid"] }
            .sort_by{|item| item["global-positioning"] || 0 }
    end

    # NxListings::listingsWhichShouldNotHaveChildren()
    def self.listingsWhichShouldNotHaveChildren()
        [
            "06ebad3e-2ecf-4acd-9eea-00cdaa6acdc3",
            "1c699298-c26c-47d9-806b-e19f84fd5d75",
            "ba25c5c4-4a7c-47f3-ab9f-8ca04793bd34"
        ]
    end

    # NxListings::elementsInNaturalOrder(listing)
    def self.elementsInNaturalOrder(listing)
        if listing["uuid"] == "06ebad3e-2ecf-4acd-9eea-00cdaa6acdc3" then # orphaned tasks (automatic)
            if NxListings::bufferInCardinal() > 0 then
                return []
            end
            return Cubes2::mikuType("NxTask")
                    .select{|item| NxTasks::isOrphan(item) }
                    .sort_by{|item| item["global-positioning"] || 0 }
        end
        if listing["uuid"] == "1c699298-c26c-47d9-806b-e19f84fd5d75" then # waves !interruption (automatic)
            return Waves::muiItems().select{|item| !item["interruption"] }
        end
        if listing["uuid"] == "ba25c5c4-4a7c-47f3-ab9f-8ca04793bd34" then # missions (automatic)
            return Cubes2::mikuType("NxMission").sort_by{|item| item["lastDoneUnixtime"] }
        end
        children(listing)
    end

    # NxListings::elementsForPrefix(listing)
    def self.elementsForPrefix(listing)
        if listing["uuid"] == "06ebad3e-2ecf-4acd-9eea-00cdaa6acdc3" then # orphaned tasks (automatic)
            return Cubes2::mikuType("NxTask")
                    .select{|item| NxTasks::isOrphan(item) }
                    .sort_by{|item| item["global-positioning"] || 0 }
        end
        if listing["uuid"] == "1c699298-c26c-47d9-806b-e19f84fd5d75" then # waves !interruption (automatic)
            return Waves::muiItems().select{|item| !item["interruption"] }
        end
        Cubes2::items()
            .select{|item| item["parentuuid-0032"] == listing["uuid"] }
            .sort_by{|item| item["global-positioning"] || 0 }
    end

    # NxListings::isTopListing(listing)
    def self.isTopListing(listing)
        listing["parentuuid-0032"].nil? or Cubes2::itemOrNull(listing["parentuuid-0032"]).nil? 
    end

    # NxListings::topListings()
    def self.topListings()
        Cubes2::mikuType("NxListing")
            .select{|item| NxListings::isTopListing(item) }
    end

    # NxListings::interactivelySelectOneToplistingOrNull()
    def self.interactivelySelectOneToplistingOrNull()
        topListings = NxListings::topListings()
                    .sort_by{|item| NxListings::dayCompletionRatio(item) }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("block", topListings, lambda{|item| NxListings::toString(item) })
    end

    # NxListings::interactivelySelectOneUsingTopDownNavigationOrNull(listing = nil)
    def self.interactivelySelectOneUsingTopDownNavigationOrNull(listing = nil)
        if listing.nil? then
            listing = NxListings::interactivelySelectOneToplistingOrNull()
            return nil if listing.nil?
            return NxListings::interactivelySelectOneUsingTopDownNavigationOrNull(listing)
        end
        childrenlistings = NxListings::elementsInNaturalOrder(listing).select{|item| item["mikuType"] == "NxListing" }.sort_by{|item| NxListings::dayCompletionRatio(item) }
        if childrenlistings.empty? then
            return listing
        end
        selected = LucilleCore::selectEntityFromListOfEntitiesOrNull("listing", [listing] + childrenlistings, lambda{|item| NxListings::toString(item) })
        return if selected.nil?
        if selected["uuid"] == listing["uuid"] then
            return selected
        end
        NxListings::interactivelySelectOneUsingTopDownNavigationOrNull(selected)
    end

    # NxListings::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        NxListings::interactivelySelectOneUsingTopDownNavigationOrNull()
    end

    # NxListings::selectZeroOrMore()
    def self.selectZeroOrMore()
        items = Cubes2::mikuType("NxListing")
                    .sort_by{|item| NxListings::dayCompletionRatio(item) }
        selected, _ = LucilleCore::selectZeroOrMore("item", [], items, lambda{|item| NxListings::toString(item) })
        selected
    end

    # NxListings::selectSubsetOfItemsAndMove(items)
    def self.selectSubsetOfItemsAndMove(items)
        selected, _ = LucilleCore::selectZeroOrMore("selection", [], items, lambda{|item| PolyFunctions::toString(item) })
        return if selected.size == 0
        listing = NxListings::interactivelySelectOneOrNull()
        return if NxListings::listingsWhichShouldNotHaveChildren().include?(listing["uuid"])
        return if listing.nil?
        selected.each{|item|
            Cubes2::setAttribute(item["uuid"], "parentuuid-0032", listing["uuid"])
        }
    end

    # NxListings::topPosition(item)
    def self.topPosition(item)
        ([0] + NxListings::elementsInNaturalOrder(item).map{|task| task["global-positioning"] || 0 }).min
    end

    # NxListings::dayCompletionRatio(item)
    def self.dayCompletionRatio(item)
        TxCores::coreDayCompletionRatio(item["engine-0020"])
    end

    # NxListings::toString3(store, item)
    def self.toString3(store, item)
        return nil if item.nil?
        storePrefix = store ? "(#{store.prefixString()})" : "     "
        global_positioning = "[#{"%7.3f" % (item["global-positioning"] || 0)}]"
        line = "#{storePrefix}#{global_positioning}#{TxCores::suffix2(item)} #{PolyFunctions::toString(item, "listing")}#{TxPayload::suffix_string(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{DoNotShowUntil2::suffixString(item)}#{Catalyst::donationSuffix(item)}#{NxStrats::suffix(item)}"

        if !DoNotShowUntil2::isVisible(item) and !NxBalls::itemIsActive(item) then
            line = line.yellow
        end

        if TmpSkip1::isSkipped(item) then
            line = line.yellow
        end

        if NxBalls::itemIsActive(item) then
            line = line.green
        end

        line
    end

    # NxListings::interactivelySelectPositionOrNull(listing)
    def self.interactivelySelectPositionOrNull(listing)
        elements = NxListings::elementsInNaturalOrder(listing)
        elements.first(20).each{|item|
            puts "#{NxListings::toString3(nil, item)}"
        }
        position = LucilleCore::askQuestionAnswerAsString("position (first, next, <position>): ")
        if position == "first" then
            return ([0] + elements.map{|item| item["global-positioning"] || 0 }).min - 1
        end
        if position == "next" then
            return ([0] + elements.map{|item| item["global-positioning"] || 0 }).max + 1
        end
        position = position.to_f
        position
    end

    # NxListings::shouldIncludeInMuiItems(listing)
    def self.shouldIncludeInMuiItems(listing)
        if listing["uuid"] == "1c699298-c26c-47d9-806b-e19f84fd5d75" then # waves !interruption (automatic)
            return Waves::muiItems().select{|item| !item["interruption"] }.size > 0
        end
        true
    end

    # ------------------
    # Ops

    # NxListings::interactivelySelectOneAndAddTo(itemuuid)
    def self.interactivelySelectOneAndAddTo(itemuuid)
        listing = NxListings::interactivelySelectOneOrNull()
        return if listing.nil?
        return if NxListings::listingsWhichShouldNotHaveChildren().include?(listing["uuid"])
        Cubes2::setAttribute(itemuuid, "parentuuid-0032", listing["uuid"])
        position = NxListings::interactivelySelectPositionOrNull(listing)
        if position then
            Cubes2::setAttribute(itemuuid, "global-positioning", position)
        end
    end

    # NxListings::access(item)
    def self.access(item)
        NxListings::program1(item, false)
    end

    # NxListings::natural(item)
    def self.natural(item)
        NxListings::program1(item, false)
    end

    # NxListings::pile(item)
    def self.pile(item)
        text = CommonUtils::editTextSynchronously("").strip
        return if text == ""
        text
            .lines
            .map{|line| line.strip }
            .reverse
            .each{|line|
                task = NxTasks::descriptionToTask1(SecureRandom.hex, line)
                puts JSON.pretty_generate(task)
                Cubes2::setAttribute(task["uuid"], "parentuuid-0032", item["uuid"])
                Cubes2::setAttribute(task["uuid"], "global-positioning", NxListings::topPosition(item) - 1)
            }
    end

    # NxListings::program1(listing, withPrefix)
    def self.program1(listing, withPrefix)
        loop {

            listing = Cubes2::itemOrNull(listing["uuid"])
            return if listing.nil?

            system("clear")

            store = ItemStore.new()

            puts  ""
            store.register(listing, false)
            puts  MainUserInterface::toString2(store, listing)
            puts  ""

            elements = NxListings::elementsInNaturalOrder(listing)
            if withPrefix then
                elements = Prefix::prefix(elements)
            end

            elements
                .each{|element|
                    store.register(element, MainUserInterface::canBeDefault(element))
                    puts  NxListings::toString3(store, element)
                }

            puts ""

            puts "top | pile | task | position * | listing | sort | move | with-prefix"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                next if NxListings::listingsWhichShouldNotHaveChildren().include?(listing["uuid"])
                task = NxTasks::interactivelyIssueNewOrNull()
                next if task.nil?
                puts JSON.pretty_generate(task)
                Cubes2::setAttribute(task["uuid"], "parentuuid-0032", listing["uuid"])
                position = NxListings::interactivelySelectPositionOrNull(listing)
                if position then
                    Cubes2::setAttribute(task["uuid"], "global-positioning", position)
                end
                next
            end

            if input == "listing" then
                next if NxListings::listingsWhichShouldNotHaveChildren().include?(listing["uuid"])
                l = NxListings::interactivelyIssueNewOrNull()
                next if l.nil?
                puts JSON.pretty_generate(l)
                Cubes2::setAttribute(l["uuid"], "parentuuid-0032", listing["uuid"])
                position = NxListings::interactivelySelectPositionOrNull(listing)
                if position then
                    Cubes2::setAttribute(task["uuid"], "global-positioning", position)
                end
                next
            end

            if input == "top" then
                next if NxListings::listingsWhichShouldNotHaveChildren().include?(listing["uuid"])
                line = LucilleCore::askQuestionAnswerAsString("description: ")
                next if line == ""
                task = NxTasks::descriptionToTask1(SecureRandom.hex, line)
                puts JSON.pretty_generate(task)
                Cubes2::setAttribute(task["uuid"], "parentuuid-0032", listing["uuid"])
                Cubes2::setAttribute(task["uuid"], "global-positioning", NxListings::topPosition(listing) - 1)
                next
            end

            if input.start_with?("position") then
                listord = input[8, input.size].strip.to_i
                i = store.get(listord.to_i)
                next if i.nil?
                position = NxListings::interactivelySelectPositionOrNull(listing)
                next if position.nil?
                Cubes2::setAttribute(i["uuid"], "global-positioning", position)
                next
            end

            if input == "pile" then
                next if NxListings::listingsWhichShouldNotHaveChildren().include?(listing["uuid"])
                NxListings::pile(listing)
                next
            end

            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("listing", [], NxListings::elementsInNaturalOrder(listing), lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|i|
                    Cubes2::setAttribute(i["uuid"], "global-positioning", NxListings::topPosition(listing) - 1)
                }
                next
            end

            if input == "move" then
                NxListings::selectSubsetOfItemsAndMove(NxListings::elementsInNaturalOrder(listing))
                next
            end

            if input == "with-prefix" then
                NxListings::program1(listing, true)
                next
            end

            puts ""
            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxListings::program2()
    def self.program2()
        loop {

            items = Cubes2::mikuType("NxListing")
                        .sort_by{|item| NxListings::dayCompletionRatio(item) }
            return if items.empty?

            system("clear")

            store = ItemStore.new()

            puts  ""

            items
                .each{|item|
                    store.register(item, MainUserInterface::canBeDefault(item))
                    puts  MainUserInterface::toString2(store, item)
                }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input.start_with?("..") then
                indx = input[2, 9].strip.to_i
                item = store.get(indx)
                next if item.nil?
                NxListings::program1(item, false)
                next
            end

            puts ""
            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxListings::done(item)
    def self.done(item)
        DoNotShowUntil2::setUnixtime(item["uuid"], CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(CommonUtils::getLocalTimeZone()))
    end

    # NxListings::upgradeItemDonations(item)
    def self.upgradeItemDonations(item)
        listings = NxListings::selectZeroOrMore()
        donation = ((item["donation-1752"] || []) + listings.map{|listing| listing["uuid"] }).uniq
        Cubes2::setAttribute(item["uuid"], "donation-1752", donation)
    end
end
