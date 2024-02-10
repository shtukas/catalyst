
class NxBlocks

    # NxBlocks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        Cubes2::itemInit(uuid, "NxBlock")
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxBlocks::icon(item)
    def self.icon(item)
        "🧊"
    end

    # NxBlocks::toString(item, context = nil)
    def self.toString(item, context = nil)
        if context == "listing" then
            str1 = "(#{"%6.2f" % Bank2::recoveredAverageHoursPerDay(item["uuid"])})".green
            return "#{NxBlocks::icon(item)} #{str1} #{item["description"]}"
        end
        if context == "inventory" then
            return "(#{"%7.3f" % (item["global-positioning"] || 0)}) #{NxBlocks::icon(item)} #{item["description"]}"
        end
        "(#{"%7.3f" % (item["global-positioning"] || 0)}) #{NxBlocks::icon(item)} #{item["description"]}"
    end

    # NxBlocks::childrenForPrefix(block)
    def self.childrenForPrefix(block)
        Catalyst::children(block)
            .each{|item|
                next if !MainUserInterface::listable(item)
                next if Bank2::recoveredAverageHoursPerDay(item["uuid"]) > 1
                return [item]
            }
        []
    end

    # NxBlocks::itemsInGlobalPositioningOrder()
    def self.itemsInGlobalPositioningOrder()
        Cubes2::mikuType("NxBlock").sort_by{|project| project["global-positioning"] || 0 }
    end

    # NxBlocks::topPositionAmongChildren(item)
    def self.topPositionAmongChildren(item)
        ([0] + Catalyst::children(item).map{|task| task["global-positioning"] || 0 }).min
    end

    # NxBlocks::topPosition()
    def self.topPosition()
        ([0] + Cubes2::mikuType("NxBlock").map{|project| project["global-positioning"] || 0 }).min
    end

    # NxBlocks::nextPosition()
    def self.nextPosition()
        ([0] + Cubes2::mikuType("NxBlock").map{|project| project["global-positioning"] || 0 }).max + 1
    end

    # NxBlocks::basicHoursPerDayForProjectsWithoutEngine()
    def self.basicHoursPerDayForProjectsWithoutEngine()
        1.5
    end

    # ------------------
    # Ops

    # NxBlocks::access(item)
    def self.access(item)
        if TxPayload::itemHasPayload(item) then
            TxPayload::access(item)
        end
        NxBlocks::program1(item)
    end

    # NxBlocks::access(item)
    def self.natural(item)
        NxBlocks::access(item)
    end

    # NxBlocks::pile(item)
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
                Cubes2::setAttribute(task["uuid"], "global-positioning", NxBlocks::topPositionAmongChildren(item) - 1)
            }
    end

    # NxBlocks::program1(block)
    def self.program1(block)
        loop {

            block = Cubes2::itemOrNull(block["uuid"])
            return if block.nil?

            system("clear")

            store = ItemStore.new()

            puts ""

            store.register(block, false)
            puts MainUserInterface::toString2(store, block, "inventory")
            puts ""

            Catalyst::children(block)
                .each{|element|
                    store.register(element, MainUserInterface::canBeDefault(element))
                    puts MainUserInterface::toString2(store, element, "listing")
                }

            puts ""

            puts "todo | pile | block | position * | sort | move"

            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "todo" then
                task = NxBlocks::interactivelyIssueNewOrNull()
                next if task.nil?
                puts JSON.pretty_generate(task)
                Cubes2::setAttribute(task["uuid"], "parentuuid-0032", block["uuid"])
                position = Catalyst::interactivelySelectPositionInContainerOrNull(block)
                Cubes2::setAttribute(task["uuid"], "global-positioning", position)
                next
            end

            if input == "pile" then
                NxBlocks::pile(block)
                next
            end

            if input == "block" then
                bx = NxBlocks::interactivelyIssueNewOrNull()
                next if bx.nil?
                puts JSON.pretty_generate(bx)
                Cubes2::setAttribute(bx["uuid"], "parentuuid-0032", block["uuid"])
                position = Catalyst::interactivelySelectPositionInContainerOrNull(block)
                Cubes2::setAttribute(bx["uuid"], "global-positioning", position)
                next
            end

            if input.start_with?("position") then
                listord = input[8, input.size].strip.to_i
                i = store.get(listord.to_i)
                next if i.nil?
                position = Catalyst::interactivelySelectPositionInContainerOrNull(block)
                next if position.nil?
                Cubes2::setAttribute(i["uuid"], "global-positioning", position)
                next
            end

            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("elements", [], Catalyst::children(block), lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|i|
                    Cubes2::setAttribute(i["uuid"], "global-positioning", NxBlocks::topPositionAmongChildren(block) - 1)
                }
                next
            end

            if input == "move" then
                Catalyst::selectSubsetOfItemsAndMoveToSelectedContainer(Catalyst::children(block))
                next
            end

            puts ""
            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxBlocks::done(item)
    def self.done(item)
        if Catalyst::children(item).empty? then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Cubes2::destroy(item["uuid"])
            end
        else
            DoNotShowUntil2::setUnixtime(item["uuid"], CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(CommonUtils::getLocalTimeZone()))
        end
    end

    # NxBlocks::maintenance()
    def self.maintenance()
        Cubes2::mikuType("NxBlock")
            .select{|item| item["parentuuid-0032"] }
            .select{|item| Cubes2::itemOrNull(item["parentuuid-0032"]).nil? }
            .each{|item|
                Cubes2::setAttribute(item["uuid"], "parentuuid-0032", "c1ec1949-5e0d-44ae-acb2-36429e9146c0") # Misc Timecore
            }
    end

    # NxBlocks::properlyPositionNewlyCreatedBlock(item)
    def self.properlyPositionNewlyCreatedBlock(item)
        timecore = nil
        loop {
            timecore = NxOrbitals::interactivelySelectOneOrNull()
            break if timecore
        }
        Cubes2::setAttribute(item["uuid"], "parentuuid-0032", timecore["uuid"])
        position = Catalyst::interactivelySelectPositionInContainerOrNull(timecore)
        Cubes2::setAttribute(item["uuid"], "global-positioning", position)
    end
end
