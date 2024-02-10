
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
        ratiostring = "[#{"%6.2f" % TxEngines::listingCompletionRatio(item["engine-0020"])}] #{TxEngines::toString(item["engine-0020"])}".green
        "💫 #{ratiostring} #{description}"
    end

    # NxOrbitals::children(orbital)
    def self.children(orbital)
        Cubes2::items()
            .select{|item| item["parentuuid-0032"] == orbital["uuid"] }
            .sort_by{|item| item["global-positioning"] || 0 }
    end

    # NxOrbitals::childrenThatAreBlocks(timecore)
    def self.childrenThatAreBlocks(timecore)
        Cubes2::items()
            .select{|item| item["parentuuid-0032"] == timecore["uuid"] }
            .select{|item| item["mikuType"] == "NxBlock" }
            .sort_by{|item| item["global-positioning"] || 0 }
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

    # NxOrbitals::childrenForPrefix(timecore)
    def self.childrenForPrefix(timecore)
        NxOrbitals::children(timecore)
            .each{|item|
                next if !MainUserInterface::listable(item)
                next if Bank2::recoveredAverageHoursPerDay(item["uuid"]) > 1
                return [item]
            }
        []
    end

    # NxOrbitals::topPositionAmongChildren(item)
    def self.topPositionAmongChildren(item)
        ([0] + NxOrbitals::children(item).map{|task| task["global-positioning"] || 0 }).min
    end

    # NxOrbitals::program(orbital)
    def self.program(orbital)
        loop {

            elements = NxOrbitals::children(orbital)
            return if elements.empty?

            system("clear")

            store = ItemStore.new()

            puts ""

            elements
                .each{|item|
                    store.register(item, MainUserInterface::canBeDefault(item))
                    puts MainUserInterface::toString2(store, item, "inventory")
                }

            puts ""
            puts "todo | block | pile | position * | sort | move"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "todo" then
                task = NxTodos::interactivelyIssueNewOrNull()
                next if task.nil?
                puts JSON.pretty_generate(task)
                Cubes2::setAttribute(task["uuid"], "parentuuid-0032", orbital["uuid"])
                position = NxOrbitals::interactivelySelectPosition(orbital)
                Cubes2::setAttribute(task["uuid"], "global-positioning", position)
                next
            end

            if input == "block" then
                block = NxBlocks::interactivelyIssueNewOrNull()
                next if block.nil?
                puts JSON.pretty_generate(block)
                Cubes2::setAttribute(block["uuid"], "parentuuid-0032", orbital["uuid"])
                position = NxOrbitals::interactivelySelectPosition(orbital)
                Cubes2::setAttribute(block["uuid"], "global-positioning", position)
                next
            end

            if input.start_with?("position") then
                listord = input[8, input.size].strip.to_i
                i = store.get(listord.to_i)
                next if i.nil?
                position = NxOrbitals::interactivelySelectPosition(orbital)
                next if position.nil?
                Cubes2::setAttribute(i["uuid"], "global-positioning", position)
                next
            end

            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("project", [], NxOrbitals::children(orbital), lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|i|
                    Cubes2::setAttribute(i["uuid"], "global-positioning", NxOrbitals::topPositionAmongChildren(orbital) - 1)
                }
                next
            end

            if input == "move" then
                Catalyst::selectSubsetOfItemsAndMoveInTimeCore(NxOrbitals::children(orbital))
                next
            end

            if input == "pile" then
                text = CommonUtils::editTextSynchronously("").strip
                next if text == ""
                text
                    .lines
                    .map{|line| line.strip }
                    .reverse
                    .each{|line|
                        task = NxTodos::descriptionToTask1(SecureRandom.hex, line)
                        puts JSON.pretty_generate(task)
                        Cubes2::setAttribute(task["uuid"], "parentuuid-0032", orbital["uuid"])
                        Cubes2::setAttribute(task["uuid"], "global-positioning", NxOrbitals::topPositionAmongChildren(orbital) - 1)
                    }
                next
            end

            puts ""
            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxOrbitals::interactivelySelectPosition(item)
    def self.interactivelySelectPosition(item)
        elements = NxOrbitals::children(item)
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

    # NxOrbitals::numbers()
    def self.numbers()
        idealTodayInHours = Cubes2::mikuType("NxOrbital").map{|orbital| TxEngines::todayIdealInHours(orbital["engine-0020"]) }.inject(0, :+)
        doneTodayInHours = Cubes2::mikuType("NxOrbital").map{|orbital| Bank2::getValueAtDate(orbital["engine-0020"]["uuid"], CommonUtils::today()) }.inject(0, :+).to_f/3600
        {
            "ratio"      => doneTodayInHours.to_f/idealTodayInHours,
            "idealToday" => idealTodayInHours,
            "doneToday"  => doneTodayInHours
        }
    end
end
