
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

    # NxTodos::toString(item, context = nil)
    def self.toString(item, context = nil)
        if context == "listing" then
            return "#{NxTodos::icon(item)} #{item["description"]}#{TxEngines::suffix2(item)}"
        end
        if context == "inventory" then
            return "(#{"%7.3f" % (item["global-positioning"] || 0)}) #{NxTodos::icon(item)} #{item["description"]}#{TxEngines::suffix2(item)}"
        end
        "(#{"%7.3f" % (item["global-positioning"] || 0)}) #{NxTodos::icon(item)} #{item["description"]}#{TxEngines::suffix2(item)}"
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

    # NxTodos::basicHoursPerDayForProjectsWithoutEngine()
    def self.basicHoursPerDayForProjectsWithoutEngine()
        1.5
    end

    # ------------------
    # Ops

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
            puts MainUserInterface::toString2(store, project, "inventory")
            puts ""

            NxTodos::children(project)
                .each{|element|
                    store.register(element, MainUserInterface::canBeDefault(element))
                    puts MainUserInterface::toString2(store, element, "listing")
                }

            puts ""

            puts "top | pile | todo | position * | sort | move"

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
                Catalyst::selectSubsetOfItemsAndMove(NxTodos::children(project))
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

    # NxTodos::properlyPositionNewlyCreatedTodo(item)
    def self.properlyPositionNewlyCreatedTodo(item)
        loop {
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["set parent", "in orbital", "with own engine"])
            next if option.nil?
            if option == "set parent" then
                parent = Catalyst::interactivelySelectNodeOrNull()
                next if parent.nil?
                Cubes2::setAttribute(item["uuid"], "parentuuid-0032", parent["uuid"])
                return
            end
            if option == "in orbital" then
                orbital = NxOrbitals::interactivelySelectOneOrNull()
                next if orbital.nil?
                Cubes2::setAttribute(item["uuid"], "parentuuid-0032", orbital["uuid"])
                return
            end
            if option == "with own engine" then
                core = TxEngines::interactivelyMakeNew()
                next if core.nil?
                Cubes2::setAttribute(item["uuid"], "engine-0020", core)
                return
            end
        }
        Catalyst::interactivelySetDonations(item)
    end
end
