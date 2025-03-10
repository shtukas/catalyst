
class NxCores

    # NxCores::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        hours = LucilleCore::askQuestionAnswerAsString("hours per week: ").to_f
        {
            "uuid"        => SecureRandom.uuid,
            "description" => description,
            "hours"       => hours
        }
    end

    # NxCores::makeNx1941()
    def self.makeNx1941()
        core = nil
        loop {
            core = NxCores::interactivelySelectOrNull()
            break if core
            core = NxCores::interactivelyIssueNewOrNull()
            break if core
        }
        position = NxCores::interactivelySelectGlobalPositionInCore(core)
        {
            "position" => position,
            "core" => core
        }
    end

    # ------------------
    # Data

    # NxCores::ratio(core)
    def self.ratio(core)
        hours = core["hours"].to_f
        [Bank1::recoveredAverageHoursPerDay(core["uuid"]), 0].max.to_f/(hours/7)
    end

    # NxCores::shouldShow(core)
    def self.shouldShow(core)
        return false if !DoNotShowUntil::isVisible(core["uuid"])
        Bank1::recoveredAverageHoursPerDay(core["uuid"]) < (core["hours"].to_f/7)
    end

    # NxCores::ratioString(core)
    def self.ratioString(core)
        "(#{"%6.2f" % (100 * NxCores::ratio(core))} %; #{"%5.2f" % core["hours"]} h/w)".yellow
    end

    # NxCores::infinityuuid()
    def self.infinityuuid()
        "427bbceb-923e-4feb-8232-05883553bb28"
    end

    # NxCores::cores()
    def self.cores()
        Items::mikuType("NxTask")
            .map{|item| item["nx1941"]["core"] }
            .reduce([]){|cores, core|
                if cores.map{|c| c["uuid"] }.include?(core["uuid"]) then
                    cores
                else
                    cores + [core]
                end
            }
    end

    # NxCores::totalHoursPerWeek()
    def self.totalHoursPerWeek()
        NxCores::cores().map{|item| item["hours"] }.inject(0, :+)
    end

    # NxCores::coresInRatioOrder()
    def self.coresInRatioOrder()
        NxCores::cores().sort_by{|core| NxCores::ratio(core) }
    end

    # NxCores::interactivelySelectOrNull()
    def self.interactivelySelectOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("core", NxCores::coresInRatioOrder(), lambda{|core| "#{NxCores::ratioString(core)} #{core["description"]}" })
    end

    # NxCores::core2NxTasksInOrder(core)
    def self.core2NxTasksInOrder(core)
        Items::mikuType("NxTask")
            .select{|item| item["nx1941"]["core"]["uuid"] == core["uuid"] }
            .sort_by{|item| item["nx1941"]["position"] }
    end

    # NxCores::firstPositionInCore(core)
    def self.firstPositionInCore(core)
        items = NxCores::core2NxTasksInOrder(core)
        return 1 if items.empty?
        items.first["nx1941"]["position"]
    end

    # NxCores::lastPositionInCore(core)
    def self.lastPositionInCore(core)
        items = NxCores::core2NxTasksInOrder(core)
        return 1 if items.empty?
        items.last["nx1941"]["position"]
    end

    # NxCores::interactivelySelectGlobalPositionInCore(core)
    def self.interactivelySelectGlobalPositionInCore(core)
        elements = NxCores::core2NxTasksInOrder(core)
        elements.first(20).each{|item|
            puts "#{PolyFunctions::toString(item)}"
        }
        position = LucilleCore::askQuestionAnswerAsString("position (first, next (default), <position>): ")
        if position == "" then # default does next
            position = "next"
        end
        if position == "first" then
            return ([0] + elements.map{|item| item["nx1941"]["position"] }).min.floor - 1
        end
        if position == "next" then
            return ([0] + elements.map{|item| item["nx1941"]["position"] }).max.ceil + 1
        end
        position = position.to_f
        position
    end

    # ------------------
    # Ops

    # NxCores::program1(core)
    def self.program1(core)

        loop {

            #system("clear")

            store = ItemStore.new()

            puts ""

            NxCores::core2NxTasksInOrder(core)
                .each{|element|
                    store.register(element, Listing::canBeDefault(element))
                    puts Listing::toString2(store, element)
                }

            puts ""

            puts "todo (here, with position selection) | hours | pile | position * | move * | sort"

            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "todo" then
                position = NxCores::interactivelySelectGlobalPositionInCore(core)
                nx1941 = {
                    "position" => position,
                    "core"     => core
                }
                todo = NxTasks::interactivelyIssueNewOrNull(nx1941)
                puts JSON.pretty_generate(todo)
                next
            end

            if input == "hours" then
                hours = LucilleCore::askQuestionAnswerAsString("hours per week: ").to_f
                Items::setAttribute(core["uuid"], "hours", hours)
                next
            end

            if input == "pile" then
                text = CommonUtils::editTextSynchronously("")
                lines = text.strip.lines.map{|line| line.strip }
                lines = lines.reverse
                lines.each{|line|
                    position = NxCores::firstPositionInCore(core) - 1
                    nx1941 = {
                        "position" => position,
                        "core"     => core
                    }
                    todo = NxTasks::descriptionToTask(line, nx1941)
                    puts JSON.pretty_generate(todo)
                }
                next
            end

            if input.start_with?("position") then
                listord = input[8, input.size].strip.to_i
                i = store.get(listord.to_i)
                next if i.nil?
                position = NxCores::interactivelySelectGlobalPositionInCore(core)
                nx1941 = {
                    "position" => position,
                    "core"     => core
                }
                Items::setAttribute(i["uuid"], "nx1941", nx1941)
                next
            end

            if input.start_with?("move") then
                listord = input[4, input.size].strip.to_i
                i = store.get(listord.to_i)
                next if i.nil?
                NxTasks::performItemPositioning(i)
                next
            end


            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("elements", [], NxCores::core2NxTasksInOrder(core).sort_by{|item| item["nx1941"]["position"] }, lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|i|
                    position = NxCores::firstPositionInCore(core) - 1
                    nx1941 = {
                        "position" => position,
                        "core"     => core
                    }
                    Items::setAttribute(i["uuid"], "nx1941", nx1941)
                }
                next
            end

            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxCores::program2()
    def self.program2()
        loop {
            puts "weekly total: #{NxCores::totalHoursPerWeek()} hours"
            core = NxCores::interactivelySelectOrNull()
            break if core.nil?
            NxCores::program1(core)
        }
    end
end
