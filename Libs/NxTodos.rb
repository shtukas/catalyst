
class NxTodos

    # NxTodos::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        Cubes2::itemInit(uuid, "NxTodo")
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::itemOrNull(uuid)
    end

    # NxTodos::descriptionToTask1(uuid, description)
    def self.descriptionToTask1(uuid, description)
        Cubes2::itemInit(uuid, "NxTodo")
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxTodos::bufferInCardinal()
    def self.bufferInCardinal()
        LucilleCore::locationsAtFolder("#{Config::pathToGalaxy()}/DataHub/Buffer-In")
            .select{|location| !File.basename(location).start_with?(".") }
            .size
    end

    # NxTodos::icon(item)
    def self.icon(item)
        if !NxTodos::children(item).empty? then
            return "🔺"
        end
        "🔹"
    end

    # NxTodos::toString(item)
    def self.toString(item)
        "(#{"%7.3f" % (item["global-positioning"] || 0)}) #{NxTodos::icon(item)} #{item["description"]}#{TxCores::suffix2(item)}"
    end

    # NxTodos::children(listing)
    def self.children(listing)
        Cubes2::items()
            .select{|item| item["parentuuid-0032"] == listing["uuid"] }
            .sort_by{|item| item["global-positioning"] || 0 }
    end

    # NxTodos::itemsInGlobalPositioningOrder()
    def self.itemsInGlobalPositioningOrder()
        Cubes2::mikuType("NxTodo").sort_by{|project| project["global-positioning"] || 0 }
    end

    # NxTodos::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("todo", NxTodos::rootTodos(), lambda{|item| NxTodos::toString(item) })
    end

    # NxTodos::selectZeroOrMore()
    def self.selectZeroOrMore()
        selected, _ = LucilleCore::selectZeroOrMore("item", [], NxTodos::rootTodos(), lambda{|item| NxTodos::toString(item) })
        selected
    end

    # NxTodos::selectSubsetOfItemsAndMove(items)
    def self.selectSubsetOfItemsAndMove(items)
        selected, _ = LucilleCore::selectZeroOrMore("selection", [], items, lambda{|item| PolyFunctions::toString(item) })
        return if selected.size == 0
        listing = NxTodos::interactivelySelectOneOrNull()
        return if listing.nil?
        selected.each{|item|
            Cubes2::setAttribute(item["uuid"], "parentuuid-0032", listing["uuid"])
        }
    end

    # NxTodos::topPositionAmongChildren(item)
    def self.topPositionAmongChildren(item)
        ([0] + NxTodos::children(item).map{|task| task["global-positioning"] || 0 }).min
    end

    # NxTodos::topPosition()
    def self.topPosition()
        ([0] + Cubes2::mikuType("NxTodo").map{|project| project["global-positioning"] || 0 }).min
    end

    # NxTodos::nextPosition()
    def self.nextPosition()
        ([0] + Cubes2::mikuType("NxTodo").map{|project| project["global-positioning"] || 0 }).max + 1
    end

    # NxTodos::interactivelySelectPositionOrNull(listing)
    def self.interactivelySelectPositionOrNull(listing)
        elements = NxTodos::children(listing)
        elements.first(20).each{|item|
            puts "#{PolyFunctions::toString(item)}"
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

    # NxTodos::muiItems()
    def self.muiItems()

        # We focus on 5 items per day to avoid being fed new items at ratio 0
        # intra day.

        # Tracking object
        # {
        #    "date"  : YYYY-MM-DD
        #    "uuids" : Array[String]
        # }

        data = (lambda {

            folderpath = "#{Config::pathToCatalystDataRepository()}/todos-daily"

            filepaths = LucilleCore::locationsAtFolder(folderpath)
                            .select{|location| location[-5, 5] == ".json" }
                            .map{|filepath|
                                data = JSON.parse(IO.read(filepath))
                                if data["date"] == CommonUtils::today() then
                                    filepath
                                else
                                    FileUtils.rm(filepath)
                                    nil
                                end
                            }
                            .compact

            filepaths.drop(1).each{|filepath| FileUtils.rm(filepath) }

            if filepaths.size > 0 then
                JSON.parse(IO.read(filepaths.first))
            else
                filepath = "#{Config::pathToCatalystDataRepository()}/todos-daily/#{CommonUtils::timeStringL22()}.json"
                data = {
                    "date"  => CommonUtils::today(),
                    "uuids" => NxTodos::rootTodos().first(5).map{|item| item["uuid"] }
                }
                File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(data)) }
                data
            end

        }).call()

        data["uuids"]
            .map{|uuid| Cubes2::itemOrNull(uuid) }
            .compact
            .select{|item| DoNotShowUntil2::isVisible(item) }
    end

    # NxTodos::basicHoursPerDayForProjectsWithoutEngine()
    def self.basicHoursPerDayForProjectsWithoutEngine()
        1.5
    end

    # NxTodos::rootTodos()
    def self.rootTodos()
        NxTodos::itemsInGlobalPositioningOrder()
            .select{|item| item["parentuuid-0032"].nil? }
            .sort_by{|item| item["global-positioning"] || 0 }
    end

    # NxTodos::interactivelySelectTopTodoOrNull()
    def self.interactivelySelectTopTodoOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("root todo", NxTodos::rootTodos(), lambda{|item| PolyFunctions::toString(item) })
    end

    # NxTodos::interactivelySelectPositionAmoungTopTodos()
    def self.interactivelySelectPositionAmoungTopTodos()
        elements = NxTodos::rootTodos()
        elements.each{|item|
            puts "#{PolyFunctions::toString(item)}"
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

    # NxTodos::interactivelySelectOneAndAddTo(itemuuid)
    def self.interactivelySelectOneAndAddTo(itemuuid)
        listing = NxTodos::interactivelySelectOneOrNull()
        return if listing.nil?
        Cubes2::setAttribute(itemuuid, "parentuuid-0032", listing["uuid"])
        position = NxTodos::interactivelySelectPositionOrNull(listing)
        if position then
            Cubes2::setAttribute(itemuuid, "global-positioning", position)
        end
    end

    # NxTodos::access(item)
    def self.access(item)
        if TxPayload::itemHasPayload(item) then
            TxPayload::access(item)
        end
        if NxTodos::children(item).size > 0 then
            NxTodos::program1(item)
        end
    end

    # NxTodos::access(item)
    def self.natural(item)
        NxTodos::access(item)
    end

    # NxTodos::pile(item)
    def self.pile(item)
        text = CommonUtils::editTextSynchronously("").strip
        return if text == ""
        text
            .lines
            .map{|line| line.strip }
            .reverse
            .each{|line|
                task = NxTodos::descriptionToTask1(SecureRandom.hex, line)
                puts JSON.pretty_generate(task)
                Cubes2::setAttribute(task["uuid"], "parentuuid-0032", item["uuid"])
                Cubes2::setAttribute(task["uuid"], "global-positioning", NxTodos::topPositionAmongChildren(item) - 1)
            }
    end

    # NxTodos::program1(project)
    def self.program1(project)
        loop {

            project = Cubes2::itemOrNull(project["uuid"])
            return if project.nil?

            system("clear")

            store = ItemStore.new()

            puts ""

            store.register(project, false)
            puts MainUserInterface::toString2(store, project)
            puts ""

            NxTodos::children(project)
                .each{|element|
                    store.register(element, MainUserInterface::canBeDefault(element))
                    puts MainUserInterface::toString2(store, element)
                }

            puts ""

            puts "top | pile | todo | position * | project | sort | move | with-prefix"

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

            if input == "todo" then
                task = NxTodos::interactivelyIssueNewOrNull()
                next if task.nil?
                puts JSON.pretty_generate(task)
                Cubes2::setAttribute(task["uuid"], "parentuuid-0032", project["uuid"])
                position = NxTodos::interactivelySelectPositionOrNull(project)
                if position then
                    Cubes2::setAttribute(task["uuid"], "global-positioning", position)
                end
                next
            end

            if input == "project" then
                l = NxTodos::interactivelyIssueNewOrNull()
                next if l.nil?
                puts JSON.pretty_generate(l)
                Cubes2::setAttribute(l["uuid"], "parentuuid-0032", project["uuid"])
                position = NxTodos::interactivelySelectPositionOrNull(project)
                if position then
                    Cubes2::setAttribute(l["uuid"], "global-positioning", position)
                end
                next
            end

            if input == "top" then
                line = LucilleCore::askQuestionAnswerAsString("description: ")
                next if line == ""
                task = NxTodos::descriptionToTask1(SecureRandom.hex, line)
                puts JSON.pretty_generate(task)
                Cubes2::setAttribute(task["uuid"], "parentuuid-0032", project["uuid"])
                Cubes2::setAttribute(task["uuid"], "global-positioning", NxTodos::topPositionAmongChildren(project) - 1)
                next
            end

            if input.start_with?("position") then
                listord = input[8, input.size].strip.to_i
                i = store.get(listord.to_i)
                next if i.nil?
                position = NxTodos::interactivelySelectPositionOrNull(project)
                next if position.nil?
                Cubes2::setAttribute(i["uuid"], "global-positioning", position)
                next
            end

            if input == "pile" then
                NxTodos::pile(project)
                next
            end

            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("project", [], NxTodos::children(project), lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|i|
                    Cubes2::setAttribute(i["uuid"], "global-positioning", NxTodos::topPositionAmongChildren(project) - 1)
                }
                next
            end

            if input == "move" then
                NxTodos::selectSubsetOfItemsAndMove(NxTodos::children(project))
                next
            end

            if input == "with-prefix" then
                NxTodos::program1(project)
                next
            end

            puts ""
            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxTodos::program2()
    def self.program2()
        loop {

            items = NxTodos::rootTodos()
            return if items.empty?

            system("clear")

            store = ItemStore.new()

            puts ""

            items
                .each{|item|
                    store.register(item, MainUserInterface::canBeDefault(item))
                    puts MainUserInterface::toString2(store, item)
                }

            puts ""

            puts "position * | sort"

            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input.start_with?("..") then
                indx = input[2, 9].strip.to_i
                item = store.get(indx)
                next if item.nil?
                NxTodos::program1(item)
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

            if input == "sort" then
                projects = NxTodos::itemsInGlobalPositioningOrder()
                selected, _ = LucilleCore::selectZeroOrMore("project", [], projects, lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|i|
                    Cubes2::setAttribute(i["uuid"], "global-positioning", NxTodos::topPosition() - 1)
                }
                next
            end

            puts ""
            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxTodos::done(item)
    def self.done(item)
        if NxTodos::children(item).empty? then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Cubes2::destroy(item["uuid"])
            end
        else
            DoNotShowUntil2::setUnixtime(item["uuid"], CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(CommonUtils::getLocalTimeZone()))
        end
    end

    # NxTodos::maintenance()
    def self.maintenance()
        Cubes2::mikuType("NxTodo")
            .select{|item| item["parentuuid-0032"] }
            .select{|item| Cubes2::itemOrNull(item["parentuuid-0032"]).nil? }
            .each{|item|
                Cubes2::setAttribute(item["uuid"], "parentuuid-0032", nil)
            }
    end

    # NxTodos::properlyDecorateNewlyCreatedTodo(item)
    def self.properlyDecorateNewlyCreatedTodo(item)
        loop {
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["top todo (with position)", "in listing", "with own engine"])
            next if option.nil?
            if option == "top todo (with position)" then
                position = NxTodos::interactivelySelectPositionAmoungTopTodos()
                Cubes2::setAttribute(item["uuid"], "global-positioning", position)
                return
            end
            if option == "in listing" then
                NxTodos::interactivelySelectOneAndAddTo(item["uuid"])
                return
            end
            if option == "with own engine" then
                core = TxCores::interactivelyMakeNew()
                next if core.nil?
                Cubes2::setAttribute(item["uuid"], "engine-0020", core)
                return
            end
            if option == "with own engine" then
                core = TxCores::interactivelyMakeNew()
                next if core.nil?
                Cubes2::setAttribute(item["uuid"], "engine-0020", core)
                return
            end
        }
        Catalyst::interactivelyUpgradeItemDonations(item)
    end
end
