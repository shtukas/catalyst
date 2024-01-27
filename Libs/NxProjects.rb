
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
        item["active"] ? "🔺" : "🔸"
    end

    # NxProjects::toString(item, context = nil)
    def self.toString(item, context = nil)
        global_position_str = ""
        icon = NxProjects::icon(item)
        suffix1 = ""
        description = item["description"]
        if item["uuid"] == "06ebad3e-2ecf-4acd-9eea-00cdaa6acdc3" then # orphaned tasks (automatic)
            if NxProjects::bufferInCardinal() > 0 then
                suffix1 = TxCores::suffix1(item["engine-0020"], context)
                description = "orphaned tasks (automatic); special circumstances: DataHub/Buffer-In"
            end
        end

        if context == "ns:projects:listing" then
            global_position_str = "(#{"%7.3f" % (item["global-positioning"] || 0)}) "
        end

        "#{global_position_str}#{icon}#{suffix1} #{item["description"]}"
    end

    # NxProjects::isRootListing(item)
    def self.isRootListing(item)
        item["parentuuid-0032"].nil? or Cubes2::itemOrNull(item["parentuuid-0032"]).nil? 
    end

    # NxProjects::children(listing)
    def self.children(listing)
        Cubes2::items()
            .select{|item| item["parentuuid-0032"] == listing["uuid"] }
            .sort_by{|item| item["global-positioning"] || 0 }
    end

    # NxProjects::whichShouldNotHaveChildren()
    def self.whichShouldNotHaveChildren()
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

    # NxProjects::itemsInGlobalPositioningOrder()
    def self.itemsInGlobalPositioningOrder()
        Cubes2::mikuType("NxProject").sort_by{|project| project["global-positioning"] || 0 }
    end

    # NxProjects::actives()
    def self.actives()
        Cubes2::mikuType("NxProject").select{|item| item["active"] }
    end

    # NxProjects::horizon()
    def self.horizon()
        NxProjects::actives()
            .select{|item| DoNotShowUntil2::isVisible(item) }
    end

    # NxProjects::itemsInMainListingOrder()
    def self.itemsInMainListingOrder()
        NxProjects::actives().sort_by{|item| TxCores::listingCompletionRatio(item["engine-0020"]) }
    end

    # NxProjects::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("project", NxProjects::itemsInMainListingOrder(), lambda{|item| NxProjects::toString(item) })
    end

    # NxProjects::selectZeroOrMore()
    def self.selectZeroOrMore()
        selected, _ = LucilleCore::selectZeroOrMore("item", [], NxProjects::itemsInMainListingOrder(), lambda{|item| NxProjects::toString(item) })
        selected
    end

    # NxProjects::selectSubsetOfItemsAndMove(items)
    def self.selectSubsetOfItemsAndMove(items)
        selected, _ = LucilleCore::selectZeroOrMore("selection", [], items, lambda{|item| PolyFunctions::toString(item) })
        return if selected.size == 0
        listing = NxProjects::interactivelySelectOneOrNull()
        return if NxProjects::whichShouldNotHaveChildren().include?(listing["uuid"])
        return if listing.nil?
        selected.each{|item|
            Cubes2::setAttribute(item["uuid"], "parentuuid-0032", listing["uuid"])
        }
    end

    # NxProjects::topPositionInProject(item)
    def self.topPositionInProject(item)
        ([0] + NxProjects::elementsInNaturalOrder(item).map{|task| task["global-positioning"] || 0 }).min
    end

    # NxProjects::topPosition()
    def self.topPosition()
        ([0] + Cubes2::mikuType("NxProject").map{|project| project["global-positioning"] || 0 }).min
    end

    # NxProjects::interactivelySelectPositionOrNull(listing)
    def self.interactivelySelectPositionOrNull(listing)
        elements = NxProjects::elementsInNaturalOrder(listing)
        elements.first(20).each{|item|
            puts "#{NxProjects::toString(nil, item)}"
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

    # NxProjects::numbersLine()
    def self.numbersLine()
        numbers = NxProjects::horizon()
                    .reduce([0, 0, 0, 0]){|acc, project|
                        n = TxCores::numbers(project["engine-0020"])
                        (0..3).map{|i| acc[i]+n[i]}
                    }
        "🔺 #{numbers.map{|x| x.round(2) }.join(" ")}"
    end

    # ------------------
    # Ops

    # NxProjects::interactivelySelectOneAndAddTo(itemuuid)
    def self.interactivelySelectOneAndAddTo(itemuuid)
        listing = NxProjects::interactivelySelectOneOrNull()
        return if listing.nil?
        return if NxProjects::whichShouldNotHaveChildren().include?(listing["uuid"])
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
                Cubes2::setAttribute(task["uuid"], "global-positioning", NxProjects::topPositionInProject(item) - 1)
            }
    end

    # NxProjects::program1(project, withPrefix)
    def self.program1(project, withPrefix)
        loop {

            project = Cubes2::itemOrNull(project["uuid"])
            return if project.nil?

            system("clear")

            store = ItemStore.new()

            puts ""

            store.register(project, false)
            puts MainUserInterface::toString2(store, project)
            puts ""

            elements = NxProjects::elementsInNaturalOrder(project)
            if withPrefix then
                elements = Prefix::prefix(elements)
            end

            elements
                .each{|element|
                    store.register(element, MainUserInterface::canBeDefault(element))
                    puts MainUserInterface::toString2(store, element)
                }

            puts ""

            puts "top | pile | task | position * | project | sort | move | with-prefix"

            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input.start_with?("position") then
                indx = input[8, 99].strip.to_i
                item = store.get(indx)
                next if item.nil?
                position = LucilleCore::askQuestionAnswerAsString("position: ")
                return if position == ""
                position = position.to_f
                Cubes2::setAttribute(item["uuid"], "global-positioning", position)
                next
            end

            if input == "task" then
                next if NxProjects::whichShouldNotHaveChildren().include?(project["uuid"])
                task = NxTasks::interactivelyIssueNewOrNull()
                next if task.nil?
                puts JSON.pretty_generate(task)
                Cubes2::setAttribute(task["uuid"], "parentuuid-0032", project["uuid"])
                position = NxProjects::interactivelySelectPositionOrNull(project)
                if position then
                    Cubes2::setAttribute(task["uuid"], "global-positioning", position)
                end
                next
            end

            if input == "project" then
                next if NxProjects::whichShouldNotHaveChildren().include?(project["uuid"])
                l = NxProjects::interactivelyIssueNewOrNull()
                next if l.nil?
                puts JSON.pretty_generate(l)
                Cubes2::setAttribute(l["uuid"], "parentuuid-0032", project["uuid"])
                position = NxProjects::interactivelySelectPositionOrNull(project)
                if position then
                    Cubes2::setAttribute(l["uuid"], "global-positioning", position)
                end
                next
            end

            if input == "top" then
                next if NxProjects::whichShouldNotHaveChildren().include?(project["uuid"])
                line = LucilleCore::askQuestionAnswerAsString("description: ")
                next if line == ""
                task = NxTasks::descriptionToTask1(SecureRandom.hex, line)
                puts JSON.pretty_generate(task)
                Cubes2::setAttribute(task["uuid"], "parentuuid-0032", project["uuid"])
                Cubes2::setAttribute(task["uuid"], "global-positioning", NxProjects::topPositionInProject(project) - 1)
                next
            end

            if input.start_with?("position") then
                listord = input[8, input.size].strip.to_i
                i = store.get(listord.to_i)
                next if i.nil?
                position = NxProjects::interactivelySelectPositionOrNull(project)
                next if position.nil?
                Cubes2::setAttribute(i["uuid"], "global-positioning", position)
                next
            end

            if input == "pile" then
                next if NxProjects::whichShouldNotHaveChildren().include?(project["uuid"])
                NxProjects::pile(project)
                next
            end

            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("project", [], NxProjects::elementsInNaturalOrder(project), lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|i|
                    Cubes2::setAttribute(i["uuid"], "global-positioning", NxProjects::topPositionInProject(project) - 1)
                }
                next
            end

            if input == "move" then
                NxProjects::selectSubsetOfItemsAndMove(NxProjects::elementsInNaturalOrder(project))
                next
            end

            if input == "with-prefix" then
                NxProjects::program1(project, true)
                next
            end

            puts ""
            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxProjects::program2()
    def self.program2()
        loop {

            items = NxProjects::itemsInGlobalPositioningOrder()
            return if items.empty?

            system("clear")

            store = ItemStore.new()

            puts ""

            actives = NxProjects::actives()

            puts ""
            actives
                .sort_by{|item| TxCores::listingCompletionRatio(item["engine-0020"]) }
                .each{|item|
                    store.register(item, MainUserInterface::canBeDefault(item))
                    puts MainUserInterface::toString2(store, item, "ns:projects:active")
                }

            puts ""
            puts Catalyst::numbers()

            puts ""
            items
                .each{|item|
                    store.register(item, MainUserInterface::canBeDefault(item))
                    puts MainUserInterface::toString2(store, item, "ns:projects:listing")
                }

            puts ""

            puts "position * | activate | disactivate | sort"

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

            if input.start_with?("position") then
                indx = input[8, 99].strip.to_i
                item = store.get(indx)
                next if item.nil?
                position = LucilleCore::askQuestionAnswerAsString("position: ")
                return if position == ""
                position = position.to_f
                Cubes2::setAttribute(item["uuid"], "global-positioning", position)
                next
            end

            if input == "activate" then
                projects = NxProjects::itemsInGlobalPositioningOrder()
                selected, _ = LucilleCore::selectZeroOrMore("project", [], projects, lambda{|i| PolyFunctions::toString(i) })
                selected.each{|i|
                    if i["engine-0020"].nil? then
                        puts "I need an engine for '#{PolyFunctions::toString(i).green}'"
                        core = TxCores::interactivelyMakeNew()
                        Cubes2::setAttribute(i["uuid"], "engine-0020", core)
                    end
                    Cubes2::setAttribute(i["uuid"], "active", true)
                }
                next
            end

            if input == "disactivate" then
                projects = NxProjects::itemsInGlobalPositioningOrder()
                selected, _ = LucilleCore::selectZeroOrMore("project", [], projects, lambda{|i| PolyFunctions::toString(i) })
                selected.each{|i|
                    Cubes2::setAttribute(i["uuid"], "active", false)
                }
                next
            end

            if input == "sort" then
                projects = NxProjects::itemsInGlobalPositioningOrder()
                selected, _ = LucilleCore::selectZeroOrMore("project", [], projects, lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|i|
                    Cubes2::setAttribute(i["uuid"], "global-positioning", NxProjects::topPosition() - 1)
                }
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
