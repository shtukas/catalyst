
class NxProjects

    # NxProjects::issueWithInit(uuid, description, engine)
    def self.issueWithInit(uuid, description, engine)
        Cubes2::itemInit(uuid, "NxProject")
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "engine-0020", engine)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::itemOrNull(uuid)
    end

    # NxProjects::interactivelyIssueNewOrNull2(uuid)
    def self.interactivelyIssueNewOrNull2(uuid)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        core = TxCores::interactivelyMakeNewOrNull()
        NxProjects::issueWithInit(uuid, description, core)
    end

    # NxProjects::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        NxProjects::interactivelyIssueNewOrNull2(uuid)
    end

    # NxProjects::interactivelyIssueMonitorOrNull()
    def self.interactivelyIssueMonitorOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        uuid = SecureRandom.uuid
        Cubes2::itemInit(uuid, "NxProject")
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "engine-0020", nil)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxProjects::bufferInCardinal()
    def self.bufferInCardinal()
        LucilleCore::locationsAtFolder("#{Config::pathToGalaxy()}/DataHub/Buffer-In")
            .select{|location| !File.basename(location).start_with?(".") }
            .size
    end

    # NxProjects::icon(item)
    def self.icon(item)
        item["engine-0020"] ? "🔺" : "🔸"
    end

    # NxProjects::toString(item, context = nil)
    def self.toString(item, context = nil)
        icon = NxProjects::icon(item)
        if item["uuid"] == "06ebad3e-2ecf-4acd-9eea-00cdaa6acdc3" then # orphaned tasks (automatic)
            if NxProjects::bufferInCardinal() > 0 then
                return "#{icon}#{TxCores::suffix1(item["engine-0020"], context)} orphaned tasks (automatic); special circumstances: DataHub/Buffer-In"
            end
        end
        "#{icon}#{TxCores::suffix1(item["engine-0020"], context)} #{item["description"]}"
    end

    # NxProjects::isRootListing(item)
    def self.isRootListing(item)
        item["parentuuid-0032"].nil? or Cubes2::itemOrNull(item["parentuuid-0032"]).nil? 
    end

    # NxProjects::muiItems2()
    def self.muiItems2()
        Cubes2::mikuType("NxProject")
            .select{|item| item["engine-0020"].nil? }
            .sort_by{|item| item["unixtime"] }
    end

    # NxProjects::children(listing)
    def self.children(listing)
        Cubes2::items()
            .select{|item| item["parentuuid-0032"] == listing["uuid"] }
            .sort_by{|item| item["global-positioning"] || 0 }
    end

    # NxProjects::listingsWhichShouldNotHaveChildren()
    def self.listingsWhichShouldNotHaveChildren()
        [
            "06ebad3e-2ecf-4acd-9eea-00cdaa6acdc3",
            "ba25c5c4-4a7c-47f3-ab9f-8ca04793bd34"
        ]
    end

    # NxProjects::elementsInNaturalOrder(listing)
    def self.elementsInNaturalOrder(listing)
        if listing["uuid"] == "06ebad3e-2ecf-4acd-9eea-00cdaa6acdc3" then # orphaned tasks (automatic)
            if NxProjects::bufferInCardinal() > 0 then
                return []
            end
            return Cubes2::mikuType("NxTask")
                    .select{|item| NxTasks::isOrphan(item) }
                    .sort_by{|item| item["global-positioning"] || 0 }
        end
        if listing["uuid"] == "ba25c5c4-4a7c-47f3-ab9f-8ca04793bd34" then # missions (automatic)
            return Cubes2::mikuType("NxMission").sort_by{|item| item["lastDoneUnixtime"] }
        end
        children(listing)
    end

    # NxProjects::elementsForPrefix(listing)
    def self.elementsForPrefix(listing)
        if listing["uuid"] == "06ebad3e-2ecf-4acd-9eea-00cdaa6acdc3" then # orphaned tasks (automatic)
            return Cubes2::mikuType("NxTask")
                    .select{|item| NxTasks::isOrphan(item) }
                    .sort_by{|item| item["global-positioning"] || 0 }
        end
        if listing["uuid"] == "ba25c5c4-4a7c-47f3-ab9f-8ca04793bd34" then # missions (automatic)
            return Cubes2::mikuType("NxMission").sort_by{|item| item["lastDoneUnixtime"] }.take(1)
        end
        Cubes2::items()
            .select{|item| item["parentuuid-0032"] == listing["uuid"] }
            .sort_by{|item| item["global-positioning"] || 0 }
    end

    # NxProjects::isTopListing(listing)
    def self.isTopListing(listing)
        listing["parentuuid-0032"].nil? or Cubes2::itemOrNull(listing["parentuuid-0032"]).nil? 
    end

    # NxProjects::topListings()
    def self.topListings()
        Cubes2::mikuType("NxProject")
            .select{|item| NxProjects::isTopListing(item) }
    end

    # NxProjects::itemsInOrder()
    def self.itemsInOrder()
        p1, p2 = Cubes2::mikuType("NxProject").partition{|item| item["engine-0020"] }
        p1 = p1.sort_by{|item| TxCores::listingCompletionRatio(item["engine-0020"]) }
        p2 = p2.sort_by{|item| item["unixtime"] }
        p1+p2
    end

    # NxProjects::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("project", NxProjects::itemsInOrder(), lambda{|item| NxProjects::toString(item) })
    end

    # NxProjects::selectZeroOrMore()
    def self.selectZeroOrMore()
        selected, _ = LucilleCore::selectZeroOrMore("item", [], NxProjects::itemsInOrder(), lambda{|item| NxProjects::toString(item) })
        selected
    end

    # NxProjects::selectSubsetOfItemsAndMove(items)
    def self.selectSubsetOfItemsAndMove(items)
        selected, _ = LucilleCore::selectZeroOrMore("selection", [], items, lambda{|item| PolyFunctions::toString(item) })
        return if selected.size == 0
        listing = NxProjects::interactivelySelectOneOrNull()
        return if NxProjects::listingsWhichShouldNotHaveChildren().include?(listing["uuid"])
        return if listing.nil?
        selected.each{|item|
            Cubes2::setAttribute(item["uuid"], "parentuuid-0032", listing["uuid"])
        }
    end

    # NxProjects::topPosition(item)
    def self.topPosition(item)
        ([0] + NxProjects::elementsInNaturalOrder(item).map{|task| task["global-positioning"] || 0 }).min
    end

    # NxProjects::toString3(store, item)
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

    # NxProjects::interactivelySelectPositionOrNull(listing)
    def self.interactivelySelectPositionOrNull(listing)
        elements = NxProjects::elementsInNaturalOrder(listing)
        elements.first(20).each{|item|
            puts "#{NxProjects::toString3(nil, item)}"
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

    # ------------------
    # Ops

    # NxProjects::interactivelySelectOneAndAddTo(itemuuid)
    def self.interactivelySelectOneAndAddTo(itemuuid)
        listing = NxProjects::interactivelySelectOneOrNull()
        return if listing.nil?
        return if NxProjects::listingsWhichShouldNotHaveChildren().include?(listing["uuid"])
        Cubes2::setAttribute(itemuuid, "parentuuid-0032", listing["uuid"])
        position = NxProjects::interactivelySelectPositionOrNull(listing)
        if position then
            Cubes2::setAttribute(itemuuid, "global-positioning", position)
        end
    end

    # NxProjects::access(item)
    def self.access(item)
        NxProjects::program1(item, false)
    end

    # NxProjects::natural(item)
    def self.natural(item)
        NxProjects::program1(item, false)
    end

    # NxProjects::pile(item)
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
                Cubes2::setAttribute(task["uuid"], "global-positioning", NxProjects::topPosition(item) - 1)
            }
    end

    # NxProjects::program1(listing, withPrefix)
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

            elements = NxProjects::elementsInNaturalOrder(listing)
            if withPrefix then
                elements = Prefix::prefix(elements)
            end

            elements
                .each{|element|
                    store.register(element, MainUserInterface::canBeDefault(element))
                    puts  NxProjects::toString3(store, element)
                }

            puts ""

            puts "top | pile | task | position * | listing | sort | move | with-prefix"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                next if NxProjects::listingsWhichShouldNotHaveChildren().include?(listing["uuid"])
                task = NxTasks::interactivelyIssueNewOrNull()
                next if task.nil?
                puts JSON.pretty_generate(task)
                Cubes2::setAttribute(task["uuid"], "parentuuid-0032", listing["uuid"])
                position = NxProjects::interactivelySelectPositionOrNull(listing)
                if position then
                    Cubes2::setAttribute(task["uuid"], "global-positioning", position)
                end
                next
            end

            if input == "listing" then
                next if NxProjects::listingsWhichShouldNotHaveChildren().include?(listing["uuid"])
                l = NxProjects::interactivelyIssueNewOrNull()
                next if l.nil?
                puts JSON.pretty_generate(l)
                Cubes2::setAttribute(l["uuid"], "parentuuid-0032", listing["uuid"])
                position = NxProjects::interactivelySelectPositionOrNull(listing)
                if position then
                    Cubes2::setAttribute(l["uuid"], "global-positioning", position)
                end
                next
            end

            if input == "top" then
                next if NxProjects::listingsWhichShouldNotHaveChildren().include?(listing["uuid"])
                line = LucilleCore::askQuestionAnswerAsString("description: ")
                next if line == ""
                task = NxTasks::descriptionToTask1(SecureRandom.hex, line)
                puts JSON.pretty_generate(task)
                Cubes2::setAttribute(task["uuid"], "parentuuid-0032", listing["uuid"])
                Cubes2::setAttribute(task["uuid"], "global-positioning", NxProjects::topPosition(listing) - 1)
                next
            end

            if input.start_with?("position") then
                listord = input[8, input.size].strip.to_i
                i = store.get(listord.to_i)
                next if i.nil?
                position = NxProjects::interactivelySelectPositionOrNull(listing)
                next if position.nil?
                Cubes2::setAttribute(i["uuid"], "global-positioning", position)
                next
            end

            if input == "pile" then
                next if NxProjects::listingsWhichShouldNotHaveChildren().include?(listing["uuid"])
                NxProjects::pile(listing)
                next
            end

            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("listing", [], NxProjects::elementsInNaturalOrder(listing), lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|i|
                    Cubes2::setAttribute(i["uuid"], "global-positioning", NxProjects::topPosition(listing) - 1)
                }
                next
            end

            if input == "move" then
                NxProjects::selectSubsetOfItemsAndMove(NxProjects::elementsInNaturalOrder(listing))
                next
            end

            if input == "with-prefix" then
                NxProjects::program1(listing, true)
                next
            end

            puts ""
            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxProjects::program2()
    def self.program2()
        loop {

            items = NxProjects::itemsInOrder()
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
                NxProjects::program1(item, false)
                next
            end

            puts ""
            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxProjects::done(item)
    def self.done(item)
        DoNotShowUntil2::setUnixtime(item["uuid"], CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(CommonUtils::getLocalTimeZone()))
    end

    # NxProjects::upgradeItemDonations(item)
    def self.upgradeItemDonations(item)
        listings = NxProjects::selectZeroOrMore()
        donation = ((item["donation-1752"] || []) + listings.map{|listing| listing["uuid"] }).uniq
        Cubes2::setAttribute(item["uuid"], "donation-1752", donation)
    end
end
