class TxTimeCores

    # TxTimeCores::interactivelyMakeNewOrNull()
    def self.interactivelyMakeNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        hours = LucilleCore::askQuestionAnswerAsString("weekly hours (empty for abort): ")
        return nil if hours == ""
        hours = hours.to_f
        return nil if hours == 0

        uuid = SecureRandom.uuid
        Cubes2::itemInit(uuid, "TxTimeCore")
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::setAttribute(uuid, "type", "weekly-hours")
        Cubes2::setAttribute(uuid, "hours", hours)

        Cubes2::itemOrNull(uuid)
    end

    # TxTimeCores::toString(item, context = nil)
    def self.toString(item, context = nil)
        if context == "timecores" then
            return "⏱️ #{TxEngines::suffix1(item)} #{item["description"]}"
        end
        "⏱️  #{item["description"]}"
    end

    # TxTimeCores::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("timecore", Cubes2::mikuType("TxTimeCore"), lambda{|item| PolyFunctions::toString(item) })
    end

    # TxTimeCores::children(timecore)
    def self.children(timecore)
        Cubes2::items()
            .select{|item| item["parentuuid-0032"] == timecore["uuid"] }
            .sort_by{|item| item["global-positioning"] || 0 }
    end

    # TxTimeCores::topPositionAmongChildren(item)
    def self.topPositionAmongChildren(item)
        ([0] + TxTimeCores::children(item).map{|task| task["global-positioning"] || 0 }).min
    end

    # TxTimeCores::interactivelySelectPositionOrNull(item)
    def self.interactivelySelectPositionOrNull(item)
        elements = TxTimeCores::children(item)
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

    # TxTimeCores::program(timecore)
    def self.program(timecore)
        loop {

            elements = TxTimeCores::children(timecore)
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
            puts "todo | pile | position * | sort | move"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "todo" then
                task = NxTodos::interactivelyIssueNewOrNull()
                next if task.nil?
                puts JSON.pretty_generate(task)
                Cubes2::setAttribute(task["uuid"], "parentuuid-0032", timecore["uuid"])
                position = TxTimeCores::interactivelySelectPositionOrNull(timecore)
                if position then
                    Cubes2::setAttribute(task["uuid"], "global-positioning", position)
                end
                next
            end

            if input.start_with?("position") then
                listord = input[8, input.size].strip.to_i
                i = store.get(listord.to_i)
                next if i.nil?
                position = TxTimeCores::interactivelySelectPositionOrNull(timecore)
                next if position.nil?
                Cubes2::setAttribute(i["uuid"], "global-positioning", position)
                next
            end

            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("project", [], TxTimeCores::children(timecore), lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|i|
                    Cubes2::setAttribute(i["uuid"], "global-positioning", TxTimeCores::topPositionAmongChildren(timecore) - 1)
                }
                next
            end

            if input == "move" then
                Catalyst::selectSubsetOfItemsAndMove(TxTimeCores::children(timecore))
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
                        Cubes2::setAttribute(task["uuid"], "parentuuid-0032", timecore["uuid"])
                        Cubes2::setAttribute(task["uuid"], "global-positioning", TxTimeCores::topPositionAmongChildren(timecore) - 1)
                    }
                next
            end

            puts ""
            CommandsAndInterpreters::interpreter(input, store)
        }
    end
end