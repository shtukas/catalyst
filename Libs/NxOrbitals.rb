
class NxOrbitals

    # NxOrbitals::interactivelyMakeNewOrNull()
    def self.interactivelyMakeNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        hours = LucilleCore::askQuestionAnswerAsString("weekly hours (empty for abort): ")
        return nil if hours == ""
        hours = hours.to_f
        return nil if hours == 0

        uuid = SecureRandom.uuid

        Cubes2::itemInit(uuid, "NxOrbital")
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::setAttribute(uuid, "engine-0020", {
            "uuid"     => SecureRandom.hex,
            "mikuType" => "TxEngine",
            "hours"    => hours
        })

        Cubes2::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxOrbitals::toString(item, context = nil)
    def self.toString(item, context = nil)
        description = item["description"]
        if context == "listing" then
            ratiostring = "[#{"%6.2f" % TxEngines::listingCompletionRatio(item["engine-0020"])}]".green
            return "💫 #{ratiostring} #{description}"
        end
        if context == "program" then
            return "💫 #{TxEngines::toString(item["engine-0020"]).green} #{description}"
        end
        ratiostring = "[#{"%6.2f" % TxEngines::listingCompletionRatio(item["engine-0020"])}] #{TxEngines::toString(item["engine-0020"])}".green
        "💫 #{ratiostring} #{description}"
    end

    # NxOrbitals::muiItems()
    def self.muiItems()
        Cubes2::mikuType("NxOrbital").each{|orbital|
            if orbital["engine-0020"].nil? then
                puts "I need an engine for orbital '#{orbital["description"]}'"
                core = TxEngines::interactivelyMakeNewOrNull()
                Cubes2::setAttribute(orbital["uuid"], "engine-0020", core)
                return NxOrbitals::muiItems()
            end
        }

        Cubes2::mikuType("NxOrbital")
            .select{|item| TxEngines::listingCompletionRatio(item["engine-0020"]) < 1 }
            .sort_by{|item| TxEngines::listingCompletionRatio(item["engine-0020"]) }
    end

    # NxOrbitals::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("orbital", Cubes2::mikuType("NxOrbital"), lambda{|item| PolyFunctions::toString(item) })
    end

    # NxOrbitals::childrenForPrefix(orbital)
    def self.childrenForPrefix(orbital)
        # Here we have two case
        # 1. Either none of the items are active in which case we focus on the top one
        # 2. There is at least one active item and we compute the expected recovery times for each and order them

        activeItems = Catalyst::children(orbital).select{|item| item["active-1708"] }

        if activeItems.size > 0 then
            totalPriority = activeItems.map{|item| item["active-1708"] }.inject(0, :+)
            items = activeItems
                        .map{|item|
                            normalisedPriority = item["active-1708"].to_f/totalPriority
                            normalisedRecoveryTime = Bank2::recoveredAverageHoursPerDay(item["uuid"]).to_f/normalisedPriority
                            {
                                "item" => item,
                                "normalisedRecoveryTime" => normalisedRecoveryTime
                            }
                        }
                        .sort_by{|packet| packet["normalisedRecoveryTime"] }
                        .map{|packet| packet["item"]}
            return items
        end

        Catalyst::children(orbital)
            .select{|item| MainUserInterface::listable(item) }
            .take(1)
    end

    # NxOrbitals::topPositionAmongChildren(item)
    def self.topPositionAmongChildren(item)
        ([0] + Catalyst::children(item).map{|task| task["global-positioning"] || 0 }).min
    end

    # NxOrbitals::program(orbital)
    def self.program(orbital)
        loop {

            elements = Catalyst::children(orbital)

            system("clear")

            store = ItemStore.new()

            puts ""

            store.register(orbital, false)
            puts MainUserInterface::toString2(store, orbital, "program")
            puts ""

            elements
                .first(20)
                .each{|item|
                    store.register(item, MainUserInterface::canBeDefault(item))
                    puts MainUserInterface::toString2(store, item, "inventory")
                }

            puts ""
            puts "todo | block | insert | position * | sort | move | children"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "todo" then
                task = NxTodos::interactivelyIssueNewOrNull()
                next if task.nil?
                puts JSON.pretty_generate(task)
                Cubes2::setAttribute(task["uuid"], "parentuuid-0032", orbital["uuid"])
                position = Catalyst::interactivelySelectPositionInContainerOrNull(orbital)
                Cubes2::setAttribute(task["uuid"], "global-positioning", position)
                next
            end

            if input == "block" then
                block = NxBlocks::interactivelyIssueNewOrNull()
                next if block.nil?
                puts JSON.pretty_generate(block)
                Cubes2::setAttribute(block["uuid"], "parentuuid-0032", orbital["uuid"])
                position = Catalyst::interactivelySelectPositionInContainerOrNull(orbital)
                Cubes2::setAttribute(block["uuid"], "global-positioning", position)
                next
            end

            if input == "insert" then
                position = LucilleCore::askQuestionAnswerAsString("position: ").to_f
                text = CommonUtils::editTextSynchronously("").strip
                next if text == ""
                descriptions = text.lines.map{|line| line.strip }.select{|line| line != "" }
                positions = Catalyst::insertionPositions(orbital, position, descriptions.size)
                descriptions.zip(positions).each{|description, position|
                        task = NxTodos::descriptionToTask1(SecureRandom.hex, description)
                        puts JSON.pretty_generate(task)
                        Cubes2::setAttribute(task["uuid"], "parentuuid-0032", orbital["uuid"])
                        Cubes2::setAttribute(task["uuid"], "global-positioning", position)
                }
                next
            end

            if input.start_with?("position") then
                listord = input[8, input.size].strip.to_i
                i = store.get(listord.to_i)
                next if i.nil?
                position = Catalyst::interactivelySelectPositionInContainerOrNull(orbital)
                next if position.nil?
                Cubes2::setAttribute(i["uuid"], "global-positioning", position)
                next
            end

            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("project", [], Catalyst::children(orbital), lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|i|
                    Cubes2::setAttribute(i["uuid"], "global-positioning", NxOrbitals::topPositionAmongChildren(orbital) - 1)
                }
                next
            end

            if input == "move" then
                Catalyst::selectSubsetOfItemsAndMoveToSelectedContainer(Catalyst::children(orbital))
                next
            end

            if input == "children" then
                Catalyst::program2(elements)
                next
            end

            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxOrbitals::numbers()
    def self.numbers()
        idealTodayInHours = Cubes2::mikuType("NxOrbital").map{|orbital| TxEngines::dailyHours(orbital["engine-0020"]) }.inject(0, :+)
        doneTodayInHours = Cubes2::mikuType("NxOrbital").map{|orbital| Bank2::getValueAtDate(orbital["engine-0020"]["uuid"], CommonUtils::today()) }.inject(0, :+).to_f/3600
        {
            "ratio"      => doneTodayInHours.to_f/idealTodayInHours,
            "idealToday" => idealTodayInHours,
            "doneToday"  => doneTodayInHours
        }
    end
end
