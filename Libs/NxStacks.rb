
class NxStacks

    # NxStacks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        payload = UxPayload::makeNewOrNull(uuid)
        hours = LucilleCore::askQuestionAnswerAsString("hours per week: ").to_f
        prefixMode = NxStacks::interactivelySelectPrefixMode()
        Items::itemInit(uuid, "NxStack")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "hours", hours)
        Items::setAttribute(uuid, "prefixMode", prefixMode)
        Items::itemOrNull(uuid)
    end

    # NxStacks::interactivelySelectPrefixMode()
    def self.interactivelySelectPrefixMode()
        loop {
            options = ["strictly-sequential", "choice", "top3-bank-order", "all-bank-order"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("prefix mode", options)
            return option if option
        }
    end

    # ------------------
    # Data

    # NxStacks::ratio(item)
    def self.ratio(item)
        hours = item["hours"].to_f
        [Bank1::recoveredAverageHoursPerDay(item["uuid"]), 0].max.to_f/(hours/7)
    end

    # NxStacks::ratioString(item)
    def self.ratioString(item)
        "(#{"%6.2f" % (100 * NxStacks::ratio(item))} %; #{"%5.2f" % item["hours"]} h/w)".yellow
    end

    # NxStacks::toString(item)
    def self.toString(item)
        "⏱️  #{NxStacks::ratioString(item)} #{item["description"]}"
    end

    # NxStacks::inRatioOrder()
    def self.inRatioOrder()
        Items::mikuType("NxStack").sort_by{|item| NxStacks::ratio(item) }
    end

    # NxStacks::listingItems()
    def self.listingItems()
        Items::mikuType("NxStack")
            .select{|item| item["listing-positioning-2141"].nil? or item["listing-positioning-2141"] < Time.new.to_i }
            .select{|item| NxStacks::ratio(item) < 1 }
            .sort_by{|item| NxStacks::ratio(item) }
    end

    # NxStacks::interactivelySelectOrNull()
    def self.interactivelySelectOrNull()
        items = Items::mikuType("NxStack").sort_by{|item| NxStacks::ratio(item) }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("target", items, lambda{|item| PolyFunctions::toString(item) })
    end

    # NxStacks::infinityuuid()
    def self.infinityuuid()
        "427bbceb-923e-4feb-8232-05883553bb28"
    end

    # NxStacks::totalHoursPerWeek()
    def self.totalHoursPerWeek()
        Items::mikuType("NxStack").map{|item| item["hours"] }.sum
    end

    # NxStacks::bankingCorrectionFactor()
    def self.bankingCorrectionFactor()
        [NxStacks::totalHoursPerWeek().to_f/60 , 1].max
    end

    # ------------------
    # Ops

    # NxStacks::program1(core)
    def self.program1(core)

        if core["description"].start_with?("[open cycle]") then
            puts "You cannot { land on / program } #{PolyFunctions::toString(core).green} (starts with `[open cycle]`)"
            LucilleCore::pressEnterToContinue()
            return
        end

        loop {

            core = Items::itemOrNull(core["uuid"])
            return if core.nil?

            #system("clear")

            store = ItemStore.new()

            puts ""

            store.register(core, false)
            puts Listing::toString2(store, core)

            puts ""

            [
                PolyFunctions::naturalChildren(core).sort_by{|item| item["global-positioning-4233"] || 0 },
                PolyFunctions::computedChildren(core).sort_by{|item| item["global-positioning-4233"] || 0 }
            ]
                .flatten
                .sort_by{|item| item["global-positioning-4233"] || 0 }
                .each{|element|
                    store.register(element, Listing::canBeDefault(element))
                    puts Listing::toString2(store, element)
                }

            puts ""

            puts "todo (here, with position selection) | pile | position * | move * | sort | set prefix mode"

            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "todo" then
                todo = NxTasks::interactivelyIssueNewOrNull()
                next if todo.nil?
                puts JSON.pretty_generate(todo)
                Items::setAttribute(todo["uuid"], "parentuuid-0014", core["uuid"])
                position = Operations::interactivelySelectGlobalPositionInParent(core)
                Items::setAttribute(todo["uuid"], "global-positioning-4233", position)
                next
            end

            if input == "pile" then
                todo = NxTasks::interactivelyIssueNewOrNull()
                next if todo.nil?
                puts JSON.pretty_generate(todo)
                Items::setAttribute(todo["uuid"], "parentuuid-0014", core["uuid"])
                position = PolyFunctions::firstPositionInParent(core) - 1
                Items::setAttribute(todo["uuid"], "global-positioning-4233", position)
                next
            end

            if input.start_with?("position") then
                listord = input[8, input.size].strip.to_i
                i = store.get(listord.to_i)
                next if i.nil?
                position = Operations::interactivelySelectGlobalPositionInParent(core)
                Items::setAttribute(i["uuid"], "global-positioning-4233", position)
                next
            end

            if input.start_with?("move") then
                listord = input[4, input.size].strip.to_i
                i = store.get(listord.to_i)
                next if i.nil?
                NxTasks::performItemPositioningInStack(i)
                next
            end


            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("elements", [], PolyFunctions::naturalChildren(core).sort_by{|item| item["global-positioning-4233"] || 0 }, lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|i|
                    Items::setAttribute(i["uuid"], "global-positioning-4233", PolyFunctions::firstPositionInParent(core) - 1)
                }
                next
            end

            if input == "set prefix mode" then
                Items::setAttribute(core["uuid"], "prefixMode", NxStacks::interactivelySelectPrefixMode())
                next
            end

            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxStacks::program2()
    def self.program2()
        loop {
 
            # system("clear")
 
            store = ItemStore.new()
 
            puts ""
            puts "weekly total     : #{NxStacks::totalHoursPerWeek()} hours"
            puts "correction factor: #{NxStacks::bankingCorrectionFactor()}"
            puts ""

            NxStacks::inRatioOrder()
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts Listing::toString2(store, item)
                }
 
            puts ""
            puts "core | hours *"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""
 
            if input == "core" then
                core = NxStacks::interactivelyIssueNewOrNull()
                next if core.nil?
                puts JSON.pretty_generate(core)
                next
            end
 
            if input.start_with?("hours") then
                item = store.get(input[5, 99].strip.to_i)
                next if item.nil?
                hours = LucilleCore::askQuestionAnswerAsString("hours per week: ").to_f
                Items::setAttribute(item["uuid"], "hours", hours)
                next
            end
 
            puts ""
            CommandsAndInterpreters::interpreter(input, store)
        }
    end
end
