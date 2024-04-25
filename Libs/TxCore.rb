class TxCores

    # TxCores::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        hours = LucilleCore::askQuestionAnswerAsString("hours per week: ").to_f
        Cubes2::itemInit(uuid, "TxCore")
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::setAttribute(uuid, "hours", hours)
        Cubes2::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # TxCores::icon(item)
    def self.icon(item)
        "⏱️"
    end

    # TxCores::performance(item)
    def self.performance(item)
        [Bank2::recoveredAverageHoursPerDay(item["uuid"]), 0].max.to_f/(item["hours"].to_f/7)
    end

    # TxCores::ratioString(item)
    def self.ratioString(item)
        "(#{"%6.2f" % (100 * TxCores::performance(item))} %; #{"%5.2f" % item["hours"]} h/w)".yellow
    end

    # TxCores::toString(item, context = nil)
    def self.toString(item, context = nil)
        "#{TxCores::icon(item)}  #{TxCores::ratioString(item)} #{item["description"]}"
    end

    # TxCores::coresInOrder()
    def self.coresInOrder()
        Cubes2::mikuType("TxCore")
            .sort_by{|item| TxCores::performance(item) }
    end

    # TxCores::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("core", TxCores::coresInOrder(), lambda{|item| PolyFunctions::toString(item) })
    end

    # TxCores::muiItems()
    def self.muiItems()
        TxCores::coresInOrder()
            .select{|core| TxCores::performance(core) < 1 }
    end

    # ------------------
    # Ops

    # TxCores::program1(core)
    def self.program1(core)
        loop {

            core = Cubes2::itemOrNull(core["uuid"])
            return if core.nil?

            system("clear")

            store = ItemStore.new()

            puts ""

            store.register(core, false)
            puts MainUserInterface::toString2(store, core)

            puts ""

            Catalyst::children(core)
                .sort_by{|item| Bank2::recoveredAverageHoursPerDay(item["uuid"]) } # item can be a NxTodo or a NxThread
                .each{|element|
                    store.register(element, MainUserInterface::canBeDefault(element))
                    puts MainUserInterface::toString2(store, element)
                }

            puts ""

            puts "todo | thread"

            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "todo" then
                todo = NxTodos::interactivelyIssueNewOrNull()
                next if todo.nil?
                puts JSON.pretty_generate(todo)
                Cubes2::setAttribute(todo["uuid"], "parentuuid-0032", core["uuid"])
                next
            end

            if input == "thread" then
                thread = NxThreads::interactivelyIssueNewOrNull()
                next if thread.nil?
                puts JSON.pretty_generate(thread)
                Cubes2::setAttribute(thread["uuid"], "parentuuid-0032", core["uuid"])
                next
            end

            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # TxCores::program2()
    def self.program2()
        loop {

            system("clear")

            store = ItemStore.new()

            puts ""

            TxCores::coresInOrder()
                .each{|item|
                    store.register(item, MainUserInterface::canBeDefault(item))
                    puts MainUserInterface::toString2(store, item)
                }

            puts ""
            puts "core | hours *"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "core" then
                core = TxCores::interactivelyIssueNewOrNull()
                next if task.nil?
                puts JSON.pretty_generate(core)
                next
            end

            if input.start_with?("hours") then
                item = store.get(input[5, 99].strip.to_i)
                next if item.nil?
                hours = LucilleCore::askQuestionAnswerAsString("hours per week: ").to_f
                Cubes2::setAttribute(item["uuid"], "hours", hours)
                next
            end

            puts ""
            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # TxCores::maintenance()
    def self.maintenance()
        Cubes2::mikuType("NxThread").each{|core|
            Catalyst::children(core).each{|child|
                if !["NxThread", "NxTodo"].include?(child["mikuType"]) then
                    Cubes1::setAttribute(child["uuid"], "parentuuid-0032", nil?)
                end
            }
        }
    end
end
